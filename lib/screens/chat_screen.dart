import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../models/chat_message.dart';
import '../models/sse_event.dart';
import '../services/prediction_service.dart';
import '../services/history_store.dart';
import '../services/config_store.dart';
import '../widgets/message_bubble.dart';
import 'settings_screen.dart';

class _RetryConfig {
  final int maxRetries;
  final int initialDelaySeconds;

  const _RetryConfig({
    this.maxRetries = 3,
    this.initialDelaySeconds = 1,
  });
}

class ChatScreen extends StatefulWidget {
  final AppConfig? config;

  const ChatScreen({super.key, this.config});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PredictionService _predictionService = PredictionService();
  final HistoryStore _historyStore = HistoryStore();
  final ConfigStore _configStore = ConfigStore();

  AppConfig? _currentConfig;
  String? _currentChatId;
  bool _isGenerating = false;
  String _currentAssistantMessage = '';
  List<SourceDocument>? _currentSourceDocuments;
  List<String>? _currentUsedTools;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadHistory();
  }

  Future<void> _loadConfig() async {
    final config = widget.config ?? await _configStore.loadConfig();
    setState(() {
      _currentConfig = config;
    });
  }

  Future<void> _loadHistory() async {
    final chatId = await _historyStore.getCurrentChatId();
    final messages = await _historyStore.loadMessages();

    setState(() {
      _currentChatId = chatId;
      _messages.addAll(messages);
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    // Check if config is set
    if (_currentConfig == null ||
        _currentConfig!.apiHost.isEmpty ||
        _currentConfig!.chatflowId.isEmpty) {
      _showError(
        'Please configure API Host and Chatflow ID in Settings first.',
      );
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: text,
    );

    setState(() {
      _messages.add(userMessage);
      _inputController.clear();
      _isGenerating = true;
      _currentAssistantMessage = '';
      _currentSourceDocuments = null;
      _currentUsedTools = null;
    });

    _scrollToBottom();
    await _historyStore.saveMessages(_messages);

    await _sendMessageWithRetry(text);
  }

  Future<void> _sendMessageWithRetry(String question) async {
    const config = _RetryConfig();
    int retryCount = 0;

    while (retryCount <= config.maxRetries) {
      try {
        if (_currentConfig!.useStreaming) {
          await _handleStreamingResponse(question);
        } else {
          await _handleNonStreamingResponse(question);
        }
        setState(() => _isGenerating = false);
        return; // Success, exit retry loop
      } on RateLimitException catch (e) {
        if (retryCount >= config.maxRetries) {
          setState(() => _isGenerating = false);
          _showError('${e.message}\nMaximum retries exceeded.');
          return;
        }

        final delaySeconds = e.retryAfterSeconds > 0
            ? e.retryAfterSeconds
            : config.initialDelaySeconds * (1 << retryCount); // Exponential backoff

        _showRetryMessage('Rate limited. Retrying in $delaySeconds seconds...');

        await Future.delayed(Duration(seconds: delaySeconds));
        retryCount++;
      } catch (e) {
        setState(() => _isGenerating = false);
        _showError(_formatErrorMessage(e));
        return;
      }
    }

    setState(() => _isGenerating = false);
  }

  Future<void> _handleStreamingResponse(String question) async {
    final stream = _predictionService.streamPrediction(
      apiHost: _currentConfig!.apiHost,
      chatflowId: _currentConfig!.chatflowId,
      question: question,
      chatId: _currentChatId,
    );

    await for (final event in stream) {
      switch (event.type) {
        case SSEEventType.start:
          break;

        case SSEEventType.token:
          setState(() {
            _currentAssistantMessage += event.data ?? '';
          });
          _scrollToBottom();
          break;

        case SSEEventType.metadata:
          if (event.data != null) {
            final metadata = MetadataEvent.fromJson(
              json.decode(event.data!) as Map<String, dynamic>,
            );
            if (metadata.chatId != null) {
              _currentChatId = metadata.chatId;
              await _historyStore.saveChatId(metadata.chatId!);
            }
          }
          break;

        case SSEEventType.sourceDocuments:
          if (event.data != null) {
            final List<dynamic> docs = json.decode(event.data!);
            _currentSourceDocuments = docs
                .map((doc) =>
                    SourceDocument.fromJson(doc as Map<String, dynamic>))
                .toList();
          }
          break;

        case SSEEventType.usedTools:
          if (event.data != null) {
            _currentUsedTools =
                (json.decode(event.data!) as List<dynamic>).cast<String>();
          }
          break;

        case SSEEventType.end:
          final assistantMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            content: _currentAssistantMessage,
            sourceDocuments: _currentSourceDocuments,
            usedTools: _currentUsedTools,
          );

          setState(() {
            _messages.add(assistantMessage);
            _currentAssistantMessage = '';
          });

          await _historyStore.saveMessages(_messages);
          break;

        case SSEEventType.error:
          throw Exception(event.data ?? 'Unknown error');

        default:
          break;
      }
    }
  }

  Future<void> _handleNonStreamingResponse(String question) async {
    final response = await _predictionService.predict(
      apiHost: _currentConfig!.apiHost,
      chatflowId: _currentConfig!.chatflowId,
      question: question,
      chatId: _currentChatId,
    );

    if (response.chatId != null) {
      _currentChatId = response.chatId;
      await _historyStore.saveChatId(response.chatId!);
    }

    final assistantMessage = ChatMessage(
      id: response.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: response.content,
      sourceDocuments: response.sourceDocuments,
      usedTools: response.usedTools,
    );

    setState(() {
      _messages.add(assistantMessage);
    });

    await _historyStore.saveMessages(_messages);
    _scrollToBottom();
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showRetryMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Network errors
    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }

    // HTTP status code errors
    if (errorString.contains('status 401') || errorString.contains('status 403')) {
      return 'Invalid API key. Please check your credentials.';
    }

    if (errorString.contains('status 404')) {
      return 'Chatflow not found. Please check your Chatflow ID.';
    }

    if (errorString.contains('status 429')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('status 500') || errorString.contains('status 502') ||
        errorString.contains('status 503')) {
      return 'Server error. Please try again later.';
    }

    // Timeout errors
    if (errorString.contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // CORS or connection errors
    if (errorString.contains('CORS') || errorString.contains('Access-Control')) {
      return 'Connection blocked. Please check CORS settings on your Flowise server.';
    }

    // Default fallback
    return 'An error occurred: ${errorString.length > 100 ? '${errorString.substring(0, 100)}...' : errorString}';
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

  Future<void> _startNewChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: const Text(
          'This will clear the current conversation and start fresh. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start New'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyStore.clearAll();
      setState(() {
        _messages.clear();
        _currentChatId = null;
        _currentAssistantMessage = '';
      });
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );

    // If settings were saved, reload config
    if (result == true) {
      await _loadConfig();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(77),
            ),
            const SizedBox(height: 24),
            Text(
              'Start a Conversation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me anything! I\'m here to help.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('What can you do?'),
                _buildSuggestionChip('Tell me about...'),
                _buildSuggestionChip('Help me with...'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _inputController.text = text;
      },
      avatar: Icon(
        Icons.lightbulb_outline,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flowise Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isGenerating
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length + (_isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return MessageBubble(message: _messages[index]);
                      } else {
                        return MessageBubble(
                          message: ChatMessage(
                            id: 'temp',
                            role: MessageRole.assistant,
                            content: _currentAssistantMessage.isEmpty
                                ? 'Thinking...'
                                : _currentAssistantMessage,
                          ),
                        );
                      }
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withAlpha(26),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isGenerating,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isGenerating ? Icons.hourglass_empty : Icons.send,
                    ),
                    onPressed: _isGenerating ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
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
