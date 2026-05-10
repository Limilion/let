import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/notes_bar.dart';
import '../../providers/note_provider.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations();
      Provider.of<NoteProvider>(context, listen: false).fetchNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final chatProvider = Provider.of<ChatProvider>(context);

    final filteredConversations = chatProvider.conversations.where((conv) {
      final name = conv['otherUser']['name'].toString().toLowerCase();
      final username = conv['otherUser']['username'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          username.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'الرسائل',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
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
              context.go('/main');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colors.primary),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(
                    alpha: themeProvider.isDarkMode ? 0.5 : 0.8,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.search_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                    border: InputBorder.none,
                    hintText: 'ابحث عن أصدقاء أو رسائل...',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),

          // Notes Bar
          if (_searchQuery.isEmpty) const NotesBar(),

          // Active Users
          if (_searchQuery.isEmpty) _buildActiveUsers(chatProvider, colors),

          // Conversations List
          Expanded(
            child: chatProvider.loadingConversations
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => chatProvider.fetchConversations(),
                    displacement: 20,
                    color: colors.primary,
                    child: filteredConversations.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.builder(
                            itemCount: filteredConversations.length,
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 10,
                              bottom: 100,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final conv = filteredConversations[index];
                              return _buildConversationCard(conv, colors, chatProvider);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: colors.primary,
        icon: Icon(Icons.group_add_rounded, color: Theme.of(context).colorScheme.onPrimary),
        label: Text('مجموعة جديدة', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conv, dynamic colors, ChatProvider chatProvider) {
    final otherUser = conv['otherUser'];
    final lastMessage = conv['lastMessage'] ?? 'ابدأ المحادثة الآن...';
    final unreadCount = conv['unreadCount'] ?? 0;
    final timeStr = conv['time'];
    final time = timeStr != null ? DateTime.parse(timeStr) : DateTime.now();
    final formattedTime = intl.DateFormat('hh:mm a').format(time);

    return GestureDetector(
      onTap: () => context.push('/chat', extra: otherUser),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.2),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: conv['isGroup'] == true
                        ? Icon(Icons.group_rounded, color: colors.primary, size: 30)
                        : (otherUser['photo'] != null
                            ? CachedNetworkImage(
                                imageUrl: ApiService.getImageUrl(otherUser['photo'])!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: colors.border.withValues(alpha: 0.1),
                                  highlightColor: colors.surface,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person_rounded,
                                  color: colors.primary,
                                  size: 30,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                color: colors.primary,
                                size: 30,
                              )),
                  ),
                ),
                if (conv['isGroup'] != true)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(right: 2, bottom: 2),
                    decoration: BoxDecoration(
                      color: chatProvider.isOnline(otherUser['id'].toString())
                          ? Colors.green
                          : Colors.grey.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Main Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUser['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: chatProvider.isTyping(otherUser['id'].toString())
                            ? Text(
                                'يكتب الآن...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              )
                            : Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: unreadCount > 0
                                      ? colors.text
                                      : colors.textSecondary,
                                ),
                              ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsers(ChatProvider chatProvider, dynamic colors) {
    if (chatProvider.conversations.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chatProvider.conversations.length,
        itemBuilder: (context, index) {
          final user = chatProvider.conversations[index]['otherUser'];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/chat', extra: user),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors.primaryGradient,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surface,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: user['photo'] != null
                                ? Image.network(
                                    ApiService.getImageUrl(user['photo'])!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.person,
                                          color: colors.primary,
                                        ),
                                  )
                                : Icon(Icons.person, color: colors.primary),
                          ),
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: chatProvider.isOnline(user['id'].toString())
                              ? Colors.green
                              : Colors.grey.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      user['name'].split(' ')[0],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة إنشاء المجموعات ستتوفر قريباً!')),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.1),
                  colors.primary.withValues(alpha: 0.01),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_rounded,
              size: 60,
              color: colors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'صندوق الرسائل فارغ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'ابدأ محادثات جديدة مع أصدقائك وشاركهم لحظاتك الرائعة!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.push('/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ابحث عن أصدقاء',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
