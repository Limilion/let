import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/home/welcome_screen.dart';
import '../screens/main_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/home/user_profile_screen.dart';
import '../screens/home/chat_screen.dart';
import '../screens/home/direct_messages_screen.dart';
import '../screens/home/settings_screen.dart';
import '../screens/home/story_viewer_screen.dart';
import '../screens/home/stats_screen.dart';
import '../screens/home/post_details_screen.dart';
import '../screens/home/create_post_screen.dart';
import '../screens/home/create_story_screen.dart';
import '../screens/home/edit_profile_screen.dart';
import '../screens/home/notifications_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/home/ai_assistant_screen.dart';
import '../screens/home/incoming_call_screen.dart';
import '../screens/home/call_screen.dart';
import '../screens/home/video_feed_screen.dart';
import '../screens/home/user_list_screen.dart';
import '../screens/home/group_info_screen.dart';
import '../screens/home/create_live_screen.dart';
import '../screens/home/feature_placeholder_screen.dart';
import '../providers/story_provider.dart';
import '../models/post.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<ModalRoute> routeObserver =
      RouteObserver<ModalRoute>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      observers: [routeObserver],
      initialLocation: '/welcome',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final bool loggedIn = authProvider.isAuthenticated;
        final bool authRoute =
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!loggedIn) {
          return authRoute ? null : '/welcome';
        }

        if (loggedIn && authRoute) {
          return '/main';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/welcome',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WelcomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/main',
          pageBuilder: (context, state) {
            int initialIndex = 0;
            String? initialVideoPostId;
            if (state.extra is int) {
              initialIndex = state.extra as int;
            } else if (state.extra is Map<String, dynamic>) {
              final extra = state.extra as Map<String, dynamic>;
              initialIndex = extra['initialIndex'] is int
                  ? extra['initialIndex'] as int
                  : 0;
              initialVideoPostId = extra['videoPostId']?.toString();
            }
            return CustomTransitionPage(
              key: state.pageKey,
              child: MainScreen(
                initialIndex: initialIndex,
                initialVideoPostId: initialVideoPostId,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final heroTag = state.extra is String ? state.extra as String : null;
            return ProfileScreen(heroTag: heroTag);
          },
        ),
        GoRoute(
          path: '/user-profile/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final heroTag = state.extra is String ? state.extra as String : null;
            return UserProfileScreen(userId: userId, heroTag: heroTag);
          },
        ),
        GoRoute(
          path: '/followers/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserListScreen(userId: userId, type: 'followers');
          },
        ),
        GoRoute(
          path: '/following/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserListScreen(userId: userId, type: 'following');
          },
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            final otherUser = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{'id': '', 'name': 'مستخدم'};
            return ChatScreen(otherUser: otherUser);
          },
        ),
        GoRoute(
          path: '/group-info',
          builder: (context, state) {
            final group = state.extra as Map<String, dynamic>;
            return GroupInfoScreen(group: group);
          },
        ),
        GoRoute(
          path: '/direct-messages',
          builder: (context, state) => const DirectMessagesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/story-viewer',
          pageBuilder: (context, state) {
            if (state.extra is! Map<String, dynamic>) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const MainScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              );
            }
            final extra = state.extra as Map<String, dynamic>;
            final userWithStories = extra['userWithStories'];
            final initialIndex = extra['initialIndex'] as int? ?? 0;
            if (userWithStories is! UserStory) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const MainScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              );
            }
            return CustomTransitionPage(
              key: state.pageKey,
              child: StoryViewerScreen(
                userWithStories: userWithStories,
                initialIndex: initialIndex,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(0.0, 1.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOutQuart)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/post-details',
          pageBuilder: (context, state) {
            if (state.extra is! Post) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const MainScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              );
            }
            final post = state.extra as Post;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PostDetailsScreen(post: post),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOutQuart)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: '/create-post',
          pageBuilder: (context, state) {
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{};
            return CustomTransitionPage(
              key: state.pageKey,
              child: CreatePostScreen(extra: extra),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(0.0, 1.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOutQuart)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: '/create-story',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CreateStoryScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(
                        begin: const Offset(0.0, 1.0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeInOutQuart)),
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/create-live',
          builder: (context, state) => const CreateLiveScreen(),
        ),
        GoRoute(
          path: '/create-note',
          builder: (context, state) => const FeaturePlaceholderScreen(
            title: 'ملاحظة',
            subtitle: 'يمكنك قريبًا إنشاء ملاحظات سريعة.',
          ),
        ),
        GoRoute(
          path: '/ai-assistant',
          builder: (context, state) => const AIAssistantScreen(),
        ),
        GoRoute(
          path: '/incoming-call',
          builder: (context, state) {
            final callData = state.extra as Map<String, dynamic>;
            return IncomingCallScreen(callData: callData);
          },
        ),
        GoRoute(
          path: '/video-feed',
          builder: (context, state) {
            final videoPostId = state.extra as String?;
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              body: VideoFeedScreen(initialVideoPostId: videoPostId),
            );
          },
        ),
        GoRoute(
          path: '/call',
          builder: (context, state) {
            final callData = state.extra as Map<String, dynamic>;
            return CallScreen(callData: callData);
          },
        ),
      ],
    );
  }
}
