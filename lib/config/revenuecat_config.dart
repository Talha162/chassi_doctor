class RevenueCatConfig {
  RevenueCatConfig._();

  static const String entitlementId = 'all_access';
  static const String offeringId = 'default';

  static const String iosPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_IOS_PUBLIC_SDK_KEY',
    defaultValue: 'appl_FIMEVQmNenhxBiPDrUsnCBQpddK',
  );
  static const String androidPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_PUBLIC_SDK_KEY',
  );

  static bool get hasAnyPlatformKey =>
      iosPublicSdkKey.isNotEmpty || androidPublicSdkKey.isNotEmpty;
}
