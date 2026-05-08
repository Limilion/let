import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/theme_provider.dart';
import '../providers/music_provider.dart';
import 'package:provider/provider.dart';

class MiniMusicPlayer extends StatelessWidget {
  final String musicUrl;
  final String title;
  final VoidCallback onStop;

  const MiniMusicPlayer({
    super.key,
    required this.musicUrl,
    required this.title,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final musicProvider = Provider.of<MusicProvider>(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.infoContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_note_rounded, color: colors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: musicProvider.progress,
                    backgroundColor: colors.border.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.info),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => musicProvider.togglePlay(),
            icon: Icon(
              musicProvider.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: colors.text,
            ),
          ),
          IconButton(
            onPressed: onStop,
            icon: Icon(
              Icons.close_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
