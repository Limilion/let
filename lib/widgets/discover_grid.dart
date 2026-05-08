import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'package:go_router/go_router.dart';

class DiscoverGrid extends StatelessWidget {
  const DiscoverGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    
    // Mix of posts with media
    final mediaPosts = postProvider.posts.where((p) => p.mediaUrl != null).toList();
    
    if (mediaPosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'استكشف',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mediaPosts.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final post = mediaPosts[index];
              final isVideo = post.isVideo;
              
              return GestureDetector(
                onTap: () => context.push('/post-details', extra: post),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.network(
                        ApiService.getImageUrl(post.mediaUrl)!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: colors.surface,
                          child: Icon(Icons.broken_image, color: colors.textSecondary),
                        ),
                      ),
                      if (isVideo)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 24,
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likes}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
