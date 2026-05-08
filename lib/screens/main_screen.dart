import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'home/feed_screen.dart';
import 'home/profile_screen.dart';
import 'home/video_feed_screen.dart';
import 'home/direct_messages_screen.dart';
import 'home/search_screen.dart';
import '../providers/music_provider.dart';
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
      label: 'الأصدقاء',
      active: FontAwesomeIcons.userGroup,
      inactive: FontAwesomeIcons.userGroup,
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
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    if (index == 3) {
      Provider.of<ChatProvider>(context, listen: false).clearUnreadNotifications();
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

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
        print('DEBUG: BACK PRESSED! Current index: $_currentIndex');
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
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).extension<CustomColors>()!.border,
                width: 0.6,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                children: List.generate(_navItems.length, (index) {
                  final isSelected = _currentIndex == index;
                  final colors = Theme.of(context).extension<CustomColors>()!;
                  final item = _navItems[index];

                  return Expanded(
                    child: InkWell(
                      onTap: () => _onItemTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutBack,
                              scale: isSelected ? 1.08 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    FaIcon(
                                      isSelected ? item.active : item.inactive,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : colors.textSecondary,
                                    ),
                                    if (index == 3 && chatProvider.unreadNotifications > 0)
                                      Positioned(
                                        right: -6,
                                        top: -6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isSelected ? colors.primary : colors.surface, width: 2),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 12,
                                            minHeight: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
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
