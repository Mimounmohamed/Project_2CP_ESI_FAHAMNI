enum AIMessageRole {
  user,
  assistant,
}

class AIMessage {
  const AIMessage({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });

  final AIMessageRole role;
  final String content;
  final bool isStreaming;

  AIMessage copyWith({
    AIMessageRole? role,
    String? content,
    bool? isStreaming,
  }) {
    return AIMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
