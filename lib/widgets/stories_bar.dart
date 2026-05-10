import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class StoriesBar extends StatelessWidget {
  final Function(UserStory) onStoryPress;
  final VoidCallback onAddStory;

  const StoriesBar({
    super.key,
    required this.onStoryPress,
    required this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);
    final user = authProvider.user;
    final stories = storyProvider.stories;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.transparent, // Flow naturally with the background
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 0, right: 10),
            child: Row(
              children: [
                // My Story / Add Story (always on left edge)
                _buildStoryItem(
                  onTap: onAddStory,
                  userName: 'قصتي',
                  imageUrl: ApiService.getImageUrl(user?['photo']),
                  isAdd: true,
                  colors: colors,
                  context: context,
                ),
                const SizedBox(width: 10),
                // Dynamic Stories
                ...stories.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildStoryItem(
                      onTap: () => onStoryPress(item),
                      userName: item.userName,
                      imageUrl: ApiService.getImageUrl(item.userPhoto),
                      colors: colors,
                      context: context,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem({
    required VoidCallback onTap,
    required String userName,
    String? imageUrl,
    bool isAdd = false,
    required CustomColors colors,
    required BuildContext context,
  }) {
    return SizedBox(
      width: 64,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAdd ? colors.surface : null,
                    gradient: isAdd
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF047857)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                    border: isAdd
                        ? Border.all(
                            color: colors.primary.withValues(alpha: 0.2),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(2.5), // Space for inner circle
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background, // Creates the gap
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isAdd && imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: colors.surface),
                              errorWidget: (context, url, error) =>
                                  _buildPlaceholder(colors),
                            )
                          : isAdd
                          ? _buildPlaceholder(colors)
                          : imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: colors.surface),
                              errorWidget: (context, url, error) =>
                                  _buildPlaceholder(colors),
                            )
                          : _buildPlaceholder(colors),
                    ),
                  ),
                ),
                if (isAdd)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isAdd ? FontWeight.w600 : FontWeight.w800,
                letterSpacing: -0.2,
                color: isAdd ? colors.textSecondary : colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(CustomColors colors) {
    return Container(
      color: colors.primary.withValues(alpha: 0.05),
      child: Icon(
        Icons.person_rounded,
        size: 30,
        color: colors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
