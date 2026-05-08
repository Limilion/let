import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمات المرور غير متطابقة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('نجاح ✨', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                child: const Text('دخول', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'حدث خطأ ما'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
      body: Stack(
        children: [
          // Header Background
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1B5E20), const Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                FadeInDown(
                  child: const Text(
                    'انضم إلينا!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                
                Expanded(
                  child: FadeInUp(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Avatar Picker
                            Center(
                              child: GestureDetector(
                                onTap: _handleChoosePhoto,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 45,
                                      backgroundColor: colors.primary.withOpacity(0.1),
                                      backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                                      child: _avatar == null
                                          ? Icon(Icons.person_add_rounded, color: colors.primary, size: 30)
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  CustomInput(
                                    placeholder: 'الاسم الكامل',
                                    icon: Icons.person_outline_rounded,
                                    controller: _nameController,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomInput(
                                    placeholder: 'اسم المستخدم',
                                    icon: Icons.alternate_email_rounded,
                                    controller: _phoneController,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المستخدم مطلوب' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomInput(
                                    placeholder: 'البريد الإلكتروني',
                                    icon: Icons.mail_outline_rounded,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
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
                                    onTogglePassword: () => setState(() => _showPassword = !_showPassword),
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
                                      if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                                      if (v != _passwordController.text) return 'كلمات المرور غير متطابقة';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'إنشاء الحساب',
                              onPressed: authProvider.loading ? null : _handleRegister,
                              loading: authProvider.loading,
                              height: 58,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('لديك حساب بالفعل؟', style: TextStyle(color: colors.textSecondary)),
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
