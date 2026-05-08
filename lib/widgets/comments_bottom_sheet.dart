import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final int initialCommentsCount;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.initialCommentsCount = 0,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final result = await postProvider.fetchComments(widget.postId);
      if (result['success'] && mounted) {
        setState(() {
          _comments = result['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // Clear input and focus
    _commentController.clear();
    final replyId = _replyingToId;
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });

    try {
      final result = await postProvider.addComment(widget.postId, text);
      if (result['success']) {
        _fetchComments(); // Refresh list
        // Scroll to bottom if it's a new main comment
        if (replyId == null) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إضافة التعليق')),
      );
    }
  }

  Future<void> _toggleLike(String commentId, int index, {int? replyIndex}) async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    try {
      final result = await postProvider.toggleCommentLike(commentId);
      if (result['success'] && mounted) {
        setState(() {
          if (replyIndex == null) {
            _comments[index]['isLiked'] = result['data']['isLiked'];
            _comments[index]['likesCount'] = result['data']['likesCount'];
          } else {
            _comments[index]['replies'][replyIndex]['isLiked'] = result['data']['isLiked'];
            _comments[index]['replies'][replyIndex]['likesCount'] = result['data']['likesCount'];
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToId = commentId;
      _replyingToName = userName;
    });
    FocusScope.of(context).nextFocus(); // Optional: trigger keyboard
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_comments.length} تعليقات',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.3)),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 60, color: colors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('لا توجد تعليقات بعد', style: TextStyle(color: colors.textSecondary)),
                            Text('كن أول من يعلق!', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) => _buildCommentItem(_comments[index], index, colors),
                      ),
          ),

          // Input Area
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.3))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            'الرد على @$_replyingToName',
                            style: TextStyle(color: colors.primary, fontSize: 12),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() {
                              _replyingToId = null;
                              _replyingToName = null;
                            }),
                            child: Icon(Icons.close, size: 16, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: context.watch<AuthProvider>().user?['photo'] != null
                            ? NetworkImage(ApiService.getImageUrl(context.watch<AuthProvider>().user!['photo'])!)
                            : null,
                        child: context.watch<AuthProvider>().user?['photo'] == null ? const Icon(Icons.person, size: 18) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'أضف تعليقاً...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                          ),
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: colors.primary),
                        onPressed: _submitComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment, int index, CustomColors colors, {bool isReply = false, int? parentIndex}) {
    final avatarUrl = ApiService.getImageUrl(comment['userPhoto']);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: isReply ? 40 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Icon(Icons.person, size: isReply ? 14 : 18) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['userName'] ?? 'مستخدم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isReply ? 12 : 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment['createdAt']),
                      style: TextStyle(fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['comment'] ?? '',
                  style: TextStyle(fontSize: isReply ? 13 : 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _startReply(comment['id'], comment['userName']),
                      child: Text(
                        'رد',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
                
                // Replies List
                if (!isReply && comment['replies'] != null && comment['replies'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: (comment['replies'] as List).asMap().entries.map((entry) {
                        return _buildCommentItem(
                          entry.value,
                          index,
                          colors,
                          isReply: true,
                          parentIndex: index,
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(
                  comment['id'],
                  parentIndex ?? index,
                  replyIndex: isReply ? (comment['replies'] as List).indexOf(comment) : null,
                ),
                child: ZoomIn(
                  child: Icon(
                    comment['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: comment['isLiked'] == true ? Colors.red : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${comment['likesCount']}',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final dt = date is DateTime ? date : DateTime.parse(date.toString());
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes} د';
    if (diff.inHours < 24) return '${diff.inHours} س';
    if (diff.inDays < 7) return '${diff.inDays} ي';
    return DateFormat('MM/dd').format(dt);
  }
}
