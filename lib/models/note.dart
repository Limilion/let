class Note {
  final int id;
  final int userId;
  final String content;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? userName;
  final String? userPhoto;
  final String? username;

  Note({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    this.userName,
    this.userPhoto,
    this.username,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Note(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      userName: user?['name'],
      userPhoto: user?['photo'],
      username: user?['username'],
    );
  }
}
