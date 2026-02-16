import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/comments/comments_bloc.dart';
import '../../repositories/order_repository.dart';

class CommentSection extends StatelessWidget {
  final String orderId;
  const CommentSection({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentsBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(CommentsFetchRequested(orderId: orderId)),
      child: _CommentSectionContent(orderId: orderId),
    );
  }
}

class _CommentSectionContent extends StatefulWidget {
  final String orderId;
  const _CommentSectionContent({required this.orderId});

  @override
  State<_CommentSectionContent> createState() => _CommentSectionContentState();
}

class _CommentSectionContentState extends State<_CommentSectionContent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendComment() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    context.read<CommentsBloc>().add(
          CommentSendRequested(orderId: widget.orderId, content: content),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            BlocBuilder<CommentsBloc, CommentsState>(
              builder: (context, state) {
                if (state is CommentsLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (state is CommentsLoaded) {
                  return _CommentList(comments: state.comments);
                }
                if (state is CommentsFailure) {
                  return Text('Error: ${state.message}');
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(),
            Row(
              children: [
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
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentList extends StatelessWidget {
  final List<OrderComment> comments;
  const _CommentList({required this.comments});

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('No comments yet')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _CommentBubble(comment: comment);
      },
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
        color: Tokens.surfaceComment,
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
          const SizedBox(height: 4),
          Text(comment.content),
        ],
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
