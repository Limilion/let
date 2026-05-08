import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/post_provider.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/comments_bottom_sheet.dart';
import '../../providers/music_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flying_hearts.dart';

class VideoFeedScreen extends StatefulWidget {
  final String? initialVideoPostId;
  const VideoFeedScreen({super.key, this.initialVideoPostId});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isScreenVisible = true;
  final Map<String, VideoPlayerController> _preloadedControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.microtask(() async {
      await Provider.of<PostProvider>(context, listen: false).fetchVideos();
      _jumpToInitialVideoIfNeeded();
    });
  }

  void _jumpToInitialVideoIfNeeded() {
    final targetId = widget.initialVideoPostId;
    if (targetId == null) return;
    final videos = Provider.of<PostProvider>(context, listen: false).videoPosts;
    final index = videos.indexWhere((v) => v.id == targetId);
    if (index <= 0) return;
    _currentIndex = index;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVideoPostId != widget.initialVideoPostId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialVideoIfNeeded());
    }
  }

  Future<void> _preloadNextVideo(List<Post> videos, int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex >= videos.length) return;
    final nextPost = videos[nextIndex];
    final key = nextPost.id;
    if (_preloadedControllers.containsKey(key)) return;
    final url = ApiService.getImageUrl(nextPost.mediaUrl);
    if (url == null) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      controller.setVolume(0);
      _preloadedControllers[key] = controller;
    } catch (_) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final videos = postProvider.videoPosts;

    if (postProvider.loading && videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text('لا توجد فيديوهات حالياً', style: TextStyle(color: Colors.white, fontSize: 18)),
              TextButton(
                onPressed: () => postProvider.fetchVideos(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: const Key('video-feed-screen'),
      onVisibilityChanged: (info) {
        if (mounted) {
          setState(() {
            _isScreenVisible = info.visibleFraction > 0.5;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            _preloadNextVideo(videos, index);
          },
          itemBuilder: (context, index) {
            return VideoPlayerItem(
              key: ValueKey(videos[index].id),
              post: videos[index],
              isActive: index == _currentIndex && _isScreenVisible,
            );
          },
        ),
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final Post post;
  final bool isActive;

  const VideoPlayerItem({
    super.key,
    required this.post,
    required this.isActive,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> with WidgetsBindingObserver, RouteAware {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _isBackground = false;
  bool _isRoutePushed = false;
  bool _isVisibleEnough = false;
  bool _isManuallyPaused = false;
  bool _showHeartOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (_isBackground) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed && widget.isActive && !_isRoutePushed && !_isManuallyPaused) {
      final isFeedPaused = Provider.of<PostProvider>(context, listen: false).isFeedPaused;
      if (!isFeedPaused) _controller.play();
    }
  }

  @override
  void didPushNext() {
    _isRoutePushed = true;
    _syncPlaybackState();
  }

  @override
  void didPopNext() {
    _isRoutePushed = false;
    _syncPlaybackState();
  }

  void _initializeController() {
    final url = ApiService.getImageUrl(widget.post.mediaUrl)!;
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _error = null;
          });
          _controller.setLooping(true);
          _syncPlaybackState();
        }
      }).catchError((e) {
        debugPrint('VideoFeed init error: $e');
        if (mounted) {
          setState(() {
            _error = 'تعذر تشغيل الفيديو';
          });
        }
      });
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive && widget.isActive) {
      _isManuallyPaused = false;
    }
    _syncPlaybackState();
  }

  void _syncPlaybackState() {
    if (!_isInitialized) return;
    final isFeedPaused = Provider.of<PostProvider>(context, listen: false).isFeedPaused;
    final shouldPlay =
        widget.isActive && _isVisibleEnough && !_isBackground && !_isRoutePushed && !_isManuallyPaused && !isFeedPaused;
    
    if (shouldPlay) {
      if (!_controller.value.isPlaying) {
        Provider.of<MusicProvider>(context, listen: false).pauseIfPlaying();
        _controller.play();
      }
    } else {
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to feed pause state
    final isFeedPaused = context.select<PostProvider, bool>((p) => p.isFeedPaused);
    if (isFeedPaused && _controller.value.isPlaying) {
      _controller.pause();
    } else if (!isFeedPaused && widget.isActive && _isVisibleEnough && !_isBackground && !_isRoutePushed && !_isManuallyPaused && !_controller.value.isPlaying) {
       _controller.play();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        if (_isInitialized)
          VisibilityDetector(
            key: Key('video-item-${widget.post.id}'),
            onVisibilityChanged: (info) {
              final newVisible = info.visibleFraction >= 0.75;
              if (newVisible != _isVisibleEnough) {
                _isVisibleEnough = newVisible;
                _syncPlaybackState();
              }
            },
            child: GestureDetector(
              onDoubleTap: () {
                // Like the post on double tap
                Provider.of<PostProvider>(context, listen: false).likePost(widget.post.id);
                setState(() => _showHeartOverlay = true);
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted) setState(() => _showHeartOverlay = false);
                });
              },
              onTap: () {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                  _isManuallyPaused = true;
                } else if (widget.isActive && _isVisibleEnough && !_isBackground && !_isRoutePushed) {
                  _controller.play();
                  _isManuallyPaused = false;
                }
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      // Heart animation overlay
                      if (_showHeartOverlay)
                        const IgnorePointer(
                          child: FlyingHeartsOverlay(visible: true),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (_error != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 50),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        // Gradient Overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),

        // Right Side Actions
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(
                icon: widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: widget.post.likes.toString(),
                color: widget.post.isLiked ? Colors.red : Colors.white,
                onTap: () => Provider.of<PostProvider>(context, listen: false).likePost(widget.post.id),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: widget.post.commentsCount.toString(),
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
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.repeat_rounded,
                label: 'إعادة نشر',
                onTap: () {
                   Provider.of<PostProvider>(context, listen: false).repostPost(widget.post.id);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إعادة النشر ✨')));
                },
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.send_rounded,
                label: 'إرسال',
                onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر صديقاً للإرسال له (قيد التطوير)')));
                },
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.more_horiz_rounded,
                label: 'المزيد',
                onTap: () => _showVideoOptions(context, widget.post, Theme.of(context).extension<CustomColors>()!),
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          right: 80,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/user-profile/${widget.post.userId}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: widget.post.userPhoto != null
                            ? NetworkImage(ApiService.getImageUrl(widget.post.userPhoto!)!)
                            : null,
                        child: widget.post.userPhoto == null ? const Icon(Icons.person, size: 16) : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.post.userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  widget.post.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    const Text('الصوت الأصلي', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVideoOptions(BuildContext context, Post post, dynamic colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            _buildOptionItem(Icons.translate_rounded, 'ترجمة النص', Colors.white, () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري الترجمة...')));
            }),
            _buildOptionItem(Icons.visibility_off_rounded, 'غير مهتم', Colors.white, () => context.pop()),
            _buildOptionItem(Icons.block_flipped, 'حظر المستخدم', Colors.red, () => context.pop()),
            _buildOptionItem(Icons.report_gmailerrorred_rounded, 'إبلاغ عن الفيديو', Colors.red, () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التقرير')));
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
