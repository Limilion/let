class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String content;
  final String? mediaUrl;
  final List<String> mediaUrls;
  final String mediaType;
  final int likes;
  final int commentsCount;
  final int viewsCount;
  final double engagementScore;
  final String createdAt;
  final String time;
  final bool isLiked;
  final bool isSaved;
  final String? musicTitle;
  final String? filterType;
  final String? repostId;
  final bool isCelebrity;
  
  bool get isVideo => (mediaType.toLowerCase().contains('video')) || 
                      (mediaUrl?.toLowerCase().endsWith('.mp4') ?? false) ||
                      (mediaUrl?.toLowerCase().endsWith('.mov') ?? false) ||
                      (mediaUrl?.toLowerCase().endsWith('.avi') ?? false);
  
  bool get isImage => mediaType.toLowerCase().contains('image');

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.content,
    this.mediaUrl,
    this.mediaUrls = const [],
    required this.mediaType,
    required this.likes,
    required this.commentsCount,
    this.viewsCount = 0,
    this.engagementScore = 0.0,
    required this.createdAt,
    required this.time,
    this.isLiked = false,
    this.isSaved = false,
    this.musicTitle,
    this.filterType,
    this.repostId,
    this.isCelebrity = false,
  });

  factory Post.fromJson(Map<String, dynamic> json, {bool isSaved = false}) {
    final bool savedFromPayload =
        json['isSaved'] == true || json['is_saved'] == true || json['isSaved'] == 1;
    return Post(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['name'] ?? '',
      userPhoto: json['photo'],
      content: json['content'] ?? '',
      mediaUrl: json['image_url'],
      mediaUrls: (json['media_urls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['image_url'] != null ? [json['image_url'].toString()] : []),
      mediaType: json['media_type'] ?? 'text',
      likes: int.tryParse(json['likes'].toString()) ?? 0,
      commentsCount: int.tryParse(json['comments_count'].toString()) ?? 0,
      viewsCount: int.tryParse(json['views_count'].toString()) ?? 0,
      engagementScore: double.tryParse(json['engagement_score'].toString()) ?? 0.0,
      createdAt: json['created_at'] ?? '',
      time: json['time'] ?? 'الآن',
      isLiked: json['isLiked'] == true || json['isLiked'] == 1,
      isSaved: savedFromPayload || isSaved,
      musicTitle: json['music_title'],
      filterType: json['filter_type'],
      repostId: json['repost_id']?.toString(),
      isCelebrity: json['isCelebrity'] == true || json['is_celebrity'] == true,
    );
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    String? content,
    String? mediaUrl,
    List<String>? mediaUrls,
    String? mediaType,
    int? likes,
    int? commentsCount,
    int? viewsCount,
    double? engagementScore,
    String? createdAt,
    String? time,
    bool? isLiked,
    bool? isSaved,
    String? musicTitle,
    String? filterType,
    String? repostId,
    bool? isCelebrity,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      engagementScore: engagementScore ?? this.engagementScore,
      createdAt: createdAt ?? this.createdAt,
      time: time ?? this.time,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      musicTitle: musicTitle ?? this.musicTitle,
      filterType: filterType ?? this.filterType,
      repostId: repostId ?? this.repostId,
      isCelebrity: isCelebrity ?? this.isCelebrity,
    );
  }
}
