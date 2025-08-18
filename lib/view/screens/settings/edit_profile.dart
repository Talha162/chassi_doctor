import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/view/widget/common_image_view_widget.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class EditProfile extends StatelessWidget {
  const EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Profile & Settings'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Account Information',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text: 'Manage your personal details and account settings',
            size: 12,
            paddingBottom: 30,
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: kSecondaryColor, // Change color as needed
                  width: 4,
                ),
                shape: BoxShape.circle,
              ),
              child: CommonImageView(
                height: 120,
                width: 120,
                radius: 100,
                url: dummyImg,
              ),
            ),
          ),
          SizedBox(height: 12),
          MyText(
            text: 'Rayan Ali',
            size: 18,
            weight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          MyText(
            text: 'Rayan.Ali@gmail.com',
            size: 14,
            textAlign: TextAlign.center,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 50,
          ),
          _EditProfileTile(
            title: 'Email',
            trailing: 'Rayan.ali@gmail.com',
            onChanged: (val) {},
          ),
          _EditProfileTile(
            title: 'Date of birth',
            trailing: 'May 10 1990',
            onChanged: (val) {},
          ),
          _EditProfileTile(
            title: 'Location',
            trailing: 'United States',
            onChanged: (val) {},
          ),
          _EditProfileTile(
            title: 'Phone',
            trailing: '+1(555) 123-4567',
            onChanged: (val) {},
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: kPrimaryColor,
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: MyButton(buttonText: 'Save Configuration', onTap: () {}),
        ),
      ),
    );
  }
}

class _EditProfileTile extends StatefulWidget {
  final String title;
  final String trailing;
  final ValueChanged<String>? onChanged;

  const _EditProfileTile({
    Key? key,
    required this.title,
    required this.trailing,
    this.onChanged,
  }) : super(key: key);

  @override
  State<_EditProfileTile> createState() => _EditProfileTileState();
}

class _EditProfileTileState extends State<_EditProfileTile> {
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.trailing);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MyText(text: widget.title, size: 12),
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      style:  TextStyle(
                        fontSize: 14,
                        color: kTertiaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                      decoration:  InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          color: kTertiaryColor,
                          fontSize: 14,
                        ),
                      ),
                      cursorColor: kSecondaryColor,
                      onSubmitted: (val) {
                        setState(() {
                          isEditing = false;
                        });
                        if (widget.onChanged != null) widget.onChanged!(val);
                      },
                    )
                  : MyText(
                      text: widget.trailing,
                      size: 14,
                      textAlign: TextAlign.end,
                    ),
            ),
            SizedBox(width: 8),
            if (!isEditing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isEditing = true;
                  });
                },
                child: Image.asset(Assets.imagesEditProfile, height: 20),
              ),
          ],
        ),
        Container(
          height: 1,
          color: kQuaternaryColor,
          margin: EdgeInsets.only(top: 10, bottom: 20),
        ),
      ],
    );
  }
}
