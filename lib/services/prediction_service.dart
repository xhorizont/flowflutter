import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sse_event.dart';
import '../models/chat_message.dart';

class RateLimitException implements Exception {
  final int retryAfterSeconds;
  final String message;

  RateLimitException(this.retryAfterSeconds, this.message);

  @override
  String toString() => message;
}

class PredictionResponse {
  final String? chatId;
  final String? messageId;
  final String content;
  final List<SourceDocument>? sourceDocuments;
  final List<String>? usedTools;

  PredictionResponse({
    this.chatId,
    this.messageId,
    required this.content,
    this.sourceDocuments,
    this.usedTools,
  });
}

class PredictionService {
  Stream<SSEEvent> streamPrediction({
    required String apiHost,
    required String chatflowId,
    required String question,
    String? chatId,
    String? apiKey,
  }) async* {
    final url = Uri.parse('$apiHost/api/v1/predictions/$chatflowId');

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey != null && apiKey.isNotEmpty)
        'Authorization': 'Bearer $apiKey',
    };

    final body = json.encode({
      'question': question,
      'streaming': true,
      if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
    });

    final request = http.Request('POST', url);
    request.headers.addAll(headers);
    request.body = body;

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode == 429) {
      final retryAfter = int.tryParse(
            response.headers['retry-after'] ?? '60',
          ) ??
          60;
      client.close();
      throw RateLimitException(
        retryAfter,
        'Too many requests. Retry after $retryAfter seconds.',
      );
    }

    if (response.statusCode != 200) {
      client.close();
      throw Exception(
        'Prediction failed with status ${response.statusCode}',
      );
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');

      String? currentEvent;
      String? currentData;

      for (final line in lines) {
        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          currentData = line.substring(5).trim();
        } else if (line.isEmpty && currentEvent != null) {
          yield SSEEvent.parse(currentEvent, currentData);
          currentEvent = null;
          currentData = null;
        }
      }
    }

    client.close();
  }

  Future<PredictionResponse> predict({
    required String apiHost,
    required String chatflowId,
    required String question,
    String? chatId,
    String? apiKey,
  }) async {
    final url = Uri.parse('$apiHost/api/v1/predictions/$chatflowId');

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey != null && apiKey.isNotEmpty)
        'Authorization': 'Bearer $apiKey',
    };

    final body = json.encode({
      'question': question,
      'streaming': false,
      if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 429) {
      final retryAfter = int.tryParse(
            response.headers['retry-after'] ?? '60',
          ) ??
          60;
      throw RateLimitException(
        retryAfter,
        'Too many requests. Retry after $retryAfter seconds.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Prediction failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    return PredictionResponse(
      chatId: data['chatId'] as String?,
      messageId: data['messageId'] as String?,
      content: data['text'] as String? ?? '',
      sourceDocuments: (data['sourceDocuments'] as List<dynamic>?)
          ?.map((doc) => SourceDocument.fromJson(doc as Map<String, dynamic>))
          .toList(),
      usedTools: (data['usedTools'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
