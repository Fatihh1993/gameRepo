import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/friend_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/theme_manager.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const FriendsScreen({
    super.key,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final AuthServiceV2 _authService = AuthServiceV2();
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();

  TabController? _tabController;
  Stream<List<FriendSummary>>? _friendsStream;
  Stream<List<FriendRequest>>? _incomingRequestsStream;
  Stream<List<FriendRequest>>? _outgoingRequestsStream;
  FriendUserPreview? _searchResult;
  String? _searchError;
  bool _isSearching = false;
  bool _isSendingRequest = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeStreams();
  }

  void _initializeStreams() {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _friendsStream = _friendService.watchFriends(uid: user.uid);
      _incomingRequestsStream =
          _friendService.watchIncomingRequests(uid: user.uid);
      _outgoingRequestsStream =
          _friendService.watchOutgoingRequests(uid: user.uid);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFriend(AppLocalizations loc) async {
    final user = _authService.currentUser;
    if (user == null || _isSearching) return;

    final username = _searchController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.friendEnterUsername),
            backgroundColor: AppColors.warning,
          ),
        );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final result = await _friendService.findUserByUsername(
        currentUid: user.uid,
        username: username,
      );
      if (!mounted) return;
      setState(() {
        _searchResult = result;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _searchResult = null;
        _searchError = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequest(AppLocalizations loc) async {
    final user = _authService.currentUser;
    if (user == null || _isSendingRequest) return;

    final result = _searchResult;
    if (result == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.friendSearchFirst),
            backgroundColor: AppColors.warning,
          ),
        );
      return;
    }

    setState(() => _isSendingRequest = true);

    try {
      final profile = await _authService.getUserProfile(user.uid);
      final currentUsername = profile?.username ?? user.email ?? 'player';
      await _friendService.sendFriendRequest(
        fromUid: user.uid,
        fromUsername: currentUsername,
        fromPhotoUrl: profile?.profileImageUrl,
        targetUsername: result.username,
      );
      if (!mounted) return;
      _searchController.clear();
      setState(() {
        _searchResult = null;
        _searchError = null;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.friendRequestSent),
            backgroundColor: AppColors.success,
          ),
        );
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
        setState(() => _isSendingRequest = false);
      }
    }
  }

  Future<void> _respondToRequest({
    required FriendRequest request,
    required bool accept,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _friendService.respondToFriendRequest(
        uid: user.uid,
        requesterUid: request.uid,
        accept: accept,
      );
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
    }
  }

  Future<void> _removeFriend(FriendSummary friend) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _friendService.removeFriend(uid: user.uid, friendUid: friend.uid);
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
    }
  }

  void _openFriendProfile(FriendSummary friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(
          friendUid: friend.uid,
          friendUsername: friend.username,
          languageManager: widget.languageManager,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.friendsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.friendsTab),
            Tab(text: loc.requestsTab),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: loc.friendSearchLabel,
                      hintText: loc.friendSearchHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed:
                      _isSearching ? null : () => _searchFriend(loc),
                  icon: _isSearching
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(loc.friendSearchButton),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(130, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _searchError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
          if (_searchResult != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SearchResultCard(
                result: _searchResult!,
                loc: loc,
                isSending: _isSendingRequest,
                onSend:
                    _isSendingRequest ? null : () => _sendFriendRequest(loc),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FriendsList(
                  stream: _friendsStream,
                  onRemove: _removeFriend,
                  onViewProfile: _openFriendProfile,
                  loc: loc,
                ),
                _RequestsTab(
                  incomingStream: _incomingRequestsStream,
                  outgoingStream: _outgoingRequestsStream,
                  onRespond: _respondToRequest,
                  loc: loc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final Stream<List<FriendSummary>>? stream;
  final void Function(FriendSummary friend) onRemove;
  final void Function(FriendSummary friend) onViewProfile;
  final AppLocalizations loc;

  const _FriendsList({
    required this.stream,
    required this.onRemove,
    required this.onViewProfile,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<FriendSummary>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return Center(
            child: Text(
              loc.friendsEmpty,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.neutral500),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _FriendTile(
              friend: friend,
              onRemove: () => onRemove(friend),
              onViewProfile: () => onViewProfile(friend),
              loc: loc,
            );
          },
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendSummary friend;
  final VoidCallback onRemove;
  final VoidCallback onViewProfile;
  final AppLocalizations loc;

  const _FriendTile({
    required this.friend,
    required this.onRemove,
    required this.onViewProfile,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onViewProfile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                friend.username.isNotEmpty
                    ? friend.username[0].toUpperCase()
                    : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lv ${friend.level} · HS ${friend.highScore}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: loc.friendViewProfile,
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.person_search_rounded),
                ),
                IconButton(
                  tooltip: loc.friendRemove,
                  onPressed: onRemove,
                  icon: const Icon(Icons.person_remove_alt_1_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final FriendUserPreview result;
  final bool isSending;
  final VoidCallback? onSend;
  final AppLocalizations loc;

  const _SearchResultCard({
    required this.result,
    required this.isSending,
    required this.onSend,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
            child: Text(
              result.username.isNotEmpty
                  ? result.username[0].toUpperCase()
                  : 'P',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lv ${result.level} · HS ${result.highScore}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onSend,
            icon: isSending
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.person_add_alt_rounded),
            label: Text(loc.friendAddButton),
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final Stream<List<FriendRequest>>? incomingStream;
  final Stream<List<FriendRequest>>? outgoingStream;
  final void Function({required FriendRequest request, required bool accept})
      onRespond;
  final AppLocalizations loc;

  const _RequestsTab({
    required this.incomingStream,
    required this.outgoingStream,
    required this.onRespond,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    if (incomingStream == null || outgoingStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          loc.friendIncomingHeader,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _IncomingRequestsList(
          stream: incomingStream!,
          onRespond: onRespond,
          loc: loc,
        ),
        const SizedBox(height: 24),
        Text(
          loc.friendOutgoingHeader,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _OutgoingRequestsList(
          stream: outgoingStream!,
          loc: loc,
        ),
      ],
    );
  }
}

class _IncomingRequestsList extends StatelessWidget {
  final Stream<List<FriendRequest>> stream;
  final void Function({required FriendRequest request, required bool accept})
      onRespond;
  final AppLocalizations loc;

  const _IncomingRequestsList({
    required this.stream,
    required this.onRespond,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _RequestEmptyPlaceholder(message: loc.requestsEmpty);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _RequestTile(
              request: request,
              onAccept: () => onRespond(request: request, accept: true),
              onReject: () => onRespond(request: request, accept: false),
              loc: loc,
            );
          },
        );
      },
    );
  }
}

class _OutgoingRequestsList extends StatelessWidget {
  final Stream<List<FriendRequest>> stream;
  final AppLocalizations loc;

  const _OutgoingRequestsList({
    required this.stream,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _RequestEmptyPlaceholder(message: loc.friendOutgoingEmpty);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _OutgoingRequestTile(
              request: request,
              loc: loc,
            );
          },
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final AppLocalizations loc;

  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  request.username.isNotEmpty
                      ? request.username[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.username,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.createdAt.toLocal().toString(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(loc.friendReject),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(loc.friendAccept),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  final FriendRequest request;
  final AppLocalizations loc;

  const _OutgoingRequestTile({
    required this.request,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              request.username.isNotEmpty
                  ? request.username[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  request.createdAt.toLocal().toString(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              loc.friendPending,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestEmptyPlaceholder extends StatelessWidget {
  final String message;

  const _RequestEmptyPlaceholder({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
