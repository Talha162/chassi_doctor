import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_images.dart';
import '../../../services/access_policy.dart';
import '../../../services/subscription_service.dart';
import '../../widget/my_button_widget.dart';
import '../../widget/my_text_widget.dart';
import 'paywall_screen.dart';

/// Wraps the signed-in app. Shows the trial paywall, an "update required"
/// screen, or the app itself, depending on [AccessPolicy].
class AccessGate extends StatefulWidget {
  const AccessGate({super.key, required this.child});

  final Widget child;

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> with WidgetsBindingObserver {
  final _policy = AccessPolicy.instance;
  final _subs = SubscriptionService.instance;
  bool _timedOut = false;
  bool _loggingIn = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _policy.load();
    // Never leave someone on a spinner: after 20 s, let them in.
    _timer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _policy.load();
      _subs.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// RevenueCat must answer for the signed-in account, not an earlier one.
  void _ensureLoggedIn(SubscriptionState sub) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _loggingIn) return;
    if (!sub.isConfigured || sub.isLoading) return;
    if (_subs.activeUserId == user.id) return;
    _loggingIn = true;
    _subs.logIn(user.id).whenComplete(() => _loggingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppConfig?>(
      valueListenable: _policy.config,
      builder: (context, _, _) => ValueListenableBuilder<SubscriptionState>(
        valueListenable: _subs.state,
        builder: (context, sub, _) {
          var decision = _policy.decide(sub);
          if (decision == AccessDecision.loading) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _ensureLoggedIn(sub),
            );
            if (_timedOut) decision = AccessDecision.open;
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (decision) {
              AccessDecision.open => KeyedSubtree(
                key: const ValueKey('open'),
                child: widget.child,
              ),
              AccessDecision.paywall => const PaywallScreen(
                key: ValueKey('paywall'),
                gate: true,
              ),
              AccessDecision.updateRequired => const _UpdateRequired(
                key: ValueKey('update'),
              ),
              AccessDecision.loading => const _Loading(
                key: ValueKey('loading'),
              ),
            },
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(Assets.mainlogo, width: 96, height: 96),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: kSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateRequired extends StatelessWidget {
  const _UpdateRequired({super.key});

  static const _appStore = 'https://apps.apple.com/app/id6752336932';
  static const _playStore =
      'https://play.google.com/store/apps/details?id=com.chassisdoctor.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(Assets.mainlogo, width: 110, height: 110),
              ),
              const SizedBox(height: 28),
              MyText(
                text: 'Update required',
                size: 24,
                weight: FontWeight.w700,
                textAlign: TextAlign.center,
                color: kSecondaryColor,
              ),
              MyText(
                paddingTop: 12,
                text:
                    'A new version of Chassis Doctor is available. Please update to keep using the app.',
                size: 14,
                lineHeight: 1.5,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              MyButton(
                buttonText: Platform.isIOS
                    ? 'Update on the App Store'
                    : 'Update on Google Play',
                radius: 50,
                onTap: () => launchUrl(
                  Uri.parse(Platform.isIOS ? _appStore : _playStore),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
