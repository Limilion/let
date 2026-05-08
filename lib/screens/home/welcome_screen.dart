import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF10196F),
              const Color(0xFF2732B9),
              colors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.forum_rounded,
                        color: colors.primary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'تواصل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تواصل وشارك لحظاتك\nاكتشف عالمك وتفاعل مع الآخرين',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 19,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 4),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('ابدأ الآن'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
