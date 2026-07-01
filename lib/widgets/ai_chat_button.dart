import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../screens/model_setup_screen.dart';
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
///
/// Conversation history is preserved across sheet open/close cycles by a
/// process-wide singleton store. The button also pulses, glows and rotates
/// its icon when idle so it stays visually alive on top of any screen.
class AiChatButton extends StatefulWidget {
  final Flashcard? currentCard;

  const AiChatButton({super.key, this.currentCard});

  @override
  State<AiChatButton> createState() => _AiChatButtonState();
}

/// In-memory chat history that survives modal close/reopen but resets when
/// the app restarts. Keyed by the current flashcard id (null = global chat).
class _ChatHistoryStore {
  static final _ChatHistoryStore instance = _ChatHistoryStore._();
  _ChatHistoryStore._();

  final Map<String, List<_ChatMessage>> _byCard = {};

  String _keyFor(Flashcard? card) => card?.id?.toString() ?? '__global__';

  List<_ChatMessage> get(Flashcard? card) => _byCard[_keyFor(card)] ?? const [];

  void set(Flashcard? card, List<_ChatMessage> messages) {
    _byCard[_keyFor(card)] = List<_ChatMessage>.from(messages);
  }

  void clear(Flashcard? card) {
    _byCard.remove(_keyFor(card));
  }
}

