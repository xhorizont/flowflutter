class AppConfig {
  final String apiHost;
  final String chatflowId;
  final bool useStreaming;

  AppConfig({
    required this.apiHost,
    required this.chatflowId,
    this.useStreaming = true,
  });

  AppConfig copyWith({
    String? apiHost,
    String? chatflowId,
    bool? useStreaming,
  }) {
    return AppConfig(
      apiHost: apiHost ?? this.apiHost,
      chatflowId: chatflowId ?? this.chatflowId,
      useStreaming: useStreaming ?? this.useStreaming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiHost': apiHost,
      'chatflowId': chatflowId,
      'useStreaming': useStreaming,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiHost: json['apiHost'] as String,
      chatflowId: json['chatflowId'] as String,
      useStreaming: json['useStreaming'] as bool? ?? true,
    );
  }

  static AppConfig get defaultConfig => AppConfig(
        apiHost: '',
        chatflowId: '',
        useStreaming: true,
      );
}
