import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/ui_state_widgets.dart';

class UserListScreen extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'

  const UserListScreen({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // Assuming backend has get_followers and get_following endpoints
    final endpoint = widget.type == 'followers' ? 'get_followers' : 'get_following';
    final result = await ApiService.get('$endpoint?user_id=${widget.userId}');

    if (mounted) {
      if (result['success']) {
        setState(() {
          _users = List<dynamic>.from(result['data']);
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'تعذر تحميل القائمة';
          _loading = false;
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
        title: Text(
          widget.type == 'followers' ? 'المتابعين' : 'يتابع',
          style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
                  ? StateEmpty(
                      icon: widget.type == 'followers' ? Icons.people_outline : Icons.person_add_outlined,
                      title: 'القائمة فارغة',
                      subtitle: widget.type == 'followers' 
                        ? 'لا يوجد متابعين لهذا الحساب حالياً'
                        : 'هذا الحساب لا يتابع أحداً حالياً',
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          onTap: () => context.push('/user-profile/${user['id']}'),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: user['photo'] != null
                                ? CachedNetworkImageProvider(ApiService.getImageUrl(user['photo'])!)
                                : null,
                            child: user['photo'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(
                            user['name'] ?? '',
                            style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '@${user['username']}',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              'عرض',
                              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
