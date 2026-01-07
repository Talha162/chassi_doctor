import 'package:get/get.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/screens/auth/sign_up/email_verification.dart';
import 'package:motorsport/view/screens/auth/sign_up/sign_up.dart';
import 'package:motorsport/view/screens/auth/sign_up/track_configuration.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/screens/home/home.dart';
import 'package:motorsport/view/screens/launch/onboarding.dart';
import 'package:motorsport/view/screens/launch/splash_screen.dart';

class AppRoutes {
  static final List<GetPage> pages = [
    GetPage(name: AppLinks.splash_screen, page: () => const SplashScreen()),
    GetPage(name: AppLinks.login, page: () => const Login()),
    GetPage(name: AppLinks.signUp, page: () => const SignUp()),
    GetPage(
        name: AppLinks.emailVerification,
        page: () => const EmailVerification()),
    GetPage(name: AppLinks.onboarding, page: () => const Onboarding()),
    GetPage(
        name: AppLinks.trackConfiguration,
        page: () => TrackConfiguration()),
    GetPage(name: AppLinks.bottomNavBar, page: () => BottomNavBar()),
    GetPage(name: AppLinks.home, page: () => const Home()),
  ];
}

class AppLinks {
  static const splash_screen = '/splash_screen';
  static const login = '/login';
  static const signUp = '/sign_up';
  static const emailVerification = '/email_verification';
  static const onboarding = '/onboarding';
  static const trackConfiguration = '/track_configuration';
  static const bottomNavBar = '/bottom_nav_bar';
  static const home = '/home';
}
