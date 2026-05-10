import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'home/feed_screen.dart';
import 'home/profile_screen.dart';
import 'home/video_feed_screen.dart';
import 'home/direct_messages_screen.dart';
import 'home/search_screen.dart';
import '../providers/chat_provider.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialVideoPostId;
  const MainScreen({super.key, this.initialIndex = 0, this.initialVideoPostId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  static const _navItems = [
    (
      label: 'الرئيسية',
      active: FontAwesomeIcons.houseChimney,
      inactive: FontAwesomeIcons.house,
    ),
    (
      label: 'البحث',
      active: FontAwesomeIcons.magnifyingGlass,
      inactive: FontAwesomeIcons.magnifyingGlass,
    ),
    (
      label: 'الفيديوهات',
      active: FontAwesomeIcons.solidCirclePlay,
      inactive: FontAwesomeIcons.circlePlay,
    ),
    (
      label: 'الدردشات',
      active: FontAwesomeIcons.solidCommentDots,
      inactive: FontAwesomeIcons.commentDots,
    ),
    (
      label: 'الملف الشخصي',
      active: FontAwesomeIcons.solidCircleUser,
      inactive: FontAwesomeIcons.circleUser,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initialIndex from the router is different from our CURRENT state, update it
    if (widget.initialIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    
    if (index == 3) {
      Provider.of<ChatProvider>(context, listen: false).clearUnreadNotifications();
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDark = themeProvider.isDarkMode;

    final screens = [
      const FeedScreen(),
      const SearchScreen(),
      VideoFeedScreen(initialVideoPostId: widget.initialVideoPostId),
      const DirectMessagesScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              top: BorderSide(
                color: colors.border.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(_navItems.length, (index) {
                  final isSelected = _currentIndex == index;
                  final item = _navItems[index];

                  return Expanded(
                    child: InkWell(
                      onTap: () => _onItemTapped(index),
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FaIcon(
                            isSelected ? item.active : item.inactive,
                            size: 24,
                            color: isSelected 
                                ? colors.text
                                : colors.textSecondary.withOpacity(0.5),
                          ),
                          if (index == 3 && chatProvider.unreadNotifications > 0)
                            Positioned(
                              top: 15,
                              right: 25,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 8,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
