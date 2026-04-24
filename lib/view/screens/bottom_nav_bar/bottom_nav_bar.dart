import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/view/screens/home/home.dart';
import 'package:motorsport/view/screens/learning_hub/learning_hub.dart';
import 'package:motorsport/controller/settings/saved_setup_history_controller.dart';
import 'package:motorsport/view/screens/settings/saved_setup_history.dart';
import 'package:motorsport/view/screens/settings/settings.dart';

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
    final List<Map<String, dynamic>> items = [
      {'icon': Assets.imagesHome, 'label': 'Home'},
      {'icon': Assets.imagesCourses, 'label': 'Learning'},
      {'icon': Assets.imagesSave, 'label': 'History'},
      {'icon': Assets.imagesProfile, 'label': 'Profile'},
    ];

    final List<Widget> screens = [
      Home(),
      const LearningHub(showBackButton: false),
      SavedSetupHistory(),
      Settings(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: screens[_currentIndex],
      bottomNavigationBar: _buildNavBar(items),
    );
  }

  Widget _buildNavBar(List<Map<String, dynamic>> items) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: kPrimaryColor,
          border: Border(
            top: BorderSide(
              color: kTertiaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: kSecondaryColor,
          unselectedItemColor: kTertiaryColor.withValues(alpha: 0.6),
          currentIndex: _currentIndex,
          onTap: _getCurrentIndex,
          items: List.generate(items.length, (index) {
            final data = items[index];
            return BottomNavigationBarItem(
              icon: SizedBox(
                height: 32,
                width: 32,
                child: Center(
                  child: ImageIcon(AssetImage(data["icon"]), size: 24),
                ),
              ),
              label: data["label"],
            );
          }),
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
    final items = [
      {'icon': Assets.imagesHome, 'label': 'Home'},
      {'icon': Assets.imagesCourses, 'label': 'Learning'},
      {'icon': Assets.imagesSave, 'label': 'History'},
      {'icon': Assets.imagesProfile, 'label': 'Profile'},
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: kPrimaryColor,
          border: Border(
            top: BorderSide(
              color: kTertiaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: kSecondaryColor,
          unselectedItemColor: kTertiaryColor.withValues(alpha: 0.6),
          currentIndex: selectedIndex,
          onTap: (index) {
            Get.offAll(() => BottomNavBar(initialIndex: index));
          },
          items: List.generate(items.length, (index) {
            final data = items[index];
            return BottomNavigationBarItem(
              icon: SizedBox(
                height: 32,
                width: 32,
                child: Center(
                  child: ImageIcon(AssetImage(data["icon"]!), size: 24),
                ),
              ),
              label: data["label"],
            );
          }),
        ),
      ),
    );
  }
}
