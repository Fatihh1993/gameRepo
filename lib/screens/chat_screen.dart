import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/message_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';

class ChatScreen extends StatefulWidget {
  final LanguageManager languageManager;
  final String friendUid;
  final String friendUsername;
  final String? friendPhotoUrl;

  const ChatScreen({
    super.key,
    required this.languageManager,
    required this.friendUid,
    required this.friendUsername,
    this.friendPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthServiceV2 _authService = AuthServiceV2();
  final MessageService _messageService = MessageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _currentUser;
  String? _currentUid;
  bool _isSending = false;
  bool _isMarkingRead = false;
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return;

    setState(() {
      _currentUid = firebaseUser.uid;
    });

    final profile = await _authService.getUserProfile(firebaseUser.uid);
    if (mounted) {
      setState(() {
        _currentUser = profile;
      });
    }

    await _messageService.markConversationAsRead(
      uid: firebaseUser.uid,
      friendUid: widget.friendUid,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(AppLocalizations loc) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final firebaseUser = _authService.currentUser;
    final currentUser = _currentUser;
    final fallbackUsername = firebaseUser?.email?.split('@').first ?? 'player';
    final username = (currentUser?.username ?? '').isNotEmpty
        ? currentUser!.username
        : fallbackUsername;

    setState(() => _isSending = true);

    try {
      await _messageService.sendMessage(
        fromUid: currentUid,
        fromUsername: username,
        fromPhotoUrl: currentUser?.profileImageUrl,
        toUid: widget.friendUid,
        message: text,
      );
      _textController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markLatestFriendMessage(String messageId) async {
    final currentUid = _currentUid;
    if (currentUid == null || _isMarkingRead) return;
    if (_lastMarkedMessageId == messageId) return;

    setState(() => _isMarkingRead = true);
    try {
      await _messageService.markConversationAsRead(
        uid: currentUid,
        friendUid: widget.friendUid,
      );
      _lastMarkedMessageId = messageId;
    } finally {
      if (mounted) {
        setState(() => _isMarkingRead = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final currentUid = _currentUid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                widget.friendUsername.isNotEmpty
                    ? widget.friendUsername[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.friendUsername),
          ],
        ),
      ),
      body: currentUid == null
          ? Center(child: Text(loc.userDataMissing))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ConversationMessage>>(
                    stream: _messageService.watchConversationMessages(
                      uid: currentUid,
                      friendUid: widget.friendUid,
                    ),
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

                      final messages = snapshot.data ?? const [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              loc.messagesStartChat,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppColors.neutral500),
                            ),
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                        for (final message in messages.reversed) {
                          if (message.senderUid == widget.friendUid) {
                            _markLatestFriendMessage(message.id);
                            break;
                          }
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMine = message.senderUid == currentUid;
                          return _MessageBubble(
                            message: message,
                            isMine: isMine,
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: loc.messagesInputHint,
                              filled: true,
                              fillColor: AppColors.primary.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: FilledButton(
                            onPressed: _isSending
                                ? null
                                : () => _handleSend(loc),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
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

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final background = isMine
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.1);
    final textColor = isMine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMine ? const Radius.circular(18) : Radius.zero,
            bottomRight: isMine ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }
}
