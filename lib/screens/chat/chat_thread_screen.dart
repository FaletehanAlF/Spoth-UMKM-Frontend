import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/notification_socket_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_badge_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../widgets/chat_avatar.dart';
import '../../widgets/shimmer_loading.dart';

// Catatan: Composer tetap direct child Stack di dalam Chat.


class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.bookingId,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.embedded = false,
  });

  final String bookingId;
  final String title;

  /// Kept for compatibility; place name is intentionally not shown in chat.
  final String? subtitle;
  final String? avatarUrl;
  final bool embedded;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = InMemoryChatController();

  bool _loading = true;
  bool _sending = false;
  bool _blocked = false;
  String _currentUserId = '';
  String _myName = 'Saya';
  NotificationSocketService? _socket;
  final _composerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tandaiDibaca());
    _load();
    _socket = ref.read(notificationSocketServiceProvider);
    _socket?.addChatMessageListener(_onChatMessage);
    _socket?.onChatMessageUpdated = _onChatMessageUpdated;
    _socket?.onChatMessageDeleted = _onChatMessageDeleted;
  }

  @override
  void dispose() {
    _socket?.removeChatMessageListener(_onChatMessage);
    _socket?.onChatMessageUpdated = null;
    _socket?.onChatMessageDeleted = null;
    _composerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _composer(BuildContext context) {
    return Composer(
      textEditingController: _composerController,
      hintText: 'Tulis pesan...',
      sendOnEnter: true,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      backgroundColor: AppColors.canvas,
      inputFillColor: AppColors.surfaceMuted,
      hintColor: AppColors.secondaryText,
      textColor: AppColors.darkText,
      sendIcon: const Icon(Icons.arrow_upward, size: 24),
      sendIconColor: AppColors.primaryDeep,
      emptyFieldSendIconColor: Colors.grey,
      sendButtonVisibilityMode: SendButtonVisibilityMode.disabled,
      inputBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.softBorder),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );
  }

  KeyEventResult _handleComposerKeyEvent(FocusNode node, KeyEvent event) {
    final enter = event.logicalKey == LogicalKeyboardKey.enter;
    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Composer menangani Enter kirim; Shift + Enter ditambahkan newline.
    if (event is KeyDownEvent && enter && shiftPressed) {
      _tambahBarisBaru();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _tambahBarisBaru() {
    final value = _composerController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final lower = start < end ? start : end;
    final upper = start < end ? end : start;
    final newText = value.text.replaceRange(lower, upper, '\n');

    _composerController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lower + 1),
    );
  }

  Future<void> _tandaiDibaca() async {
    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    try {
      final total = await ref.read(chatServiceProvider).markRead(
        token: token,
        bookingId: widget.bookingId,
      );
      if (!mounted) return;
      ref.read(chatBadgeProvider.notifier).setTotal(total);
    } catch (_) {
    }
  }

  Future<void> _load() async {
    await Future<void>.value();

    final user = ref.read(authNotifierProvider).user;
    _currentUserId = user?.id ?? '';
    _myName = user?.nama ?? 'Saya';

    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final messages = await ref
          .read(chatServiceProvider)
          .messages(token: token, bookingId: widget.bookingId);

      if (!mounted) return;
      await _controller.setMessages(messages.map(_toTextMessage).toList());

      final blockStatus = await ref
          .read(chatServiceProvider)
          .blockStatus(token: token, bookingId: widget.bookingId);
      if (mounted) setState(() => _blocked = blockStatus.blocked);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onChatMessage(Map<String, dynamic> data) async {
    if (!mounted || _loading) return;

    try {
      final message = ChatMessageModel.fromJson(data);
      if (message.bookingId != widget.bookingId) return;
      if (message.senderId == _currentUserId) return;
      await _addMessage(message);
      unawaited(_tandaiDibaca());
    } catch (_) {
    }
  }

  Future<void> _onChatMessageUpdated(Map<String, dynamic> data) async {
    if (!mounted) return;
    try {
      final message = ChatMessageModel.fromJson(data);
      if (message.bookingId != widget.bookingId) return;
      final oldMessage = _findMessage(message.id);
      if (oldMessage != null) {
        await _controller.updateMessage(oldMessage, _toTextMessage(message));
      }
    } catch (_) {}
  }

  Future<void> _onChatMessageDeleted(Map<String, dynamic> data) async {
    if (!mounted) return;
    final bookingId = data['booking_id']?.toString();
    final messageId = data['id']?.toString();
    if (bookingId != widget.bookingId || messageId == null) return;

    final oldMessage = _findMessage(messageId);
    if (oldMessage != null) {
      await _controller.removeMessage(oldMessage);
    }
  }

  Message? _findMessage(String id) {
    for (final message in _controller.messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  Future<void> _addMessage(ChatMessageModel message) async {
    if (!mounted) return;
    if (_controller.messages.any((m) => m.id == message.id)) return;
    await _controller.insertMessage(_toTextMessage(message));
  }

  TextMessage _toTextMessage(ChatMessageModel message) {
    return TextMessage(
      id: message.id,
      authorId: message.senderId,
      text: message.body,
      createdAt: message.createdAt,
      sentAt: message.createdAt,
      status: MessageStatus.seen,
    );
  }

  Future<void> _onMessageSend(String text) async {
    final body = text.trim();
    if (body.isEmpty || _sending) return;

    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    _sending = true;
    try {
      final message = await ref
          .read(chatServiceProvider)
          .send(token: token, bookingId: widget.bookingId, body: body);

      if (!mounted) return;
      await _addMessage(message);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException && error.message == 'anda di blokir'
          ? 'anda di blokir'
          : 'Pesan gagal dikirim. Coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _sending = false;
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bersihkan chat?'),
        content: const Text('Semua pesan di percakapan ini akan dibersihkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Iya, bersihkan'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    await _controller.setMessages(const []);
  }

  Future<void> _toggleBlocked() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_blocked ? 'Buka blokir?' : 'Blokir kontak?'),
        content: Text(
          _blocked
              ? 'Kontak ini akan bisa mengirim chat kembali.'
              : 'Kontak ini tidak akan bisa mengirim chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Iya'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    final service = ref.read(chatServiceProvider);
    try {
      if (_blocked) {
        await service.unblockContact(token: token, bookingId: widget.bookingId);
      } else {
        await service.blockContact(token: token, bookingId: widget.bookingId);
      }

      if (!mounted) return;
      setState(() => _blocked = !_blocked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status blokir gagal diubah. Coba lagi.')),
      );
    }
  }

  Future<void> _showMessageActions(Message message) async {
    if (!mounted || message.authorId != _currentUserId || message is! TextMessage) {
      return;
    }

    final action = await showDialog<_ChatMessageAction>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Pilih aksi pesan'),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ChatMessageAction.edit),
            child: const Text('Edit pesan'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ChatMessageAction.delete),
            child: const Text(
              'Hapus pesan',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;
    if (action == _ChatMessageAction.edit) {
      await _editMessage(message);
    } else {
      await _deleteMessage(message);
    }
  }

  Future<void> _editMessage(TextMessage message) async {
    final textController = TextEditingController(text: message.text);

    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit pesan'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) Navigator.of(dialogContext).pop(text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    textController.dispose();

    if (!mounted || newText == null || newText == message.text) return;
    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    try {
      final updated = await ref
          .read(chatServiceProvider)
          .editMessage(
            token: token,
            bookingId: widget.bookingId,
            messageId: message.id,
            body: newText,
          );

      if (!mounted) return;
      final oldMessage = _findMessage(message.id);
      if (oldMessage != null) {
        await _controller.updateMessage(oldMessage, _toTextMessage(updated));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan gagal diedit. Coba lagi.')),
      );
    }
  }

  Future<void> _deleteMessage(TextMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pesan?'),
        content: const Text(
          'Pesan ini akan dihapus dan tidak terlihat oleh kontak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    try {
      await ref
          .read(chatServiceProvider)
          .deleteMessage(
            token: token,
            bookingId: widget.bookingId,
            messageId: message.id,
          );

      if (!mounted) return;
      final oldMessage = _findMessage(message.id);
      if (oldMessage != null) await _controller.removeMessage(oldMessage);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan gagal dihapus. Coba lagi.')),
      );
    }
  }

  Future<User> _resolveUser(UserID id) async {
    final name = id == _currentUserId ? _myName : widget.title;
    return User(id: id, name: name);
  }

  Widget _header() {
    return Row(
      children: [
        ChatAvatar(name: widget.title, imageUrl: widget.avatarUrl, size: 36),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.charcoal,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<_ChatMenuAction>(
          tooltip: 'Menu percakapan',
          padding: const EdgeInsets.all(AppSpacing.sm),
          onSelected: (action) {
            if (action == _ChatMenuAction.clear) {
              _clearChat();
            } else {
              _toggleBlocked();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _ChatMenuAction.clear,
              child: Text('Bersihkan chat'),
            ),
            PopupMenuItem(
              value: _ChatMenuAction.block,
              child: Text(_blocked ? 'Buka blokir' : 'Blokir'),
            ),
          ],
          child: const Text(
            ' :',
            style: TextStyle(
              color: AppColors.charcoal,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }

  Widget _percakapan() {
    final chat = Focus(
      onKeyEvent: _handleComposerKeyEvent,
      child: Chat(
        currentUserId: _currentUserId,
        resolveUser: _resolveUser,
        chatController: _controller,
        onMessageSend: _onMessageSend,
        onMessageLongPress:
            (context, message, {required index, required details}) =>
                _showMessageActions(message),
        onMessageSecondaryTap:
            (context, message, {required index, details}) =>
                _showMessageActions(message),
        backgroundColor: AppColors.surfaceMuted,
        builders: Builders(composerBuilder: _composer),
        theme: ChatTheme.light().copyWith(
          colors: ChatTheme.light().colors.copyWith(
            primary: AppColors.primaryDeep,
            onPrimary: AppColors.white,
            surface: AppColors.surfaceMuted,
            surfaceContainer: AppColors.white,
            surfaceContainerLow: AppColors.white,
            surfaceContainerHigh: AppColors.lightOrange,
          ),
          shape: BorderRadius.circular(18),
        ),
      ),
    );

    return _loading ? const _ChatThreadSkeleton() : chat;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                _header(),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.softBorder),
              ],
            ),
          ),
          Expanded(child: _percakapan()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.charcoal),
        titleSpacing: 0,
        title: _header(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.softBorder),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _percakapan(),
        ),
      ),
    );
  }
}

class _ChatThreadSkeleton extends StatelessWidget {
  const _ChatThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerBox(width: 220, height: 54, radius: 18),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ShimmerBox(width: 180, height: 46, radius: 18),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerBox(width: 260, height: 62, radius: 18),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ShimmerBox(width: 160, height: 46, radius: 18),
          ),
        ],
      ),
    );
  }
}
enum _ChatMessageAction { edit, delete }
enum _ChatMenuAction { clear, block }
