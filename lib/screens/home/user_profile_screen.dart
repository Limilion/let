import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import '../../widgets/mini_music_player.dart';
import '../../widgets/rich_bio_text.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/post.dart';
import '../../widgets/ui_state_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? heroTag;
  const UserProfileScreen({super.key, required this.userId, this.heroTag});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profileData;
  List<Post> _userPosts = [];
  bool _loading = true;
  bool _followingLoading = false;
  String? _loadError;
  String? _activeMusicUrl;
  String? _activeMusicTitle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final result = await postProvider.getUserProfile(widget.userId);
    if (!mounted) return;

    if (result['success']) {
      final data = result['data'] as Map<String, dynamic>;
      final user = Map<String, dynamic>.from(
        data['user'] as Map<String, dynamic>,
      );
      final stats = (user['stats'] as Map<String, dynamic>?) ?? {};
      user['followersCount'] =
          user['followersCount'] ?? stats['followers'] ?? 0;
      user['followingCount'] =
          user['followingCount'] ?? stats['following'] ?? 0;

      setState(() {
        _profileData = user;
        _userPosts = ((data['posts'] as List?) ?? [])
            .map((json) => Post.fromJson(json))
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loadError = result['message']?.toString() ?? 'تعذر تحميل الملف الشخصي';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFollow() async {
    if (_profileData == null) return;

    final isFollowing =
        _profileData!['isFollowing'] == true ||
        _profileData!['isFollowing'] == 1;
    final followers =
        int.tryParse(_profileData!['followersCount'].toString()) ?? 0;

    // Truly Optimistic Update
    setState(() {
      _profileData!['isFollowing'] = !isFollowing;
      _profileData!['followersCount'] = isFollowing
          ? followers - 1
          : followers + 1;
    });

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final result = await postProvider.toggleFollow(widget.userId);

    if (mounted && !result['success']) {
      // Revert if failed
      setState(() {
        _profileData!['isFollowing'] = isFollowing;
        _profileData!['followersCount'] = followers;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'فشل في تنفيذ العملية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: StateLoading(message: 'جار تحميل الملف الشخصي...'),
      );
    }
    if (_profileData == null) {
      return Scaffold(
        body: Center(child: Text(_loadError ?? 'تعذر تحميل الملف الشخصي')),
      );
    }

    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isMe =
        authProvider.user?['id']?.toString() == widget.userId.toString();

    final mediaPosts = _userPosts.where((p) => p.mediaUrl != null).toList();
    final isFollowing =
        _profileData!['isFollowing'] == true ||
        _profileData!['isFollowing'] == 1;
    final isCelebrity =
        _profileData!['isCelebrity'] == true ||
        ((int.tryParse(_profileData!['followersCount']?.toString() ?? '0') ??
                0) >=
            10000);
    final coverUrl = ApiService.getImageUrl(_profileData!['coverPhoto']);
    final musicTrack = _profileData!['musicTrack']?.toString();

    return Scaffold(
      backgroundColor: colors.background,
      body: DefaultTabController(
        length: 2,
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 220,
                    floating: false,
                    pinned: true,
                    backgroundColor: colors.background,
                    elevation: 0,
                    collapsedHeight: 60,
                    toolbarHeight: 60,
                    automaticallyImplyLeading: false,
                    title: innerBoxIsScrolled
                        ? Text(
                            _profileData!['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          )
                        : null,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Stack(
                        children: [
                          // Cover area
                          // Background Gradient (instead of cover)
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.primary.withValues(alpha: 0.1),
                                  colors.background,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          // Horizontal Profile Info
                          Positioned(
                            top: 60,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Avatar
                                      Hero(
                                        tag: widget.heroTag ?? 'avatar-${widget.userId}',
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: colors.primaryGradient,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colors.primary.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            width: 84,
                                            height: 84,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: colors.background,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: _profileData!['photo'] != null
                                                ? CachedNetworkImage(
                                                    imageUrl: ApiService.getImageUrl(_profileData!['photo'])!,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Shimmer.fromColors(
                                                      baseColor: colors.border.withValues(alpha: 0.1),
                                                      highlightColor: colors.surface,
                                                      child: Container(color: Colors.white),
                                                    ),
                                                    errorWidget: (context, url, error) => Icon(
                                                      Icons.person_rounded,
                                                      color: colors.primary,
                                                      size: 40,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.person_rounded,
                                                    color: colors.primary,
                                                    size: 40,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  _profileData!['name'] ?? '',
                                                  style: TextStyle(
                                                    color: colors.text,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                if (isCelebrity) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.verified_rounded,
                                                    color: colors.text,
                                                    size: 18,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _buildCompactStat(
                                                  _profileData!['stats']?['posts']
                                                          ?.toString() ??
                                                      '0',
                                                  'منشور',
                                                  colors,
                                                ),
                                                GestureDetector(
                                                  onTap: () => context.push('/followers/${widget.userId}'),
                                                  child: _buildCompactStat(
                                                    _profileData!['followersCount']
                                                        .toString(),
                                                    'متابع',
                                                    colors,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => context.push('/following/${widget.userId}'),
                                                  child: _buildCompactStat(
                                                    _profileData!['followingCount']
                                                        .toString(),
                                                    'يتابع',
                                                    colors,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: isMe ? () => context.push('/liked-posts') : null,
                                                  child: _buildCompactStat(
                                                    _profileData!['stats']?['likes']?.toString() ?? '0',
                                                    'إعجاب',
                                                    colors,
                                                  ),
                                                ),
                                                _buildCompactStat(
                                                  _profileData!['stats']?['views']?.toString() ?? '0',
                                                  'مشاهدة',
                                                  colors,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),
                                // Bio Section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichBioText(
                                        text:
                                            _profileData!['bio'] ??
                                            'لا يوجد وصف متاح ✨',
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (musicTrack != null) ...[
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _activeMusicUrl = musicTrack;
                                              _activeMusicTitle =
                                                  _profileData!['musicTitle'] ??
                                                  'موسيقى الملف الشخصي';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colors.primary
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.music_note_rounded,
                                                  color: colors.primary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _profileData!['musicTitle'] ??
                                                      'استمع للموسيقى',
                                                  style: TextStyle(
                                                    color: colors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),
                                // Action Buttons
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: _handleToggleFollow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isFollowing
                                                ? colors.surface
                                                : colors.primary,
                                            foregroundColor: isFollowing
                                                ? colors.text
                                                : Theme.of(context).colorScheme.onPrimary,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: isFollowing
                                                  ? BorderSide(
                                                      color: colors.border,
                                                    )
                                                  : BorderSide.none,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          child: _followingLoading
                                              ? SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: isFollowing 
                                                              ? colors.primary 
                                                              : Theme.of(context).colorScheme.onPrimary,
                                                          ),
                                                )
                                              : Text(
                                                  isFollowing
                                                      ? 'متابَع'
                                                      : (_profileData!['isFollowedBy'] ==
                                                                true
                                                            ? 'رد المتابعة'
                                                            : 'متابعة'),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => context.push(
                                            '/chat',
                                            extra: _profileData,
                                          ),
                                          style:
                                              ElevatedButton.styleFrom(
                                                backgroundColor: colors.surface,
                                                foregroundColor: colors.text,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  side: BorderSide(
                                                    color: colors.border,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                          child: const Text(
                                            'رسالة',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildIconButton(
                                        Icons.share_rounded,
                                        () {},
                                        colors,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: colors.text,
                        indicatorWeight: 3,
                        labelColor: colors.text,
                        unselectedLabelColor: colors.textSecondary.withValues(
                          alpha: 0.75,
                        ),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.grid_on_outlined),
                            text: 'المنشورات',
                          ),
                          Tab(
                            icon: Icon(Icons.image_outlined),
                            text: 'الوسائط',
                          ),
                        ],
                      ),
                      colors.background,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _userPosts.isEmpty
                      ? _buildEmptyState('لا توجد منشورات بعد', colors)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: _userPosts.length,
                          itemBuilder: (context, index) => PostCard(
                            key: ValueKey(_userPosts[index].id),
                            post: _userPosts[index],
                            autoplayVideo: false,
                          ),
                        ),
                  mediaPosts.isEmpty
                      ? _buildEmptyState('لا توجد وسائط', colors)
                      : GridView.builder(
                          padding: const EdgeInsets.all(5),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                          itemCount: mediaPosts.length,
                          itemBuilder: (context, index) => CachedNetworkImage(
                            imageUrl: ApiService.getImageUrl(mediaPosts[index].mediaUrl)!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colors.surface,
                              child: Shimmer.fromColors(
                                baseColor: colors.border.withValues(alpha: 0.1),
                                highlightColor: colors.surface,
                                child: Container(color: Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colors.surface,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),

            // Music player overlay
            if (_activeMusicUrl != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: MiniMusicPlayer(
                  musicUrl: _activeMusicUrl!,
                  title: _activeMusicTitle!,
                  onStop: () => setState(() => _activeMusicUrl = null),
                ),
              ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: _buildHeaderAction(
                Icons.arrow_back_rounded,
                () {
                  HapticFeedback.lightImpact();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/main');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String value, String label, CustomColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onTap,
    CustomColors colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.text, size: 20),
        onPressed: onTap,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildEmptyState(String message, CustomColors colors) {
    return StateEmpty(icon: Icons.grid_view_rounded, title: message);
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
