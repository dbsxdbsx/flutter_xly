import 'dart:ui';

class MyMenuStyle {
  final double fontSize;
  final double iconPadding;
  final double itemHeight;
  final double borderRadius;
  final double blurSigma;
  final double borderWidth;
  final Color focusColor;

  const MyMenuStyle({
    this.fontSize = 15,
    this.iconPadding = 90,
    this.itemHeight = 50,
    this.borderRadius = 13,
    this.blurSigma = 10,
    this.borderWidth = 1,
    this.focusColor = const Color(0xFF007AFF),
  });
}
