import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/story_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> with WidgetsBindingObserver {
  File? _mediaFile;
  String _mediaType = 'image';
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isBackground = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (_isBackground) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController?.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? pickedFile = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('المعرض'),
                onTap: () async => Navigator.pop(context, await _picker.pickMedia()),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('كاميرا (صورة)'),
                onTap: () async => Navigator.pop(context, await _picker.pickImage(source: source)),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('كاميرا (فيديو)'),
                onTap: () async => Navigator.pop(context, await _picker.pickVideo(source: source)),
              ),
            ],
          ),
        ),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final isVideo = pickedFile.path.toLowerCase().endsWith('.mp4');
        
        setState(() {
          _mediaFile = file;
          _mediaType = isVideo ? 'video' : 'image';
        });

        if (isVideo) {
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(file)
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
              _videoController?.setLooping(true);
            });
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  Future<void> _handleUpload() async {
    if (_mediaFile == null) return;

    setState(() => _isLoading = true);

    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final result = await storyProvider.addStory(_mediaFile!);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة القصة بنجاح!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'فشل إضافة القصة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_mediaFile != null)
            FadeInRight(
              child: TextButton(
                onPressed: _isLoading ? null : _handleUpload,
                child: _isLoading
                    ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2)
                    : const Text(
                        'نشر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Media Preview
          Center(
            child: _mediaFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                        child: Icon(Icons.add_photo_alternate_outlined,
                            size: 100, color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickMedia(ImageSource.gallery),
                          icon: const Icon(Icons.perm_media),
                          label: const Text('اختر صورة أو فيديو للقصة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Hero(
                    tag: 'story-preview',
                    child: _mediaType == 'video'
                        ? (_videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary))
                        : Image.file(_mediaFile!, fit: BoxFit.contain),
                  ),
          ),
          
          // Controls
          if (_mediaFile != null && !_isLoading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeInUp(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCircleActionButton(
                      icon: Icons.edit,
                      onTap: () {}, // Text editing coming soon
                    ),
                    const SizedBox(width: 24),
                    _buildCircleActionButton(
                      icon: Icons.refresh,
                      onTap: () => _pickMedia(ImageSource.gallery),
                    ),
                    const SizedBox(width: 24),
                    _buildCircleActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () {
                        setState(() {
                          _mediaFile = null;
                          _videoController?.dispose();
                          _videoController = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
