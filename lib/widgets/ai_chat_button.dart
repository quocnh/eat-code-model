import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/llm_service.dart';
import '../styles/colors.dart';

// ---------------------------------------------------------------------------
// Smart card-aware Q&A — used when on-device model is not loaded
// ---------------------------------------------------------------------------

/// Parses a markdown string into a map of { lowercased-header → body }.
Map<String, String> _parseSections(String markdown) {
  final sections = <String, String>{};
  final re =
      RegExp(r'#{1,3}\s+([^\n]+)\n([\s\S]*?)(?=#{1,3}\s|\z)', multiLine: true);
  for (final m in re.allMatches(markdown)) {
    sections[m.group(1)!.toLowerCase().trim()] = m.group(2)!.trim();
  }
  return sections;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// History-aware, section-aware answer builder.
/// [history] = all messages exchanged BEFORE the current question.
String _buildSmartAnswer(
    String question, List<_ChatMessage> history, Flashcard? card) {
  if (card == null) {
    return 'Open a flashcard first and I\'ll answer questions about it!';
  }

  final q = question.toLowerCase().trim();
  final solution = card.solution;
  final cardQuestion = card.question;

  // ── Parse markdown into sections ─────────────────────────────────────────
  final sections = _parseSections(solution);

  // All code blocks
  final codeBlocks = RegExp(r'```[^\n]*\n([\s\S]*?)```')
      .allMatches(solution)
      .map((m) => '```\n${m.group(1)!.trim()}\n```')
      .join('\n\n');

  // Complexity lines (tolerates bold/italic markers)
  final timeMatch = RegExp(
          r'[*_]{0,2}time[*_]{0,2}\s*(?:complexity)?[*_]{0,2}[:\s]+([^\n]+)',
          caseSensitive: false)
      .firstMatch(solution);
  final spaceMatch = RegExp(
          r'[*_]{0,2}space[*_]{0,2}\s*(?:complexity)?[*_]{0,2}[:\s]+([^\n]+)',
          caseSensitive: false)
      .firstMatch(solution);

  // ── Follow-up detection: merge prev question topic into effective query ───
  final prevUserQ = history.reversed
          .where((m) => m.role == 'user' && m.text.isNotEmpty)
          .map((m) => m.text.toLowerCase())
          .firstOrNull ??
      '';
  final shortFollowUp = q.split(' ').length <= 5 &&
      RegExp(r'^(why|how|what|explain|more|elaborate|show|tell|give|can you)')
          .hasMatch(q);
  final effectiveQ =
      (shortFollowUp && prevUserQ.isNotEmpty) ? '$prevUserQ $q' : q;

  // ── Complexity ────────────────────────────────────────────────────────────
  if (effectiveQ.contains('time') ||
      effectiveQ.contains('space') ||
      effectiveQ.contains('complex') ||
      effectiveQ.contains('big o') ||
      effectiveQ.contains('o(')) {
    final parts = <String>[];
    if (timeMatch != null) {
      parts.add('⏱ **Time Complexity:** ${timeMatch.group(1)!.trim()}');
    }
    if (spaceMatch != null) {
      parts.add('💾 **Space Complexity:** ${spaceMatch.group(1)!.trim()}');
    }
    final complexSection = sections.entries
        .firstWhere(
            (e) =>
                e.key.contains('complex') ||
                e.key.contains('analys') ||
                e.key.contains('performance'),
            orElse: () => const MapEntry('', ''))
        .value;
    if (parts.isNotEmpty) {
      return [
        parts.join('\n'),
        if (complexSection.isNotEmpty) '\n$complexSection',
      ].join();
    }
    if (complexSection.isNotEmpty) return complexSection;
    return 'No explicit complexity label found. Here\'s the approach:\n\n'
        '${sections.values.firstOrNull ?? solution.split('\n').take(6).join('\n')}';
  }

  // ── Code / implementation ─────────────────────────────────────────────────
  if (effectiveQ.contains('code') ||
      effectiveQ.contains('implement') ||
      effectiveQ.contains('write') ||
      effectiveQ.contains('syntax') ||
      effectiveQ.contains('program') ||
      (effectiveQ.contains('solution') && !effectiveQ.contains('what'))) {
    if (codeBlocks.isNotEmpty) return codeBlocks;
    final codeSection = sections.entries
        .firstWhere(
            (e) =>
                e.key.contains('code') ||
                e.key.contains('impl') ||
                e.key.contains('solution'),
            orElse: () => const MapEntry('', ''))
        .value;
    if (codeSection.isNotEmpty) return codeSection;
    return 'Tap the card to see the full code in the solution section.';
  }

  // ── Approach / algorithm / intuition ──────────────────────────────────────
  if (effectiveQ.contains('approach') ||
      effectiveQ.contains('algorithm') ||
      effectiveQ.contains('intuition') ||
      effectiveQ.contains('idea') ||
      effectiveQ.contains('solve') ||
      effectiveQ.contains('how')) {
    final key = sections.keys.firstWhere(
        (k) =>
            k.contains('approach') ||
            k.contains('algorithm') ||
            k.contains('intuition') ||
            k.contains('idea') ||
            k.contains('method'),
        orElse: () => '');
    if (key.isNotEmpty) {
      return '**${_capitalize(key)}:**\n\n${sections[key]}';
    }
    // Return first non-code section
    final first = sections.entries.firstWhere(
        (e) =>
            !e.key.contains('code') &&
            !e.key.contains('complex') &&
            e.value.isNotEmpty,
        orElse: () => const MapEntry('', ''));
    if (first.value.isNotEmpty) return first.value;
  }

  // ── Hint ──────────────────────────────────────────────────────────────────
  if (effectiveQ.contains('hint') ||
      effectiveQ.contains('tip') ||
      effectiveQ.contains('start') ||
      effectiveQ.contains('begin')) {
    final hintSection = sections.entries
        .firstWhere((e) => e.key.contains('hint') || e.key.contains('tip'),
            orElse: () => const MapEntry('', ''))
        .value;
    if (hintSection.isNotEmpty) return '💡 **Hint:**\n\n$hintSection';
    final lines = solution.split('\n').where((l) => l.trim().isNotEmpty);
    return '💡 **Hint:** ${lines.take(3).join(' ').replaceAll(RegExp(r'#+\s*'), '')}';
  }

  // ── Problem description ───────────────────────────────────────────────────
  if (effectiveQ.contains('what') ||
      effectiveQ.contains('explain') ||
      effectiveQ.contains('describ') ||
      effectiveQ.contains('problem') ||
      effectiveQ.contains('question') ||
      effectiveQ.contains('about')) {
    final lines =
        cardQuestion.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.take(8).join('\n');
  }

  // ── Examples ──────────────────────────────────────────────────────────────
  if (effectiveQ.contains('example') ||
      effectiveQ.contains('input') ||
      effectiveQ.contains('output') ||
      effectiveQ.contains('test case')) {
    final exKey = sections.keys.firstWhere(
        (k) => k.contains('example') || k.contains('test'),
        orElse: () => '');
    if (exKey.isNotEmpty) return '**Examples:**\n\n${sections[exKey]}';
  }

  // ── Difficulty / category ─────────────────────────────────────────────────
  if (effectiveQ.contains('difficult') ||
      effectiveQ.contains('level') ||
      effectiveQ.contains('categor') ||
      effectiveQ.contains('type')) {
    return 'This is a **${card.difficulty}** level **${card.category}** problem.';
  }

  // ── Generic: return full structured overview ──────────────────────────────
  if (sections.isNotEmpty) {
    final buf = StringBuffer();
    var count = 0;
    for (final e in sections.entries) {
      if (e.value.isNotEmpty && count < 3) {
        buf.writeln('**${_capitalize(e.key)}:**\n${e.value}\n');
        count++;
      }
    }
    if (codeBlocks.isNotEmpty) buf.writeln(codeBlocks);
    return buf.toString().trim();
  }

  final lines = solution.split('\n').where((l) => l.trim().isNotEmpty).toList();
  return lines.take(8).join('\n');
}

// ---------------------------------------------------------------------------
// AiChatButton widget
// ---------------------------------------------------------------------------

/// Floating draggable AI assistant button.
/// Must be placed inside a Stack (use Positioned.fill as parent).
class AiChatButton extends StatefulWidget {
  final Flashcard? currentCard;

  const AiChatButton({super.key, this.currentCard});

  @override
  State<AiChatButton> createState() => _AiChatButtonState();
}

class _AiChatButtonState extends State<AiChatButton> {
  Offset? _pos;
  bool _isDragging = false;

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiChatSheet(card: widget.currentCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialise to bottom-right on first build
        _pos ??= Offset(
          constraints.maxWidth - 72,
          constraints.maxHeight - 80,
        );
        final dx = _pos!.dx.clamp(0.0, constraints.maxWidth - 56);
        final dy = _pos!.dy.clamp(0.0, constraints.maxHeight - 56);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: dx,
              top: dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  setState(() {
                    _isDragging = true;
                    _pos = Offset(
                      (_pos!.dx + d.delta.dx)
                          .clamp(0, constraints.maxWidth - 56),
                      (_pos!.dy + d.delta.dy)
                          .clamp(0, constraints.maxHeight - 56),
                    );
                  });
                },
                onPanEnd: (_) => setState(() => _isDragging = false),
                onTap: () {
                  if (!_isDragging) _openChat(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(_isDragging ? 0.5 : 0.3),
                        blurRadius: _isDragging ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology,
                      color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Chat sheet
// ---------------------------------------------------------------------------

class _AiChatSheet extends StatefulWidget {
  final Flashcard? card;
  const _AiChatSheet({this.card});

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isGenerating = false;
  final _gemma = GemmaLlmService();

  @override
  void initState() {
    super.initState();
    // Refresh the badge once init completes (loaded or failed).
    _gemma.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      if (mounted) setState(() {});
    });
    if (widget.card != null) {
      _messages.add(_ChatMessage(
        role: 'assistant',
        text:
            'I can help you with **${widget.card!.title}**. Ask me anything — hints, time complexity, code walkthrough, etc.',
      ));
    } else {
      _messages.add(const _ChatMessage(
        role: 'assistant',
        text: 'Ask me any coding question and I\'ll help!',
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _buildGemmaPrompt(String userQuestion) {
    final card = widget.card;

    // Build a conversation transcript from the last ~6 turns (exclude the
    // current empty assistant placeholder at the end of _messages).
    final prior = _messages
        .take(_messages.length - 1)
        .where((m) => m.text.isNotEmpty)
        .toList();
    final start = (prior.length - 6).clamp(0, prior.length);
    final histText = prior
        .sublist(start)
        .map((m) => '${m.role == 'user' ? 'User' : 'Assistant'}: ${m.text}')
        .join('\n');
    final histBlock =
        histText.isNotEmpty ? 'Conversation so far:\n$histText\n\n' : '';

    if (card == null) {
      return 'You are a concise coding tutor.\n\n'
          '${histBlock}User: $userQuestion\n\nAnswer concisely in 2-4 sentences.';
    }
    return 'You are a concise coding tutor. '
        'The user is studying "${card.title}" (${card.difficulty} ${card.category}).\n\n'
        'Problem:\n${card.question}\n\nSolution:\n${card.solution}\n\n'
        '${histBlock}User: $userQuestion\n\n'
        'Answer in 2-4 sentences. If showing code, keep it short.';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isGenerating) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _messages.add(const _ChatMessage(role: 'assistant', text: ''));
      _isGenerating = true;
    });
    _scrollToBottom();

    // Use Gemma streaming if model is loaded, else smart card-based fallback
    if (_gemma.isModelLoaded) {
      final buffer = StringBuffer();
      try {
        await for (final chunk
            in _gemma.generateStream(_buildGemmaPrompt(text))) {
          buffer.write(chunk);
          if (mounted) {
            setState(() {
              _messages.last =
                  _ChatMessage(role: 'assistant', text: buffer.toString());
            });
            _scrollToBottom();
          }
        }
      } catch (_) {
        // ignore — fall through to smart answer below
      }
      // If Gemma produced nothing, fall back to smart answer
      if (buffer.isEmpty && mounted) {
        final history =
            List<_ChatMessage>.from(_messages.sublist(0, _messages.length - 2));
        final answer = _buildSmartAnswer(text, history, widget.card);
        setState(() {
          _messages.last = _ChatMessage(role: 'assistant', text: answer);
        });
        _scrollToBottom();
      }
    } else {
      // Template fallback — answer using card content directly
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final history =
          List<_ChatMessage>.from(_messages.sublist(0, _messages.length - 2));
      final answer = _buildSmartAnswer(text, history, widget.card);
      if (mounted) {
        setState(() {
          _messages.last = _ChatMessage(role: 'assistant', text: answer);
        });
        _scrollToBottom();
      }
    }

    if (mounted) setState(() => _isGenerating = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65 + bottom,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.psychology,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.card != null
                            ? 'Ask about: ${widget.card!.title}'
                            : 'AI Assistant',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_gemma.isModelLoaded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Template mode',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange[700]),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
          // Input bar
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask a question…',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _isGenerating ? Colors.grey[300] : AppColors.primary,
                    ),
                    child: _isGenerating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: msg.text.isEmpty && !isUser && _isGenerating
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.grey[400]),
              )
            : Text(
                msg.text.isNotEmpty ? msg.text : '…',
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  const _ChatMessage({required this.role, required this.text});
}
