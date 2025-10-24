import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/message_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/time_formatter.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final LanguageManager languageManager;

  const MessagesScreen({
    super.key,
    required this.languageManager,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final AuthServiceV2 _authService = AuthServiceV2();
  final MessageService _messageService = MessageService();
  Stream<List<ConversationPreview>>? _conversationsStream;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    final current = _authService.currentUser;
    if (current != null) {
      _currentUid = current.uid;
      _conversationsStream = _messageService.watchConversations(uid: current.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final conversationStream = _conversationsStream;
    final currentUid = _currentUid;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.messagesTitle),
      ),
      body: currentUid == null || conversationStream == null
          ? Center(child: Text(loc.userDataMissing))
          : StreamBuilder<List<ConversationPreview>>(
              stream: conversationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text(loc.error));
                }

                final conversations = snapshot.data ?? const [];
                if (conversations.isEmpty) {
                  return _EmptyInbox(loc: loc);
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      currentUid: currentUid,
                      loc: loc,
                      onOpen: () => _openConversation(conversation, loc),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: conversations.length,
                );
              },
            ),
    );
  }

  Future<void> _openConversation(
    ConversationPreview conversation,
    AppLocalizations loc,
  ) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    await _messageService.markConversationAsRead(
      uid: currentUid,
      friendUid: conversation.friendUid,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          languageManager: widget.languageManager,
          friendUid: conversation.friendUid,
          friendUsername: conversation.friendUsername,
          friendPhotoUrl: conversation.friendPhotoUrl,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationPreview conversation;
  final AppLocalizations loc;
  final VoidCallback onOpen;
  final String currentUid;

  const _ConversationTile({
    required this.conversation,
    required this.loc,
    required this.onOpen,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewText = _buildPreviewText();
    final timeText = _formatTime();
    final initial = conversation.friendUsername.isNotEmpty
        ? conversation.friendUsername[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.friendUsername,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          timeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    if (conversation.hasUnread) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${conversation.unreadCount} ${loc.messagesUnread}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildPreviewText() {
    if (conversation.lastMessage.isEmpty) {
      return '';
    }
    final isMine = conversation.lastMessageSenderUid == currentUid;
    if (isMine) {
      return '${loc.messagesYouPrefix} ${conversation.lastMessage}';
    }
    return conversation.lastMessage;
  }

  String _formatTime() {
    final createdAt = conversation.lastMessageAt;
    if (createdAt == null) {
      return loc.relativeJustNow;
    }
    return formatRelativeTime(createdAt, loc);
  }
}

class _EmptyInbox extends StatelessWidget {
  final AppLocalizations loc;

  const _EmptyInbox({required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              loc.messagesInbox,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.messagesEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
