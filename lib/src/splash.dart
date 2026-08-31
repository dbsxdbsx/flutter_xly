import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:xly/app.dart';

/// 启动叠层：只负责品牌脸，并上报「一圈播完 / 加载失败」。
///
/// 揭开由 [MyApp] 的门闩决定，不要在这里写 Timer 或改路由。
/// 所有尺寸参数均为**设计尺寸值**，内部在 build 时通过 ScreenUtil 换算。
class MySplash extends StatefulWidget {
  /// 已无导航作用，保留只为旧调用方还能编译。
  @Deprecated('Splash 不是路由。无品牌脸请传 splash: null。')
  final String nextRoute;

  final String? lottieAssetPath;
  final String? appTitle;
  final Color backgroundColor;

  /// 已不再用于揭开。有 Lottie 时播完一圈；静态脸用 [minVisible]。
  @Deprecated('揭开看 bootstrap × 动画，不再用固定时长。')
  final Duration splashDuration;

  final Color textColor;

  /// 标题字号（设计尺寸值，内部自动 .sp），默认 50
  final double? fontSize;
  final FontWeight fontWeight;

  /// Lottie 动画宽度（设计尺寸值，内部自动 .w），默认 200
  final double? lottieWidth;

  /// 动画与标题之间的间距（设计尺寸值，内部自动 .w），默认 20
  final double? spaceBetween;

  /// 无 Lottie 的静态品牌脸最短可见时间，防止闪一帧。有 Lottie 时忽略。
  final Duration minVisible;

  /// Lottie hang（`onLoaded` 不回调）时视为动画结束。
  final Duration brandTimeout;

  static const overlayKey = Key('xly-splash-overlay');

  const MySplash({
    super.key,
    @Deprecated('Splash 不是路由。无品牌脸请传 splash: null。') this.nextRoute = '',
    this.lottieAssetPath,
    this.appTitle,
    this.backgroundColor = Colors.white,
    @Deprecated('揭开看 bootstrap × 动画，不再用固定时长。')
    this.splashDuration = const Duration(milliseconds: 2500),
    this.textColor = Colors.black,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.lottieWidth,
    this.spaceBetween,
    this.minVisible = const Duration(milliseconds: 300),
    this.brandTimeout = const Duration(seconds: 8),
  });

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash>
    with SingleTickerProviderStateMixin {
  AnimationController? _lottieController;
  var _reported = false;

  @override
  void initState() {
    super.initState();
    if (widget.lottieAssetPath == null) {
      _reportDone();
      return;
    }
    _lottieController = AnimationController(vsync: this);
    _lottieController!.addStatusListener(_onLottieStatus);
  }

  @override
  void dispose() {
    _lottieController?.dispose();
    super.dispose();
  }

  void _reportDone() {
    if (_reported) return;
    _reported = true;
    MyApp.reportBrandAnimationDone();
  }

  void _onLottieStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _reportDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fatal = MyApp.splashPhase.value == MySplashPhase.fatal;
      return Material(
        key: MySplash.overlayKey,
        color: widget.backgroundColor,
        child: fatal ? _buildFatal() : _buildBrand(),
      );
    });
  }

  Widget _buildFatal() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Text(
          MyApp.splashFatalMessage ?? '启动失败',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.textColor,
            fontSize: (widget.fontSize ?? 22).sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.lottieAssetPath != null)
            Lottie.asset(
              widget.lottieAssetPath!,
              width: (widget.lottieWidth ?? 200).w,
              controller: _lottieController,
              repeat: false,
              onLoaded: (composition) {
                final controller = _lottieController;
                if (controller == null) return;
                controller
                  ..duration = composition.duration
                  ..forward();
              },
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _reportDone();
                });
                return const SizedBox.shrink();
              },
            ),
          if (widget.lottieAssetPath != null && widget.appTitle != null)
            SizedBox(height: (widget.spaceBetween ?? 20).w),
          if (widget.appTitle != null)
            Text(
              widget.appTitle!,
              style: TextStyle(
                color: widget.textColor,
                fontSize: (widget.fontSize ?? 50).sp,
                fontWeight: widget.fontWeight,
              ),
            ),
        ],
      ),
    );
  }
}
