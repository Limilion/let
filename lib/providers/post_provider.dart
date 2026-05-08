import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class PostProvider with ChangeNotifier {
  static const int _postsPageSize = 20;
  static const Duration _feedCacheTtl = Duration(minutes: 2);
  static const Duration _discoveryCacheTtl = Duration(minutes: 5);
  List<Post> _posts = [];
  List<Post> _savedPosts = [];
  List<Post> _videoPosts = [];
  List<Map<String, dynamic>> _suggestedUsers = [];
  List<Map<String, dynamic>> _foundUsers = [];
  List<Post> _foundPosts = [];
  bool _searchLoading = false;
  String? _searchError;
  int _unreadNotifications = 0;
  List<Map<String, dynamic>> _trendingTags = [];
  bool _loading = false;
  bool _hasMorePosts = true;
  String? _nextCursor;
  String? _error;
  String? _loadMoreError;
  AuthProvider _authProvider;
  final Set<String> _viewTrackedPostIds = <String>{};
  DateTime? _feedCachedAt;
  DateTime? _suggestionsCachedAt;
  DateTime? _trendingCachedAt;

  bool _isFeedPaused = false;
  
  PostProvider(this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
    if (_authProvider.isAuthenticated) {
      fetchPosts();
      fetchSavedPosts();
    }
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated && _posts.isEmpty && !_loading) {
      fetchPosts();
      fetchSavedPosts();
    }
  }

  void updateAuth(AuthProvider auth) {
    if (_authProvider == auth) return;
    _authProvider.removeListener(_onAuthChanged);
    _authProvider = auth;
    _authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  List<Post> get posts => _posts;
  List<Post> get savedPosts => _savedPosts;
  List<Post> get videoPosts => _videoPosts;
  List<Map<String, dynamic>> get suggestedUsers => _suggestedUsers;
  List<Map<String, dynamic>> get foundUsers => _foundUsers;
  List<Post> get foundPosts => _foundPosts;
  bool get searchLoading => _searchLoading;
  String? get searchError => _searchError;
  List<Map<String, dynamic>> get trendingTags => _trendingTags;
  bool get loading => _loading;
  bool get hasMorePosts => _hasMorePosts;
  String? get error => _error;
  String? get loadMoreError => _loadMoreError;

  bool get isFeedPaused => _isFeedPaused;

  void setFeedPaused(bool value) {
    if (_isFeedPaused == value) return;
    _isFeedPaused = value;
    notifyListeners();
  }

  Future<void> fetchPosts({bool isRefresh = true}) async {
    if (!_authProvider.isAuthenticated) return;
    final shouldUseFeedCache =
        isRefresh && _feedCachedAt != null && DateTime.now().difference(_feedCachedAt!) < _feedCacheTtl;

    if (shouldUseFeedCache && _posts.isNotEmpty) {
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _loading = true;
      notifyListeners();
    }

    final query = isRefresh
        ? 'get_posts?limit=$_postsPageSize'
        : 'get_posts?limit=$_postsPageSize&cursor=${Uri.encodeComponent(_nextCursor ?? '')}';

    try {
      final result = await ApiService.get(query);

      if (result['success']) {
        final payload = Map<String, dynamic>.from(result['data'] ?? const {});
        final List<dynamic> items = List<dynamic>.from(payload['items'] ?? const []);
        final bool hasMore = payload['hasMore'] == true;
        final String? nextCursor = payload['nextCursor']?.toString();

        final List<Post> newPosts = items.map((json) {
          return Post.fromJson(Map<String, dynamic>.from(json));
        }).toList();
        _hasMorePosts = hasMore;
        _nextCursor = nextCursor;
        _loadMoreError = null;

        if (isRefresh) {
          _posts = newPosts;
          _feedCachedAt = DateTime.now();
        } else {
          // Avoid duplicates
          final existingIds = _posts.map((p) => p.id).toSet();
          _posts.addAll(newPosts.where((p) => !existingIds.contains(p.id)));
        }
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'فشل في تحميل المنشورات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (!_authProvider.isAuthenticated || _loading || !_hasMorePosts || _nextCursor == null) return;

    _loading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(
        'get_posts?limit=$_postsPageSize&cursor=${Uri.encodeComponent(_nextCursor!)}',
      );

      if (result['success']) {
        final payload = Map<String, dynamic>.from(result['data'] ?? const {});
        final List<dynamic> items = List<dynamic>.from(payload['items'] ?? const []);
        final bool hasMore = payload['hasMore'] == true;
        final String? nextCursor = payload['nextCursor']?.toString();

        final List<Post> newPosts = items.map((json) {
          return Post.fromJson(Map<String, dynamic>.from(json));
        }).toList();
        _hasMorePosts = hasMore;
        _nextCursor = nextCursor;
        _loadMoreError = null;

        // Avoid duplicates
        final existingIds = _posts.map((p) => p.id).toSet();
        final uniqueNewPosts = newPosts
            .where((p) => !existingIds.contains(p.id))
            .toList();
        _posts.addAll(uniqueNewPosts);
        if (uniqueNewPosts.isEmpty) {
          _hasMorePosts = false;
          _nextCursor = null;
        }
        _error = null;
      } else {
        _loadMoreError = result['message'] ?? 'فشل في تحميل المزيد من المنشورات';
      }
    } catch (e) {
      _loadMoreError = 'فشل في تحميل المزيد من المنشورات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVideos({bool isRefresh = true}) async {
    if (!_authProvider.isAuthenticated) return;

    if (isRefresh) {
      _loading = true;
      notifyListeners();
    }

    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get('get_videos?user_id=$userId');

      if (result['success']) {
        final List<Post> newVideos = (result['data'] as List).map((json) {
          return Post.fromJson(json);
        }).toList();

        if (isRefresh) {
          _videoPosts = newVideos;
        } else {
          _videoPosts.addAll(newVideos);
        }
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'فشل في تحميل الفيديوهات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSavedPosts() async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_saved_posts?user_id=$userId',
      );
      if (result['success']) {
        _savedPosts = (result['data'] as List)
            .map((json) => Post.fromJson(json, isSaved: true))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching saved posts: $e');
    }
  }



  void _updatePostInAllLists(String postId, Post Function(Post) updateFn) {
    bool updated = false;
    
    // Update main feed
    final mainIndex = _posts.indexWhere((p) => p.id == postId);
    if (mainIndex != -1) {
      _posts[mainIndex] = updateFn(_posts[mainIndex]);
      updated = true;
    }
    
    // Update video feed
    final videoIndex = _videoPosts.indexWhere((p) => p.id == postId);
    if (videoIndex != -1) {
      _videoPosts[videoIndex] = updateFn(_videoPosts[videoIndex]);
      updated = true;
    }
    
    // Update saved posts
    final savedIndex = _savedPosts.indexWhere((p) => p.id == postId);
    if (savedIndex != -1) {
      _savedPosts[savedIndex] = updateFn(_savedPosts[savedIndex]);
      updated = true;
    }
    
    // Update search results
    final foundIndex = _foundPosts.indexWhere((p) => p.id == postId);
    if (foundIndex != -1) {
      _foundPosts[foundIndex] = updateFn(_foundPosts[foundIndex]);
      updated = true;
    }

    if (updated) notifyListeners();
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      // Optimistic update using copyWith and helper
      _updatePostInAllLists(postId, (post) {
        final newIsLiked = !post.isLiked;
        return post.copyWith(
          isLiked: newIsLiked,
          likes: newIsLiked ? post.likes + 1 : post.likes - 1,
        );
      });

      final result = await ApiService.post('toggle_like', {
        'user_id': userId,
        'post_id': postId,
      });
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل التفاعل'};
    }
  }

  Future<Map<String, dynamic>> toggleSavePost(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false};
    }
    final userId = _authProvider.user!['id'];

    try {
      // Optimistic update
      _updatePostInAllLists(postId, (post) {
        return post.copyWith(isSaved: !post.isSaved);
      });

      final result = await ApiService.post('toggle_save', {
        'user_id': userId,
        'post_id': postId,
      });
      if (result['success']) {
        fetchSavedPosts();
      }
      return result;
    } catch (e) {
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> deletePost(String postId) async {
    if (!_authProvider.isAuthenticated)
      return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('delete_post', {
        'user_id': userId,
        'post_id': postId,
      });

      if (result['success']) {
        _posts.removeWhere((p) => p.id == postId);
        _videoPosts.removeWhere((p) => p.id == postId);
        _savedPosts.removeWhere((p) => p.id == postId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'فشل حذف المنشور'};
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final result = await ApiService.get('get_user_stats?user_id=$userId');
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في جلب الإحصائيات'};
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String profileId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false};
    }
    final currentUserId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_user_profile?profile_id=$profileId&current_user_id=$currentUserId',
      );
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في جلب ملف الشخصي'};
    }
  }

  Future<Map<String, dynamic>> toggleFollow(String profileId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false};
    }
    final currentUserId = _authProvider.user!['id'];

    bool? previousSuggestionFollowState;
    bool? previousFoundUserFollowState;

    // Optimistic update for suggestions
    final sugIndex = _suggestedUsers.indexWhere((u) => u['id'].toString() == profileId);
    if (sugIndex != -1) {
      final isFollowing = _suggestedUsers[sugIndex]['isFollowing'] == true || _suggestedUsers[sugIndex]['isFollowing'] == 1;
      previousSuggestionFollowState = isFollowing;
      _suggestedUsers[sugIndex]['isFollowing'] = !isFollowing;
      notifyListeners();
    }

    // Optimistic update for search results
    final foundIndex = _foundUsers.indexWhere((u) => u['id'].toString() == profileId);
    if (foundIndex != -1) {
      final isFollowing = _foundUsers[foundIndex]['isFollowing'] == true || _foundUsers[foundIndex]['isFollowing'] == 1;
      previousFoundUserFollowState = isFollowing;
      _foundUsers[foundIndex]['isFollowing'] = !isFollowing;
      notifyListeners();
    }

    try {
      final result = await ApiService.post('toggle_follow', {
        'user_id': currentUserId,
        'profile_id': profileId,
      });
      if (result['success'] != true) {
        if (sugIndex != -1 && previousSuggestionFollowState != null) {
          _suggestedUsers[sugIndex]['isFollowing'] = previousSuggestionFollowState;
        }
        if (foundIndex != -1 && previousFoundUserFollowState != null) {
          _foundUsers[foundIndex]['isFollowing'] = previousFoundUserFollowState;
        }
        notifyListeners();
      }
      return result;
    } catch (e) {
      if (sugIndex != -1 && previousSuggestionFollowState != null) {
        _suggestedUsers[sugIndex]['isFollowing'] = previousSuggestionFollowState;
      }
      if (foundIndex != -1 && previousFoundUserFollowState != null) {
        _foundUsers[foundIndex]['isFollowing'] = previousFoundUserFollowState;
      }
      notifyListeners();
      return {'success': false, 'error': 'فشل في تنفيذ العملية'};
    }
  }

  Future<void> fetchSuggestions() async {
    if (!_authProvider.isAuthenticated) return;
    final shouldUseCache =
        _suggestionsCachedAt != null &&
        DateTime.now().difference(_suggestionsCachedAt!) < _discoveryCacheTtl &&
        _suggestedUsers.isNotEmpty;
    if (shouldUseCache) {
      notifyListeners();
      return;
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_suggested_users?current_user_id=$userId',
      );
      if (result['success']) {
        _suggestedUsers = List<Map<String, dynamic>>.from(result['data']);
        _suggestionsCachedAt = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (!_authProvider.isAuthenticated || query.isEmpty) return;
    _searchLoading = true;
    _searchError = null;
    notifyListeners();

    try {
      final userResult = await ApiService.get('search_users?q=$query');
      if (userResult['success']) {
        _foundUsers = List<Map<String, dynamic>>.from(userResult['data']);
      }
      
      final postResult = await ApiService.get('search_posts?q=$query');
      if (postResult['success']) {
        _foundPosts = (postResult['data'] as List).map((json) => Post.fromJson(json)).toList();
      }
      
    } catch (e) {
      _searchError = 'تعذر إكمال البحث الآن';
      debugPrint('Error searching: $e');
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrendingTags() async {
    final shouldUseCache =
        _trendingCachedAt != null &&
        DateTime.now().difference(_trendingCachedAt!) < _discoveryCacheTtl &&
        _trendingTags.isNotEmpty;
    if (shouldUseCache) {
      notifyListeners();
      return;
    }
    try {
      final result = await ApiService.get('get_trending_tags');
      if (result['success']) {
        _trendingTags = List<Map<String, dynamic>>.from(result['data']);
        _trendingCachedAt = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching trending tags: $e');
    }
  }

  Future<Map<String, dynamic>> fetchComments(String postId) async {
    try {
      final userId = _authProvider.user?['id'];
      final result = await ApiService.get(
        'get_comments?post_id=$postId${userId != null ? '&user_id=$userId' : ''}',
      );
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في جلب التعليقات'};
    }
  }

  Future<Map<String, dynamic>> fetchPostById(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final existing = _posts.cast<Post?>().firstWhere(
      (p) => p?.id == postId,
      orElse: () => null,
    );
    if (existing != null) {
      return {'success': true, 'data': existing};
    }
    try {
      final userId = _authProvider.user!['id'];
      final result = await ApiService.get('get_post?user_id=$userId&post_id=$postId');
      if (result['success']) {
        final post = Post.fromJson(result['data']);
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index == -1) {
          _posts.insert(0, post);
        } else {
          _posts[index] = post;
        }
        notifyListeners();
        return {'success': true, 'data': post};
      }
      return {'success': false, 'error': result['message'] ?? 'تعذر جلب المنشور'};
    } catch (e) {
      return {'success': false, 'error': 'تعذر جلب المنشور'};
    }
  }

  Future<Map<String, dynamic>> addComment(String postId, String comment) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('add_comment', {
        'post_id': postId,
        'user_id': userId,
        'comment': comment,
      });

      if (result['success']) {
        // Update local comment count for the post
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = Post(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userPhoto: post.userPhoto,
            content: post.content,
            mediaUrl: post.mediaUrl,
            mediaType: post.mediaType,
            likes: post.likes,
            commentsCount: post.commentsCount + 1,
            viewsCount: post.viewsCount,
            engagementScore: post.engagementScore,
            createdAt: post.createdAt,
            time: post.time,
            isLiked: post.isLiked,
            isSaved: post.isSaved,
          );
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل إضافة التعليق'};
    }
  }

  Future<Map<String, dynamic>> deleteComment(String commentId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    try {
      final result = await ApiService.post('delete_comment', {
        'comment_id': commentId,
      });
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل حذف التعليق'};
    }
  }

  Future<Map<String, dynamic>> addReply(
    String postId,
    String parentCommentId,
    String comment,
  ) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];
    try {
      return await ApiService.post('add_comment', {
        'post_id': postId,
        'user_id': userId,
        'comment': comment,
        'parent_id': parentCommentId,
      });
    } catch (e) {
      return {'success': false, 'error': 'فشل إضافة الرد'};
    }
  }

  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];
    try {
      return await ApiService.post('toggle_comment_like', {
        'comment_id': commentId,
        'user_id': userId,
      });
    } catch (e) {
      return {'success': false, 'error': 'فشل التفاعل مع التعليق'};
    }
  }

  Future<Map<String, dynamic>> addPost(
    String content,
    File? media,
    String privacy, {
    String? mediaUrl,
  }) async {
    if (!_authProvider.isAuthenticated)
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    final userId = _authProvider.user!['id'];

    try {
      final Map<String, dynamic> body = {
        'user_id': userId,
        'content': content,
        'privacy': privacy,
        'media_type': media != null
            ? (RegExp(r'\.(mp4|mov|avi|mkv|3gp|flv|webm)$', caseSensitive: false).hasMatch(media.path) ? 'video' : 'image')
            : (mediaUrl != null ? 'image' : 'text'),
      };
      if (mediaUrl != null) body['media_url'] = mediaUrl;

      final result = await ApiService.post('create_post', body, file: media);

      if (result['success']) {
        // Add the new post to the top of the feed
        final newPost = Post.fromJson(result['data']);
        _posts.insert(0, newPost);
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل نشر المنشور'};
    }
  }

  Future<Map<String, dynamic>> addPostMultiImage(
    String content,
    List<File> images,
    String privacy,
  ) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.postMultipart('create_post_multi', {
        'user_id': userId,
        'content': content,
        'privacy': privacy,
        'media_type': 'image',
      }, files: images);

      if (result['success']) {
        final newPost = Post.fromJson(result['data']);
        _posts.insert(0, newPost);
        notifyListeners();
        return {'success': true};
      }
      return {'success': false, 'error': result['message'] ?? 'فشل نشر المنشور'};
    } catch (e) {
      return {'success': false, 'error': 'فشل نشر المنشور'};
    }
  }

  Future<Map<String, dynamic>> repostPost(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('repost_post', {
        'user_id': userId,
        'post_id': postId,
      });

      if (result['success']) {
        await fetchPosts(); // Refresh feed to show repost
        return {'success': true};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل إعادة نشر المنشور'};
    }
  }

  Future<void> markPostViewed(String postId) async {
    if (!_authProvider.isAuthenticated || _viewTrackedPostIds.contains(postId)) {
      return;
    }

    _viewTrackedPostIds.add(postId);
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('mark_view', {
        'user_id': userId,
        'post_id': postId,
      });

      if (result['success']) {
        final viewsCount = int.tryParse(result['views_count'].toString()) ?? 0;
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          _posts[postIndex] = Post(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userPhoto: post.userPhoto,
            content: post.content,
            mediaUrl: post.mediaUrl,
            mediaType: post.mediaType,
            likes: post.likes,
            commentsCount: post.commentsCount,
            viewsCount: viewsCount,
            engagementScore: post.engagementScore,
            createdAt: post.createdAt,
            time: post.time,
            isLiked: post.isLiked,
            isSaved: post.isSaved,
            musicTitle: post.musicTitle,
            filterType: post.filterType,
            repostId: post.repostId,
          );
          notifyListeners();
        }
      } else {
        _viewTrackedPostIds.remove(postId);
      }
    } catch (_) {
      _viewTrackedPostIds.remove(postId);
    }
  }
}
