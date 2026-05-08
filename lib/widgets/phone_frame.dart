import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PhoneFrame extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool showNotch;
  final double? height;
  final double? width;

  const PhoneFrame({
    super.key,
    required this.child,
    this.borderRadius = 32.0,
    this.showNotch = true,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colors.border.withValues(alpha: 0.8),
          width: 8, // Bezel
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Content
          Positioned.fill(child: child),

          // Notch / Dynamic Island
          if (showNotch)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                height: 20,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Bottom Indicator Bar (Optional but nice)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 4,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
