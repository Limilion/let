import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/stories_bar.dart';
import '../../widgets/ui_state_widgets.dart';
import '../../services/api_service.dart';
import '../../widgets/shimmer_loading.dart';

enum _CreateAction { post, story, reels, live, note, ai }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const double _paginationTriggerOffset = 500;
  static const Duration _scrollDebounceDuration = Duration(milliseconds: 250);
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(_scrollDebounceDuration, _tryLoadMore);
  }

  void _tryLoadMore() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    if (_isLoadingMore) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _paginationTriggerOffset) {
      return;
    }

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    if (postProvider.loading || !postProvider.hasMorePosts) return;
    if (postProvider.loadMoreError != null) return;

    setState(() => _isLoadingMore = true);
    postProvider.loadMorePosts().whenComplete(() {
      if (postProvider.loadMoreError != null) {
        ApiService.trackEvent(
          'feed_load_more_failed',
          source: 'feed_screen',
          metadata: {'error': postProvider.loadMoreError},
        );
      }
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _refreshFeed(
    PostProvider postProvider,
    StoryProvider storyProvider,
  ) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        postProvider.fetchPosts(),
        storyProvider.fetchStories(),
      ]);
      await ApiService.trackEvent(
        'feed_refresh',
        source: 'feed_screen',
        metadata: {'postsCount': postProvider.posts.length},
      );
    } finally {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final postProvider = Provider.of<PostProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);
    final feedPosts = postProvider.posts;

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: () => _refreshFeed(postProvider, storyProvider),
        color: colors.primary,
        backgroundColor: colors.surface,
        displacement: MediaQuery.of(context).padding.top + 60,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Glassmorphic SliverAppBar
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: colors.surface.withOpacity(0.85),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      bottom: 8,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: Icon(Icons.menu_rounded, color: colors.text, size: 28),
                        ),
                        Text(
                          'الرئيسية',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: colors.text,
                          ),
                        ),
                        Row(
                          children: [
                            _buildCreateMenuButton(colors),
                            const SizedBox(width: 4),
                            _buildHeaderIconButton(Icons.search_rounded, colors, () => context.push('/search')),
                            _buildNotificationButton(colors, notificationProvider),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              toolbarHeight: 60,
            ),
            
            // Stories and Content
            if (postProvider.loading && postProvider.posts.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const PostShimmer(),
                  childCount: 4,
                ),
              )
            else if (postProvider.error != null && postProvider.posts.isEmpty)
              SliverFillRemaining(
                child: _buildErrorView(colors, postProvider),
              )
            else ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: StoriesBar(
                        onStoryPress: (story) {
                          context.push(
                            '/story-viewer',
                            extra: {'userWithStories': story, 'initialIndex': 0},
                          );
                        },
                        onAddStory: () => context.push('/create-story'),
                      ),
                    ),
                    if (feedPosts.isEmpty) ...[
                      const SizedBox(height: 40),
                      _buildEmptyView(colors),
                    ],
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      bool showSuggestions = postProvider.suggestedUsers.isNotEmpty && feedPosts.length >= 3;
                      
                      if (showSuggestions && index == 3) {
                        return _buildSuggestedUsers(postProvider.suggestedUsers, colors);
                      }
                      
                      int postIndex = index;
                      if (showSuggestions && index > 3) {
                        postIndex--;
                      }
                      
                      if (postIndex < feedPosts.length) {
                        final post = feedPosts[postIndex];
                        return PostCard(
                          key: ValueKey(post.id),
                          post: post,
                          onLike: (id) => postProvider.likePost(id),
                          onComment: (p) => context.push('/post-details', extra: p),
                        );
                      }
                      
                      if (postIndex >= feedPosts.length) {
                        return _isLoadingMore
                            ? _buildLoadMoreShimmer()
                            : _buildFeedFooter(colors, postProvider, feedPosts);
                      }
                      return null;
                    },
                    childCount: feedPosts.isEmpty
                        ? 0
                        : feedPosts.length +
                            1 + // For footer
                            (postProvider.suggestedUsers.isNotEmpty && feedPosts.length >= 3 ? 1 : 0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
    IconData icon,
    CustomColors colors,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.text, size: 26),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildNotificationButton(
    CustomColors colors,
    NotificationProvider notificationProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: colors.text,
              size: 26,
            ),
            if (notificationProvider.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => context.push('/notifications'),
        splashRadius: 24,
      ),
    );
  }

  Widget _buildErrorView(CustomColors colors, PostProvider postProvider) {
    return StateError(
      title: 'فشل في تحميل المنشورات',
      subtitle: postProvider.error ?? 'حدث خطأ غير متوقع',
      onRetry: () => postProvider.fetchPosts(),
    );
  }

  Widget _buildEmptyView(CustomColors colors) {
    return StateEmpty(
      icon: Icons.post_add_rounded,
      title: 'لا توجد منشورات بعد',
      subtitle: 'كن أول من ينشر شيئاً!',
      actionLabel: 'إنشاء منشور',
      onAction: () => context.push('/create-post'),
    );
  }

  Widget _buildSuggestedUsers(List<dynamic> users, CustomColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مقترح لك',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/search'),
                child: Text(
                  'عرض الكل',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/user-profile/${user['id']}'),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: user['photo'] != null
                            ? NetworkImage(ApiService.getImageUrl(user['photo'])!)
                            : null,
                        child: user['photo'] == null ? const Icon(Icons.person) : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '@${user['username']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () => Provider.of<PostProvider>(
                          context,
                          listen: false,
                        ).toggleFollow(user['id'].toString()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isUserFollowing(user)
                              ? colors.surface
                              : colors.primary,
                          foregroundColor: _isUserFollowing(user)
                              ? colors.text
                              : Theme.of(context).colorScheme.onPrimary,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: _isUserFollowing(user)
                              ? BorderSide(
                                  color: colors.border.withValues(alpha: 0.5),
                                )
                              : BorderSide.none,
                        ),
                        child: Text(
                          _isUserFollowing(user) ? 'متابع' : 'متابعة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isUserFollowing(user)
                                ? colors.text
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: colors.border.withValues(alpha: 0.5), thickness: 1),
      ],
    );
  }

  bool _isUserFollowing(Map<String, dynamic> user) {
    final value = user['isFollowing'];
    return value == true || value == 1;
  }

  Widget _buildFeedFooter(
    CustomColors colors,
    PostProvider postProvider,
    List<dynamic> feedPosts,
  ) {
    if (feedPosts.isEmpty) {
      return const SizedBox(height: 120);
    }

    if (postProvider.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                postProvider.loadMoreError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  if (_isLoadingMore) return;
                  setState(() => _isLoadingMore = true);
                  postProvider.loadMorePosts().whenComplete(() {
                    if (!mounted) return;
                    setState(() => _isLoadingMore = false);
                  });
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (!postProvider.hasMorePosts) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Center(
          child: Text(
            'وصلت لنهاية المنشورات',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 120);
  }

  Widget _buildLoadMoreShimmer() {
    return Column(
      children: List.generate(
        2,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: PostShimmer(),
        ),
      ),
    );
  }

  Widget _buildCreateMenuButton(CustomColors colors) {
    return PopupMenuButton<_CreateAction>(
      tooltip: 'إنشاء',
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border.withValues(alpha: 0.2)),
      ),
      onSelected: _onCreateActionSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CreateAction.post,
          child: _MenuRow(icon: FontAwesomeIcons.penToSquare, label: 'منشور', colors: colors),
        ),
        PopupMenuItem(
          value: _CreateAction.story,
          child: _MenuRow(icon: FontAwesomeIcons.images, label: 'قصة', colors: colors),
        ),
        PopupMenuItem(
          value: _CreateAction.reels,
          child: _MenuRow(
            icon: FontAwesomeIcons.clapperboard,
            label: 'مقطع ريلز',
            colors: colors,
          ),
        ),
        PopupMenuItem(
          value: _CreateAction.live,
          child: _MenuRow(
            icon: FontAwesomeIcons.towerBroadcast,
            label: 'بث مباشر',
            colors: colors,
          ),
        ),
        PopupMenuItem(
          value: _CreateAction.note,
          child: _MenuRow(icon: FontAwesomeIcons.noteSticky, label: 'ملاحظة', colors: colors),
        ),
        PopupMenuItem(
          value: _CreateAction.ai,
          child: _MenuRow(
            icon: FontAwesomeIcons.wandMagicSparkles,
            label: 'الذكاء الاصطناعي',
            colors: colors,
          ),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const FaIcon(FontAwesomeIcons.squarePlus, size: 21),
          color: colors.text,
          onPressed: null,
        ),
      ),
    );
  }

  void _onCreateActionSelected(_CreateAction action) {
    switch (action) {
      case _CreateAction.post:
        context.push('/create-post');
        break;
      case _CreateAction.story:
        context.push('/create-story');
        break;
      case _CreateAction.reels:
        context.push('/create-post', extra: {'mode': 'video'});
        break;
      case _CreateAction.live:
        context.push('/create-live');
        break;
      case _CreateAction.note:
        context.push('/create-note');
        break;
      case _CreateAction.ai:
        context.push('/ai-assistant');
        break;
    }
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final CustomColors colors;
  const _MenuRow({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, color: colors.text, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
