enum MessageRole {
  user,
  assistant,
  system,
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<SourceDocument>? sourceDocuments;
  final List<String>? usedTools;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.sourceDocuments,
    this.usedTools,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    List<SourceDocument>? sourceDocuments,
    List<String>? usedTools,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      sourceDocuments: sourceDocuments ?? this.sourceDocuments,
      usedTools: usedTools ?? this.usedTools,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'sourceDocuments': sourceDocuments?.map((doc) => doc.toJson()).toList(),
      'usedTools': usedTools,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sourceDocuments: (json['sourceDocuments'] as List<dynamic>?)
          ?.map((doc) => SourceDocument.fromJson(doc as Map<String, dynamic>))
          .toList(),
      usedTools: (json['usedTools'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class SourceDocument {
  final String pageContent;
  final Map<String, dynamic>? metadata;

  SourceDocument({
    required this.pageContent,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'pageContent': pageContent,
      'metadata': metadata,
    };
  }

  factory SourceDocument.fromJson(Map<String, dynamic> json) {
    return SourceDocument(
      pageContent: json['pageContent'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
