import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';

class ChatSheet extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String receiverId;
  final String receiverName;

  const ChatSheet({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.receiverId,
    this.receiverName = 'Admin Support',
  });

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<bool>? _presenceSubscription;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isOnline = false; // Used ONLY for the green/grey indicator — never blocks send

  @override
  void initState() {
    super.initState();
    _listenStatus();
    _listenPresence();
    _loadHistory();
  }

  void _listenStatus() {
    _statusSubscription = ChatService.statusStream.listen((status) {
      if (!mounted || status.trim().isEmpty) return;

      // Don't show online/offline as snackbar — it's shown as dot in header
      if (status.toLowerCase().contains('online') ||
          status.toLowerCase().contains('offline') ||
          status.toLowerCase().contains('connected') ||
          status.toLowerCase().contains('disconnected') ||
          status.toLowerCase().contains('socket') ||
          status.toLowerCase().contains('stomp') ||
          status.toLowerCase().contains('sending...')) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status),
          backgroundColor:
              status.toLowerCase().contains('failed') ||
                      status.toLowerCase().contains('error') ||
                      status.toLowerCase().contains('network')
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF1E3A8A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _listenPresence() {
    _presenceSubscription = ChatService.presenceStream.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
    });
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _isLoading = true);

    await ChatService.initChat(widget.currentUserId, widget.receiverId);

    if (!mounted) return;

    setState(() {
      _isOnline = ChatService.isReceiverOnline;
      _isLoading = false;
    });

    ChatService.connect(
      userId: widget.currentUserId,
      receiverId: widget.receiverId,
    );

    _scrollToBottom(jump: true);
  }

  void _scrollToBottom({bool jump = false}) {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;
      if (!_scrollController.position.hasContentDimensions) return;

      final offset = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(offset);
      } else {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();
    setState(() {}); // refresh send button immediately

    final result = await ChatService.sendMessage(
      senderId: widget.currentUserId,
      receiverId: widget.receiverId,
      message: text,
      senderName: widget.currentUserName,
    );

    if (!mounted) return;

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _scrollToBottom();
    setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _presenceSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    ChatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_isSending && _controller.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9), // Clean soft slate background
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessages()),
              _buildInputBar(canSend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isAdminChat = widget.receiverName == 'Admin Support';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1E36), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // iOS style top grabber pill
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              // Avatar with glowing ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isAdminChat
                            ? Icons.support_agent_rounded
                            : Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receiverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? const Color(0xFF34D399)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isOnline ? 'Online now' : 'Offline',
                          style: TextStyle(
                            color: _isOnline
                                ? const Color(0xFF34D399)
                                : const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: _loadHistory,
                tooltip: 'Refresh messages',
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2563EB),
              strokeWidth: 2.5,
            ),
            SizedBox(height: 12),
            Text(
              'Loading messages...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.messagesStream,
      initialData: ChatService.messages,
      builder: (context, snapshot) {
        final allMessages = snapshot.data ?? [];

        final messages = allMessages.where((msg) {
          return (msg.senderId == widget.currentUserId &&
                  msg.receiverId == widget.receiverId) ||
              (msg.senderId == widget.receiverId &&
                  msg.receiverId == widget.currentUserId);
        }).toList();

        _scrollToBottom();

        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 32,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Send a message to start communicating with ${widget.receiverName}. Messages sync in real-time.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final msg = messages[i];
            final isMe = msg.senderId == widget.currentUserId;

            return Column(
              children: [
                if (i == 0) const _DateChip(label: 'Today'),
                _ChatBubble(
                  msg: msg,
                  isMe: isMe,
                  otherName: widget.receiverName == 'Admin Support'
                      ? (msg.senderName.isEmpty ? 'Admin' : msg.senderName)
                      : widget.receiverName,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar(bool canSend) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1E36).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                enabled: !_isSending,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) _send();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: canSend
                    ? const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canSend ? null : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      color: canSend ? Colors.white : const Color(0xFF94A3B8),
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final String otherName;

  const _ChatBubble({
    required this.msg,
    required this.isMe,
    required this.otherName,
  });

  String _formatTimestamp(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final local = dt.toLocal();
        final hour = local.hour;
        final minute = local.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$h:$minute $period';
      }
    } catch (_) {}
    return raw;
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: msg.message));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Message copied to clipboard',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0F1E36),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTimestamp(msg.timestamp);
    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for incoming message
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble Container with High-Contrast Legible Content
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                  minWidth: 70,
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe
                      ? null
                      : Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sender header for incoming messages
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          otherName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),

                    // Message Content - 100% Crisp Visible Text
                    Text(
                      msg.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14.5,
                        height: 1.38,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Timestamp & Status Indicator Row
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (formattedTime.isNotEmpty)
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isMe
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.done_all_rounded,
                              size: 13.5,
                              color: Color(0xFF93C5FD),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
