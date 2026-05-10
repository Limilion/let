import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

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
      body: Stack(
        children: [
          // Dynamic Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B5E20), // Dark Green
                  const Color(0xFF2E7D32), // Medium Green
                  const Color(0xFF43A047), // Light Green
                ],
              ),
            ),
          ).animate().fadeIn(duration: 800.ms),

          // Abstract background shapes for premium look
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurCircle(300, Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildBlurCircle(400, Colors.black.withOpacity(0.1)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo and Title Area
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        // New Professional Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(15),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.eco_rounded,
                                color: colors.primary,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'LinkUp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            fontFamily: 'Inter',
                          ),
                        ).animate().shimmer(duration: 2.seconds, color: Colors.white70),
                        const SizedBox(height: 12),
                        Text(
                          'تواصل، شارك، وانمو مع مجتمعك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 3),

                  // Action Buttons
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        // Glassmorphism Primary Button
                        _buildGlassButton(
                          context,
                          label: 'تسجيل الدخول',
                          onPressed: () => context.go('/login'),
                          isPrimary: true,
                        ),
                        const SizedBox(height: 16),
                        // Glassmorphism Secondary Button
                        _buildGlassButton(
                          context,
                          label: 'إنشاء حساب جديد',
                          onPressed: () => context.go('/register'),
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer text
                  Center(
                    child: Text(
                      'بواسطة LinkUp Team',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildGlassButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? Colors.white : Colors.white.withOpacity(0.15),
            foregroundColor: isPrimary ? const Color(0xFF1B5E20) : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isPrimary 
                  ? BorderSide.none 
                  : BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
