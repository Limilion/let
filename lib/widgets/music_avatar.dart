import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class MusicAvatar extends StatefulWidget {
  final String? avatarUrl;
  final double radius;

  const MusicAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 46,
  });

  @override
  State<MusicAvatar> createState() => _MusicAvatarState();
}

class _MusicAvatarState extends State<MusicAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _noteController;
  final List<MusicNoteParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _noteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_updateParticles);
    _noteController.repeat();
  }

  void _updateParticles() {
    if (!mounted) return;
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    
    if (musicProvider.isPlaying) {
      if (_random.nextInt(10) < 2) {
        _particles.add(MusicNoteParticle(
          x: _random.nextDouble() * widget.radius * 2,
          y: widget.radius * 2,
          size: 10 + _random.nextDouble() * 10,
          opacity: 1.0,
          speed: 1 + _random.nextDouble() * 2,
          icon: _random.nextBool() ? Icons.music_note_rounded : Icons.music_video_rounded,
        ));
      }
    }

    for (int i = 0; i < _particles.length; i++) {
      _particles[i].y -= _particles[i].speed;
      _particles[i].opacity -= 0.02;
    }

    _particles.removeWhere((p) => p.opacity <= 0);
    setState(() {});
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final musicProvider = Provider.of<MusicProvider>(context);
    final isPlaying = musicProvider.isPlaying;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Floating Music Notes
        ..._particles.map((p) => Positioned(
          left: p.x - widget.radius,
          top: p.y - widget.radius * 2.5,
          child: Opacity(
            opacity: p.opacity.clamp(0, 1),
            child: Icon(p.icon, size: p.size, color: colors.primary),
          ),
        )),

        // Main Avatar Container with Progress Ring
        GestureDetector(
          onTap: () => musicProvider.togglePlay(),
          onHorizontalDragUpdate: (details) {
            // Simple seek logic could be added here
          },
          child: Container(
            width: (widget.radius + 6) * 2,
            height: (widget.radius + 6) * 2,
            child: CustomPaint(
              painter: MusicProgressPainter(
                progress: musicProvider.progress,
                color: colors.primary,
                backgroundColor: colors.border.withOpacity(0.2),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: widget.radius,
                    backgroundColor: colors.background,
                    child: ClipOval(
                      child: widget.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.avatarUrl!,
                              width: widget.radius * 2,
                              height: widget.radius * 2,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: colors.border.withOpacity(0.1),
                                highlightColor: colors.surface,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person_rounded,
                                size: widget.radius,
                                color: colors.textSecondary,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: widget.radius,
                              color: colors.textSecondary,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Play/Pause Small Toggle Button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => musicProvider.togglePlay(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.background, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MusicNoteParticle {
  double x, y, size, opacity, speed;
  IconData icon;
  MusicNoteParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.icon,
  });
}

class MusicProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  MusicProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(MusicProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
