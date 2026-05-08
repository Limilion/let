import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/ui_state_widgets.dart';
import '../../widgets/discover_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      postProvider.fetchSuggestions();
      postProvider.fetchTrendingTags();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2) {
        ApiService.trackEvent(
          'search_query',
          source: 'search_screen',
          metadata: {'query': query},
        );
        Provider.of<PostProvider>(
          context,
          listen: false,
        ).searchUsers(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final query = _searchController.text;
    final showResults = query.length >= 2;

    // Use backend filtered posts
    final filteredPosts = postProvider.foundPosts;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/main', extra: 0);
            }
          },
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            style: TextStyle(color: colors.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث عن أشخاص أو منشورات...',
              hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                color: colors.textSecondary,
                size: 20,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        bottom: showResults
            ? TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                labelColor: colors.primary,
                unselectedLabelColor: colors.textSecondary,
                tabs: [
                  Tab(text: 'المنشورات (${filteredPosts.length})'),
                  Tab(text: 'الأشخاص (${postProvider.foundUsers.length})'),
                ],
              )
            : null,
      ),
      body: showResults
          ? TabBarView(
              controller: _tabController,
              children: [
                // Posts Results
                _buildPostsResults(
                  filteredPosts,
                  colors,
                  postProvider.searchLoading,
                  postProvider.searchError,
                ),
                // People Results
                _buildPeopleResults(
                  postProvider.foundUsers,
                  colors,
                  authProvider.user!['id'].toString(),
                ),
              ],
            )
          : _buildSuggestions(postProvider.suggestedUsers, colors, postProvider.trendingTags),
    );
  }

  Widget _buildPostsResults(
    List<dynamic> posts,
    dynamic colors,
    bool isSearching,
    String? error,
  ) {
    if (isSearching) {
      return const StateLoading(message: 'جار البحث...');
    }
    if (error != null) {
      return StateError(
        title: 'تعذر إكمال البحث',
        subtitle: error,
        onRetry: () => Provider.of<PostProvider>(context, listen: false).searchUsers(_searchController.text),
      );
    }
    if (posts.isEmpty) {
      return _buildEmptyState(
        'لا توجد منشورات تطابق بحثك',
        Icons.search_off,
        colors,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        120,
      ), // Added bottom padding for floating navbar
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(
        key: ValueKey(posts[index].id),
        post: posts[index],
        onComment: (p) => context.push('/post-details', extra: p),
      ),
    );
  }

  Widget _buildPeopleResults(
    List<dynamic> users,
    dynamic colors,
    String currentUserId,
  ) {
    if (Provider.of<PostProvider>(context).searchLoading) {
      return const StateLoading(message: 'جار البحث...');
    }
    final searchError = Provider.of<PostProvider>(context).searchError;
    if (searchError != null) {
      return StateError(
        title: 'تعذر إكمال البحث',
        subtitle: searchError,
        onRetry: () => Provider.of<PostProvider>(context, listen: false).searchUsers(_searchController.text),
      );
    }
    if (users.isEmpty) {
      return _buildEmptyState(
        'لم نجد أحداً بهذا الاسم',
        Icons.person_off_outlined,
        colors,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        120,
      ), // Added bottom padding for floating navbar
      itemCount: users.length,
      itemBuilder: (context, index) =>
          _buildUserCard(users[index], colors, currentUserId),
    );
  }

  Widget _buildSuggestions(List<dynamic> suggestions, dynamic colors, List<dynamic> trendingTags) {
    if (suggestions.isEmpty && trendingTags.isEmpty) {
      return const StateLoading(message: 'جار تحميل المقترحات...');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        if (trendingTags.isNotEmpty) ...[
          Text(
            'الأوسمة الرائجة',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ).marginBottom,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingTags.map((tagData) => _buildTagChip(tagData, colors)).toList(),
          ).marginBottom,
          const Divider(height: 32).marginBottom,
        ],
        if (suggestions.isNotEmpty) ...[
          Text(
            'مقترح لك',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ).marginBottom,
          ...suggestions.map((user) => _buildUserCard(user, colors, '')).toList(),
          const Divider(height: 32).marginBottom,
          const DiscoverGrid(),
        ],
      ],
    );
  }

  Widget _buildTagChip(dynamic tagData, dynamic colors) {
    return ActionChip(
      label: Text(
        '#${tagData['tag']}',
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
      onPressed: () {
        _searchController.text = '#${tagData['tag']}';
        _onSearchChanged('#${tagData['tag']}');
        setState(() {});
      },
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    dynamic colors,
    String currentUserId,
  ) {
    final String userId = user['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final heroTag = 'search-avatar-$userId';
              context.push('/user-profile/$userId', extra: heroTag);
            },
            child: Hero(
              tag: 'search-avatar-$userId',
              child: CircleAvatar(
                radius: 25,
                backgroundColor: colors.background,
                child: ClipOval(
                  child: user['photo'] != null
                      ? CachedNetworkImage(
                          imageUrl: ApiService.getImageUrl(user['photo'])!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          errorWidget: (context, url, error) => Icon(
                            Icons.person_rounded,
                            color: colors.primary,
                          ),
                        )
                      : Icon(Icons.person_rounded, color: colors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
            onTap: () {
              final heroTag = 'search-avatar-$userId';
              context.push('/user-profile/$userId', extra: heroTag);
            },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? '',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '@${user['username'] ?? ''}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (userId != currentUserId)
            StatefulBuilder(
              builder: (context, setState) {
                final bool isFollowing =
                    user['isFollowing'] == true || user['isFollowing'] == 1;
                return ElevatedButton(
                  onPressed: () async {
                    final previous = isFollowing;
                    setState(() {
                      user['isFollowing'] = !isFollowing;
                    });
                    final result = await Provider.of<PostProvider>(
                      context,
                      listen: false,
                    ).toggleFollow(userId);
                    if (result['success'] != true && context.mounted) {
                      setState(() => user['isFollowing'] = previous);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['error']?.toString() ??
                                'تعذرت المتابعة الآن',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? Colors.transparent
                        : colors.primary,
                    foregroundColor: isFollowing
                        ? colors.primary
                        : Colors.white,
                    elevation: 0,
                    side: isFollowing
                        ? BorderSide(color: colors.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    isFollowing ? 'متابع' : 'متابعة',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Text {
  Text copyWith({TextStyle? style}) => Text(data!, style: style ?? this.style);
}

// Fixed spacing issue in ListView children
extension on Widget {
  Widget get marginBottom =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: this);
}
