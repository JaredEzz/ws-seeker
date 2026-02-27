import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/all_chats/all_chats_bloc.dart';
import '../../blocs/comments/comments_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/theme_toggle_button.dart';

class AllChatsScreen extends StatelessWidget {
  const AllChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AllChatsBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(const AllChatsFetchRequested()),
      child: const AllChatsContent(),
    );
  }
}

class AllChatsContent extends StatelessWidget {
  const AllChatsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<AllChatsBloc>().add(const AllChatsFetchRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AllChatsBloc, AllChatsState>(
        builder: (context, state) {
          if (state is AllChatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AllChatsFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AllChatsLoaded) {
            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No conversations yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Comments on orders will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              );
            }
            return _ConversationList(conversations: state.conversations);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<OrderConversation> conversations;
  const _ConversationList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ConversationCard(conversation: conversations[index]),
        );
      },
    );
  }
}

class _ConversationCard extends StatefulWidget {
  final OrderConversation conversation;
  const _ConversationCard({required this.conversation});

  @override
  State<_ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<_ConversationCard> {
  bool _expanded = false;
  static const _collapsedPreviewCount = 3;

  @override
  Widget build(BuildContext context) {
    final order = widget.conversation.order;
    final comments = widget.conversation.comments;
    final theme = Theme.of(context);

    // For collapsed view, show the last few messages (most recent first in the list,
    // but display oldest-first for reading order)
    final previewComments = comments.length <= _collapsedPreviewCount
        ? comments.reversed.toList()
        : comments.take(_collapsedPreviewCount).toList().reversed.toList();

    final displayId = order.displayOrderNumber ?? order.id;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — order info + expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Tokens.statusColor(order.status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order $displayId',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.language.name.toUpperCase()} '
                          '- ${Tokens.statusLabel(order.status)} '
                          '- ${comments.length} message${comments.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/orders/${order.id}'),
                    child: const Text('View Order'),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          // Collapsed: preview of recent messages
          if (!_expanded) ...[
            const Divider(height: 1),
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No messages yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final comment in previewComments)
                      _CompactCommentRow(comment: comment),
                    if (comments.length > _collapsedPreviewCount)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${comments.length - _collapsedPreviewCount} more message${comments.length - _collapsedPreviewCount == 1 ? '' : 's'}...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          // Expanded: full conversation + input
          if (_expanded) ...[
            const Divider(height: 1),
            _ExpandedConversation(
              orderId: order.id,
              comments: comments,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact single-line comment preview for collapsed view.
class _CompactCommentRow extends StatelessWidget {
  final OrderComment comment;
  const _CompactCommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = comment.imageUrl != null;
    final text = comment.content.isNotEmpty
        ? comment.content
        : (hasImage ? '[Image]' : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              comment.userName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(comment.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}

/// Full conversation view with all messages and input field.
class _ExpandedConversation extends StatelessWidget {
  final String orderId;
  final List<OrderComment> comments;

  const _ExpandedConversation({
    required this.orderId,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentsBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(CommentsFetchRequested(orderId: orderId)),
      child: _ExpandedConversationContent(orderId: orderId),
    );
  }
}

class _ExpandedConversationContent extends StatefulWidget {
  final String orderId;
  const _ExpandedConversationContent({required this.orderId});

  @override
  State<_ExpandedConversationContent> createState() =>
      _ExpandedConversationContentState();
}

class _ExpandedConversationContentState
    extends State<_ExpandedConversationContent> {
  final _controller = TextEditingController();
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _pendingImageBytes = file.bytes;
      _pendingImageName = file.name;
    });
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageName = null;
    });
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _pendingImageBytes == null) return;
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      String? imageUrl;
      if (_pendingImageBytes != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadCommentImage(
          orderId: widget.orderId,
          filename: _pendingImageName!,
          bytes: _pendingImageBytes!,
        );
      }

      if (!mounted) return;
      context.read<CommentsBloc>().add(
            CommentSendRequested(
              orderId: widget.orderId,
              content: content,
              imageUrl: imageUrl,
            ),
          );
      _controller.clear();
      _clearPendingImage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live comment list from CommentsBloc
        BlocBuilder<CommentsBloc, CommentsState>(
          builder: (context, state) {
            if (state is CommentsLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (state is CommentsLoaded) {
              return _FullCommentList(comments: state.comments);
            }
            if (state is CommentsFailure) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Error: ${state.message}'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const Divider(height: 1),
        // Pending image preview
        if (_pendingImageBytes != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _pendingImageBytes!,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: _clearPendingImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Input row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                tooltip: 'Attach image',
                onPressed: _isSending ? null : _pickImage,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filled(
                      icon: const Icon(Icons.send),
                      onPressed: _sendComment,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full list of comment bubbles (same style as existing CommentSection).
class _FullCommentList extends StatelessWidget {
  final List<OrderComment> comments;
  const _FullCommentList({required this.comments});

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('No comments yet')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: comments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _CommentBubble(comment: comments[index]);
        },
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final OrderComment comment;
  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SemanticColors.userColor(comment.userId, Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(Tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.userName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                _formatTime(comment.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          if (comment.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(comment.content),
          ],
          if (comment.imageUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullImage(context, comment.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 200, maxHeight: 150),
                  child: Image.network(
                    comment.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 200,
                        height: 100,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: Icon(Icons.broken_image_outlined)),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon:
                    const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
