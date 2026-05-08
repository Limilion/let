import 'package:flutter_test/flutter_test.dart';
import 'package:let_flutter/models/post.dart';

void main() {
  test('Post.fromJson reads isSaved from payload', () {
    final post = Post.fromJson({
      'id': 1,
      'user_id': 2,
      'name': 'A',
      'content': 'hello',
      'media_type': 'text',
      'likes': 0,
      'comments_count': 0,
      'views_count': 0,
      'created_at': '2026-01-01T00:00:00.000Z',
      'time': 'الآن',
      'isSaved': true,
    });

    expect(post.isSaved, isTrue);
  });
}
