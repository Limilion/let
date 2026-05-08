import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class UserStory {
  final String userId;
  final String userName;
  final String? userPhoto;
  final List<StoryItem> stories;

  UserStory({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.stories,
  });

  factory UserStory.fromJson(Map<String, dynamic> json) {
    return UserStory(
      userId: json['user_id'].toString(),
      userName: json['name'] ?? '',
      userPhoto: json['photo'],
      stories: (json['stories'] as List).map((s) => StoryItem.fromJson(s)).toList(),
    );
  }
}

class StoryItem {
  final String id;
  final String url;
  final String type;
  final bool isLiked;
  final int likes;
  final int? views;
  final bool isViewed;

  StoryItem({
    required this.id,
    required this.url,
    required this.type,
    this.isLiked = false,
    this.likes = 0,
    this.views = 0,
    this.isViewed = false,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'].toString(),
      url: json['media_url'] ?? '',
      type: json['media_type'] ?? 'image',
      isLiked: json['isLiked'] == true || json['isLiked'] == 1,
      likes: int.tryParse(json['likes'].toString()) ?? 0,
      views: int.tryParse(json['views']?.toString() ?? json['views_count']?.toString() ?? '0'),
    );
  }
}

class StoryProvider with ChangeNotifier {
  List<UserStory> _stories = [];
  bool _loading = false;
  AuthProvider _authProvider;

  StoryProvider(this._authProvider) {
    if (_authProvider.isAuthenticated) {
      fetchStories();
    }
  }

  void updateAuth(AuthProvider auth) {
    final wasAuthenticated = _authProvider.isAuthenticated;
    final oldUserId = wasAuthenticated ? (_authProvider.user?['id']?.toString()) : null;
    
    _authProvider = auth;
    
    final isNowAuthenticated = _authProvider.isAuthenticated;
    final newUserId = isNowAuthenticated ? (_authProvider.user?['id']?.toString()) : null;

    if (isNowAuthenticated && (!wasAuthenticated || oldUserId != newUserId || _stories.isEmpty)) {
      fetchStories();
    } else if (!isNowAuthenticated && wasAuthenticated) {
      _stories = [];
      notifyListeners();
    }
  }

  List<UserStory> get stories => _stories;
  bool get loading => _loading;

  Future<void> fetchStories() async {
    if (!_authProvider.isAuthenticated) return;
    _loading = true;
    notifyListeners();

    try {
      final userId = _authProvider.user!['id'];
      final result = await ApiService.get('get_stories?user_id=$userId');
      
      if (result['success']) {
        _stories = (result['data'] as List).map((json) => UserStory.fromJson(json)).toList();
      }
    } catch (error) {
      print('FetchStories Error: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addStory(File mediaFile) async {
    if (!_authProvider.isAuthenticated) return {'success': false, 'error': 'يجب تسجيل الدخول'};
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('add_story', {
        'user_id': userId,
        'media_type': RegExp(r'\.(mp4|mov|avi|mkv|3gp|flv|webm)$', caseSensitive: false).hasMatch(mediaFile.path) ? 'video' : 'image',
      }, file: mediaFile);

      if (result['success']) {
        fetchStories();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (error) {
      return {'success': false, 'error': 'حدث خطأ أثناء إضافة القصة'};
    }
  }

  Future<Map<String, dynamic>> toggleStoryLike(String storyId) async {
    if (!_authProvider.isAuthenticated) return {'success': false};
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('toggle_story_like', {
        'user_id': userId,
        'story_id': storyId,
      });
      return result;
    } catch (e) {
      return {'success': false};
    }
  }

  Future<void> markStoryViewed(String storyId) async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user!['id'];

    try {
      await ApiService.post('mark_story_viewed', {
        'user_id': userId,
        'story_id': storyId,
      });
    } catch (e) {
      debugPrint('Error marking story viewed: $e');
    }
  }
}
