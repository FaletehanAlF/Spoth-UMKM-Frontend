import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/chat_service.dart';
import '../../core/services/notification_socket_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_badge_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../widgets/chat_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import 'chat_thread_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _loading = true;
  String? _error;
  List<ChatConversation> _items = const [];
  ChatConversation? _terpilih;
  NotificationSocketService? _socket;

  @override
  void initState() {
    super.initState();
    _load();
    _socket = ref.read(notificationSocketServiceProvider);
    _socket?.addChatMessageListener(_onChatMessage);
  }

  @override
  void dispose() {
    _socket?.removeChatMessageListener(_onChatMessage);
    super.dispose();
  }

  void _onChatMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      final message = ChatMessageModel.fromJson(data);
      final userId = ref.read(authNotifierProvider).user?.id;
      if (message.senderId == userId) return;
      if (_terpilih?.bookingId == message.bookingId) return;

      final diperbarui = <ChatConversation>[];
      var ditemukan = false;

      for (final item in _items) {
        if (item.bookingId == message.bookingId) {
          ditemukan = true;
          diperbarui.add(item.copyWith(unreadCount: item.unreadCount + 1));
        } else {
          diperbarui.add(item);
        }
      }
      if (!ditemukan) return;

      setState(() => _items = diperbarui);
    } catch (_) {
    }
  }

  Future<void> _load() async {
    await Future<void>.value();

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _terpilih = null;
          _loading = false;
          _error = null;
        });
        return;
      }

      final items = await ref.read(chatServiceProvider).conversations(token: token);
      if (!mounted) return;

      final total = items.fold<int>(0, (jumlah, item) => jumlah + item.unreadCount);
      ref.read(chatBadgeProvider.notifier).setTotal(total);

      setState(() {
        _items = items;
        _terpilih = null;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat chat';
        _loading = false;
      });
    }
  }

  Future<void> _buka(ChatConversation conversation, bool duaPanel) async {
    setState(() {
      _terpilih = conversation;
      _items = [
        for (final item in _items)
          if (item.bookingId == conversation.bookingId)
            item.copyWith(unreadCount: 0)
          else
            item,
      ];
    });

    if (duaPanel) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadScreen(
          bookingId: conversation.bookingId,
          title: conversation.namaLain,
          avatarUrl: conversation.foto,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleEscape,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: const SpothAppBar(
          title: Text('Chat'),
          showRiwayat: true,
          showNotification: true,
        ),
        body: SafeArea(top: false, child: _isiTubuh()),
      ),
    );
  }

  KeyEventResult _handleEscape(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _terpilih != null) {
      _closeChat();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _closeChat() {
    setState(() => _terpilih = null);
  }

  Widget _isiTubuh() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaPanel = constraints.maxWidth >= AppWidth.sidebar;

        if (!duaPanel) return _daftar(false);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 320, child: _daftar(true)),
            Expanded(child: _detail(true)),
          ],
        );
      },
    );
  }

  Widget _daftar(bool duaPanel) {
    if (_loading) return const _ChatListSkeleton();

    if (_error != null) {
      return Center(
        child: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: _error!,
          message: 'Periksa koneksi lalu coba lagi.',
          actionLabel: 'Coba lagi',
          onAction: _load,
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Belum ada chat',
          message: 'Mulai pemesanan untuk chat dengan penyewa/pemilik.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: duaPanel ? double.infinity : AppWidth.list,
          ),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final conversation = _items[index];
              return _ConversationCard(
                conversation: conversation,
                selected: duaPanel && _terpilih?.bookingId == conversation.bookingId,
                onTap: () => _buka(conversation, duaPanel),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detail(bool duaPanel) {
    final conversation = _terpilih;
    if (conversation == null) {
      return const _BelumPilihChat();
    }

    return ChatThreadScreen(
      key: ValueKey(conversation.bookingId),
      embedded: duaPanel,
      bookingId: conversation.bookingId,
      title: conversation.namaLain,
      avatarUrl: conversation.foto,
    );
  }
}

class _BelumPilihChat extends StatelessWidget {
  const _BelumPilihChat();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Belum ada percakapan dibuka',
        message: 'Pilih chat di daftar untuk membaca pesan.',
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = conversation.namaLain.isEmpty ? 'Pengguna' : conversation.namaLain;

    return Material(
      color: selected ? AppColors.lightOrange : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primaryOrange : AppColors.softBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatAvatar(name: name, imageUrl: conversation.foto, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (conversation.lastMessage?.trim().isNotEmpty ?? false) ...[
                          const Icon(
                            Icons.done_all,
                            size: 14,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            conversation.lastMessage ?? 'Mulai percakapan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversation.lastMessageAt != null)
                    Text(
                      formatWaktuChat(conversation.lastMessageAt),
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  if (conversation.unreadCount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 48, height: 48, radius: 24),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 150, height: 15),
                    SizedBox(height: 9),
                    ShimmerBox(width: 100, height: 12),
                    SizedBox(height: 9),
                    ShimmerBox(width: double.infinity, height: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
