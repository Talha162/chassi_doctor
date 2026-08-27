import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';

class SubscriptionPreviewPlan {
  const SubscriptionPreviewPlan({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.ctaLabel,
    required this.billingLabel,
    this.badge,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String ctaLabel;
  final String billingLabel;
  final String? badge;
}

class SubscriptionState {
  const SubscriptionState({
    required this.isConfigured,
    required this.isLoading,
    required this.hasActiveSubscription,
    required this.offerings,
    required this.customerInfo,
    required this.previewPlans,
    required this.trialEligibility,
    this.errorMessage,
    this.debugMessage,
  });

  final bool isConfigured;
  final bool isLoading;
  final bool hasActiveSubscription;
  final Offerings? offerings;
  final CustomerInfo? customerInfo;
  final List<SubscriptionPreviewPlan> previewPlans;
  final Map<String, bool> trialEligibility;
  final String? errorMessage;
  final String? debugMessage;

  bool get hasLivePackages =>
      offerings?.current?.availablePackages.any(_isSupportedPackage) ?? false;

  static bool _isSupportedPackage(Package package) {
    return package.packageType == PackageType.monthly ||
        package.packageType == PackageType.annual;
  }

  SubscriptionState copyWith({
    bool? isConfigured,
    bool? isLoading,
    bool? hasActiveSubscription,
    Offerings? offerings,
    CustomerInfo? customerInfo,
    List<SubscriptionPreviewPlan>? previewPlans,
    Map<String, bool>? trialEligibility,
    String? errorMessage,
    String? debugMessage,
    bool clearErrorMessage = false,
    bool clearDebugMessage = false,
  }) {
    return SubscriptionState(
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      offerings: offerings ?? this.offerings,
      customerInfo: customerInfo ?? this.customerInfo,
      previewPlans: previewPlans ?? this.previewPlans,
      trialEligibility: trialEligibility ?? this.trialEligibility,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      debugMessage: clearDebugMessage
          ? null
          : (debugMessage ?? this.debugMessage),
    );
  }

  factory SubscriptionState.initial() {
    return const SubscriptionState(
      isConfigured: false,
      isLoading: false,
      hasActiveSubscription: false,
      offerings: null,
      customerInfo: null,
      previewPlans: [
        SubscriptionPreviewPlan(
          id: 'monthly_preview',
          title: 'All Access Monthly',
          priceLabel: 'GBP 7.99',
          ctaLabel: 'Start 3-day free trial',
          billingLabel: 'Then GBP 7.99 per month',
        ),
        SubscriptionPreviewPlan(
          id: 'annual_preview',
          title: 'All Access Yearly',
          priceLabel: 'GBP 69.99',
          ctaLabel: 'Start 3-day free trial',
          billingLabel: 'Then GBP 69.99 per year',
          badge: 'Best value',
        ),
      ],
      trialEligibility: {},
      errorMessage: null,
      debugMessage: null,
    );
  }
}

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final ValueNotifier<SubscriptionState> state = ValueNotifier(
    SubscriptionState.initial(),
  );

  Future<void>? _initializationFuture;
  CustomerInfoUpdateListener? _customerInfoUpdateListener;

  bool get hasActiveSubscription => state.value.hasActiveSubscription;

  Future<void> initialize({String? appUserId}) async {
    if (state.value.isConfigured) {
      await refresh();
      return;
    }

    final initializationFuture = _initializationFuture;
    if (initializationFuture != null) {
      await initializationFuture;
      return;
    }

    final future = _initializeSdk(appUserId: appUserId);
    _initializationFuture = future;
    try {
      await future;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initializeSdk({String? appUserId}) async {
    final apiKey = _platformApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      state.value = state.value.copyWith(
        debugMessage:
            'RevenueCat public SDK key is still missing for this platform.',
      );
      return;
    }

    var sdkConfigured = false;
    try {
      state.value = state.value.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      );

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId;

      await Purchases.configure(configuration);
      sdkConfigured = true;
      state.value = state.value.copyWith(
        isConfigured: true,
        clearDebugMessage: true,
      );
      if (_customerInfoUpdateListener != null) {
        Purchases.removeCustomerInfoUpdateListener(
          _customerInfoUpdateListener!,
        );
      }
      _customerInfoUpdateListener = _handleCustomerInfoUpdate;
      Purchases.addCustomerInfoUpdateListener(_customerInfoUpdateListener!);

      final customerInfo = await Purchases.getCustomerInfo();
      final offerings = await Purchases.getOfferings();
      final trialEligibility = await _trialEligibilityFor(offerings);
      state.value = state.value.copyWith(
        isConfigured: true,
        isLoading: false,
        offerings: offerings,
        customerInfo: customerInfo,
        trialEligibility: trialEligibility,
        hasActiveSubscription: _hasEntitlement(customerInfo),
        clearDebugMessage: true,
      );
    } catch (e) {
      debugPrint('RevenueCat initialization failed: $e');
      state.value = state.value.copyWith(
        isConfigured: sdkConfigured,
        isLoading: false,
        errorMessage: sdkConfigured
            ? 'Subscriptions are temporarily unavailable. Please try again later.'
            : 'Payments could not be started. Please try again later.',
      );
    }
  }

  Future<void> refresh() async {
    if (!state.value.isConfigured) {
      return;
    }

    try {
      state.value = state.value.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      );
      final customerInfo = await Purchases.getCustomerInfo();
      final offerings = await Purchases.getOfferings();
      final trialEligibility = await _trialEligibilityFor(offerings);
      state.value = state.value.copyWith(
        isLoading: false,
        offerings: offerings,
        customerInfo: customerInfo,
        trialEligibility: trialEligibility,
        hasActiveSubscription: _hasEntitlement(customerInfo),
      );
    } catch (e) {
      debugPrint('RevenueCat refresh failed: $e');
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage:
            'Subscriptions are temporarily unavailable. Please try again later.',
      );
    }
  }

  Future<void> logIn(String appUserId) async {
    if (!state.value.isConfigured) {
      return;
    }

    try {
      state.value = state.value.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      );
      final result = await Purchases.logIn(appUserId);
      state.value = state.value.copyWith(
        isLoading: false,
        customerInfo: result.customerInfo,
        hasActiveSubscription: _hasEntitlement(result.customerInfo),
      );
      await refresh();
    } catch (e) {
      debugPrint('RevenueCat login failed: $e');
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage:
            'Your subscription profile could not be refreshed. Please try again.',
      );
    }
  }

  Future<void> logOut() async {
    if (!state.value.isConfigured) {
      state.value = state.value.copyWith(hasActiveSubscription: false);
      return;
    }

    try {
      await Purchases.logOut();
      state.value = state.value.copyWith(
        customerInfo: null,
        hasActiveSubscription: false,
      );
      await refresh();
    } catch (e) {
      debugPrint('RevenueCat logout failed: $e');
      state.value = state.value.copyWith(
        errorMessage:
            'Your subscription session could not be reset. Please try again.',
      );
    }
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!state.value.isConfigured) {
      state.value = state.value.copyWith(
        errorMessage:
            'RevenueCat is not configured yet. Add the public SDK key first.',
      );
      return null;
    }

    try {
      state.value = state.value.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      );
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final customerInfo = purchaseResult.customerInfo;
      state.value = state.value.copyWith(
        isLoading: false,
        customerInfo: customerInfo,
        hasActiveSubscription: _hasEntitlement(customerInfo),
      );
      return customerInfo;
    } on Exception catch (e) {
      debugPrint('RevenueCat purchase failed: $e');
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: 'The purchase was not completed. Please try again.',
      );
      return null;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!state.value.isConfigured) {
      state.value = state.value.copyWith(
        errorMessage:
            'RevenueCat is not configured yet. Add the public SDK key first.',
      );
      return null;
    }

    try {
      state.value = state.value.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      );
      final customerInfo = await Purchases.restorePurchases();
      state.value = state.value.copyWith(
        isLoading: false,
        customerInfo: customerInfo,
        hasActiveSubscription: _hasEntitlement(customerInfo),
      );
      return customerInfo;
    } catch (e) {
      debugPrint('RevenueCat restore failed: $e');
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: 'Purchases could not be restored. Please try again.',
      );
      return null;
    }
  }

  List<Package> get currentPackages {
    final packages = state.value.offerings?.current?.availablePackages;
    if (packages == null || packages.isEmpty) {
      return const [];
    }

    final sorted = packages
        .where(SubscriptionState._isSupportedPackage)
        .toList();
    sorted.sort(
      (a, b) => _sortOrder(a.packageType).compareTo(_sortOrder(b.packageType)),
    );
    return sorted;
  }

  bool isTrialEligible(Package package) {
    return state.value.trialEligibility[package.storeProduct.identifier] ??
        false;
  }

  String get missingKeysMessage {
    if (Platform.isIOS) {
      return 'Provide the RevenueCat iOS public SDK key that starts with appl_.';
    }
    if (Platform.isAndroid) {
      return 'Provide the RevenueCat Android public SDK key that starts with goog_.';
    }
    return 'Provide the RevenueCat public SDK key for the active platform.';
  }

  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    state.value = state.value.copyWith(
      customerInfo: customerInfo,
      hasActiveSubscription: _hasEntitlement(customerInfo),
      clearErrorMessage: true,
    );
  }

  bool _hasEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(
      RevenueCatConfig.entitlementId,
    );
  }

  String? get _platformApiKey {
    if (Platform.isIOS) {
      return RevenueCatConfig.iosPublicSdkKey;
    }
    if (Platform.isAndroid) {
      return RevenueCatConfig.androidPublicSdkKey;
    }
    return null;
  }

  int _sortOrder(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return 0;
      case PackageType.annual:
        return 1;
      default:
        return 2;
    }
  }

  Future<Map<String, bool>> _trialEligibilityFor(Offerings offerings) async {
    final packages =
        offerings.current?.availablePackages
            .where(SubscriptionState._isSupportedPackage)
            .toList() ??
        const <Package>[];
    if (packages.isEmpty) return const {};

    if (!Platform.isIOS) {
      return {
        for (final package in packages)
          package.storeProduct.identifier:
              package.storeProduct.introductoryPrice?.price == 0,
      };
    }

    try {
      final productIds = packages
          .map((package) => package.storeProduct.identifier)
          .toList();
      final eligibility =
          await Purchases.checkTrialOrIntroductoryPriceEligibility(productIds);
      return {
        for (final productId in productIds)
          productId:
              eligibility[productId]?.status ==
              IntroEligibilityStatus.introEligibilityStatusEligible,
      };
    } catch (e) {
      debugPrint('Trial eligibility check failed: $e');
      return const {};
    }
  }
}
