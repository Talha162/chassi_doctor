import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/theme/dark_theme.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/view/bindings/auth_bindings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/routes/routes.dart';
import 'config/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = Get.put(ThemeController());
  await themeController.loadTheme();


  await Supabase.initialize(
    url: 'https://pmhsmskjxywqtkyhdvgj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBtaHNtc2tqeHl3cXRreWhkdmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNzYwMDgsImV4cCI6MjA3Nzg1MjAwOH0.XnYxiYdzpfGsJxAnccRj8SqQkOKwo693YI8AaInL9Tg',
  );

  runApp(MyApp());
}

//DO NOT REMOVE Unless you find their usage.
String dummyImg =
    'https://images.unsplash.com/photo-1597290282695-edc43d0e7129?q=80&w=2075&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

class MyApp extends StatelessWidget {
  @override

  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final ThemeController themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: 'Chassis Doctor',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeController.themeMode.value,
      initialRoute: AppLinks.splash_screen,
      getPages: AppRoutes.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}
