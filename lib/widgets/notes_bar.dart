import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';
import '../models/note.dart';
import 'package:animate_do/animate_do.dart';

class NotesBar extends StatefulWidget {
  const NotesBar({super.key});

  @override
  State<NotesBar> createState() => _NotesBarState();
}

class _NotesBarState extends State<NotesBar> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NoteProvider>().fetchNotes());
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    if (noteProvider.loading && noteProvider.notes.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    if (noteProvider.error != null && noteProvider.notes.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'خطأ في الملاحظات: ${noteProvider.error}',
          style: const TextStyle(color: Colors.red, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      );
    }

    final myNote = noteProvider.notes.firstWhere(
      (n) => n.userId.toString() == authProvider.user!['id'].toString(),
      orElse: () => Note(id: 0, userId: 0, content: '', createdAt: DateTime.now(), expiresAt: DateTime.now()),
    );

    final otherNotes = noteProvider.notes.where(
      (n) => n.userId.toString() != authProvider.user!['id'].toString(),
    ).toList();

    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMyNoteItem(myNote, authProvider.user!, colors),
          ...otherNotes.map((note) => _buildNoteItem(note, colors)),
        ],
      ),
    );
  }

  Widget _buildMyNoteItem(Note myNote, Map<String, dynamic> user, dynamic colors) {
    final bool hasNote = myNote.id != 0;
    
    return GestureDetector(
      onTap: () => _showCreateNoteDialog(myNote.content),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 2),
                  ),
                  child: ClipOval(
                    child: user['photo'] != null
                        ? Image.network(
                            ApiService.getImageUrl(user['photo'])!,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.person, color: colors.primary, size: 35),
                  ),
                ),
                Positioned(
                  top: -15,
                  right: -5,
                  child: ZoomIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          constraints: const BoxConstraints(maxWidth: 85),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasNote && myNote.type == 'voice')
                                Icon(Icons.mic_rounded, color: colors.primary, size: 16)
                              else if (hasNote && myNote.type == 'video')
                                Icon(Icons.play_circle_fill_rounded, color: colors.primary, size: 16)
                              else
                                Text(
                                  hasNote ? myNote.content : 'ملاحظة...',
                                  style: TextStyle(
                                    color: hasNote ? colors.text : colors.textSecondary.withValues(alpha: 0.5),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                        // Cloud "tails"
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!hasNote)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ملاحظتك',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(Note note, dynamic colors) {
    return FadeInRight(
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ClipOval(
                    child: note.userPhoto != null
                        ? Image.network(
                            ApiService.getImageUrl(note.userPhoto)!,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.person, color: colors.textSecondary, size: 35),
                  ),
                ),
                Positioned(
                  top: -15,
                  right: -5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        constraints: const BoxConstraints(maxWidth: 85),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (note.type == 'voice')
                              Icon(Icons.mic_rounded, color: colors.primary, size: 16)
                            else if (note.type == 'video')
                              Icon(Icons.play_circle_fill_rounded, color: colors.primary, size: 16)
                            else
                              Text(
                                note.content,
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                      // Cloud "tails"
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.userName ?? 'مستخدم',
              style: TextStyle(
                color: colors.text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNoteDialog(String initialText) {
    final controller = TextEditingController(text: initialText);
    final colors = context.read<ThemeProvider>().colors;

    context.read<PostProvider>().setFeedPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(
            'شارك ملاحظة',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: 60,
                maxLines: 3,
                autofocus: true,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  hintText: 'ما الذي يدور في ذهنك؟',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<PostProvider>().setFeedPaused(false);
                Navigator.pop(context);
              },
              child: Text('إلغاء', style: TextStyle(color: colors.textSecondary)),
            ),
            if (initialText.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await context.read<NoteProvider>().deleteNote();
                  if (context.mounted) {
                    context.read<PostProvider>().setFeedPaused(false);
                    Navigator.pop(context);
                  }
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await context.read<NoteProvider>().postNote(controller.text);
                  if (context.mounted) {
                    context.read<PostProvider>().setFeedPaused(false);
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('مشاركة', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
