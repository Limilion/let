import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../providers/theme_provider.dart';

class CreateLiveScreen extends StatefulWidget {
  const CreateLiveScreen({super.key});

  @override
  State<CreateLiveScreen> createState() => _CreateLiveScreenState();
}

class _CreateLiveScreenState extends State<CreateLiveScreen> with TickerProviderStateMixin {
  bool _isLive = false;
  int _viewerCount = 0;
  final List<String> _comments = [];
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  void _startLive() {
    setState(() {
      _isLive = true;
      _viewerCount = 142;
      _comments.add('مرحباً بك في البث! 👋');
    });
    // Simulate comments
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _comments.add('واو، الفلتر رائع! ✨'));
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.read<ThemeProvider>().colors;

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview Mock
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 80),
            ),
          ),
          
          // Header Actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => context.pop(),
                  ),
                if (_isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('$_viewerCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 30),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Bottom Controls
          if (!_isLive)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'جاهز للبث؟',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _startLive,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Live Overlay
          if (_isLive) ...[
            // Comments List
            Positioned(
              bottom: 120,
              left: 20,
              right: 80,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white24,
                            child: Text(
                              _comments[index],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Interaction Buttons
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.white24,
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'قل شيئاً...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red, size: 40),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
