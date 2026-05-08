import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    
    return Shimmer.fromColors(
      baseColor: colors.surface,
      highlightColor: colors.background,
      child: child,
    );
  }
}

class PostShimmer extends StatelessWidget {
  const PostShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerLoading(
                child: CircleAvatar(radius: 20, backgroundColor: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(
                    child: Container(width: 100, height: 12, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  ShimmerLoading(
                    child: Container(width: 60, height: 10, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
            child: Container(width: double.infinity, height: 14, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            child: Container(width: MediaQuery.of(context).size.width * 0.7, height: 14, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
            child: Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerLoading(
          child: Container(width: double.infinity, height: 200, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const ShimmerLoading(
          child: CircleAvatar(radius: 50, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 16),
        ShimmerLoading(
          child: Container(width: 150, height: 20, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ShimmerLoading(
          child: Container(width: 200, height: 14, color: Colors.white),
        ),
      ],
    );
  }
}
