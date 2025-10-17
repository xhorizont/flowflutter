enum SSEEventType {
  start,
  token,
  metadata,
  sourceDocuments,
  usedTools,
  end,
  error,
  unknown,
}

class SSEEvent {
  final SSEEventType type;
  final String? data;

  SSEEvent({
    required this.type,
    this.data,
  });

  factory SSEEvent.parse(String event, String? data) {
    final type = _parseEventType(event);
    return SSEEvent(
      type: type,
      data: data,
    );
  }

  static SSEEventType _parseEventType(String event) {
    switch (event) {
      case 'start':
        return SSEEventType.start;
      case 'token':
        return SSEEventType.token;
      case 'metadata':
        return SSEEventType.metadata;
      case 'sourceDocuments':
        return SSEEventType.sourceDocuments;
      case 'usedTools':
        return SSEEventType.usedTools;
      case 'end':
        return SSEEventType.end;
      case 'error':
        return SSEEventType.error;
      default:
        return SSEEventType.unknown;
    }
  }
}

class MetadataEvent {
  final String? chatId;
  final String? messageId;

  MetadataEvent({
    this.chatId,
    this.messageId,
  });

  factory MetadataEvent.fromJson(Map<String, dynamic> json) {
    return MetadataEvent(
      chatId: json['chatId'] as String?,
      messageId: json['messageId'] as String?,
    );
  }
}
