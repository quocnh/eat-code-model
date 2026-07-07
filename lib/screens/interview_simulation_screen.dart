import 'dart:async';
import 'package:flutter/material.dart';
import '../models/technique.dart';
import '../styles/colors.dart';

// ---------------------------------------------------------------------------
// Phase enum
// ---------------------------------------------------------------------------

enum InterviewPhase {
  welcome,
  problemPresented,
  thinking,
  hintCheck,
  hintGiven,
  complexityCheck,
  optimizeCheck,
  scaleCheck,
  codeIt,
  tradeoffs,
  wrapUp,
}

// ---------------------------------------------------------------------------
// Chat message model
// ---------------------------------------------------------------------------

enum MessageSender { interviewer, user, system }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ---------------------------------------------------------------------------
// Interview script builder
// ---------------------------------------------------------------------------

class _InterviewScript {
  final Technique? technique;
  final String pathName;

  _InterviewScript({this.technique, required this.pathName});

  String get topic => technique?.name ?? pathName;

  String get welcome =>
      'Welcome! I\'m glad you made it. Before we dive in — any questions about the format?\n\n'
      'I\'ll give you a $topic problem. Think out loud as much as you can. '
      'There\'s no penalty for asking clarifying questions. Ready to begin?';

  String get problem {
    final problem = technique?.relatedProblems.isNotEmpty == true
        ? technique!.relatedProblems.first
        : 'a classic $topic problem';
    final context = technique?.shortDescription ?? '';
    return 'Great! Here\'s your problem:\n\n'
        '📌 **$problem**\n\n'
        '$context\n\n'
        'Take a moment to think through your approach. What\'s the first thing '
        'that comes to mind?';
  }

  String get thinking =>
      'Sounds like you have a direction. Take your time — '
      'I\'ll check back in a bit. Let me know when you\'re ready to walk me through it.';

  String get hintCheck =>
      'How\'s it going? Would you like a hint, or are you comfortable continuing on your own?';

  String get hint {
    if (technique?.tips.isNotEmpty == true) {
      return '💡 Hint: ${technique!.tips.first}\n\n'
          'Does that help clarify the approach?';
    }
    return '💡 Think about what invariant you can maintain as you scan '
        'through the data. What property stays true at every step?';
  }

  String get complexity =>
      'Good approach! Now let\'s talk about performance.\n\n'
      'What\'s the **time complexity** of your solution? And what about space?';

  String get complexityFollowUp {
    final time = technique?.timeComplexity ?? 'O(n)';
    final space = technique?.spaceComplexity ?? 'O(n)';
    return 'Exactly right — **$time** time, **$space** space. '
        'Can you walk me through *why* it\'s $time? '
        'What\'s the dominant operation?';
  }

  String get optimize {
    if (technique?.tips.length != null && technique!.tips.length > 1) {
      return 'Nice. One follow-up: ${technique!.tips[1]}\n\n'
          'Can you think of any way to push the complexity further, '
          'or is this already optimal for this class of problem?';
    }
    return 'Can you think of any optimizations? '
        'What if you had to reduce the space usage — is that possible here?';
  }

  String get scale =>
      'Interesting! Let\'s make it harder.\n\n'
      'Imagine the input is **1 TB of streaming data** that doesn\'t fit in memory. '
      'How would you adapt your approach? '
      'What changes and what stays the same?';

  String get code =>
      'Let\'s see it in code. Walk me through your implementation — '
      'you can describe your pseudocode or write the actual code. '
      'I\'m most interested in how you handle the edge cases.';

  String get tradeoffs {
    final mistake = technique?.commonMistakes.isNotEmpty == true
        ? technique!.commonMistakes.first
        : 'off-by-one errors';
    return 'Almost done! Last question:\n\n'
        'What are the **trade-offs** of your approach? '
        'When would a different algorithm be a better choice?\n\n'
        'Also — what\'s the most common mistake people make here? '
        '(Hint: it\'s often related to: $mistake)';
  }

