import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupInfoScreen({super.key, required this.group});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  List<dynamic> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    // Mocking members fetch
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _members = List<dynamic>.from(widget.group['members'] ?? []);
        _loading = false;
      });
    }
  }

  void _removeMember(String userId) {
    setState(() {
      _members.removeWhere((m) => m['id'].toString() == userId);
    });
    // Optional: Call API to remove member
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.read<ThemeProvider>().colors;
    final authProvider = context.read<AuthProvider>();
    final isAdmin = widget.group['adminId']?.toString() == authProvider.user!['id'].toString();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('معلومات المجموعة', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        backgroundImage: widget.group['photo'] != null 
                          ? CachedNetworkImageProvider(ApiService.getImageUrl(widget.group['photo'])!)
                          : null,
                        child: widget.group['photo'] == null 
                          ? Icon(Icons.group_rounded, size: 50, color: colors.primary)
                          : null,
                      ),
                      if (isAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                            child: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.group['name'] ?? 'مجموعة',
                  style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_members.length} عضو',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 30),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الأعضاء', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (isAdmin)
                        TextButton.icon(
                          onPressed: () {
                            // Navigation to add member screen
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 20),
                          label: const Text('إضافة'),
                        ),
                    ],
                  ),
                ),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isMemberAdmin = widget.group['adminId']?.toString() == member['id']?.toString();
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member['photo'] != null 
                          ? CachedNetworkImageProvider(ApiService.getImageUrl(member['photo'])!)
                          : null,
                        child: member['photo'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(member['name'] ?? '', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                      subtitle: isMemberAdmin ? Text('مسؤول', style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                      trailing: isAdmin && !isMemberAdmin ? IconButton(
                        icon: const Icon(Icons.person_remove_rounded, color: Colors.red),
                        onPressed: () => _removeMember(member['id'].toString()),
                      ) : null,
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                if (!isAdmin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        // Exit group logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('مغادرة المجموعة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
