/// Comments API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware/auth_middleware.dart';
import '../services/comment_service.dart';

class CommentsHandler {
  final CommentService _commentService;

  CommentsHandler({required CommentService commentService})
      : _commentService = commentService;

  Router get router {
    final router = Router();

    // POST /api/orders/<orderId>/comments - Add comment
    router.post('/<orderId>/comments', _addComment);

    // GET /api/orders/<orderId>/comments - List comments
    router.get('/<orderId>/comments', _getComments);

    return router;
  }

  /// POST /api/orders/<orderId>/comments
  /// Body: { content: string, isInternal?: bool }
  Future<Response> _addComment(Request request, String orderId) async {
    final userId = request.context[AuthContext.userId] as String?;
    final userEmail = request.context[AuthContext.userEmail] as String?;

    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final content = data['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'content is required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final comment = await _commentService.addComment(
        orderId: orderId,
        userId: userId,
        userName: userEmail ?? 'Unknown',
        content: content,
        isInternal: data['isInternal'] as bool? ?? false,
      );

      return Response(201,
          body: jsonEncode({'comment': comment}),
          headers: {'Content-Type': 'application/json'});
    } on ArgumentError catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to add comment: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// GET /api/orders/<orderId>/comments
  Future<Response> _getComments(Request request, String orderId) async {
    final userId = request.context[AuthContext.userId] as String?;
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final comments = await _commentService.getComments(orderId);

      return Response.ok(
          jsonEncode({'comments': comments}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch comments: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
