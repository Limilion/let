import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/story_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_router.dart';

class StoryViewerScreen extends StatefulWidget {
  final UserStory userWithStories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.userWithStories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late int _currentIndex;
  late List<StoryItem> _stories;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isBackground = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _stories = widget.userWithStories.stories;
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(vsync: this);

    _loadStory(story: _stories[_currentIndex]);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onNext();
      }
    });

    // Mark as viewed
    _markViewed();
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
      _videoController?.pause();
      _animationController.stop();
    } else if (state == AppLifecycleState.resumed && !_isPaused) {
      _videoController?.play();
      _animationController.forward();
    }
  }

  @override
  void didPushNext() {
    _videoController?.pause();
    _animationController.stop();
  }

  @override
  void didPopNext() {
    if (!_isPaused) {
      _videoController?.play();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _isPaused = true;
    });
    _animationController.stop();
    _videoController?.pause();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final receiverId = widget.userWithStories.userId;
      
      final result = await chatProvider.sendMessage(receiverId, 'الرد على القصة: \n$text');
      
      if (mounted) {
        if (result['success']) {
          _commentController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الرد بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'فشل إرسال الرد')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isPaused = false;
        });
        _animationController.forward();
        _videoController?.play();
      }
    }
  }

  void _loadStory({required StoryItem story, bool animate = true}) {
    _animationController.stop();
    _animationController.reset();

    if (story.type == 'video') {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(ApiService.getImageUrl(story.url)!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isLoading = false);
            _videoController!.play();
            _animationController.duration = _videoController!.value.duration;
            _animationController.forward();
          }
        });
    } else {
      _isLoading = false;
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward();
    }
  }

  void _markViewed() {
    Provider.of<StoryProvider>(context, listen: false)
        .markStoryViewed(_stories[_currentIndex].id);
  }

  void _onNext() {
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
        _isLoading = true;
      });
      _loadStory(story: _stories[_currentIndex]);
      _markViewed();
    } else {
      if (context.canPop()) context.pop();
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isLoading = true;
      });
      _loadStory(story: _stories[_currentIndex]);
      _markViewed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final story = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapX = details.globalPosition.dx;

          if (tapX < screenWidth / 3) {
            _onPrevious();
          } else if (tapX > 2 * screenWidth / 3) {
            _onNext();
          }
        },
        onLongPressStart: (_) {
          setState(() => _isPaused = true);
          _animationController.stop();
          _videoController?.pause();
        },
        onLongPressEnd: (_) {
          setState(() => _isPaused = false);
          _animationController.forward();
          _videoController?.play();
        },
        child: Stack(
          children: [
            // Media
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: story.type == 'video'
                    ? (_videoController != null && _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator())
                    : Image.network(
                        ApiService.getImageUrl(story.url)!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
              ),
            ),

            // Progress Bars
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children: _stories.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Stack(
                        children: [
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              double widthFactor = 0;
                              if (entry.key < _currentIndex) {
                                widthFactor = 1;
                              } else if (entry.key == _currentIndex) {
                                widthFactor = _animationController.value;
                              }
                              return FractionallySizedBox(
                                widthFactor: widthFactor,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Header
            Positioned(
              top: 55,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.userWithStories.userPhoto != null
                        ? NetworkImage(ApiService.getImageUrl(widget.userWithStories.userPhoto!)!)
                        : null,
                    child: widget.userWithStories.userPhoto == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.userWithStories.userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (story.views != null && story.views! > 0)
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${story.views}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Text(
                        'منذ قليل',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () {
                      if (context.canPop()) context.pop();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Actions (Simplified)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _commentController,
                        onSubmitted: (_) => _handleSendMessage(),
                        onTap: () {
                           setState(() => _isPaused = true);
                           _animationController.stop();
                           _videoController?.pause();
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'ارسل رسالة...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      story.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: story.isLiked ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Provider.of<StoryProvider>(context, listen: false)
                          .toggleStoryLike(story.id);
                      setState(() {
                        // Optimistic update
                        _stories[_currentIndex] = StoryItem(
                          id: story.id,
                          url: story.url,
                          type: story.type,
                          isLiked: !story.isLiked,
                          likes: story.likes + (story.isLiked ? -1 : 1),
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 26),
                    onPressed: _handleSendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
