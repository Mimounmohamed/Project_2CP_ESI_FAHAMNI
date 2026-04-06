import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Services/ai_service.dart';
import '../models/ai_message.dart';
import '../models/chat_model.dart';
import '../models/student_profile.dart';

class AIStudyChatPage extends StatefulWidget {
  const AIStudyChatPage({super.key});

  @override
  State<AIStudyChatPage> createState() => _AIStudyChatPageState();
}

class _AIStudyChatPageState extends State<AIStudyChatPage> {
  final AIService _aiService = AIService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIMessage> _messages = <AIMessage>[];
  StreamSubscription<String>? _streamSubscription;

  StudentProfile? _studentProfile;
  bool _isLoading = false;
  bool _isProfileLoading = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isProfileLoading = false;
        _profileError = 'Sign in as a student to use AI Study Help.';
      });
      return;
    }

    try {
      final StudentProfile profile = await _aiService.getStudentProfile(userId);
      if (!mounted) return;
      setState(() {
        _studentProfile = profile;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
        _profileError = 'AI Study Help is available for student profiles only.';
      });
    }
  }

  List<String> get _quickActions => const <String>[
        'Explain this concept simply',
        'Give me a practice question',
        'Quiz me on this topic',
        'Help me solve this step by step',
      ];

  Future<void> _submitPrompt([String? forcedPrompt]) async {
    final String prompt = (forcedPrompt ?? _controller.text).trim();
    if (prompt.isEmpty || _isLoading || _studentProfile == null) {
      return;
    }

    final AIMessage userMessage = AIMessage(
      role: AIMessageRole.user,
      content: prompt,
    );
    final AIMessage placeholder = const AIMessage(
      role: AIMessageRole.assistant,
      content: '',
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(placeholder);
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final int assistantIndex = _messages.length - 1;
    final List<AIMessage> history = List<AIMessage>.from(
      _messages.take(_messages.length - 1),
    );

    await _streamSubscription?.cancel();
    _streamSubscription = _aiService
        .streamAssistantResponse(
          studentProfile: _studentProfile!,
          conversationMessages: const <MessageModel>[],
          userPrompt: prompt,
          aiHistory: history,
        )
        .listen(
          (String chunk) {
            if (!mounted) return;
            final AIMessage current = _messages[assistantIndex];
            setState(() {
              _messages[assistantIndex] = current.copyWith(
                content: current.content + chunk,
                isStreaming: true,
              );
            });
            _scrollToBottom();
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _messages[assistantIndex] = _messages[assistantIndex].copyWith(
                content: 'AI error: $error',
                isStreaming: false,
              );
              _isLoading = false;
            });
          },
          onDone: () {
            if (!mounted) return;
            setState(() {
              _messages[assistantIndex] = _messages[assistantIndex].copyWith(
                isStreaming: false,
              );
              _isLoading = false;
            });
          },
          cancelOnError: false,
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(20, 0, 0, 128),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF000080),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Study Help',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _studentProfile == null
                        ? 'General study chatbot'
                        : 'For ${_studentProfile!.schoolLevelLabel}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isProfileLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _profileError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickActions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final String action = _quickActions[index];
                            return ActionChip(
                              onPressed: () => _submitPrompt(action),
                              label: Text(action),
                              backgroundColor:
                                  const Color.fromARGB(20, 0, 0, 128),
                              side: const BorderSide(
                                color: Color.fromARGB(30, 0, 0, 128),
                              ),
                              labelStyle: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        itemCount: _messages.isEmpty ? 1 : _messages.length,
                        itemBuilder: (context, index) {
                          if (_messages.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(14, 31, 41, 55),
                                    blurRadius: 20,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Ask any study-related question here. You can ask for explanations, worked steps, quick quizzes, revision help, or examples.',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  height: 1.55,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            );
                          }

                          final AIMessage message = _messages[index];
                          final bool isUser = message.role == AIMessageRole.user;
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 340),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFF000080)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: _AIStudyMessageBody(
                                content: message.content.isEmpty &&
                                        message.isStreaming
                                    ? 'Thinking...'
                                    : message.content,
                                textColor: isUser
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 5,
                                style: GoogleFonts.nunito(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Ask any study question...',
                                  hintStyle: GoogleFonts.nunito(),
                                  filled: true,
                                  fillColor: const Color(0xFFF4F5F7),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (_) => _submitPrompt(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF000080),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isLoading ? null : _submitPrompt,
                                icon: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AIStudyMessageBody extends StatelessWidget {
  const _AIStudyMessageBody({
    required this.content,
    required this.textColor,
  });

  final String content;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final List<_AiStudySegment> segments = _splitSegments(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        switch (segment.type) {
          case _AiStudySegmentType.markdown:
            return MarkdownBody(
              data: segment.value,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.nunito(
                  fontSize: 14,
                  height: 1.5,
                  color: textColor,
                ),
                codeblockDecoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                code: TextStyle(color: textColor),
                h1: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                h2: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            );
          case _AiStudySegmentType.math:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  segment.value,
                  textStyle: TextStyle(color: textColor, fontSize: 18),
                ),
              ),
            );
        }
      }).toList(),
    );
  }

  List<_AiStudySegment> _splitSegments(String input) {
    final RegExp mathRegex = RegExp(r'(\$\$[\s\S]+?\$\$|\$[^$\n]+\$)');
    final Iterable<RegExpMatch> matches = mathRegex.allMatches(input);

    if (matches.isEmpty) {
      return <_AiStudySegment>[
        _AiStudySegment(_AiStudySegmentType.markdown, input),
      ];
    }

    int currentIndex = 0;
    final List<_AiStudySegment> segments = <_AiStudySegment>[];
    for (final RegExpMatch match in matches) {
      if (match.start > currentIndex) {
        segments.add(
          _AiStudySegment(
            _AiStudySegmentType.markdown,
            input.substring(currentIndex, match.start),
          ),
        );
      }

      final String raw = match.group(0) ?? '';
      final String tex = raw.startsWith(r'$$')
          ? raw.substring(2, raw.length - 2).trim()
          : raw.substring(1, raw.length - 1).trim();
      segments.add(_AiStudySegment(_AiStudySegmentType.math, tex));
      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      segments.add(
        _AiStudySegment(
          _AiStudySegmentType.markdown,
          input.substring(currentIndex),
        ),
      );
    }

    return segments.where((segment) => segment.value.trim().isNotEmpty).toList();
  }
}

enum _AiStudySegmentType { markdown, math }

class _AiStudySegment {
  const _AiStudySegment(this.type, this.value);

  final _AiStudySegmentType type;
  final String value;
}
