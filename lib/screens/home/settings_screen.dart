import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoPlay = true;
  bool _saveData = false;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.go('/login');
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final colors = Provider.of<ThemeProvider>(context).colors;
          return AlertDialog(
            backgroundColor: colors.surface,
            title: Text(
              'تغيير كلمة المرور',
              style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordCtrl,
                  obscureText: true,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: true,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (context.canPop()) context.pop();
                      },
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('كلمات المرور الجديدة غير متطابقة'),
                            ),
                          );
                          return;
                        }
                        if (newPasswordCtrl.text.isEmpty ||
                            currentPasswordCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء تعبئة كافة الحقول'),
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);
                        final result =
                            await ApiService.post('change_password', {
                              'currentPassword': currentPasswordCtrl.text,
                              'newPassword': newPasswordCtrl.text,
                            });
                        setState(() => isLoading = false);

                        if (result['success']) {
                          if (mounted) {
                            if (context.canPop()) context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تغيير كلمة المرور بنجاح'),
                              ),
                            );
                          }
                        } else {
                          if (context.canPop()) context.pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'فشل تغيير كلمة المرور',
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleShareApp() async {
    await Share.share(
      'انضم إلي على LinkUp! تطبيق التواصل الاجتماعي الأفضل 🚀',
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الموقع')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = themeProvider.colors;
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'الإعدادات',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            _buildProfileCard(user, colors),
            const SizedBox(height: 24),

            // Account Section
            _buildSection('الحساب', [
              _buildSettingItem(
                icon: Icons.person_outline,
                label: 'تعديل الملف الشخصي',
                color: Colors.blue,
                onTap: () => context.push('/edit-profile'),
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.lock_outline,
                label: 'تغيير كلمة المرور',
                color: Colors.indigo,
                onTap: _handleChangePassword,
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.notifications_none,
                label: 'الإشعارات',
                color: Colors.orange,
                isSwitch: true,
                valueSwitch: _notifications,
                onChanged: (val) => setState(() => _notifications = val),
                colors: colors,
              ),
            ], colors),

            // Preferences Section
            _buildSection('التفضيلات', [
              _buildSettingItem(
                icon: Icons.dark_mode_outlined,
                label: 'الوضع الليلي',
                color: Colors.deepPurple,
                isSwitch: true,
                valueSwitch: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(),
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.volume_up_outlined,
                label: 'الصوت',
                color: Colors.red,
                isSwitch: true,
                valueSwitch: _soundEnabled,
                onChanged: (val) => setState(() => _soundEnabled = val),
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.vibration,
                label: 'الاهتزاز',
                color: Colors.purple,
                isSwitch: true,
                valueSwitch: _vibrationEnabled,
                onChanged: (val) => setState(() => _vibrationEnabled = val),
                colors: colors,
              ),
            ], colors),

            // Support Section
            _buildSection('الدعم', [
              _buildSettingItem(
                icon: Icons.help_outline,
                label: 'المساعدة',
                color: Colors.indigo,
                onTap: () {},
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.mail_outline,
                label: 'اتصل بنا',
                color: Colors.red,
                onTap: () => _launchUrl('mailto:support@linkup.app'),
                colors: colors,
              ),
            ], colors),

            // About Section
            _buildSection('حول', [
              _buildSettingItem(
                icon: Icons.info_outline,
                label: 'عن التطبيق',
                value: 'الإصدار 1.0.0',
                color: Colors.blue,
                onTap: () {},
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.star_border,
                label: 'قيم التطبيق',
                color: Colors.amber,
                onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.linkup.app',
                ),
                colors: colors,
              ),
              _buildSettingItem(
                icon: Icons.share_outlined,
                label: 'شارك التطبيق',
                color: Colors.pink,
                onTap: _handleShareApp,
                colors: colors,
              ),
            ], colors),

            // Logout Button
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error.withValues(alpha: 0.1),
                foregroundColor: colors.error,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: colors.error.withValues(alpha: 0.2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LinkUp v1.0.0 (Build 100)',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? user, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(user, colors),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['name'] ?? 'مستخدم',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  user?['email'] ?? '',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic>? user, dynamic colors) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.7)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: user?['photo'] != null
            ? Image.network(
                ApiService.getImageUrl(user!['photo'])!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, color: Colors.white, size: 30),
              )
            : const Icon(Icons.person, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required Color color,
    required dynamic colors,
    String? value,
    bool isSwitch = false,
    bool? valueSwitch,
    Function(bool)? onChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: isSwitch ? null : onTap,
      leading: Icon(icon, color: colors.text, size: 23),
      title: Text(
        label,
        style: TextStyle(
          color: colors.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: isSwitch
          ? Switch(
              value: valueSwitch ?? false,
              onChanged: onChanged,
              activeColor: colors.primary,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  Text(
                    value,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: colors.textSecondary,
                  size: 18,
                ),
              ],
            ),
    );
  }
}
