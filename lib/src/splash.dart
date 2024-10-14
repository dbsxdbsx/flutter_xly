import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class MySplash extends StatefulWidget {
  final String nextRoute;
  final String? lottieAssetPath;
  final String? appTitle;
  final Color backgroundColor;
  final Duration splashDuration;
  final Color textColor;
  final double? fontSize;
  final FontWeight fontWeight;
  final double? lottieWidth;
  final double? spaceBetween;
  final Transition? transition;
  final Duration transitionDuration;

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
    this.transition,
    this.transitionDuration = const Duration(milliseconds: 300),
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
      Get.off(
        () => GetRouterOutlet.builder(
          routerDelegate: Get.rootDelegate,
          builder: (context, delegate, config) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          },
        ),
        routeName: widget.nextRoute,
        transition: widget.transition,
        duration: widget.transitionDuration,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.lottieAssetPath != null)
              Lottie.asset(widget.lottieAssetPath!,
                  width: widget.lottieWidth ?? 200.w),
            if (widget.lottieAssetPath != null && widget.appTitle != null)
              SizedBox(height: widget.spaceBetween ?? 20.w),
            if (widget.appTitle != null)
              _AppTitleHero(
                appTitle: widget.appTitle!,
                fontSize: widget.fontSize ?? 50.sp,
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
