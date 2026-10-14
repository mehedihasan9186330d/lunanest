import '../domain/models.dart';

/// Single place that decides what Premium unlocks.
///
/// LAUNCH STATE: everything is free. Every flag below is OFF / limits are equal for
/// free and premium users, so no sound, mixer feature or download is restricted and
/// no paywall appears in the player or mixer. The subscription system (billing,
/// paywall, restore, entitlement tracking) is fully wired and ready.
///
/// To make something Premium later, change ONE value here (e.g.
/// `lockPremiumSounds: true` plus `"premium": true` on chosen sounds in
/// assets/catalog.json, or lower a free limit). Nothing else needs to change.
class FeatureGates {
  const FeatureGates({
    this.lockPremiumSounds = false,
    this.freeMaxLayers = 6,
    this.premiumMaxLayers = 6,
    this.freeMaxSavedMixes = 50,
    this.premiumMaxSavedMixes = 50,
    this.freeMaxDownloads = 1000,
    this.premiumMaxDownloads = 1000,
  });

  /// When true, sounds flagged `"premium": true` in the catalog require a subscription.
  final bool lockPremiumSounds;
  final int freeMaxLayers;
  final int premiumMaxLayers;
  final int freeMaxSavedMixes;
  final int premiumMaxSavedMixes;
  final int freeMaxDownloads;
  final int premiumMaxDownloads;

  static const launch = FeatureGates();

  bool soundLocked(Sound s, bool premium) => lockPremiumSounds && s.premium && !premium;
  bool mixLocked(Mix m, Catalog c, bool premium) => lockPremiumSounds && !premium && c.mixNeedsPremium(m);

  int maxLayers(bool premium) => premium ? premiumMaxLayers : freeMaxLayers;
  int maxSavedMixes(bool premium) => premium ? premiumMaxSavedMixes : freeMaxSavedMixes;
  int maxDownloads(bool premium) => premium ? premiumMaxDownloads : freeMaxDownloads;

  /// True when Premium would actually change anything for a user right now.
  bool get hasPaidBenefits =>
      lockPremiumSounds ||
      freeMaxLayers < premiumMaxLayers ||
      freeMaxSavedMixes < premiumMaxSavedMixes ||
      freeMaxDownloads < premiumMaxDownloads;
}
