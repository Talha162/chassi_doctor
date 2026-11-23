import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'subscription_service.dart';

/// Who may use the app right now. Driven by the `app_config` table, so the
/// paywall, grace period and minimum version change without a new release.
enum AccessDecision { loading, open, paywall, updateRequired }

class AppConfig {
  const AppConfig({
    this.hardPaywall = false,
    this.paywallSince,
    this.legacyGraceUntil,
    this.minBuild = 0,
  });

  /// The whole app needs All Access (a 3-day free trial first).
  final bool hardPaywall;

  /// Accounts created before this are existing users...
  final DateTime? paywallSince;

  /// ...who keep free access until this time.
  final DateTime? legacyGraceUntil;

  /// Builds below this must update before they can be used.
  final int minBuild;

  static AppConfig fromRows(List<dynamic> rows) {
    final v = {for (final r in rows) r['key'] as String: r['value']};
    final platform = Platform.isIOS ? 'ios' : 'android';
    DateTime? date(Object? x) =>
        x is String ? DateTime.tryParse(x)?.toUtc() : null;
    return AppConfig(
      hardPaywall: v['hard_paywall_$platform'] == true,
      paywallSince: date(v['paywall_since']),
      legacyGraceUntil: date(v['legacy_grace_until']),
      minBuild: (v['min_build_$platform'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccessPolicy {
  AccessPolicy._();
  static final AccessPolicy instance = AccessPolicy._();

  /// Null until loaded. If it can't be loaded the app stays open (fail open),
  /// so a network problem never locks out a paying member.
  final ValueNotifier<AppConfig?> config = ValueNotifier(null);
  int? _build;
  String? _role;
  String? _roleFor;
  bool _loading = false;

  int get currentBuild => _build ?? 0;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      _build ??= int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .timeout(const Duration(seconds: 10));
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && _roleFor != user.id) {
        final row = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        _role = row?['role'] as String?;
        _roleFor = user.id;
      }
      config.value = AppConfig.fromRows(rows as List<dynamic>);
    } catch (e) {
      debugPrint('App config could not be loaded: $e');
      config.value ??= const AppConfig();
    } finally {
      _loading = false;
    }
  }

  /// Free access left for an existing user, or null if none.
  DateTime? graceUntil(User user, AppConfig c) {
    final created = DateTime.tryParse(user.createdAt)?.toUtc();
    final since = c.paywallSince;
    final until = c.legacyGraceUntil;
    if (created == null || since == null || until == null) return null;
    if (!created.isBefore(since)) return null;
    return DateTime.now().toUtc().isBefore(until) ? until : null;
  }

  AccessDecision decide(SubscriptionState sub) {
    final c = config.value;
    if (c == null) return AccessDecision.loading;
    if (c.minBuild > 0 && _build != null && _build! < c.minBuild) {
      return AccessDecision.updateRequired;
    }
    if (!c.hardPaywall) return AccessDecision.open;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return AccessDecision.open;
    if (_role == 'admin' || _role == 'system_admin') return AccessDecision.open;
    if (graceUntil(user, c) != null) return AccessDecision.open;

    // Payments not set up on this platform yet (e.g. Android): stay open.
    if (!sub.isConfigured) {
      return SubscriptionService.instance.initAttempted
          ? AccessDecision.open
          : AccessDecision.loading;
    }
    if (sub.hasActiveSubscription) return AccessDecision.open;
    // Wait until RevenueCat has answered for *this* account.
    if (sub.customerInfo == null ||
        SubscriptionService.instance.activeUserId != user.id) {
      return AccessDecision.loading;
    }
    return AccessDecision.paywall;
  }
}
