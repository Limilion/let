import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const IncomingCallScreen({super.key, required this.callData});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _acceptCall() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.answerCall(widget.callData['callerId'].toString());
    // Navigate to active call screen
    context.pushReplacement('/call', extra: widget.callData);
  }

  void _rejectCall() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.rejectCall(widget.callData['callerId'].toString());
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    
    final callerName = widget.callData['callerName'] ?? 'مستخدم';
    final callerPhoto = widget.callData['callerPhoto'];
    final isVideo = widget.callData['isVideo'] == true;
    final photoUrl = callerPhoto != null ? ApiService.getImageUrl(callerPhoto) : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (blurred image or dark color)
          if (photoUrl != null)
            Image.network(photoUrl, fit: BoxFit.cover)
          else
            Container(color: colors.background),
            
          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
          
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Caller Info
                Text(
                  isVideo ? 'مكالمة فيديو واردة' : 'مكالمة صوتية واردة',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 30),
                
                // Pulsing Avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isVideo ? Colors.blue : Colors.green, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: (isVideo ? Colors.blue : Colors.green).withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: photoUrl != null
                              ? Image.network(photoUrl, fit: BoxFit.cover)
                              : Icon(Icons.person, size: 80, color: colors.textSecondary),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  callerName,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                
                const Spacer(),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reject
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _rejectCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('رفض', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      
                      // Accept
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _acceptCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: isVideo ? Colors.blue : Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('قبول', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
