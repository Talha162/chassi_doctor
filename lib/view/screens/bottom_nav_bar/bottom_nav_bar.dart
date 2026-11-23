import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/view/widget/app_nav_bar.dart';
import 'package:motorsport/view/screens/home/home.dart';
import 'package:motorsport/view/screens/learning_hub/learning_hub.dart';
import 'package:motorsport/controller/settings/saved_setup_history_controller.dart';
import 'package:motorsport/view/screens/settings/saved_setup_history.dart';
import 'package:motorsport/view/screens/settings/settings.dart';
import 'package:motorsport/view/screens/subscriptions/access_gate.dart';

// ignore: must_be_immutable
class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _getCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      if (Get.isRegistered<SavedSetupHistoryController>()) {
        Get.find<SavedSetupHistoryController>().fetchSavedSetups();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      Home(),
      const LearningHub(showBackButton: false),
      SavedSetupHistory(),
      Settings(),
    ];

    return AccessGate(
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        // Tabs cross-fade with a slight rise instead of snapping.
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: screens[_currentIndex],
          ),
        ),
        bottomNavigationBar: AppNavBar(
          currentIndex: _currentIndex,
          onTap: _getCurrentIndex,
        ),
      ),
    );
  }
}

class ChildScreenBottomNav extends StatelessWidget {
  final int selectedIndex;

  const ChildScreenBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return AppNavBar(
      currentIndex: selectedIndex,
      onTap: (index) => Get.offAll(() => BottomNavBar(initialIndex: index)),
    );
  }
}
