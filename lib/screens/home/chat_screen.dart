import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:ui';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/ui_state_widgets.dart';
import '../../widgets/voice_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.fetchMessages(widget.otherUser['id'].toString());
    chatProvider.setCurrentChat(widget.otherUser['id'].toString());

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty && !_isTyping) {
        _isTyping = true;
        chatProvider.setTyping(widget.otherUser['id'].toString(), true);
      } else if (_messageController.text.isEmpty && _isTyping) {
        _isTyping = false;
        chatProvider.setTyping(widget.otherUser['id'].toString(), false);
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    Provider.of<ChatProvider>(context, listen: false).setCurrentChat(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final text = _messageController.text.trim();
    _messageController.clear();

    final result = await chatProvider.sendMessage(
      widget.otherUser['id'].toString(),
      text,
    );
    if (result['success']) {
      _scrollToBottom();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = p.join(dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final result = await chatProvider.sendMessage(
          widget.otherUser['id'].toString(),
          null,
          filePath: path,
          type: 'voice',
        );
        if (result['success']) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (photo != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final result = await chatProvider.sendMessage(
          widget.otherUser['id'].toString(),
          null,
          filePath: photo.path,
          type: 'image',
        );
        if (result['success']) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final result = await chatProvider.sendMessage(
          widget.otherUser['id'].toString(),
          null,
          filePath: image.path,
          type: 'image',
        );
        if (result['success']) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
  
  void _initiateCall(bool isVideo) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final currentUser = authProvider.user!;
    final callerName = currentUser['name'] ?? 'مستخدم';
    final callerPhoto = currentUser['photo'];
    
    final callData = {
      'callerId': currentUser['id'].toString(),
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'receiverId': widget.otherUser['id'].toString(),
      'receiverName': widget.otherUser['name'],
      'receiverPhoto': widget.otherUser['photo'],
      'isVideo': isVideo,
    };
    
    chatProvider.callUser(
      widget.otherUser['id'].toString(),
      callerName,
      callerPhoto ?? '',
      isVideo,
    );
    
    context.push('/call', extra: callData);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          context.go('/direct-messages');
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AppBar(
                backgroundColor: colors.surface.withValues(alpha: 0.7),
                elevation: 0,
                titleSpacing: 0,
                toolbarHeight: 70,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colors.text,
                    size: 22,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/direct-messages');
                    }
                  },
                ),
                title: GestureDetector(
                  onTap: () =>
                      context.push('/user-profile/${widget.otherUser['id']}'),
                  child: Row(
                    children: [
                      _buildHeaderAvatar(widget.otherUser, colors),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUser['name'],
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color:
                                      chatProvider.isTyping(
                                        widget.otherUser['id'].toString(),
                                      )
                                      ? colors.primary
                                      : (chatProvider.isOnline(widget.otherUser['id'].toString()) 
                                          ? Colors.green 
                                          : Colors.grey.shade400),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (chatProvider.isTyping(
                                      widget.otherUser['id'].toString(),
                                    ) || chatProvider.isOnline(widget.otherUser['id'].toString()))
                                      BoxShadow(
                                        color: (chatProvider.isTyping(widget.otherUser['id'].toString()) ? colors.primary : Colors.green).withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chatProvider.isTyping(
                                      widget.otherUser['id'].toString(),
                                    )
                                    ? 'يكتب الآن...'
                                    : (chatProvider.isOnline(widget.otherUser['id'].toString()) 
                                        ? 'متصل الآن' 
                                        : 'غير متصل'),
                                style: TextStyle(
                                  color:
                                      chatProvider.isTyping(
                                        widget.otherUser['id'].toString(),
                                      )
                                      ? colors.primary
                                      : colors.textSecondary.withValues(
                                          alpha: 0.7,
                                        ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.call_rounded, color: colors.text, size: 24),
                    onPressed: () {
                      _initiateCall(false);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.videocam_rounded, color: colors.text, size: 26),
                    onPressed: () {
                      _initiateCall(true);
                    },
                  ),
                  const SizedBox(width: 8)
                ],
                shape: Border(
                  bottom: BorderSide(
                    color: colors.border.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Telegram-style Patterned Background
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.network(
                  'https://www.transparenttextures.com/patterns/cubes.png',
                  repeat: ImageRepeat.repeat,
                  color: colors.text,
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: chatProvider.messages.isEmpty
                      ? _buildEmptyState(colors)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 100,
                            bottom: 20,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chatProvider.messages[index];
                            final isMine =
                                msg['senderId'].toString() ==
                                currentUser?['id'].toString();

                            // Grouping Logic
                            bool isLastInGroup = true;
                            if (index < chatProvider.messages.length - 1) {
                              isLastInGroup =
                                  chatProvider.messages[index + 1]['senderId']
                                      .toString() !=
                                  msg['senderId'].toString();
                            }

                            bool isFirstInGroup = true;
                            if (index > 0) {
                              isFirstInGroup =
                                  chatProvider.messages[index - 1]['senderId']
                                      .toString() !=
                                  msg['senderId'].toString();
                            }

                            return ZoomIn(
                              duration: const Duration(milliseconds: 300),
                              child: _buildSmartMessageBubble(
                                msg,
                                isMine,
                                isFirstInGroup,
                                isLastInGroup,
                                colors,
                              ),
                            );
                          },
                        ),
                ),
                if (chatProvider.isTyping(widget.otherUser['id'].toString()))
                  _buildTypingIndicator(colors),
                _buildInputArea(colors, chatProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(Map<String, dynamic> user, dynamic colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.primary.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: user['photo'] != null
            ? CachedNetworkImage(
                imageUrl: ApiService.getImageUrl(user['photo'])!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: colors.border.withValues(alpha: 0.1),
                  highlightColor: colors.surface,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.person, color: colors.primary, size: 20),
              )
            : Icon(Icons.person, color: colors.primary, size: 20),
      ),
    );
  }

  Widget _buildSmartMessageBubble(
    Map<String, dynamic> msg,
    bool isMine,
    bool isFirst,
    bool isLast,
    dynamic colors,
  ) {
    final timeStr = msg['time'];
    final time = timeStr != null ? DateTime.parse(timeStr) : DateTime.now();
    final formattedTime = intl.DateFormat('HH:mm').format(time);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 16 : 4, top: isFirst ? 8 : 0),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (isLast)
              _buildSmallAvatar(widget.otherUser, colors)
            else
              const SizedBox(width: 32),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMine
                    ? LinearGradient(
                        colors: colors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMine ? null : colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMine ? 22 : (isLast ? 4 : 22)),
                  bottomRight: Radius.circular(isMine ? (isLast ? 4 : 22) : 22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg['type'] == 'voice')
                    VoiceMessageBubble(
                      audioUrl: msg['mediaUrl'] ?? '',
                      isMe: isMine,
                      color: isMine ? Colors.white24 : null,
                    )
                  else if (msg['type'] == 'image')
                    GestureDetector(
                      onTap: () {
                         // Full screen view logic
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: ApiService.getImageUrl(msg['mediaUrl']) ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        color: isMine ? Colors.white : colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : colors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg['isRead'] == true || msg['isRead'] == 1
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 10),
            if (isLast)
              _buildSmallAvatar(
                Provider.of<AuthProvider>(context).user!,
                colors,
              )
            else
              const SizedBox(width: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(Map<String, dynamic> user, dynamic colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.primary.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: user['photo'] != null
            ? CachedNetworkImage(
                imageUrl: ApiService.getImageUrl(user['photo'])!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: colors.border.withValues(alpha: 0.1),
                  highlightColor: colors.surface,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.person, color: colors.primary, size: 16),
              )
            : Icon(Icons.person, color: colors.primary, size: 16),
      ),
    );
  }

  Widget _buildTypingIndicator(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _buildDot(colors.primary),
                const SizedBox(width: 4),
                _buildDot(colors.primary),
                const SizedBox(width: 4),
                _buildDot(colors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildInputArea(dynamic colors, ChatProvider chatProvider) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 15,
        bottom: MediaQuery.of(context).padding.bottom + 15,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isRecording)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt_rounded, color: colors.primary, size: 26),
                  onPressed: _takePhoto,
                ),
                IconButton(
                  icon: Icon(Icons.image_rounded, color: colors.primary, size: 26),
                  onPressed: _pickImage,
                ),
              ],
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                ),
                textAlign: TextAlign.right,
                onChanged: (val) {
                  chatProvider.setTyping(
                    widget.otherUser['id'].toString(),
                    val.isNotEmpty,
                  );
                  if (_isTyping != val.isNotEmpty) {
                    setState(() => _isTyping = val.isNotEmpty);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onLongPressStart: (_) {
              if (!_isTyping) _startRecording();
            },
            onLongPressEnd: (_) {
              if (!_isTyping) _stopRecording();
            },
            onTap: _isTyping ? _handleSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: _isRecording
                    ? const LinearGradient(colors: [Colors.red, Colors.redAccent])
                    : LinearGradient(colors: colors.primaryGradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : colors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isTyping
                    ? Icons.send_rounded
                    : (_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded),
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return StateEmpty(
      icon: Icons.chat_bubble_outline,
      title: 'ابدأ المحادثة',
      subtitle: 'كن أول من يرسل رسالة إلى ${widget.otherUser['name']}',
    );
  }
}
