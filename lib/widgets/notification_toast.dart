import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class NotificationToast extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;

  const NotificationToast({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: GestureDetector(
            onTap: onTap,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(20),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    if (imageUrl != null)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.notifications_rounded, color: theme.primaryColor),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, {
    required String title,
    required String body,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    _currentOverlay?.remove();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: NotificationToast(
          title: title,
          body: body,
          imageUrl: imageUrl,
          onTap: () {
            _currentOverlay?.remove();
            _currentOverlay = null;
            onTap();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    Future.delayed(const Duration(seconds: 4), () {
      if (_currentOverlay != null) {
        _currentOverlay?.remove();
        _currentOverlay = null;
      }
    });
  }
}
