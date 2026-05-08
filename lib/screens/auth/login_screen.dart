import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text;
    final password = _passwordController.text;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(email, password);

    if (!result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'حدث خطأ ما')),
        );
      }
    } else {
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'مرحباً بك مجدداً!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سجل دخولك لمتابعة التواصل',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      CustomInput(
                        placeholder: 'البريد الإلكتروني',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'البريد الإلكتروني مطلوب';
                          }
                          if (!v.contains('@')) return 'صيغة البريد غير صحيحة';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomInput(
                        placeholder: 'كلمة المرور',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        isPassword: true,
                        showPassword: _showPassword,
                        onTogglePassword: () =>
                            setState(() => _showPassword = !_showPassword),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'كلمة المرور مطلوبة';
                          if (v.length < 6) return 'كلمة المرور قصيرة';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
                CustomButton(
                  text: 'تسجيل الدخول',
                  onPressed: authProvider.loading ? null : _handleLogin,
                  loading: authProvider.loading,
                  height: 52,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: Divider(color: colors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'أو',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: colors.border)),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                  label: const Text('متابعة بـ Google'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.apple_rounded, size: 20),
                  label: const Text('متابعة بـ Apple'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('إنشاء حساب'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
