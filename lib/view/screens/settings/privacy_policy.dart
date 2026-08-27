import 'package:flutter/material.dart';
import 'package:motorsport/config/legal_config.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This link could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Privacy Policy'),
      body: ListView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kQuaternaryColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderColor2),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip_rounded,
                  color: kSecondaryColor,
                  size: 44,
                ),
                const SizedBox(height: 14),
                MyText(
                  text: 'Your privacy matters',
                  size: 20,
                  weight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                MyText(
                  text:
                      'Read the official Chassis Doctor Privacy Policy to learn how information is handled and protected.',
                  size: 13,
                  lineHeight: 1.5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _openUrl(
                    context,
                    Uri.parse(LegalConfig.privacyPolicyUrl),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Privacy Policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MyText(text: 'Privacy questions', size: 16, weight: FontWeight.w700),
          const SizedBox(height: 8),
          MyText(
            text:
                'Contact the Chassis Doctor team if you have a privacy request or question.',
            size: 13,
            lineHeight: 1.5,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openUrl(
              context,
              Uri(
                scheme: 'mailto',
                path: LegalConfig.privacyContactEmail,
                queryParameters: const {'subject': 'Privacy enquiry'},
              ),
            ),
            icon: const Icon(Icons.email_outlined),
            label: const Text(LegalConfig.privacyContactEmail),
          ),
        ],
      ),
    );
  }
}
