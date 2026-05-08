import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/music_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import '../../widgets/rich_bio_text.dart';
import '../../widgets/ui_state_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/music_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final String? heroTag;
  const ProfileScreen({super.key, this.heroTag});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {
    'posts': 0,
    'followers': 0,
    'following': 0,
    'likes': 0,
  };
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final userId = authProvider.user!['id'].toString();
      final result = await postProvider.getUserStats(userId);

      if (mounted && result['success']) {
        setState(() {
          _stats = result['data'];
          _loadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.user;

    final userPosts = postProvider.posts
        .where((p) => p.userId == user?['id'].toString())
        .toList();
    final savedPosts = postProvider.savedPosts;
    final repostedPosts = postProvider.posts
        .where((p) => p.repostId != null && p.userId == user?['id'].toString())
        .toList();
    final taggedPosts = postProvider.posts
        .where((p) => p.content.contains('@${user?['username'] ?? ''}'))
        .toList();
    final coverUrl = ApiService.getImageUrl(user?['coverPhoto']);
    final avatarUrl = ApiService.getImageUrl(user?['photo']);
    final followersCount =
        int.tryParse(_stats['followers']?.toString() ?? '0') ?? 0;
    final isCelebrity =
        followersCount >= 10000 || _stats['isCelebrity'] == true;

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: colors.background,
              elevation: 0,
              toolbarHeight: 60,
              centerTitle: true,
              leading: IconButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    await nav.maybePop();
                  } else {
                    // If we can't pop, go back to home tab
                    context.go('/');
                  }
                },
                icon: FaIcon(FontAwesomeIcons.chevronRight, color: colors.text, size: 18),
              ),
              title: innerBoxIsScrolled
                  ? Text(
                      user?['name'] ?? 'الملف الشخصي',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ).animate().fadeIn().scale()
                  : null,
              actions: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/settings');
                  },
                  icon: FaIcon(FontAwesomeIcons.ellipsisVertical, color: colors.text, size: 18),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  children: [
                    // Cover Photo
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        image: coverUrl != null
                            ? DecorationImage(
                                image: NetworkImage(coverUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: coverUrl == null
                            ? LinearGradient(
                                colors: colors.primaryGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                    ),
                    // Avatar
                    Positioned(
                      bottom: 0,
                      left: 24,
                      child: Hero(
                        tag: widget.heroTag ?? 'profile-avatar-${user?['id']}',
                        child: MusicAvatar(
                          avatarUrl: avatarUrl,
                          radius: 46,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user?['name'] ?? '',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colors.text,
                          ),
                        ),
                        if (isCelebrity) ...[
                          const SizedBox(width: 6),
                          FaIcon(
                            FontAwesomeIcons.solidCircleCheck,
                            color: Colors.blue.shade500,
                            size: 16,
                          ),
                        ],
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                    Text(
                      '@${user?['username'] ?? ''}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 20),
                    _loadingStats 
                      ? _buildShimmerStats(colors)
                      : Row(
                          children: [
                            _buildStat(_stats['posts'].toString(), 'منشور', colors),
                            const SizedBox(width: 32),
                            _buildStat(_stats['followers'].toString(), 'متابع', colors),
                            const SizedBox(width: 32),
                            _buildStat(_stats['following'].toString(), 'يتابع', colors),
                          ],
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    RichBioText(
                      text: user?['bio'] ?? 'أضف لمسة خاصة لبروفايلك من هنا ✨',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    if (user?['musicTrack'] != null) ...[
                      const SizedBox(height: 16),
                      _buildMusicButton(user, colors).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.push('/edit-profile');
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: colors.primaryGradient),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'تعديل الملف الشخصي',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildActionIcon(FontAwesomeIcons.qrcode, colors, () {
                          HapticFeedback.lightImpact();
                          _showQrCode(context, user, colors);
                        }),
                        const SizedBox(width: 12),
                        _buildActionIcon(FontAwesomeIcons.shareNodes, colors, () {
                          HapticFeedback.lightImpact();
                          Share.share('https://let_let.app/user/${user?['username']}');
                        }),
                      ],
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  indicatorColor: colors.primary,
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: colors.text,
                  unselectedLabelColor: colors.textSecondary.withOpacity(0.5),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(icon: FaIcon(FontAwesomeIcons.grip, size: 18)),
                    Tab(icon: FaIcon(FontAwesomeIcons.clapperboard, size: 18)),
                    Tab(icon: FaIcon(FontAwesomeIcons.bookmark, size: 18)),
                    Tab(icon: FaIcon(FontAwesomeIcons.userTag, size: 18)),
                  ],
                ),
                colors.background,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildGrid(userPosts, colors),
            _buildGrid(repostedPosts, colors),
            _buildGrid(savedPosts, colors),
            _buildGrid(taggedPosts, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerStats(CustomColors colors) {
    return Shimmer.fromColors(
      baseColor: colors.border.withOpacity(0.3),
      highlightColor: colors.border.withOpacity(0.1),
      child: Row(
        children: List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(right: 32),
          width: 60,
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        )),
      ),
    );
  }

  Widget _buildMusicButton(dynamic user, CustomColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Provider.of<MusicProvider>(context, listen: false).playMusic(
          user?['musicTrack'],
          user?['musicTitle'] ?? 'موسيقى الملف الشخصي',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.infoContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.info.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.music, color: colors.info, size: 14),
            const SizedBox(width: 10),
            Text(
              user?['musicTitle'] ?? 'استمع للموسيقى',
              style: TextStyle(color: colors.info, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, CustomColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.text)),
        Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary.withOpacity(0.7), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, CustomColors colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withOpacity(0.5)),
        ),
        child: Center(child: FaIcon(icon, color: colors.text, size: 18)),
      ),
    );
  }

  Widget _buildGrid(List<dynamic> posts, CustomColors colors) {
    if (posts.isEmpty) {
      return const StateEmpty(icon: FontAwesomeIcons.boxOpen, title: 'لا توجد منشورات حتى الآن');
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrl = post.mediaUrl != null ? ApiService.getImageUrl(post.mediaUrl) : null;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/post-details', extra: post);
          },
          child: Container(
            color: colors.surface,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: colors.border.withOpacity(0.3),
                      highlightColor: colors.border.withOpacity(0.1),
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colors.surface,
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.circleExclamation,
                          color: colors.textSecondary.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : Center(child: FaIcon(FontAwesomeIcons.fileLines, color: colors.border, size: 24)),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  void _showQrCode(BuildContext context, dynamic user, CustomColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            Text('رمز Lettuce الخاص بك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.text)),
            const SizedBox(height: 8),
            Text('@${user?['username'] ?? ''}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textSecondary)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: colors.primary.withOpacity(0.1), blurRadius: 40)],
              ),
              child: QrImageView(
                data: 'https://let_flutter.app/user/${user?['id']}',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }
  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
