import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../navigation/app_router.dart';
import 'flying_hearts.dart';
import 'comments_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final Function(String)? onLike;
  final Function(Post)? onComment;
  final Function(String)? onDelete;
  final Function(String)? onFollow;
  final bool hideComments;
  final bool autoplayVideo;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.onFollow,
    this.hideComments = false,
    this.autoplayVideo = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late AnimationController _likeController;
  late AnimationController _overlayHeartController;
  VideoPlayerController? _videoController;
  bool _isVideoVisible = false;
  bool _showHeartOverlay = false;
  String? _videoError;
  bool _isBackground = false;
  bool _isRoutePushed = false;
  bool _viewMarked = false;
  bool _isPlaying = true;
  bool _showPlayPauseIcon = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _overlayHeartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _isRoutePushed = true;
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController?.pause();
    }
  }

  @override
  void didPopNext() {
    _isRoutePushed = false;
    if (_isVideoVisible && !_isBackground && _videoController != null && _videoController!.value.isInitialized) {
      _videoController?.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
    if (_isBackground && _videoController != null && _videoController!.value.isInitialized) {
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _likeController.dispose();
    _overlayHeartController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _triggerLikeAnimation() {
    _likeController.forward(from: 0.0).then((_) => _likeController.reverse());
  }

  void _handleDoubleTap() {
    setState(() => _showHeartOverlay = true);
    _overlayHeartController.forward(from: 0.0).then((_) {
      _overlayHeartController.reverse().then((_) {
        setState(() => _showHeartOverlay = false);
      });
    });

    if (!widget.post.isLiked) {
      _triggerLikeAnimation();
      widget.onLike?.call(widget.post.id);
    }
  }

  void _onVideoVisibilityChanged(VisibilityInfo info) {
    if (!widget.autoplayVideo) return;
    if (widget.post.isVideo && widget.post.mediaUrl != null) {
      if (info.visibleFraction > 0.5 &&
          !_isVideoVisible &&
          !_isBackground &&
          !_isRoutePushed) {
        _isVideoVisible = true;
        _markViewIfNeeded();
        _initializeVideoController();
      } else if (info.visibleFraction <= 0.2 && _isVideoVisible) {
        _isVideoVisible = false;
        if (_videoController != null && _videoController!.value.isInitialized) {
          _videoController?.pause();
        }
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  void _toggleVideoPlay() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController?.pause();
        _isPlaying = false;
      } else {
        _videoController?.play();
        _isPlaying = true;
      }
      _showPlayPauseIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showPlayPauseIcon = false);
      }
    });
  }

  void _disposeVideoController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    if (mounted) setState(() {});
  }

  void _markViewIfNeeded() {
    if (_viewMarked) return;
    _viewMarked = true;
    Provider.of<PostProvider>(
      context,
      listen: false,
    ).markPostViewed(widget.post.id);
  }

  void _initializeVideoController() {
    if (_videoController == null && widget.post.mediaUrl != null) {
      final videoUrl = ApiService.getImageUrl(widget.post.mediaUrl);
      if (videoUrl != null) {
        try {
          _videoController =
              VideoPlayerController.networkUrl(Uri.parse(videoUrl))
                ..initialize()
                    .then((_) {
                      if (mounted) {
                        setState(() => _videoError = null);
                        if (_isVideoVisible &&
                            !_isBackground &&
                            !_isRoutePushed) {
                          _videoController?.play();
                          _videoController?.setLooping(true);
                        }
                      }
                    })
                    .catchError((error) {
                      debugPrint('Video init error: $error');
                      if (mounted)
                        setState(() => _videoError = 'فشل تحميل الفيديو');
                    });
        } catch (e) {
          debugPrint('Video try-catch error: $e');
          if (mounted) setState(() => _videoError = 'خطأ غير متوقع');
        }
      }
    } else {
      _videoController?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.user;
    final isOwnPost = widget.post.userId == user?['id']?.toString();

    final mediaUrl = ApiService.getImageUrl(widget.post.mediaUrl);
    final mediaUrls = widget.post.mediaUrls
        .map((e) => ApiService.getImageUrl(e))
        .whereType<String>()
        .toList();
    if (!widget.post.isVideo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markViewIfNeeded();
      });
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border.withOpacity(0.5), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (isOwnPost) {
                      context.go('/main', extra: 4);
                    } else {
                      final heroTag = 'avatar-${widget.post.userId}-${widget.post.id}';
                      GoRouter.of(context).push(
                        '/user-profile/${widget.post.userId}',
                        extra: heroTag,
                      );
                    }
                  },
                  child: Row(
                    children: [
                      _buildAvatar(colors),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.post.userName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.text,
                                ),
                              ),
                              if (widget.post.isCelebrity) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: colors.primary,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            widget.post.time,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showPostOptions(
                    context,
                    postProvider,
                    isOwnPost,
                    colors,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Post Content Text
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                widget.post.content,
                style: TextStyle(fontSize: 14, color: colors.text, height: 1.3),
              ),
            ),

          // Media Area
          if (mediaUrl != null || mediaUrls.isNotEmpty)
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              onTap: () {
                if (widget.post.isVideo) {
                  // Navigate to full video screen
                  context.push('/video-feed', extra: widget.post.id);
                } else {
                  context.push('/post-details', extra: widget.post);
                }
              },
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.background,
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.passthrough, // Ensure stack doesn't collapse/expand unexpectedly
                  children: [
                    widget.post.isVideo
                        ? VisibilityDetector(
                            key: Key('video-${widget.post.id}'),
                            onVisibilityChanged: _onVideoVisibilityChanged,
                            child:
                                _videoController != null &&
                                    _videoController!.value.isInitialized
                                ? SizedBox(
                                    width: double.infinity,
                                     child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: SizedBox(
                                        width:
                                            _videoController!.value.size.width,
                                        height:
                                            _videoController!.value.size.height,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            VideoPlayer(_videoController!),
                                            if (_showPlayPauseIcon)
                                              FadeIn(
                                                duration: const Duration(milliseconds: 200),
                                                child: Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.3),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                                    color: Colors.white,
                                                    size: 50,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : _videoError != null
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: colors.textSecondary,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _videoError!,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: CircularProgressIndicator(
                                      color: colors.primary,
                                    ),
                                  ),
                          )
                        : (mediaUrls.length > 1
                              ? Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      child: PageView.builder(
                                        itemCount: mediaUrls.length,
                                        onPageChanged: (idx) => setState(
                                          () => _currentImageIndex = idx,
                                        ),
                                        itemBuilder: (context, index) =>
                                            CachedNetworkImage(
                                              imageUrl: mediaUrls[index],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (context, url) =>
                                                  Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: colors.primary,
                                                        ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      _buildImageError(colors),
                                            ),
                                      ),
                                    ),
                                    if (mediaUrls.length > 1)
                                      Positioned(
                                        bottom: 12,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            mediaUrls.length,
                                            (index) {
                                              return AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                    ),
                                                height: 6,
                                                width:
                                                    _currentImageIndex == index
                                                    ? 16
                                                    : 6,
                                                decoration: BoxDecoration(
                                                  color:
                                                      _currentImageIndex ==
                                                          index
                                                      ? Colors.white
                                                      : Colors.white.withValues(
                                                          alpha: 0.5,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : CachedNetworkImage(
                                  imageUrl: mediaUrl ?? mediaUrls.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: colors.primary,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      _buildImageError(colors),
                                )),

                    // Video Play Icon Overlay
                    if (widget.post.isVideo &&
                        _videoController != null &&
                        _videoController!.value.isInitialized &&
                        !_videoController!.value.isPlaying)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),

                    // Flying Hearts Animation Overlay - Wrap with IgnorePointer to prevent layout shifts
                    IgnorePointer(
                      child: FlyingHeartsOverlay(visible: _showHeartOverlay),
                    ),
                  ],
                ),
              ),
            ),

          // Engagement Stats & Actions Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                _buildAnimatedActionButton(
                  icon: widget.post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: widget.post.isLiked ? colors.error : colors.text,
                  onTap: () {
                    _triggerLikeAnimation();
                    widget.onLike?.call(widget.post.id);
                  },
                  controller: _likeController,
                ),
                Text(
                  '${widget.post.likes}',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: colors.text,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsBottomSheet(
                        postId: widget.post.id,
                        initialCommentsCount: widget.post.commentsCount,
                      ),
                    );
                  },
                ),
                Text(
                  '${widget.post.commentsCount}',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.repeat_rounded,
                  color: colors.text,
                  onTap: () {
                     Provider.of<PostProvider>(context, listen: false).repostPost(widget.post.id);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إعادة النشر ✨')));
                  },
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.send_rounded,
                  color: colors.text,
                  onTap: () {
                    // Logic to send to friend
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر صديقاً للإرسال له (قيد التطوير)')));
                  },
                ),
                const Spacer(),
                _buildActionButton(
                  icon: widget.post.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: widget.post.isSaved ? colors.primary : colors.text,
                  onTap: () => postProvider.toggleSavePost(widget.post.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError(CustomColors colors) {
    return Container(
      color: colors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 40, color: colors.muted),
          const SizedBox(height: 8),
          Text(
            'تعذر تحميل الصورة',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildAnimatedActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required AnimationController controller,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 0.8).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildAvatar(CustomColors colors) {
    final avatarUrl = ApiService.getImageUrl(widget.post.userPhoto);
    return Hero(
      tag: 'avatar-${widget.post.userId}-${widget.post.id}',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [colors.border, colors.border.withValues(alpha: 0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(2), // Gradient border illusion
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl != null
              ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.contain)
              : Container(
                  color: colors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: colors.primary, size: 24),
                ),
        ),
      ),
    );
  }

  void _showPostOptions(
    BuildContext context,
    PostProvider provider,
    bool isOwnPost,
    CustomColors colors,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionItem(
                  Icons.translate_rounded,
                  'ترجمة المنشور',
                  colors.primary,
                  () {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري الترجمة بواسطة ذكاء LinkUp...')));
                  },
                ),
                _buildOptionItem(
                  Icons.visibility_off_rounded,
                  'غير مهتم / لم يعجبني',
                  colors.text,
                  () => context.pop(),
                ),
                _buildOptionItem(
                  Icons.favorite_outline_rounded,
                  'مهتم بهذا المحتوى',
                  colors.text,
                  () => context.pop(),
                ),
                if (!isOwnPost) ...[
                  _buildOptionItem(
                    Icons.block_flipped,
                    'حظر المستخدم',
                    colors.error,
                    () => context.pop(),
                  ),
                  _buildOptionItem(
                    Icons.report_gmailerrorred_rounded,
                    'تقارير / إبلاغ',
                    colors.error,
                    () {
                      if (context.canPop()) context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم إرسال البلاغ للتحقق.'),
                          backgroundColor: colors.error,
                        ),
                      );
                    },
                  ),
                ],
                if (isOwnPost)
                  _buildOptionItem(
                    Icons.delete_rounded,
                    'حذف المنشور',
                    colors.error,
                    () {
                      if (context.canPop()) context.pop();
                      _showDeleteDialog(context, provider);
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PostProvider provider) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'حذف المنشور',
          style: TextStyle(fontWeight: FontWeight.w900, color: colors.text),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف هذا المنشور بشكل نهائي؟',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (context.canPop()) context.pop();
              final result = await provider.deletePost(widget.post.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['success']
                          ? 'تم حذف المنشور بنجاح!'
                          : (result['message'] ?? 'فشل الحذف'),
                    ),
                    backgroundColor: result['success']
                        ? colors.primary
                        : colors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRepostDialog(BuildContext context, PostProvider provider) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'إعادة نشر',
          style: TextStyle(fontWeight: FontWeight.w900, color: colors.text),
        ),
        content: Text(
          'هل تريد إعادة نشر هذا المنشور على صفحتك؟',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (context.canPop()) context.pop();
              final result = await provider.repostPost(widget.post.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['success']
                          ? 'تم إعادة نشر المنشور بنجاح!'
                          : (result['error'] ?? 'حدث خطأ'),
                    ),
                    backgroundColor: result['success']
                        ? colors.primary
                        : colors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تأكيد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
