// Screenshot tour: opens every screen of the app in both themes and prints
// `SHOT:<theme>_<name>` when each one is ready. A shell watcher captures the
// simulator at each marker (see scripts/screenshot_tour.sh).
//
// Signed-out screens always run. Signed-in screens run only when demo
// credentials are passed:
//   --dart-define=TOUR_EMAIL=... --dart-define=TOUR_PASSWORD=...
//
// This is a dev tool; it does not ship in the app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/main.dart' as app;
import 'package:motorsport/models/history_entry.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/forgot_pass.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/screens/auth/sign_up/email_verification.dart';
import 'package:motorsport/view/screens/auth/sign_up/sign_up.dart';
import 'package:motorsport/view/screens/auth/sign_up/track_configuration.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/screens/courses/all_courses.dart';
import 'package:motorsport/view/screens/courses/course_detail_screen.dart';
import 'package:motorsport/view/screens/courses/courses.dart';
import 'package:motorsport/view/screens/courses/module_video_screen.dart';
import 'package:motorsport/view/screens/courses/my_courses.dart';
import 'package:motorsport/view/screens/home/identify_issues.dart';
import 'package:motorsport/view/screens/home/setup_recommendation.dart';
import 'package:motorsport/view/screens/launch/onboarding.dart';
import 'package:motorsport/view/screens/launch/onboarding_slides.dart';
import 'package:motorsport/view/screens/notifications/notifications_screen.dart';
import 'package:motorsport/view/screens/settings/chassis_session_detail.dart';
import 'package:motorsport/view/screens/settings/edit_profile.dart';
import 'package:motorsport/view/screens/settings/privacy_policy.dart';
import 'package:motorsport/view/screens/subscriptions/paywall_screen.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/app_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _email = String.fromEnvironment('TOUR_EMAIL');
const _password = String.fromEnvironment('TOUR_PASSWORD');
const _onboardingOnly = bool.fromEnvironment('TOUR_ONBOARDING_ONLY');
const _validationOnly = bool.fromEnvironment('TOUR_VALIDATION_ONLY');
const _geometryStep = String.fromEnvironment('TOUR_GEOMETRY');
const _demo = bool.fromEnvironment('TOUR_DEMO');
const _sessionTheme = String.fromEnvironment('TOUR_SESSION');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('screenshot tour', (tester) async {
    // No push-permission alert covering the screenshots.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', false);

    await app.main();
    await _wait(tester, 4000);

    if (_demo) {
      await _demoWalkthrough(tester);
      print('TOUR_DONE');
      return;
    }

    if (_sessionTheme.isNotEmpty) {
      await _sessionFlow(tester, _sessionTheme);
      print('TOUR_DONE');
      return;
    }

    if (_geometryStep.isNotEmpty) {
      await _geometryFlow(tester, _geometryStep);
      print('TOUR_DONE');
      return;
    }

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      ThemeController.instance.setTheme(mode);
      final theme = mode == ThemeMode.light ? 'blue' : 'black';
      if (_validationOnly) {
        await _validationChecks(tester, theme);
        continue;
      }
      if (_onboardingOnly) {
        await _onboardingWalkthrough(tester, theme);
        continue;
      }
      await _signedOutScreens(tester, theme);
      if (_email.isNotEmpty) {
        await _signedInScreens(tester, theme, prefs);
      }
    }

    ThemeController.instance.setTheme(ThemeMode.light);
    await prefs.remove('push_notifications_enabled');
    print('TOUR_DONE');
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Future<void> _signedOutScreens(WidgetTester t, String theme) async {
  if (Supabase.instance.client.auth.currentSession != null) {
    await Supabase.instance.client.auth.signOut();
    await _wait(t, 1500);
  }
  await _open(t, theme, 'login', () => Get.offAll(() => const Login()));
  await _open(t, theme, 'signup', () => Get.offAll(() => const SignUp()));
  await _open(
    t,
    theme,
    'forgot_password',
    () => Get.offAll(() => const ForgotPassword()),
  );
  await _open(
    t,
    theme,
    'email_verification',
    () => Get.offAll(() => const EmailVerification(email: 'alex@example.com')),
  );
  await _onboardingWalkthrough(t, theme);
}

Future<void> _signedInScreens(
  WidgetTester t,
  String theme,
  SharedPreferences prefs,
) async {
  final auth = Supabase.instance.client.auth;
  await auth.signInWithPassword(email: _email, password: _password);
  await _wait(t, 2500);
  final userId = auth.currentUser!.id;
  final service = SupabaseService.instance;

  // Mirror what Track Configuration stores locally, so Home shows car type.
  final config = await service.getLatestTrackConfigurationForUser(userId);
  await prefs.setString(
    'track_circuit_name',
    config?.circuitName ?? 'Brands Hatch',
  );
  await prefs.setString('engine_position', config?.enginePosition ?? 'Front');
  await prefs.setString('aerofoils', config?.aerofoils ?? 'No');
  await prefs.setString('drive_type', config?.driveType ?? 'RWD');

  await _open(t, theme, 'home', () => Get.offAll(() => const BottomNavBar()));
  // --- Setup Help flow ---
  await _open(
    t,
    theme,
    'symptoms',
    () => Get.offAll(() => const IdentifyIssues()),
  );
  final symptoms = await service.getChassisSymptoms();
  final oversteer = symptoms.firstWhere(
    (s) => s.title.toLowerCase() == 'oversteer',
    orElse: () => symptoms.first,
  );
  await _open(
    t,
    theme,
    'corner_phase',
    () => Get.to(() => SetupRecommendation(symptom: oversteer)),
  );
  final entry = find.text('Corner Entry');
  if (entry.evaluate().isNotEmpty) {
    await t.tap(entry.first);
    await _wait(t, 600);
    await _shot(t, theme, 'corner_phase_selected');
    final go = find.text('Recommend Adjustments');
    await t.ensureVisible(go.first);
    await _wait(t, 500);
    await t.tap(go.first);
    await _wait(t, 5000);
    final heading = find.text('Recommended Adjustment');
    if (heading.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(
        heading.evaluate().first,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
      );
      await _wait(t, 1200);
    }
    await _shot(t, theme, 'recommendations');
  }

  // --- History ---
  final sessions = await service.getChassisSessionsForUser(userId);
  if (sessions.isNotEmpty) {
    final s = sessions.first;
    final entry = HistoryEntry(
      id: s.id,
      createdAt: s.createdAt,
      trackSnapshot: s.trackSnapshot,
      symptomSnapshot: s.symptomSnapshot,
      issuesSnapshot: s.issuesSnapshot,
      recommendations: s.recommendations,
      hasSessionData: true,
    );
    await _open(
      t,
      theme,
      'session_detail',
      () => Get.to(() => ChassisSessionDetail(session: entry)),
    );
  }

  await _open(
    t,
    theme,
    'tab_learning',
    () => Get.offAll(() => const BottomNavBar(initialIndex: 1)),
  );
  await _open(
    t,
    theme,
    'tab_history',
    wait: 6000,
    () => Get.offAll(() => const BottomNavBar(initialIndex: 2)),
  );
  await _open(
    t,
    theme,
    'tab_profile',
    () => Get.offAll(() => const BottomNavBar(initialIndex: 3)),
  );
  await _open(
    t,
    theme,
    'track_configuration',
    wait: 6000,
    () => Get.to(() => TrackConfiguration()),
  );

  // --- Learning ---
  await _open(
    t,
    theme,
    'courses',
    () => Get.offAll(() => const Courses(showBackButton: true)),
  );
  await _open(t, theme, 'all_courses', () => Get.to(() => const AllCourses()));
  await _open(t, theme, 'my_courses', () => Get.to(() => const MyCourses()));
  final courses = await service.getPublishedCourses();
  if (courses.isNotEmpty) {
    final course = courses.first;
    await _open(
      t,
      theme,
      'course_detail',
      () => Get.to(() => CourseDetailScreen(course: course)),
    );
    final modules = await service.getModulesForCourse(course.id);
    if (modules.isNotEmpty) {
      await _open(
        t,
        theme,
        'module_videos',
        () => Get.to(
          () => ModuleVideosScreen(course: course, module: modules.first),
        ),
      );
    }
  }
  await _open(
    t,
    theme,
    'paywall',
    () => Get.to(() => const PaywallScreen(sourceLabel: 'Learning Hub')),
  );

  // --- Profile sub-screens ---
  await _open(
    t,
    theme,
    'edit_profile',
    () => Get.offAll(() => const EditProfile()),
  );
  await _open(
    t,
    theme,
    'notifications',
    () => Get.to(() => const NotificationsScreen()),
  );
  await _open(
    t,
    theme,
    'privacy_policy',
    () => Get.to(() => const PrivacyPolicy()),
  );

  await auth.signOut();
  await _wait(t, 1500);
}

/// Screen-recorded product walkthrough (scripts/record_demo.sh). Natural pacing:
/// every screen is given time to animate in and be read.
Future<void> _demoWalkthrough(WidgetTester t) async {
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) {
    await auth.signOut();
  }
  ThemeController.instance.setTheme(ThemeMode.light);
  Get.offAll(() => const Login());
  await _wait(t, 2500);

  Future<void> pause([int ms = 1400]) => _wait(t, ms);

  // Taps and swipes are sent as ordinary device events, so the recording
  // has no test-runner crosshairs over the app.
  final binding = WidgetsBinding.instance as LiveTestWidgetsFlutterBinding;
  binding.shouldPropagateDevicePointerEvents = true;
  var pointerId = 900;
  void send(PointerEvent e) =>
      binding.handlePointerEventForSource(e, source: TestBindingEventSource.device);

  Future<void> tapAt(Offset p) async {
    final id = ++pointerId;
    send(PointerDownEvent(pointer: id, position: p));
    await _wait(t, 90);
    send(PointerUpEvent(pointer: id, position: p));
  }

  Future<void> tap(Finder f, {int after = 1600}) async {
    await t.ensureVisible(f.first);
    await _wait(t, 350);
    await tapAt(t.getCenter(f.first));
    await _wait(t, after);
  }

  Finder button(String text) {
    final inButton = find.descendant(of: find.byType(MyButton), matching: find.text(text));
    return inButton.evaluate().isNotEmpty ? inButton : find.text(text);
  }

  Future<void> scroll(double dy, {int ms = 1100, Finder? on}) async {
    final target = on ?? find.byType(Scrollable).first;
    if (target.evaluate().isEmpty) return;
    final start = t.getCenter(target.first);
    final id = ++pointerId;
    const steps = 30;
    send(PointerDownEvent(pointer: id, position: start));
    for (var i = 1; i <= steps; i++) {
      // Ease-in-out so the swipe looks like a finger, not a jump.
      final x = i / steps;
      final eased = x < 0.5 ? 2 * x * x : 1 - 2 * (1 - x) * (1 - x);
      await _wait(t, ms ~/ steps);
      send(PointerMoveEvent(
        pointer: id,
        position: start + Offset(0, dy * eased),
        delta: Offset(0, dy / steps),
      ));
    }
    send(PointerUpEvent(pointer: id, position: start + Offset(0, dy)));
    await _wait(t, 900);
  }

  Finder navTab(int i) => find
      .descendant(of: find.byType(AppNavBar), matching: find.byType(GestureDetector))
      .at(i);

  Future<void> typeSlowly(Finder field, String text) async {
    for (var i = 1; i <= text.length; i += 3) {
      await t.enterText(field, text.substring(0, i.clamp(0, text.length)));
      await _wait(t, 60);
    }
    await t.enterText(field, text);
    await _wait(t, 300);
  }

  print('DEMO_START');
  await pause(1500);

  // ── 1. Sign in: validation, then log in ──
  await tap(button('Login'), after: 2200); // empty → inline messages
  await typeSlowly(find.byType(TextFormField).at(0), _email);
  await typeSlowly(find.byType(TextFormField).at(1), _password);
  await pause(700);
  await tap(button('Login'), after: 3500);

  // ── 2. First-run onboarding (shown after sign-up) ──
  Get.offAll(() => const Onboarding());
  await _wait(t, 5200);
  for (var i = 0; i < onboardingSlides.length - 1; i++) {
    await tap(find.text('Next'), after: 5200);
  }
  await tap(find.text('Set up my car'), after: 3200);

  // ── 3. Track configuration → Home ──
  await scroll(-500, ms: 1400);
  await scroll(-500, ms: 1400);
  await pause(800);
  await tap(find.text('Save Track & Car Setup'), after: 4000);

  // ── 4. Home ──
  await scroll(-420, ms: 1200);
  await pause(1200);
  await scroll(420, ms: 1000);

  // ── 5. Setup Help ──
  await tap(find.text('Setup Help'), after: 3200);
  await tap(find.text('Oversteer'), after: 3500);
  await tap(find.text('Corner Entry'), after: 1300);
  await tap(find.text('Mid Corner'), after: 1300);
  await tap(find.text('Recommend Adjustments'), after: 4500);
  final heading = find.text('Recommended Adjustment');
  if (heading.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(heading.evaluate().first,
        alignment: 0.0, duration: const Duration(milliseconds: 900));
    await pause(1800);
    await scroll(-650, ms: 1800);
    await pause(1200);
  }
  // Save to session, then straight to History.
  if (find.text('Save to session').evaluate().isEmpty) {
    await scroll(-500, ms: 1200);
  }
  await tap(find.text('Save to session'), after: 1600);
  final sessionFields = find.byType(TextFormField);
  await tap(find.text('Qualifying'), after: 900);
  await typeSlowly(sessionFields.at(2), 'Rear ARB one step softer. Car rotates mid-corner.');
  await pause(900);
  await tap(find.text('Save session'), after: 3600);
  await tap(find.text('View in History'), after: 3400);

  // ── 6. Tabs: Learning, History (+ session), Profile ──
  await tap(navTab(1), after: 3000);
  await scroll(-450, ms: 1300);
  await scroll(450, ms: 900);
  await tap(button('View'), after: 3200);
  await scroll(-500, ms: 1400);
  await pause(800);
  await tap(find.byType(AppBackButton), after: 2000);
  await tap(navTab(3), after: 3000);
  await tap(navTab(0), after: 2500);

  // ── 7. Geometry Tools ──
  await tap(find.text('Geometry Tools'), after: 3200);
  await tap(find.text('IFS Roll Centre Calculator'), after: 5500);
  await tap(find.text('Save setup'), after: 1500);
  final fields = find.byType(TextFormField);
  await typeSlowly(fields.at(0), 'Lydden Hill – race 2');
  await typeSlowly(fields.at(1), 'Lydden Hill');
  await typeSlowly(fields.at(2), 'Front RC raised 10 mm. Better turn-in.');
  await pause(900);
  await tap(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Save setup')),
      after: 3800);
  await tap(find.text('My setups'), after: 3200);
  final web = find.text('Snetterton – wet');
  if (web.evaluate().isNotEmpty) {
    final load = find.descendant(
      of: find.ancestor(of: web.first, matching: find.byType(Container)).first,
      matching: find.text('Load'),
    );
    await tap(load.evaluate().isNotEmpty ? load : find.text('Load'), after: 4500);
  } else {
    await tapAt(const Offset(200, 120));
    await pause(1500);
  }
  await tap(find.byType(AppBackButton), after: 2500);
  await scroll(-400, ms: 1200);
  await pause(1500);
  await tap(find.byType(AppBackButton), after: 2200);

  // ── 8. Black theme ──
  await tap(navTab(3), after: 2500);
  await tap(find.text('Switch to Dark Theme'), after: 2500);
  await tap(navTab(0), after: 3000);
  await scroll(-420, ms: 1200);
  await scroll(420, ms: 1000);
  await tap(find.text('Geometry Tools'), after: 3500);
  await tap(find.byType(AppBackButton), after: 1800);
  await tap(navTab(1), after: 2500);
  await tap(navTab(2), after: 2500);
  await tap(navTab(0), after: 3000);

  print('DEMO_END');
  await pause(800);
  binding.shouldPropagateDevicePointerEvents = false;
  if (ThemeController.instance.isDarkMode) {
    await ThemeController.instance.toggleTheme(); // leave the app in Blue
  }
}

