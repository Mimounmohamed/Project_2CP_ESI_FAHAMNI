import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ai_message.dart';
import '../models/chat_model.dart';
import '../models/parent_model.dart';
import '../models/student_model.dart';
import '../models/student_profile.dart';
import '../models/tutor_model.dart';

enum AITaskType {
  smartReply,
  summarizeChat,
  practiceQuestion,
  simplifyTutorMessage,
  explainConcept,
  generalTutorHelp,
}

enum AIProvider {
  anthropic,
  gemini,
}

class AIService {
  AIService({
    http.Client? client,
    FirebaseFirestore? firestore,
  }) : _client = client ?? http.Client(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final http.Client _client;
  final FirebaseFirestore _firestore;

  Future<StudentProfile> getStudentProfile(String studentId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('students').doc(studentId).get();

    if (snapshot.exists && snapshot.data() != null) {
      final StudentModel student = StudentModel.fromMap(snapshot.data()!);
      return StudentProfile.fromStudentModel(student);
    }

    final DocumentSnapshot<Map<String, dynamic>> tutorSnapshot =
        await _firestore.collection('tutors').doc(studentId).get();
    if (tutorSnapshot.exists && tutorSnapshot.data() != null) {
      final TutorModel tutor = TutorModel.fromMap(tutorSnapshot.data()!);
      return StudentProfile(
        studentId: tutor.uid,
        firstName: tutor.firstName,
        studyLevel: _studyLevelFromTutor(tutor),
        learningObjectives: tutor.expertiseDomain,
        schoolLevelLabel: tutor.levelsTaught.isNotEmpty
            ? tutor.levelsTaught.first
            : 'Secondary',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> parentSnapshot =
        await _firestore.collection('parents').doc(studentId).get();
    if (parentSnapshot.exists && parentSnapshot.data() != null) {
      final ParentModel parent = ParentModel.fromMap(parentSnapshot.data()!);
      return StudentProfile(
        studentId: parent.uid,
        firstName: parent.firstName,
        studyLevel: StudyLevel.secondary,
        learningObjectives: '',
        schoolLevelLabel: 'Secondary',
      );
    }

    throw Exception('No compatible profile found for AI assistant.');
  }

  List<String> quickActions({MessageModel? lastTutorMessage}) {
    return <String>[
      'Summarize this chat',
      'Give me a practice question',
      if (lastTutorMessage != null && lastTutorMessage.content.trim().isNotEmpty)
        'Simplify the tutor\'s last message',
      if (lastTutorMessage != null && lastTutorMessage.content.trim().isNotEmpty)
        'Explain this concept',
    ];
  }

  AITaskType taskTypeForPrompt(String prompt) {
    final String normalized = prompt.trim().toLowerCase();
    if (normalized.contains('summarize')) return AITaskType.summarizeChat;
    if (normalized.contains('practice question')) {
      return AITaskType.practiceQuestion;
    }
    if (normalized.contains('simplify')) return AITaskType.simplifyTutorMessage;
    if (normalized.contains('explain')) return AITaskType.explainConcept;
    return AITaskType.generalTutorHelp;
  }

  Stream<String> streamAssistantResponse({
    required StudentProfile studentProfile,
    required List<MessageModel> conversationMessages,
    required String userPrompt,
    List<AIMessage> aiHistory = const <AIMessage>[],
    AITaskType? taskType,
  }) {
    final AITaskType resolvedTaskType =
        taskType ?? taskTypeForPrompt(userPrompt);
    final AIProvider provider = _providerFromEnv();
    final String systemInstruction = _buildSystemInstruction(
      studentProfile: studentProfile,
      taskType: resolvedTaskType,
    );
    final List<Map<String, String>> messages = _buildAiMessages(
      conversationMessages: conversationMessages,
      aiHistory: aiHistory,
      userPrompt: userPrompt,
    );

    switch (provider) {
      case AIProvider.anthropic:
        return _streamAnthropic(
          systemInstruction: systemInstruction,
          messages: messages,
          taskType: resolvedTaskType,
        );
      case AIProvider.gemini:
        return _streamGemini(
          systemInstruction: systemInstruction,
          messages: messages,
          taskType: resolvedTaskType,
        );
    }
  }

  AIProvider _providerFromEnv() {
    final String provider =
        dotenv.env['AI_PROVIDER']?.trim().toLowerCase() ?? 'anthropic';
    return provider == 'gemini' ? AIProvider.gemini : AIProvider.anthropic;
  }

  String _buildSystemInstruction({
    required StudentProfile studentProfile,
    required AITaskType taskType,
  }) {
    final String levelInstruction = switch (studentProfile.studyLevel) {
      StudyLevel.primary =>
        'Use short sentences, everyday vocabulary, concrete examples, and a warm encouraging tone. Avoid jargon unless you define it immediately.',
      StudyLevel.secondary =>
        'Use clear school-level explanations, step-by-step reasoning, and check understanding occasionally. Introduce technical terms carefully and define them in plain language.',
      StudyLevel.university =>
        'Use precise academic language, preserve rigor, and explain why methods work. You may use domain terminology, but stay clear and well-structured.',
    };

    final String taskInstruction = switch (taskType) {
      AITaskType.smartReply =>
        'Offer concise reply suggestions the student could send. Keep them brief and natural.',
      AITaskType.summarizeChat =>
        'Summarize the tutor conversation into key takeaways, open questions, and next study steps.',
      AITaskType.practiceQuestion =>
        'Create one helpful practice question, then provide a short hint without revealing the answer unless asked.',
      AITaskType.simplifyTutorMessage =>
        'Rewrite the tutor explanation in simpler language while preserving the meaning.',
      AITaskType.explainConcept =>
        'Provide a deeper teaching-oriented explanation with examples, intuition, and if useful a worked solution.',
      AITaskType.generalTutorHelp =>
        'Act like a supportive study companion. Clarify the tutor conversation without replacing the tutor relationship.',
    };

    final String learningGoals = studentProfile.learningObjectives.trim().isEmpty
        ? ''
        : 'The student\'s learning objectives are: ${studentProfile.learningObjectives}. ';

    return '''
You are an academic AI assistant embedded inside a tutor chat for the Fahamni app.
The student is at the ${studentProfile.schoolLevelLabel} level.
$learningGoals
$levelInstruction
$taskInstruction
Keep answers educational, safe, and supportive. If the student asks for harmful, cheating-focused, or unsafe help, refuse briefly and redirect to learning.
When you use Markdown, prefer clear headings and bullets. Use fenced code blocks for code and LaTeX notation for equations when useful.
''';
  }

  List<Map<String, String>> _buildAiMessages({
    required List<MessageModel> conversationMessages,
    required List<AIMessage> aiHistory,
    required String userPrompt,
  }) {
    final String conversationTranscript = conversationMessages
        .map(
          (message) =>
              '${message.senderId == message.receiverId ? 'user' : 'chat'} ${message.senderId}: ${message.content}',
        )
        .join('\n');

    final List<Map<String, String>> messages = <Map<String, String>>[
      <String, String>{
        'role': 'user',
        'content':
            'Tutor conversation transcript:\n$conversationTranscript\n\nStudent request:\n$userPrompt',
      },
    ];

    for (final AIMessage item in aiHistory) {
      messages.add(<String, String>{
        'role': item.role == AIMessageRole.user ? 'user' : 'assistant',
        'content': item.content,
      });
    }

    return messages;
  }

  Stream<String> _streamAnthropic({
    required String systemInstruction,
    required List<Map<String, String>> messages,
    required AITaskType taskType,
  }) async* {
    final String apiKey = dotenv.env['ANTHROPIC_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw Exception('Missing ANTHROPIC_API_KEY in .env');
    }

    final String model = _anthropicModelFor(taskType);
    final http.Request request = http.Request(
      'POST',
      Uri.parse('https://api.anthropic.com/v1/messages'),
    );

    request.headers.addAll(<String, String>{
      'content-type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-dangerous-direct-browser-access': 'true',
    });
    try {
      request.body = jsonEncode(<String, dynamic>{
        'model': model,
        'max_tokens': 1024,
        'stream': true,
        'system': systemInstruction,
        'messages': messages,
      });

      final http.StreamedResponse response = await _client.send(request);
      if (response.statusCode >= 400) {
        final String body = await response.stream.bytesToString();
        throw Exception(
          'Anthropic request failed (${response.statusCode}): $body',
        );
      }

      await for (final String chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!chunk.startsWith('data:')) continue;

        final String payload = chunk.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;

        final Map<String, dynamic> data = jsonDecode(payload);
        if (data['type'] == 'content_block_delta') {
          final String? text = data['delta']?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        }
      }
    } catch (_) {
      final http.Response response = await _client.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: <String, String>{
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: jsonEncode(<String, dynamic>{
          'model': model,
          'max_tokens': 1024,
          'system': systemInstruction,
          'messages': messages,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception(
          'Anthropic request failed (${response.statusCode}): ${response.body}',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> content = data['content'] as List<dynamic>? ?? <dynamic>[];
      final String text = content
          .map((item) => item['text']?.toString() ?? '')
          .join();
      yield* _chunkText(text);
    }
  }

  Stream<String> _streamGemini({
    required String systemInstruction,
    required List<Map<String, String>> messages,
    required AITaskType taskType,
  }) async* {
    final String apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env');
    }

    final String model = _geminiModelFor(taskType);
    final http.Request request = http.Request(
      'POST',
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey',
      ),
    );

    request.headers['content-type'] = 'application/json';
    final Map<String, dynamic> payload = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, String>>[
          <String, String>{'text': systemInstruction},
        ],
      },
      'contents': messages
          .map(
            (message) => <String, dynamic>{
              'role': message['role'] == 'assistant' ? 'model' : 'user',
              'parts': <Map<String, String>>[
                <String, String>{'text': message['content'] ?? ''},
              ],
            },
          )
          .toList(),
    };

    try {
      request.body = jsonEncode(payload);

      final http.StreamedResponse response = await _client.send(request);
      if (response.statusCode >= 400) {
        final String body = await response.stream.bytesToString();
        throw Exception('Gemini request failed (${response.statusCode}): $body');
      }

      await for (final String chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!chunk.startsWith('data:')) continue;

        final String payload = chunk.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;

        final dynamic decoded = jsonDecode(payload);
        final List<dynamic> candidates =
            decoded['candidates'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic candidate in candidates) {
          final List<dynamic> parts =
              candidate['content']?['parts'] as List<dynamic>? ?? <dynamic>[];
          for (final dynamic part in parts) {
            final String? text = part['text'] as String?;
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          }
        }
      }
    } catch (_) {
      final http.Response response = await _client.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        ),
        headers: <String, String>{'content-type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 400) {
        throw Exception(
          'Gemini request failed (${response.statusCode}): ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> candidates =
          decoded['candidates'] as List<dynamic>? ?? <dynamic>[];
      final String text = candidates
          .expand(
            (candidate) =>
                candidate['content']?['parts'] as List<dynamic>? ?? <dynamic>[],
          )
          .map((part) => part['text']?.toString() ?? '')
          .join();
      yield* _chunkText(text);
    }
  }

  String _anthropicModelFor(AITaskType taskType) {
    if (_usesSmallModel(taskType)) {
      return dotenv.env['ANTHROPIC_SMALL_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['ANTHROPIC_SMALL_MODEL']!.trim()
          : 'claude-3-5-haiku-latest';
    }

    return dotenv.env['ANTHROPIC_LARGE_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['ANTHROPIC_LARGE_MODEL']!.trim()
        : 'claude-3-7-sonnet-latest';
  }

  String _geminiModelFor(AITaskType taskType) {
    final String? envModel = _usesSmallModel(taskType)
        ? dotenv.env['GEMINI_SMALL_MODEL']
        : dotenv.env['GEMINI_LARGE_MODEL'];

    if (envModel != null && envModel.trim().isNotEmpty) {
      return envModel.trim();
    }

    if (_usesSmallModel(taskType)) {
      return 'gemini-2.5-flash';
    }

    return 'gemini-2.5-pro';
  }

  bool _usesSmallModel(AITaskType taskType) {
    return taskType != AITaskType.explainConcept;
  }

  StudyLevel _studyLevelFromTutor(TutorModel tutor) {
    final String normalized = tutor.levelsTaught.join(' ').toLowerCase();
    if (normalized.contains('primary')) return StudyLevel.primary;
    if (normalized.contains('university')) return StudyLevel.university;
    return StudyLevel.secondary;
  }

  Stream<String> _chunkText(String text) async* {
    if (text.trim().isEmpty) {
      yield 'No response received.';
      return;
    }

    final List<String> words = text.split(' ');
    final StringBuffer buffer = StringBuffer();
    for (final String word in words) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(word);
      yield '$word${word == words.last ? '' : ' '}';
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }
}
