import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/ui_state_widgets.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<AIMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(AIMessage(
      content: 'مرحباً بك! أنا مساعدك الذكي. يمكنني مساعدتك في كتابة منشورات إبداعية أو توليد أفكار جديدة. ماذا يمكنني أن أفعل لك اليوم؟',
      isAI: true,
    ));
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(AIMessage(content: text, isAI: false));
      _inputController.clear();
      _isTyping = true;
    });

    try {
      final result = await ApiService.post('prompt', {'prompt': text});
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          if (result['success']) {
            final data = result['data'];
            _messages.add(AIMessage(
              content: data['content'], 
              isAI: true,
              type: data['type'] ?? 'text',
              imageUrl: data['imageUrl'],
            ));
          } else {
            _messages.add(AIMessage(content: 'عذراً، حدث خطأ أثناء الاتصال بالذكاء الاصطناعي.', isAI: true));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(AIMessage(content: 'عذراً، تعذر الوصول للمساعد الذكي حالياً.', isAI: true));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(FontAwesomeIcons.wandMagicSparkles, size: 16, color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(width: 12),
            Text(
              'المساعد الذكي',
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, colors);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'جاري التفكير...',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          _buildQuickActions(colors),
          _buildInputArea(colors),
        ],
      ),
    );
  }

  Widget _buildQuickActions(dynamic colors) {
    final actions = [
      {'label': '💡 أفكار منشورات', 'prompt': 'أعطني فكرة لمنشور جديد'},
      {'label': '📝 كتابة كابشن', 'prompt': 'اكتب لي كابشن لمنشور عن النجاح'},
      {'label': '🎨 توليد صورة', 'prompt': 'ولد لي صورة فنية'},
      {'label': '👤 سيرة ذاتية', 'prompt': 'اكتب لي سيرة ذاتية (Bio) احترافية'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                actions[index]['label']!,
                style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.border.withValues(alpha: 0.3)),
              onPressed: () {
                _inputController.text = actions[index]['prompt']!;
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message, dynamic colors) {
    return Align(
      alignment: message.isAI ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: message.isAI ? colors.surface : colors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(message.isAI ? 24 : 0),
            bottomRight: Radius.circular(message.isAI ? 0 : 24),
          ),
          border: message.isAI ? Border.all(color: colors.border.withValues(alpha: 0.5)) : null,
          boxShadow: [
            if (message.isAI)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == 'image' && message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  message.imageUrl!, 
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: colors.background,
                      child: Center(child: CircularProgressIndicator(color: colors.primary)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: message.isAI ? colors.text : Theme.of(context).colorScheme.onPrimary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message.isAI) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (message.type == 'text')
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      label: 'نسخ',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم النسخ إلى الحافظة')),
                        );
                      },
                      colors: colors,
                    ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.add_box_rounded,
                    label: 'استخدام في منشور',
                    onPressed: () {
                      context.push('/create-post', extra: {
                        'image_url': message.imageUrl,
                        'initial_text': message.content,
                      });
                    },
                    colors: colors,
                    primary: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required dynamic colors,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primary ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary ? colors.primary : colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? colors.primary : colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _inputController,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  hintText: 'اسأل المساعد الذكي...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class AIMessage {
  final String content;
  final bool isAI;
  final String? imageUrl;
  final String type; // 'text', 'image'

  AIMessage({
    required this.content, 
    required this.isAI, 
    this.imageUrl, 
    this.type = 'text'
  });
}
