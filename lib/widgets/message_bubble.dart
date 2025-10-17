import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF4169FF), Color(0xFF5B7FFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withOpacity(0.7)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (message.sourceDocuments != null &&
                    message.sourceDocuments!.isNotEmpty)
                  _buildSourceDocuments(context),
                if (message.usedTools != null && message.usedTools!.isNotEmpty)
                  _buildUsedTools(context),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF4169FF), Color(0xFF5B7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSourceDocuments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: Text(
          'Source Documents (${message.sourceDocuments!.length})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: message.sourceDocuments!.map((doc) {
          return ListTile(
            dense: true,
            title: Text(
              doc.pageContent,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: doc.metadata != null
                ? Text(
                    doc.metadata.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsedTools(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 4,
        children: message.usedTools!.map((tool) {
          return Chip(
            label: Text(
              tool,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == timestamp.day) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('E HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }
}