  String get wrapUp =>
      'That was a great session! 🎉\n\n'
      '**What you did well:**\n'
      '• Clear articulation of the approach before jumping to code\n'
      '• Good complexity analysis\n'
      '• Solid understanding of the $topic pattern\n\n'
      '**Areas to keep practicing:**\n'
      '• Edge cases and boundary conditions\n'
      '• Explaining trade-offs more precisely\n\n'
      'Overall: strong performance. Keep practicing and you\'ll nail it in a real interview!';
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class InterviewSimulationScreen extends StatefulWidget {
  final Technique? technique;
  final String pathName;
  final Color pathColor;

  const InterviewSimulationScreen({
    super.key,
    this.technique,
    required this.pathName,
    this.pathColor = AppColors.primary,
  });

  @override
  State<InterviewSimulationScreen> createState() =>
      _InterviewSimulationScreenState();
}

class _InterviewSimulationScreenState
    extends State<InterviewSimulationScreen> {
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  InterviewPhase _phase = InterviewPhase.welcome;
  bool _isTyping = false;
  bool _timerVisible = true;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late _InterviewScript _script;
  String _lastUserText = '';

  // Phases that expect a typed response vs. just a "Continue" tap
  static const _inputPhases = {
    InterviewPhase.welcome,
    InterviewPhase.problemPresented,
    InterviewPhase.thinking,
    InterviewPhase.hintCheck,
    InterviewPhase.hintGiven,
    InterviewPhase.complexityCheck,
    InterviewPhase.optimizeCheck,
    InterviewPhase.scaleCheck,
    InterviewPhase.codeIt,
    InterviewPhase.tradeoffs,
  };

  // Human-readable phase labels for the progress strip
  static const _phaseLabels = [
    'Intro',
    'Problem',
    'Think',
    'Hint?',
    'Hint',
    'Complexity',
    'Optimize',
    'Scale',
    'Code',
    'Trade-offs',
    'Done',
  ];

  @override
  void initState() {
    super.initState();
    _script = _InterviewScript(
      technique: widget.technique,
      pathName: widget.pathName,
    );
    _startTimer();
    // Post the welcome message after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postInterviewerMessage(_script.welcome);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _postInterviewerMessage(String text) async {
    setState(() => _isTyping = true);
    // Simulate a realistic typing delay (400–900ms based on message length)
    final delay = Duration(milliseconds: (text.length * 8).clamp(400, 900));
    await Future<void>.delayed(delay);
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: text, sender: MessageSender.interviewer));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _phase != InterviewPhase.wrapUp) return;

    if (!_inputPhases.contains(_phase) && text.isEmpty) return;

    // Save text before clearing so _advancePhase can read it
    _lastUserText = text;

    // Add user message
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: text, sender: MessageSender.user));
        _controller.clear();
      });
      _scrollToBottom();
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Advance phase and post next interviewer message
    await _advancePhase();
  }

  Future<void> _advancePhase() async {
    switch (_phase) {
      case InterviewPhase.welcome:
        _phase = InterviewPhase.problemPresented;
        await _postInterviewerMessage(_script.problem);
        break;

      case InterviewPhase.problemPresented:
        _phase = InterviewPhase.thinking;
        await _postInterviewerMessage(_script.thinking);
        break;

      case InterviewPhase.thinking:
        _phase = InterviewPhase.hintCheck;
        await _postInterviewerMessage(_script.hintCheck);
        break;

      case InterviewPhase.hintCheck:
        final hintQuery = _lastUserText.toLowerCase();
        final wantsHint = hintQuery.contains('yes') ||
            hintQuery.contains('hint') ||
            hintQuery.contains('help') ||
            hintQuery.contains('sure');
        if (wantsHint) {
          _phase = InterviewPhase.hintGiven;
          await _postInterviewerMessage(_script.hint);
        } else {
          _phase = InterviewPhase.complexityCheck;
          await _postInterviewerMessage(_script.complexity);
        }
        break;

      case InterviewPhase.hintGiven:
        _phase = InterviewPhase.complexityCheck;
        await _postInterviewerMessage(_script.complexity);
        break;

      case InterviewPhase.complexityCheck:
        _phase = InterviewPhase.optimizeCheck;
        await _postInterviewerMessage(_script.complexityFollowUp);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await _postInterviewerMessage(_script.optimize);
        break;

      case InterviewPhase.optimizeCheck:
        _phase = InterviewPhase.scaleCheck;
        await _postInterviewerMessage(_script.scale);
        break;

      case InterviewPhase.scaleCheck:
        _phase = InterviewPhase.codeIt;
        await _postInterviewerMessage(_script.code);
        break;

      case InterviewPhase.codeIt:
        _phase = InterviewPhase.tradeoffs;
        await _postInterviewerMessage(_script.tradeoffs);
        break;

      case InterviewPhase.tradeoffs:
        _phase = InterviewPhase.wrapUp;
        _timer?.cancel();
        await _postInterviewerMessage(_script.wrapUp);
        break;

      case InterviewPhase.wrapUp:
        Navigator.pop(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathColor = widget.pathColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      // Disable automatic resize so the body column handles keyboard insets manually
      // via a Padding wrapper — avoids double-shift when keyboard appears.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: pathColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('🎙️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Interview Simulation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Scripted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_timerVisible)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              _timerVisible ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: Colors.white,
            ),
            tooltip: _timerVisible ? 'Hide timer' : 'Show timer',
            onPressed: () => setState(() => _timerVisible = !_timerVisible),
          ),
        ],
      ),
      body: Padding(
        // Single source of keyboard avoidance — moves the whole column up
        // as the keyboard appears, so the input bar stays fully visible.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            _buildPhaseBar(pathColor),
            if (widget.technique != null) _buildTopicChip(pathColor),
            Expanded(child: _buildChatArea()),
            _buildInputArea(pathColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseBar(Color pathColor) {
    final total = InterviewPhase.values.length;
    final current = _phase.index;
    return Container(
      color: pathColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / (total - 1),
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Phase ${current + 1}/$total: ${_phaseLabels[current]}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChip(Color pathColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 16, color: pathColor),
          const SizedBox(width: 6),
          Text(
            'Topic: ${widget.technique?.name ?? widget.pathName}',
            style: TextStyle(
              color: pathColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessage(_messages[index]);
      },
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isInterviewer = msg.sender == MessageSender.interviewer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isInterviewer ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isInterviewer) ...[
            _avatarCircle(widget.pathColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isInterviewer ? Colors.white : widget.pathColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isInterviewer ? 4 : 16),
                  bottomRight: Radius.circular(isInterviewer ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _renderMessageText(
                msg.text,
                isInterviewer,
              ),
            ),
          ),
          if (!isInterviewer) ...[
            const SizedBox(width: 8),
            _avatarCircle(AppColors.textSecondary, icon: Icons.person),
          ],
        ],
      ),
    );
  }

  Widget _renderMessageText(String text, bool isInterviewer) {
    // Simple bold rendering: wrap **text** in bold
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
          color: isInterviewer ? AppColors.textPrimary : Colors.white,
          fontSize: 14.5,
          height: 1.5,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _avatarCircle(Color color, {IconData icon = Icons.support_agent}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatarCircle(widget.pathColor),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _TypingDots(color: widget.pathColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color pathColor) {
    final isDone = _phase == InterviewPhase.wrapUp;
    final hint = _phaseInputHint(_phase);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: isDone
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pathColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Finish Interview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isTyping,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _onSend(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isTyping ? null : _onSend,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isTyping
                          ? pathColor.withOpacity(0.4)
                          : pathColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
    );
  }

  String _phaseInputHint(InterviewPhase phase) {
    switch (phase) {
      case InterviewPhase.welcome:
        return 'Type "ready" or ask a question…';
      case InterviewPhase.problemPresented:
        return 'Share your initial approach…';
      case InterviewPhase.thinking:
        return 'Walk me through your solution…';
      case InterviewPhase.hintCheck:
        return 'Type "yes" for a hint, or continue…';
      case InterviewPhase.hintGiven:
        return 'How does that help? Continue…';
      case InterviewPhase.complexityCheck:
        return 'What\'s the time / space complexity?';
      case InterviewPhase.optimizeCheck:
        return 'Can you optimize further?';
      case InterviewPhase.scaleCheck:
        return 'How would you handle 1TB of data?';
      case InterviewPhase.codeIt:
        return 'Walk through your code or pseudocode…';
      case InterviewPhase.tradeoffs:
        return 'Discuss trade-offs…';
      case InterviewPhase.wrapUp:
        return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Animated typing dots widget
// ---------------------------------------------------------------------------

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_anim.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.3, 1.0);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