/// Cross-platform check of saved geometry setups (watch it on the simulator).
/// step 'save': open the hub, open Roll Centre, save a setup.
/// step 'open': open the hub and load the newest setup (saved from the website).
Future<void> _geometryFlow(WidgetTester t, String step) async {
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    await auth.signInWithPassword(email: _email, password: _password);
    await _wait(t, 2500);
  }
  Get.offAll(() => const BottomNavBar());
  await _wait(t, 3000);
  await _shot(t, 'geo', '${step}_1_home');
  final card = find.text('Geometry Tools');
  await t.ensureVisible(card.first);
  await _wait(t, 900);
  await t.tap(card.first, warnIfMissed: false);
  await _wait(t, 3500);
  await _shot(t, 'geo', '${step}_2_hub');

  if (step == 'save') {
    await t.tap(find.text('IFS Roll Centre Calculator').first);
    await _wait(t, 6000);
    await _shot(t, 'geo', 'save_3_calculator');
    await t.tap(find.text('Save setup').last);
    await _wait(t, 1500);
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Brands Hatch – qualifying');
    await t.enterText(fields.at(1), 'Brands Hatch');
    await t.enterText(fields.at(2), 'Dry, 18°C. Softer front ARB felt better on turn-in.');
    await _wait(t, 800);
    await _shot(t, 'geo', 'save_4_form');
    await t.tap(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Save setup')));
    await _wait(t, 3500);
    await _shot(t, 'geo', 'save_5_saved');
    await t.tap(find.text('My setups').last);
    await _wait(t, 3000);
    await _shot(t, 'geo', 'save_6_my_setups');
  } else {
    // Newest setup first (the one just saved on the website).
    await t.ensureVisible(find.text('Recent setups'));
    await _wait(t, 900);
    await _shot(t, 'geo', 'open_3_recent');
    await t.ensureVisible(find.text('Snetterton – wet').first);
    await _wait(t, 900);
    await t.tap(find.text('Snetterton – wet').first, warnIfMissed: false);
    await _wait(t, 6000);
    await _shot(t, 'geo', 'open_4_loaded');
    await t.tap(find.text('My setups').last);
    await _wait(t, 3000);
    await _shot(t, 'geo', 'open_5_my_setups');
  }
  await _wait(t, 2000);
}

