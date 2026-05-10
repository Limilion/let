import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/post_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/story_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/music_provider.dart';
import 'providers/note_provider.dart';
import 'package:go_router/go_router.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';

import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  try {
    await Firebase.initializeApp();
    print('✅✅✅ FIREBASE INITIALIZED SUCCESSFULLY! التطبيق متصل بفايربيس ✅✅✅');
  } catch (e) {
    print('❌❌❌ FIREBASE ERROR: خطأ في الاتصال بفايربيس: $e ❌❌❌');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PostProvider>(
          create: (context) => PostProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => (previous ?? PostProvider(auth))..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => (previous ?? ChatProvider(auth))..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StoryProvider>(
          create: (context) => StoryProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => (previous ?? StoryProvider(auth))..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => (previous ?? NotificationProvider(auth))..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          // Initialize router only once or when authProvider changes if needed
          // refreshListenable: authProvider handles internal state changes
          _router ??= AppRouter.createRouter(authProvider);
          
          return MaterialApp.router(
            title: 'LinkUp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(false),
            darkTheme: AppTheme.getTheme(true),
            themeMode: themeProvider.themeMode,
            routerConfig: _router!,
            builder: (context, child) {
              return child!;
            },
          );
        },
      ),
    );
  }
}
