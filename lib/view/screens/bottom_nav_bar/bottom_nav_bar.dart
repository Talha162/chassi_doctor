import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/view/screens/geometry/geometry.dart';
import 'package:motorsport/view/screens/settings/settings.dart';

// ignore: must_be_immutable
class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  void _getCurrentIndex(int index) => setState(() {
    _currentIndex = index;
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _items = [
      {'icon': Assets.imagesHome, 'label': 'Home'},
      {'icon': Assets.imagesLearn, 'label': 'Learn'},
      {'icon': Assets.imagesCourses, 'label': 'Courses'},
      {'icon': Assets.imagesGeometry, 'label': 'Geometry'},
      {'icon': Assets.imagesProfile, 'label': 'Profile'},
    ];

    final List<Widget> _screens = [
      Container(),
      Container(),
      Container(),
      Geometry(),
      Settings(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildNavBar(_items),
    );
  }

  Container _buildNavBar(List<Map<String, dynamic>> _items) {
    return Container(
      height: Platform.isIOS ? null : 65,
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
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.transparent,
        selectedItemColor: kSecondaryColor,
        unselectedItemColor: kTertiaryColor.withValues(alpha: 0.6),
        currentIndex: _currentIndex,
        onTap: (index) => _getCurrentIndex(index),
        items: List.generate(_items.length, (index) {
          var data = _items[index];
          return BottomNavigationBarItem(
            icon: Container(
              margin: EdgeInsets.only(bottom: 2),
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
    );
  }
}
