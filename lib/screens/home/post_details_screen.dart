import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/post.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/ui_state_widgets.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  String? _commentsError;
  late Post _currentPost;
  String? _replyToCommentId;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    Provider.of<PostProvider>(
      context,
      listen: false,
    ).markPostViewed(_currentPost.id);
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });
    final result = await Provider.of<PostProvider>(
      context,
      listen: false,
    ).fetchComments(_currentPost.id);
    if (mounted) {
      setState(() {
        _comments = result['success'] ? result['data'] : [];
        _commentsError = result['success']
            ? null
            : (result['error']?.toString() ?? 'تعذر تحميل التعليقات');
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _handleAddComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final result = _replyToCommentId == null
        ? await postProvider.addComment(_currentPost.id, text)
        : await postProvider.addReply(
            _currentPost.id,
            _replyToCommentId!,
            text,
          );
    if (result['success']) {
      _commentController.clear();
      _replyToCommentId = null;
      _fetchComments();
      // Update local post comment count
      setState(() {
        _currentPost = Post(
          id: _currentPost.id,
          userId: _currentPost.userId,
          userName: _currentPost.userName,
          userPhoto: _currentPost.userPhoto,
          content: _currentPost.content,
          mediaUrl: _currentPost.mediaUrl,
          mediaType: _currentPost.mediaType,
          likes: _currentPost.likes,
          commentsCount: _currentPost.commentsCount + 1,
          viewsCount: _currentPost.viewsCount,
          engagementScore: _currentPost.engagementScore,
          createdAt: _currentPost.createdAt,
          time: _currentPost.time,
          isLiked: _currentPost.isLiked,
          isSaved: _currentPost.isSaved,
          musicTitle: _currentPost.musicTitle,
          filterType: _currentPost.filterType,
          repostId: _currentPost.repostId,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'فشل إضافة التعليق')),
      );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'الآن';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inMinutes < 60) return '${difference.inMinutes} د';
      if (difference.inHours < 24) return '${difference.inHours} س';
      if (difference.inDays < 7) return '${difference.inDays} ي';
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (e) {
      return 'قديماً';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final currentUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?['id']?.toString();

    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: colors.surface.withValues(alpha: 0.8),
              elevation: 0,
              centerTitle: true,
              title: Text(
                'المنشور',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.text,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              shape: Border(
                bottom: BorderSide(color: colors.border.withValues(alpha: 0.1)),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostCard(post: _currentPost),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التعليقات',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_comments.length}',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingComments)
                    const StateLoading(message: 'جار تحميل التعليقات...')
                  else if (_commentsError != null)
                    StateError(
                      title: 'فشل تحميل التعليقات',
                      subtitle: _commentsError,
                      onRetry: _fetchComments,
                    )
                  else if (_comments.isEmpty)
                    const StateEmpty(
                      icon: Icons.chat_bubble_outline,
                      title: 'لا توجد تعليقات بعد',
                    )
                  else
                    ..._comments.map(
                      (comment) => _buildCommentItem(
                        comment,
                        colors,
                        false,
                        currentUserId,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildCommentInput(colors),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    Map<String, dynamic> comment,
    dynamic colors,
    bool isReply,
    String? currentUserId,
  ) {
    final canDelete =
        comment['userId']?.toString() == currentUserId ||
        _currentPost.userId?.toString() == currentUserId;

    return Container(
      margin: isReply
          ? const EdgeInsets.only(left: 44, top: 4)
          : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReply ? colors.surface.withValues(alpha: 0.5) : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors.primaryGradient),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.surface,
              backgroundImage: comment['userPhoto'] != null
                  ? NetworkImage(ApiService.getImageUrl(comment['userPhoto'])!)
                  : null,
              child: comment['userPhoto'] == null
                  ? Icon(Icons.person, size: 18, color: colors.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment['userName'] ?? 'مستخدم',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      _formatTime(comment['createdAt']),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment['comment'] ?? '',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await Provider.of<PostProvider>(
                          context,
                          listen: false,
                        ).toggleCommentLike(comment['id'].toString());
                        if (result['success']) {
                          _fetchComments();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (comment['isLiked'] == true)
                              ? colors.error.withValues(alpha: 0.1)
                              : colors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (comment['isLiked'] == true)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 14,
                              color: (comment['isLiked'] == true)
                                  ? colors.error
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment['likesCount'] ?? 0}',
                              style: TextStyle(
                                color: (comment['isLiked'] == true)
                                    ? colors.error
                                    : colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isReply)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _replyToCommentId = comment['id'].toString();
                          });
                        },
                        child: Text(
                          'رد',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    if (canDelete) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: colors.surface,
                              title: Text(
                                'تأكيد الحذف',
                                style: TextStyle(color: colors.text),
                              ),
                              content: Text(
                                'هل أنت متأكد من حذف هذا التعليق؟',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => ctx.pop(false),
                                  child: Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => ctx.pop(true),
                                  child: Text(
                                    'حذف',
                                    style: TextStyle(color: colors.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final res = await Provider.of<PostProvider>(
                              context,
                              listen: false,
                            ).deleteComment(comment['id'].toString());
                            if (res['success']) _fetchComments();
                          }
                        },
                        child: Text(
                          'حذف',
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if ((comment['replies'] as List?)?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: (comment['replies'] as List)
                          .map(
                            (reply) => _buildCommentItem(
                              Map<String, dynamic>.from(reply),
                              colors,
                              true,
                              currentUserId,
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(dynamic colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: null,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: _replyToCommentId == null
                      ? 'اكتب تعليقاً...'
                      : 'اكتب ردًا...',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (_replyToCommentId != null)
            IconButton(
              onPressed: () => setState(() => _replyToCommentId = null),
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
            ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors.primaryGradient),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _handleAddComment,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
