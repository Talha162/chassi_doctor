// ...existing code...
import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Privacy Policy'),
      body: ListView(
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          _SectionTitle('Terms & Condition'),
          _SectionText(
            'Lorem ipsum dolor sit amet consectetur. Lectus facilisi condimentum purus ornare tellus tempor cursus. Amet aliquam vestibulum cursus enim luctus nec enim. Quis egestas sed est eget mauris nisl tempus tellus purus.',
          ),
          _SectionTitle('How to use this'),
          _SectionText(
            'Sit massa leo vel faucibus. Aenean sit non placerat etiam felis. Nisi eros eleifend vulputate ut velit eget egestas. Fermentum auctor faucibus enim massa egestas. Eu eget leo nibh eu eu ac. Morbi malesuada viverra ut etiam egestas arcu.',
          ),
          _SectionTitle('Understree'),
          _SectionText(
            'The car turns less than desired when cornering, often leading to a wider path.',
          ),
          _SectionTitle('Privacy policy'),
          _SectionText(
            'Sit massa leo vel faucibus. Aenean sit non placerat etiam felis. Nisi eros eleifend vulputate ut velit eget egestas. Fermentum auctor faucibus enim massa egestas. Eu eget leo nibh eu eu ac. Morbi malesuada viverra ut etiam egestas arcu.',
          ),
          _SectionTitle('Privacy policy'),
          _SectionText(
            'Sit massa leo vel faucibus. Aenean sit non placerat etiam felis. Nisi eros eleifend vulputate ut velit eget egestas. Fermentum auctor faucibus enim massa egestas. Eu eget leo nibh eu eu ac. Morbi malesuada viverra ut etiam egestas arcu.',
          ),
          _SectionTitle('How to use this'),
          _SectionText(
            'Sit massa leo vel faucibus. Aenean sit non placerat etiam felis. Nisi eros eleifend vulputate ut velit eget egestas. Fermentum auctor faucibus enim massa egestas. Eu eget leo nibh eu eu ac. Morbi malesuada viverra ut etiam egestas arcu.',
          ),
          _SectionTitle('Privacy policy'),
          _SectionText(
            'Sit massa leo vel faucibus. Aenean sit non placerat etiam felis. Nisi eros eleifend vulputate ut velit eget egestas. Fermentum auctor faucibus enim massa egestas. Eu eget leo nibh eu eu ac. Morbi malesuada viverra ut etiam egestas arcu.',
          ),
          _SectionTitle('Privacy policy'),
          _SectionText(
            'Sit massa leo vel faucibus. Aenean sit non placerat etiam felis. Nisi eros eleifend vulputate ut velit eget egestas. Fermentum auctor faucibus enim massa egestas. Eu eget leo nibh eu eu ac. Morbi malesuada viverra ut etiam egestas arcu.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: MyText(text: title, size: 16, weight: FontWeight.bold),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MyText(
        text: text,
        size: 12,
        lineHeight: 1.5,
        color: kTertiaryColor.withOpacity(0.8),
      ),
    );
  }
}
