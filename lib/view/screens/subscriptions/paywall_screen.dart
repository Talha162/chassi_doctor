import 'package:flutter/material.dart';
import 'package:motorsport/config/legal_config.dart';
import 'package:motorsport/config/revenuecat_config.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/services/subscription_service.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.sourceLabel});

  final String? sourceLabel;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  Future<void> _purchasePackage(Package package) async {
    final customerInfo = await _subscriptionService.purchasePackage(package);
    if (!mounted || customerInfo == null) return;

    if (customerInfo.entitlements.active.containsKey(
      RevenueCatConfig.entitlementId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All Access is now active on this account.'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _restorePurchases() async {
    final customerInfo = await _subscriptionService.restorePurchases();
    if (!mounted || customerInfo == null) return;

    final hasAccess = customerInfo.entitlements.active.containsKey(
      RevenueCatConfig.entitlementId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasAccess
              ? 'Your subscription was restored successfully.'
              : 'No active subscription was found to restore.',
        ),
      ),
    );
    if (hasAccess) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _openTerms() async {
    final opened = await launchUrl(
      Uri.parse(LegalConfig.termsOfUseUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terms of Use could not be opened.')),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      Uri.parse(LegalConfig.privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy Policy could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<SubscriptionState>(
        valueListenable: _subscriptionService.state,
        builder: (context, state, _) {
          final packages = _subscriptionService.currentPackages;
          final hasTrial = packages.any(_subscriptionService.isTrialEligible);
          return SafeArea(
            child: ListView(
              padding: AppSizes.DEFAULT,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: MyText(
                        text: 'Chassis Doctor All Access',
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kQuaternaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorderColor2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: kPrimaryColor,
                            child: ClipOval(
                              child: Image.asset(
                                Assets.mainlogo,
                                fit: BoxFit.cover,
                                width: 42,
                                height: 42,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  text: hasTrial
                                      ? '3-day free trial'
                                      : 'All Access',
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: kSecondaryColor,
                                ),
                                MyText(
                                  text: hasTrial
                                      ? 'Then unlock every current course with one subscription.'
                                      : 'Unlock every current course with one subscription.',
                                  size: 12,
                                  lineHeight: 1.5,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.sourceLabel != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: MyText(
                            text: 'Opened from: ${widget.sourceLabel}',
                            size: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _BenefitRow(
                        text: 'Full access to all currently published courses',
                      ),
                      const _BenefitRow(
                        text: 'Monthly or yearly billing from the same paywall',
                      ),
                      const _BenefitRow(
                        text: 'Restore purchases across your devices',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null)
                  _NoticeCard(
                    text: state.errorMessage!,
                    color: Colors.red.shade50,
                    textColor: Colors.red.shade800,
                  ),
                if (!state.isConfigured)
                  _NoticeCard(
                    text:
                        '${state.debugMessage ?? 'RevenueCat is not configured yet.'} ${_subscriptionService.missingKeysMessage}',
                    color: const Color(0xffFFF4D6),
                    textColor: const Color(0xff4B3500),
                  ),
                if (state.isConfigured && !state.hasLivePackages)
                  const _NoticeCard(
                    text:
                        'The app-side integration is ready, but no live subscription packages were returned yet. Finish the store product setup and RevenueCat offering next.',
                  ),
                const SizedBox(height: 6),
                ..._buildPlanCards(packages, state),
                const SizedBox(height: 18),
                MyButton(
                  buttonText: state.isLoading
                      ? 'Working...'
                      : 'Restore existing purchase',
                  onTap: state.isLoading ? null : _restorePurchases,
                  bgColor: kPrimaryColor,
                  textColor: kSecondaryColor,
                ),
                const SizedBox(height: 12),
                MyText(
                  text: hasTrial
                      ? 'Free trial converts automatically unless cancelled at least 24 hours before renewal. Manage subscriptions in App Store or Google Play settings.'
                      : 'Subscriptions renew automatically unless cancelled at least 24 hours before renewal. Manage subscriptions in App Store or Google Play settings.',
                  size: 11,
                  lineHeight: 1.5,
                  textAlign: TextAlign.center,
                  color: kTertiaryColor.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _openPrivacyPolicy,
                      child: const Text('Privacy Policy'),
                    ),
                    MyText(
                      text: '|',
                      size: 12,
                      color: kTertiaryColor.withValues(alpha: 0.7),
                    ),
                    TextButton(
                      onPressed: _openTerms,
                      child: const Text('Terms of Use'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPlanCards(
    List<Package> packages,
    SubscriptionState state,
  ) {
    if (packages.isNotEmpty) {
      return packages.map((package) {
        final trialEligible = _subscriptionService.isTrialEligible(package);
        final title = switch (package.packageType) {
          PackageType.monthly => 'All Access Monthly',
          PackageType.annual => 'All Access Yearly',
          _ => package.storeProduct.title,
        };
        final billingPeriod = package.packageType == PackageType.annual
            ? 'year'
            : 'month';
        final billingLabel = trialEligible
            ? '3 days free, then ${package.storeProduct.priceString} per $billingPeriod'
            : '${package.storeProduct.priceString} per $billingPeriod';
        final badge = package.packageType == PackageType.annual
            ? 'Best value'
            : null;

        return _PlanCard(
          title: title,
          priceLabel: package.storeProduct.priceString,
          billingLabel: billingLabel,
          badge: badge,
          ctaLabel: trialEligible ? 'Start 3-day free trial' : 'Subscribe now',
          enabled: !state.isLoading,
          onTap: () => _purchasePackage(package),
        );
      }).toList();
    }

    return state.previewPlans.map((plan) {
      return _PlanCard(
        title: plan.title,
        priceLabel: plan.priceLabel,
        billingLabel: plan.billingLabel,
        badge: plan.badge,
        ctaLabel: plan.ctaLabel,
        enabled: false,
        onTap: null,
      );
    }).toList();
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.priceLabel,
    required this.billingLabel,
    required this.ctaLabel,
    required this.enabled,
    this.badge,
    this.onTap,
  });

  final String title;
  final String priceLabel;
  final String billingLabel;
  final String ctaLabel;
  final bool enabled;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorderColor2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText(text: title, size: 16, weight: FontWeight.w700),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: MyText(
                    text: badge!,
                    size: 11,
                    weight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          MyText(text: priceLabel, size: 22, weight: FontWeight.w700),
          const SizedBox(height: 4),
          MyText(
            text: billingLabel,
            size: 12,
            lineHeight: 1.5,
            color: kTertiaryColor.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 14),
          MyButton(
            buttonText: enabled ? ctaLabel : 'Store setup pending',
            onTap: enabled ? onTap : null,
            bgColor: enabled ? kSecondaryColor : const Color(0xff6575A7),
            textColor: enabled ? kPrimaryColor : Colors.white,
            height: 44,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: kSecondaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: MyText(text: text, size: 13, lineHeight: 1.5)),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text, this.color, this.textColor});

  final String text;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? const Color(0xffF5F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: MyText(
        text: text,
        size: 12,
        lineHeight: 1.5,
        color: textColor ?? const Color(0xff1B2A52),
      ),
    );
  }
}