Future<void> _validationChecks(WidgetTester t, String theme) async {
  if (Supabase.instance.client.auth.currentSession != null) {
    await Supabase.instance.client.auth.signOut();
    await _wait(t, 1500);
  }
  Finder field(int i) => find.byType(TextFormField).at(i);
  Future<void> tapText(String text) async {
    // Prefer a button with this label over a same-named title.
    final inButton = find.descendant(
      of: find.byType(MyButton),
      matching: find.text(text),
    );
    final f = inButton.evaluate().isNotEmpty ? inButton : find.text(text);
    await t.ensureVisible(f.last);
    await t.tap(f.last);
    await _wait(t, 1800);
  }

  // ── Login ──
  Get.offAll(() => const Login());
  await _wait(t, 2500);
  await tapText('Login');
  await _shot(t, theme, 'val_login_empty');
  await t.enterText(field(0), 'alex@');
  await t.enterText(field(1), 'x');
  await _wait(t, 800);
  await _shot(t, theme, 'val_login_bad_email');
  await t.enterText(field(0), _email.isEmpty ? 'nobody@example.com' : _email);
  await t.enterText(field(1), 'WrongPass123');
  await tapText('Login');
  await _wait(t, 2500);
  await _shot(t, theme, 'val_login_wrong_password');

  // ── Sign up ──
  Get.offAll(() => const SignUp());
  await _wait(t, 2500);
  await tapText('Sign Up');
  await _shot(t, theme, 'val_signup_empty');
  await t.enterText(field(0), 'A');
  await t.enterText(field(1), 'alex@example');
  await t.enterText(field(2), 'short');
  await t.enterText(field(3), 'different');
  await _wait(t, 800);
  await _shot(t, theme, 'val_signup_invalid');
  if (_email.isNotEmpty) {
    await t.enterText(field(0), 'Alex Turner');
    await t.enterText(field(1), _email);
    await t.enterText(field(2), 'Racing2026');
    await t.enterText(field(3), 'Racing2026');
    await tapText('Sign Up');
    await _wait(t, 2500);
    await _shot(t, theme, 'val_signup_existing');
  }

  // ── Forgot password ──
  Get.offAll(() => const ForgotPassword());
  await _wait(t, 2500);
  await tapText('Send Reset Link');
  await _shot(t, theme, 'val_forgot_empty');

  if (_email.isEmpty) return;

  // ── Signed-in forms ──
  await Supabase.instance.client.auth
      .signInWithPassword(email: _email, password: _password);
  await _wait(t, 2500);
  Get.offAll(() => const IdentifyIssues());
  await _wait(t, 3000);
  await tapText('Report a New Symptom');
  await _wait(t, 800);
  await tapText('Submit');
  await _shot(t, theme, 'val_report_empty');
  await tapText('Cancel');

  Get.offAll(() => const EditProfile());
  await _wait(t, 3000);
  final phone = find.byType(TextFormField).last;
  await t.enterText(phone, '12ab');
  await tapText('Save Changes');
  await _shot(t, theme, 'val_profile_bad_phone');
  await t.enterText(phone, '');
  await _wait(t, 500);

  await Supabase.instance.client.auth.signOut();
  await _wait(t, 1500);
}

