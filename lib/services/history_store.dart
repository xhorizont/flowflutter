import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';

class HistoryStore {
  static const String _chatIdKey = 'current_chat_id';
  static const String _messagesKey = 'chat_messages';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getCurrentChatId() async {
    try {
      return await _storage.read(key: _chatIdKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveChatId(String chatId) async {
    try {
      await _storage.write(key: _chatIdKey, value: chatId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearChatId() async {
    await _storage.delete(key: _chatIdKey);
  }

  Future<List<ChatMessage>> loadMessages() async {
    try {
      final messagesJson = await _storage.read(key: _messagesKey);

      if (messagesJson == null) {
        return [];
      }

      final List<dynamic> data = json.decode(messagesJson);
      return data
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final messagesJson = json.encode(
        messages.map((msg) => msg.toJson()).toList(),
      );
      await _storage.write(key: _messagesKey, value: messagesJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearMessages() async {
    await _storage.delete(key: _messagesKey);
  }

  Future<void> clearAll() async {
    await clearChatId();
    await clearMessages();
  }
}
