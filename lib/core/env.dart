/// Build-time configuration, injected with --dart-define. No secrets in source.
class Env {
  static const revenueCatAndroidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const premiumEntitlement = String.fromEnvironment('PREMIUM_ENTITLEMENT', defaultValue: 'premium');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
}
