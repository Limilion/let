import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  File? _avatar;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChoosePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمات المرور غير متطابقة')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      profileImage: _avatar,
    );

    if (result['success']) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'نجاح',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text('تم إنشاء الحساب بنجاح! يرجى الدخول لحسابك.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'حدث خطأ ما')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            children: [
              Text(
                'إنشاء حساب جديد!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'انضم إلى تواصل الآن',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _handleChoosePhoto,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      backgroundImage: _avatar != null
                          ? FileImage(_avatar!)
                          : null,
                      child: _avatar == null
                          ? Icon(
                              Icons.camera_alt_rounded,
                              color: colors.primary,
                              size: 26,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إضافة صورة شخصية',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    CustomInput(
                      placeholder: 'الاسم الكامل',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الاسم مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CustomInput(
                      placeholder: 'اسم المستخدم',
                      icon: Icons.alternate_email_rounded,
                      controller: _phoneController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اسم المستخدم مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CustomInput(
                      placeholder: 'البريد الإلكتروني',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'البريد الإلكتروني مطلوب';
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
                        if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                        if (v.length < 6) return '6 أحرف على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomInput(
                      placeholder: 'تأكيد كلمة المرور',
                      icon: Icons.lock_reset_rounded,
                      controller: _confirmController,
                      isPassword: true,
                      showPassword: _showPassword,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'تأكيد كلمة المرور مطلوب';
                        if (v != _passwordController.text)
                          return 'كلمات المرور غير متطابقة';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (_) {},
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      'أوافق على الشروط والأحكام وسياسة الخصوصية',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              CustomButton(
                text: 'إنشاء حساب',
                onPressed: authProvider.loading ? null : _handleRegister,
                loading: authProvider.loading,
                height: 52,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('لديك حساب؟ تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
