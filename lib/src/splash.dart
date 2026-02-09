import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:xly/xly.dart';

/// 启动屏组件
///
/// 所有尺寸参数（[fontSize]、[lottieWidth]、[spaceBetween]）均为**设计尺寸值**，
/// 组件内部会在 build 时自动通过 ScreenUtil 进行等比缩放，
/// 调用方无需（也不应该）手动添加 `.sp` / `.w` 等后缀。
class MySplash extends StatefulWidget {
  final String nextRoute;
  final String? lottieAssetPath;
  final String? appTitle;
  final Color backgroundColor;
  final Duration splashDuration;
  final Color textColor;

  /// 标题字号（设计尺寸值，内部自动 .sp），默认 50
  final double? fontSize;
  final FontWeight fontWeight;

  /// Lottie 动画宽度（设计尺寸值，内部自动 .w），默认 200
  final double? lottieWidth;

  /// 动画与标题之间的间距（设计尺寸值，内部自动 .w），默认 20
  final double? spaceBetween;

  const MySplash({
    super.key,
    required this.nextRoute,
    this.lottieAssetPath,
    this.appTitle,
    this.backgroundColor = Colors.white,
    this.splashDuration = const Duration(milliseconds: 2500),
    this.textColor = Colors.black,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.lottieWidth,
    this.spaceBetween,
  });

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> {
  @override
  void initState() {
    super.initState();
    _navigateToNextRoute();
  }

  void _navigateToNextRoute() {
    Timer(widget.splashDuration, () {
      // 通知App启动屏已结束
      MyApp.isSplashFinished.value = true;
      // 导航操作不再需要，因为主路由会自动显示
      // Get.offNamed(widget.nextRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 统一在 build 中应用 ScreenUtil（此时已初始化），
    // 避免调用方在 MyApp.initialize() 参数中使用 .sp/.w 导致时序异常
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.lottieAssetPath != null)
              Lottie.asset(widget.lottieAssetPath!,
                  width: (widget.lottieWidth ?? 200).w),
            if (widget.lottieAssetPath != null && widget.appTitle != null)
              SizedBox(height: (widget.spaceBetween ?? 20).w),
            if (widget.appTitle != null)
              _AppTitleHero(
                appTitle: widget.appTitle!,
                fontSize: (widget.fontSize ?? 50).sp,
                textColor: widget.textColor,
                fontWeight: widget.fontWeight,
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTitleHero extends StatelessWidget {
  final String appTitle;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;

  const _AppTitleHero({
    required this.appTitle,
    required this.fontSize,
    required this.textColor,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'AppTitleHeroTag',
      child: Text(
        appTitle,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
