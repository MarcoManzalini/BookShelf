import 'package:flutter/material.dart';

/// Round picture of a welcome slide: the mascot on its peach disc.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, required this.asset});

  final String asset;

  static const mascot = 'assets/images/welcome_frog.png';
  static const find = 'assets/images/welcome_find.png';
  static const track = 'assets/images/welcome_track.png';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
