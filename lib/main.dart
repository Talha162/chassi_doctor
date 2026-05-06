import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/theme/dark_theme.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'config/routes/routes.dart';
import 'config/theme/light_theme.dart';
import 'services/auth/auth_service.dart';
import 'services/notification_service.dart';

StreamSubscription<AuthState>? _authStateSubscription;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Background notification: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final themeController = Get.put(ThemeController());
  await themeController.loadTheme();

  await Supabase.initialize(
    url: 'https://pmhsmskjxywqtkyhdvgj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBtaHNtc2tqeHl3cXRreWhkdmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNzYwMDgsImV4cCI6MjA3Nzg1MjAwOH0.XnYxiYdzpfGsJxAnccRj8SqQkOKwo693YI8AaInL9Tg',
  );

  final authService = AuthService();
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    await authService.ensurePublicUserProfile(currentUser);
    await NotificationService.instance.init(userId: currentUser.id);
  }

  _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
    data,
  ) async {
    final event = data.event;
    final session = data.session;
    if (session?.user != null) {
      await authService.ensurePublicUserProfile(session!.user);
      await NotificationService.instance.init(userId: session!.user.id);
      if (event == AuthChangeEvent.passwordRecovery) {
        Get.offAllNamed(AppLinks.createNewPassword);
        return;
      }
      if (event == AuthChangeEvent.signedIn &&
          Get.currentRoute != AppLinks.bottomNavBar) {
        Get.offAllNamed(AppLinks.bottomNavBar);
      }
    } else {
      await NotificationService.instance.clearCurrentDeviceToken();
      if (event == AuthChangeEvent.signedOut &&
          Get.currentRoute != AppLinks.login &&
          Get.currentRoute != AppLinks.splash_screen) {
        Get.offAllNamed(AppLinks.login);
      }
    }
  });

  runApp(MyApp());
}

String dummyImg =
    'https://images.unsplash.com/photo-1597290282695-edc43d0e7129?q=80&w=2075&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        debugShowMaterialGrid: false,
        title: 'Chassis Doctor',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeController.themeMode.value,
        initialRoute: AppLinks.splash_screen,
        getPages: AppRoutes.pages,
        defaultTransition: Transition.fadeIn,
      ),
    );
  }
}