Future<void> _onboardingWalkthrough(WidgetTester t, String theme) async {
  Get.offAll(() => const Onboarding());
  for (var i = 0; i < onboardingSlides.length; i++) {
    // Mid-animation frame, then the settled slide.
    await _wait(t, 900);
    await _shot(t, theme, 'onb_${i + 1}_mid');
    await _wait(t, 3600);
    await _shot(t, theme, 'onb_${i + 1}');
    final next = find.text('Next');
    if (next.evaluate().isNotEmpty) {
      await t.tap(next.first);
    }
  }
}

Future<void> _open(
  WidgetTester t,
  String theme,
  String name,
  void Function() navigate, {
  int wait = 3500, // data loads + entrance animations
}) async {
  navigate();
  await _wait(t, wait);
  await _shot(t, theme, name);
}

Future<void> _shot(WidgetTester t, String theme, String name) async {
  print('SHOT:${theme}_$name');
  await _wait(t, 1800); // watcher captures the simulator meanwhile
}

Future<void> _wait(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// Setup Help → recommendations → leave prompt → Save to session → History.
Future<void> _sessionFlow(WidgetTester t, String theme) async {
  ThemeController.instance.setTheme(
    theme == 'black' ? ThemeMode.dark : ThemeMode.light,
  );
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    await auth.signInWithPassword(email: _email, password: _password);
  }
  Get.offAll(() => const BottomNavBar());
  await _wait(t, 3500);

  Future<void> tap(Finder f, {int after = 1800}) async {
    await t.ensureVisible(f.first);
    await _wait(t, 300);
    await t.tap(f.first, warnIfMissed: false);
    await _wait(t, after);
  }

  await tap(find.text('Setup Help'), after: 3000);
  await tap(find.text('Oversteer'), after: 3500);
  await tap(find.text('Corner Entry'), after: 900);
  await tap(find.text('Mid Corner'), after: 900);
  await tap(find.text('Recommend Adjustments'), after: 4500);
  await t.scrollUntilVisible(
    find.text('Save to session'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await _wait(t, 600);
  await t.ensureVisible(find.text('Save to session').first);
  await _wait(t, 1200);
  await _shot(t, theme, 'sess_1_panel');

  // Back without saving → prompt.
  await tap(find.byType(AppBackButton), after: 1500);
  await _shot(t, theme, 'sess_2_leave_prompt');
  await tap(find.text('Save to session').last, after: 1800);
  await _shot(t, theme, 'sess_3_sheet');

  // Empty name → validation.
  await tap(find.text('Save session'), after: 1200);
  await _shot(t, theme, 'sess_4_validation');

  await tap(find.text('Race 1'), after: 600);
  await t.enterText(find.byType(TextFormField).at(2), 'Rear ARB one step softer. Better rotation mid-corner.');
  await _wait(t, 600);
  FocusManager.instance.primaryFocus?.unfocus();
  await _wait(t, 800);
  await _shot(t, theme, 'sess_5_filled');
  await tap(find.text('Save session'), after: 3500);
  await _shot(t, theme, 'sess_6_saved');

  await tap(find.text('View in History'), after: 3800);
  await _shot(t, theme, 'sess_7_history');
  final view = find.descendant(of: find.byType(MyButton), matching: find.text('View'));
  await tap(view, after: 3200);
  await _shot(t, theme, 'sess_8_detail');
}