class _AiChatButtonState extends State<AiChatButton>
    with TickerProviderStateMixin {
  Offset? _pos;
  bool _isDragging = false;
  bool _isPressed = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _rotateController;
  late final AnimationController _haloController;
  late final Animation<double> _haloAnimation;

  final _gemma = GemmaLlmService();

  @override
  void initState() {
    super.initState();

    // Slow breathing/pulse animation — scales the button gently when idle.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slow icon rotation — gives the AI brain a subtle "thinking" feel.
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Halo / ripple ring that expands outward.
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _haloAnimation = CurvedAnimation(
      parent: _haloController,
      curve: Curves.easeOut,
    );

    // Eagerly kick off the on-device LLM init so the chat can use the LLM
    // the moment the user taps the button (vs. waiting until the sheet opens).
    _gemma.initialize().catchError((_) {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _haloController.dispose();
    super.dispose();
  }

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
        final dx = _pos!.dx.clamp(0.0, constraints.maxWidth - 72);
        final dy = _pos!.dy.clamp(0.0, constraints.maxHeight - 72);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: dx,
              top: dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanUpdate: (d) {
                  setState(() {
                    _pos = Offset(
                      (_pos!.dx + d.delta.dx)
                          .clamp(0, constraints.maxWidth - 72),
                      (_pos!.dy + d.delta.dy)
                          .clamp(0, constraints.maxHeight - 72),
                    );
                  });
                },
                onPanEnd: (_) {
                  // Snap to nearest horizontal edge for a polished feel.
                  setState(() {
                    _isDragging = false;
                    final snappedX = _pos!.dx + 36 < constraints.maxWidth / 2
                        ? 12.0
                        : constraints.maxWidth - 72 - 12;
                    _pos = Offset(snappedX, _pos!.dy);
                  });
                },
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapCancel: () => setState(() => _isPressed = false),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTap: () {
                  if (!_isDragging) _openChat(context);
                },
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseController,
                      _rotateController,
                      _haloController,
                    ]),
                    builder: (context, _) {
                      final scale = _isPressed
                          ? 0.9
                          : (_isDragging ? 1.12 : _pulseAnimation.value);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Expanding halo ring — fades as it grows.
                          if (!_isDragging)
                            Opacity(
                              opacity:
                                  (1.0 - _haloAnimation.value).clamp(0.0, 0.55),
                              child: Container(
                                width: 40 + 36 * _haloAnimation.value,
                                height: 40 + 36 * _haloAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF42A5F5),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          // Main pulsing button
                          Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF42A5F5),
                                    Color(0xFF7E57C2),
                                    Color(0xFF1565C0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(
                                      _isDragging ? 0.55 : 0.35,
                                    ),
                                    blurRadius: _isDragging ? 18 : 12,
                                    spreadRadius: _isDragging ? 2 : 0,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF7E57C2)
                                        .withOpacity(0.25),
                                    blurRadius: 20,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Slowly rotating sparkle ring
                                  Transform.rotate(
                                    angle:
                                        _rotateController.value * 2 * 3.14159,
                                    child: Opacity(
                                      opacity: 0.7,
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white.withOpacity(0.85),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  // Central AI icon
                                  const Icon(
                                    Icons.psychology,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tiny status dot — green when the LLM is loaded
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _gemma.isModelLoaded
                                    ? const Color(0xFF4CAF50)
                                    : Colors.orange,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
  late List<_ChatMessage> _messages;
  bool _isGenerating = false;
  final _gemma = GemmaLlmService();

  @override
  void initState() {
    super.initState();

    // Restore prior conversation for this card (if any) so the assistant
    // remembers what was said in earlier sessions of the same flashcard.
    final saved = _ChatHistoryStore.instance.get(widget.card);
    _messages = List<_ChatMessage>.from(saved);

    // Refresh the badge once init completes (loaded or failed).
    _gemma.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      if (mounted) setState(() {});
    });

    if (_messages.isEmpty) {
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
      _persistHistory();
    } else {
      // Auto-scroll to the bottom of the restored conversation.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _persistHistory() {
    _ChatHistoryStore.instance.set(widget.card, _messages);
  }

  void _clearHistory() {
    setState(() {
      _messages.clear();
      if (widget.card != null) {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: 'Cleared. Ask me anything about **${widget.card!.title}**.',
        ));
      } else {
        _messages.add(const _ChatMessage(
          role: 'assistant',
          text: 'Cleared. Ask me a new question!',
        ));
      }
    });
    _persistHistory();
  }

  String _buildGemmaPrompt(String userQuestion) {
    final card = widget.card;

    // Build a conversation transcript using the WHOLE persisted history
    // (last 12 turns to keep the prompt bounded) so the assistant remembers
    // earlier sessions, not just messages from the current open of the sheet.
    final prior = _messages
        .take(_messages.length - 1)
        .where((m) => m.text.isNotEmpty)
        .toList();
    final start = (prior.length - 12).clamp(0, prior.length);
    final histText = prior
        .sublist(start)
        .map((m) => '${m.role == 'user' ? 'User' : 'Assistant'}: ${m.text}')
        .join('\n');
    final histBlock =
        histText.isNotEmpty ? 'Conversation so far:\n$histText\n\n' : '';

    if (card == null) {
      return 'You are a concise coding tutor. Remember the conversation context.\n\n'
          '${histBlock}User: $userQuestion\n\nAnswer concisely in 2-4 sentences.';
    }
    return 'You are a concise coding tutor. Remember and build on the conversation context. '
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
    _persistHistory();
    _scrollToBottom();

    // Ensure the model has had a chance to load before we decide which path
    // to take. If init was already attempted this is essentially a no-op.
    try {
      await _gemma.initialize();
    } catch (_) {}

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

    if (mounted) {
      setState(() => _isGenerating = false);
      _persistHistory();
    }
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
                    // Mode badge — green when LLM is loaded, orange otherwise.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gemma.isModelLoaded
                            ? AppColors.success.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _gemma.isModelLoaded
                                ? Icons.memory
                                : Icons.description_outlined,
                            size: 12,
                            color: _gemma.isModelLoaded
                                ? AppColors.success
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _gemma.isModelLoaded ? 'LLM' : 'Template',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _gemma.isModelLoaded
                                  ? AppColors.success
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Clear conversation
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Clear conversation',
                      onPressed: _isGenerating ? null : _clearHistory,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          // AI setup nudge — only shown when Gemma is not loaded
          if (!_gemma.isModelLoaded) _buildAiSetupBanner(context),
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

  /// Orange banner at the top of the chat — nudges the user to download the
  /// on-device model when the service is running in template-fallback mode.
  Widget _buildAiSetupBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.memory_outlined, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Template mode — download the AI model for real on-device answers.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Capture the navigator before popping the sheet.
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(MaterialPageRoute(
                builder: (_) => ModelSetupScreen(
                  onSetupComplete: () {
                    // Reset the singleton so _attempted / _initFuture are
                    // cleared — otherwise initialize() short-circuits to
                    // template mode even though the model is now on disk.
                    GemmaLlmService().reset();
                    GemmaLlmService().initialize().catchError((_) {});
                  },
                ),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Enable AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
