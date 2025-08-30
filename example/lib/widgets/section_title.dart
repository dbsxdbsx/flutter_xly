import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

/// 统一的分节标题组件
/// - 默认字号 18.sp，粗体
/// - 可自定义颜色、对齐与内边距
class SectionTitle extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final EdgeInsetsGeometry? padding;

  const SectionTitle(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight = FontWeight.bold,
    this.color,
    this.textAlign,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final title = Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: (fontSize ?? 18.sp),
        fontWeight: fontWeight,
        color: color,
      ),
    );
    if (padding != null) {
      return Padding(padding: padding!, child: title);
    }
    return title;
  }
}

