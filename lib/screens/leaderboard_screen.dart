import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/leaderboard_service.dart';
import '../services/friend_service.dart';
import '../services/message_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';

class LeaderboardScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  final ProgrammingLanguage? language;

  const LeaderboardScreen({
    super.key,
    required this.themeManager,
    required this.languageManager,
    this.language,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthServiceV2 _authService = AuthServiceV2();
  final FriendService _friendService = FriendService();
  final MessageService _messageService = MessageService();

  LeaderboardEntry? _globalEntry;
  LeaderboardEntry? _languageEntry;
  bool _isLoadingUser = true;
  late final TabController _tabController;
  UserModel? _currentUser;
  final Set<String> _pendingFriendRequests = <String>{};
  final Set<String> _sendingMessages = <String>{};
  StreamSubscription<List<FriendSummary>>? _friendsSubscription;
  Set<String> _friendIds = <String>{};

  String get _languageKey => _mapLanguageKey(widget.language?.name ?? 'global');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserRanks();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _ensureFriendsSubscription(String uid) {
    if (_friendsSubscription != null) return;

    _friendsSubscription = _friendService.watchFriends(uid: uid).listen(
      (friends) {
        final ids = friends.map((friend) => friend.uid).toSet();
        if (!mounted) return;
        setState(() {
          _friendIds = ids;
        });
      },
    );
  }

  Future<void> _handleAddFriend(
    LeaderboardEntry entry,
    AppLocalizations loc,
  ) async {
    final user = _authService.currentUser;
    final profile = _currentUser;
    if (user == null || profile == null) {
      _showSnack(
        message: loc.friendLoginRequired,
        background: AppColors.warning,
      );
      return;
    }

    if (_pendingFriendRequests.contains(entry.userId)) {
      return;
    }

    setState(() {
      _pendingFriendRequests.add(entry.userId);
    });

    try {
      await _friendService.sendFriendRequest(
        fromUid: user.uid,
        fromUsername: profile.username,
        fromPhotoUrl: profile.profileImageUrl,
        targetUsername: entry.username,
      );

      _showSnack(
        message: loc.friendRequestSent,
        background: AppColors.success,
      );
    } catch (error) {
      _showSnack(
        message: error.toString(),
        background: AppColors.danger,
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingFriendRequests.remove(entry.userId);
        });
      }
    }
  }

  Future<void> _openMessageSheet(
    LeaderboardEntry entry,
    AppLocalizations loc,
  ) async {
    final user = _authService.currentUser;
    final profile = _currentUser;
    if (user == null || profile == null) {
      _showSnack(
        message: loc.friendLoginRequired,
        background: AppColors.warning,
      );
      return;
    }

    if (!_friendIds.contains(entry.userId)) {
      _showSnack(
        message: loc.messagesFriendsOnly,
        background: AppColors.warning,
      );
      return;
    }

    final controller = TextEditingController();
    String? errorText;
    bool isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.leaderboardMessageTitle(entry.username),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    minLines: 2,
                    autofocus: true,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: loc.leaderboardMessageHint,
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSending
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                              },
                        child: Text(loc.cancel),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: isSending
                            ? null
                            : () async {
                                final message = controller.text.trim();
                                if (message.length < 3) {
                                  setModalState(() {
                                    errorText = loc.leaderboardMessageTooShort;
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSending = true;
                                  errorText = null;
                                });
                                setState(() {
                                  _sendingMessages.add(entry.userId);
                                });

                                try {
                                  await _messageService.sendMessage(
                                    fromUid: user.uid,
                                    fromUsername: profile.username.isNotEmpty
                                        ? profile.username
                                        : (user.email ?? 'player'),
                                    fromPhotoUrl: profile.profileImageUrl,
                                    toUid: entry.userId,
                                    message: message,
                                  );

                                  if (mounted) {
                                    Navigator.of(sheetContext).pop();
                                    _showSnack(
                                      message: loc.leaderboardMessageSent,
                                      background: AppColors.success,
                                    );
                                  }
                                } catch (error) {
                                  setModalState(() {
                                    isSending = false;
                                    errorText = error.toString();
                                  });
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _sendingMessages.remove(entry.userId);
                                    });
                                  }
                                }
                              },
                        icon: isSending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(loc.leaderboardMessageSend),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showSnack({
    required String message,
    required Color background,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: background,
        ),
      );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _friendsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserRanks() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }

    final uid = user.uid;

    _ensureFriendsSubscription(uid);

    try {
      final results = await Future.wait<LeaderboardEntry?>([
        _leaderboardService.fetchUserEntry(uid: uid, language: 'global'),
        if (widget.language != null)
          _leaderboardService.fetchUserEntry(uid: uid, language: _languageKey)
        else
          Future.value(null),
      ]);

      final profile = await _authService.getUserProfile(uid);

      setState(() {
        _globalEntry = results[0];
        _languageEntry = results.length > 1 ? results[1] : null;
        _isLoadingUser = false;
        _currentUser = profile;
      });
    } catch (error) {
      debugPrint('Leaderboard user rank error: $error');
      setState(() => _isLoadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final languageName = widget.language?.name ?? loc.leaderboardLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.leaderboardTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.leaderboardGlobal),
            Tab(text: languageName),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildUserSummary(loc),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(loc, 'global'),
                _buildLeaderboardList(loc, _languageKey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSummary(AppLocalizations loc) {
    if (_isLoadingUser) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      );
    }

    final bool showingGlobal = _tabController.index == 0;
    final targetEntry = showingGlobal ? _globalEntry : _languageEntry;
    final fallbackEntry = showingGlobal ? _languageEntry : _globalEntry;
    final entry = targetEntry ?? fallbackEntry;
    final bool isFallback = targetEntry == null && fallbackEntry != null;

    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Text(
          loc.leaderboardNoData,
          style: const TextStyle(color: AppColors.neutral500),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                loc.leaderboardYou[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.leaderboardYou,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.leaderboardRank}: ${entry.rank > 0 ? entry.rank : '-'}',
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${loc.leaderboardScore}: ${entry.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.language == 'global'
                      ? loc.leaderboardGlobal
                      : _findLanguageName(entry.language),
                  style: const TextStyle(color: AppColors.neutral500),
                ),
                if (isFallback)
                  Text(
                    showingGlobal
                        ? loc.leaderboardLanguage
                        : loc.leaderboardGlobal,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(AppLocalizations loc, String languageKey) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _leaderboardService.watchTopEntries(
        language: languageKey,
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              loc.leaderboardNoData,
              style: const TextStyle(color: AppColors.neutral500),
            ),
          );
        }

        final userId = _authService.currentUser?.uid;
        final entries = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            final isYou = userId != null && userId == entry.userId;
            final languageLabel = _findLanguageName(entry.language);
            final isPending = _pendingFriendRequests.contains(entry.userId);
      final isFriend = _friendIds.contains(entry.userId);
      final canSendFriendRequest =
        !isYou && userId != null && _currentUser != null && !isFriend;
      final canSendMessage =
        !isYou && userId != null && _currentUser != null && isFriend;
            final isMessageSending = _sendingMessages.contains(entry.userId);

            return _LeaderboardTile(
              entry: entry.copyWith(rank: rank),
              isCurrentUser: isYou,
              languageLabel: languageLabel,
              onAddFriend: canSendFriendRequest
                  ? () => _handleAddFriend(entry, loc)
                  : null,
              isSendingFriendRequest: isPending,
              friendActionTooltip: loc.friendAddButton,
              onSendMessage:
                  canSendMessage ? () => _openMessageSheet(entry, loc) : null,
              isSendingMessage: isMessageSending,
              messageActionTooltip: loc.leaderboardMessageAction,
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: entries.length,
        );
      },
    );
  }

  String _mapLanguageKey(String name) {
    switch (name.toLowerCase()) {
      case 'c#':
        return 'csharp';
      case 'javascript':
        return 'javascript';
      default:
        return name.toLowerCase();
    }
  }

  String _findLanguageName(String key) {
    if (key == 'global') return 'Global';
    final match = StaticData.languages.firstWhere(
      (lang) => _mapLanguageKey(lang.name) == key,
      orElse: () =>
          ProgrammingLanguage(name: key, icon: '🏆', color: AppColors.primary),
    );
    return match.name;
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final String languageLabel;
  final VoidCallback? onAddFriend;
  final bool isSendingFriendRequest;
  final String friendActionTooltip;
  final VoidCallback? onSendMessage;
  final bool isSendingMessage;
  final String messageActionTooltip;

  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
    required this.languageLabel,
    this.onAddFriend,
    this.isSendingFriendRequest = false,
    this.friendActionTooltip = '',
    this.onSendMessage,
    this.isSendingMessage = false,
    this.messageActionTooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _tileBackground(entry.rank, isCurrentUser);
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank, highlight: isCurrentUser),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                _LanguageLabel(
                  language: languageLabel,
                  highlight: isCurrentUser,
                ),
              ],
            ),
          ),
          Text(
            entry.score.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: textColor,
            ),
          ),
          if (onAddFriend != null || onSendMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSendMessage != null)
                  _LeaderboardActionButton(
                    tooltip: messageActionTooltip,
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: onSendMessage,
                    isLoading: isSendingMessage,
                    highlight: false,
                  ),
                if (onSendMessage != null && onAddFriend != null)
                  const SizedBox(width: 8),
                if (onAddFriend != null)
                  _LeaderboardActionButton(
                    tooltip: friendActionTooltip,
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: onAddFriend,
                    isLoading: isSendingFriendRequest,
                    highlight: isCurrentUser,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _tileBackground(int rank, bool highlight) {
    if (highlight) {
      return AppColors.primary;
    }
    switch (rank) {
      case 1:
        return const Color(0xFFFFF4DC);
      case 2:
        return const Color(0xFFE6ECFF);
      case 3:
        return const Color(0xFFEFF7F0);
      default:
        return Colors.transparent;
    }
  }
}

class _LeaderboardActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool isLoading;
  final bool highlight;

  const _LeaderboardActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.isLoading,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = highlight ? Colors.white : AppColors.primary;
    final Color background = highlight
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.primary.withValues(alpha: 0.08);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(foreground),
                    ),
                  )
                : Icon(
                    icon,
                    key: const ValueKey('icon'),
                    size: 18,
                    color: foreground,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LanguageLabel extends StatelessWidget {
  final String language;
  final bool highlight;

  const _LanguageLabel({
    required this.language,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final display = language;
    return Text(
      display,
      style: TextStyle(
        fontSize: 12,
        color: highlight
            ? Colors.white.withValues(alpha: 0.8)
            : AppColors.neutral500,
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool highlight;

  const _RankBadge({
    required this.rank,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight ? Colors.white : AppColors.backgroundLight;
    final textColor = highlight ? AppColors.primary : Colors.black87;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        rank > 0 ? '$rank' : '-',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
