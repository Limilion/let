import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const CallScreen({super.key, required this.callData});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isSpeakerOn = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isCameraOn = widget.callData['isVideo'] == true;
    _startTimer();

    // Listen for call ended event
    SocketService.on('call_ended', _onCallEnded);
    SocketService.on('call_rejected', _onCallRejected);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SocketService.off('call_ended', _onCallEnded);
    SocketService.off('call_rejected', _onCallRejected);
    super.dispose();
  }

  void _onCallEnded(dynamic data) {
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت المكالمة', textAlign: TextAlign.center)),
      );
    }
  }

  void _onCallRejected(dynamic data) {
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض المكالمة', textAlign: TextAlign.center)),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // Determine the other user ID (could be caller or answerer depending on who initiated)
    // Extra could have callerId or answererId depending on the context
    final otherUserId = widget.callData['callerId']?.toString() ?? widget.callData['receiverId']?.toString();
    if (otherUserId != null) {
      chatProvider.endCall(otherUserId);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    
    final otherName = widget.callData['callerName'] ?? widget.callData['receiverName'] ?? 'مستخدم';
    final otherPhoto = widget.callData['callerPhoto'] ?? widget.callData['receiverPhoto'];
    final isVideo = widget.callData['isVideo'] == true;
    final photoUrl = otherPhoto != null ? ApiService.getImageUrl(otherPhoto) : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated Video Feed or Background
          if (isVideo && _isCameraOn)
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.white24, size: 100), // Placeholder for actual camera feed
              ),
            )
          else if (photoUrl != null)
            Image.network(photoUrl, fit: BoxFit.cover)
          else
            Container(color: colors.background),
            
          if (!isVideo || !_isCameraOn)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.8)),
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header (Name & Time)
                Text(
                  otherName,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_secondsElapsed),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                
                const Spacer(),
                
                // Avatar (if audio call)
                if (!isVideo || !_isCameraOn)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 4),
                      image: photoUrl != null
                          ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 80, color: Colors.white)
                        : null,
                  ),

                const Spacer(),

                // Small self camera view (if video)
                if (isVideo && _isCameraOn)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 20, bottom: 20),
                      width: 100,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Center(child: Icon(Icons.person, color: Colors.white54)),
                    ),
                  ),

                // Controls Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Speaker Toggle
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        isActive: _isSpeakerOn,
                        onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                      ),
                      
                      // Video/Camera Toggle
                      if (isVideo)
                        _buildControlButton(
                          icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                          isActive: _isCameraOn,
                          onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                        ),
                        
                      // Mute Toggle
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        isActive: !_isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      
                      // End Call
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                        ),
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

  Widget _buildControlButton({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
