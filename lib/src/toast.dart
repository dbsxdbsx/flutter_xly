import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

/// MyToast 提供了一个统一的 Toast 显示组件
/// 支持自定义样式、动画和显示位置
class MyToast {
  /// 显示一条 Toast 消息
  ///
  /// [message] Toast显示的文本内容
  /// [forever] 是否永久显示
  /// [duration] 显示持续时间
  /// [textStyle] 文本样式
  /// [backgroundColor] 背景颜色
  /// [radius] 圆角半径
  /// [textPadding] 文本内边距
  /// [position] 显示位置
  /// [stackToasts] 是否堆叠显示多条Toast
  /// [animationDuration] 动画持续时间
  /// [animationCurve] 动画曲线
  static Widget show(
    String message, {
    bool? forever,
    Duration? duration,
    TextStyle? textStyle,
    Color? backgroundColor,
    double? radius,
    EdgeInsetsGeometry? textPadding,
    ToastPosition? position,
    bool stackToasts = true,
    Duration animationDuration = const Duration(milliseconds: 500),
    Curve animationCurve = Curves.easeOutCubic,
    bool hideSpinner = true,
  }) {
    if (hideSpinner) {
      dismissAllToast(showAnim: false);
    }
    showToast(
      message,
      dismissOtherToast: !stackToasts,
      duration: forever == true
          ? const Duration(days: 365)
          : duration ?? const Duration(seconds: 3),
      textStyle: textStyle ?? TextStyle(fontSize: 25.sp, color: Colors.white),
      backgroundColor: backgroundColor ?? Colors.black87.withOpacity(0.7),
      radius: radius ?? 20.0,
      textPadding:
          textPadding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
      position: position ?? ToastPosition.center,
      animationBuilder: (context, child, controller, direction) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: controller,
            curve: animationCurve,
          )),
          child: FadeTransition(
            opacity:
                Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
              parent: controller,
              curve: animationCurve,
            )),
            child: child,
          ),
        );
      },
      animationDuration: animationDuration,
      animationCurve: animationCurve,
    );
    return const SizedBox.shrink();
  }

  /// 隐藏所有显示的 Toast
  /// [milliseconds] 延迟隐藏的毫秒数
  static Widget hideAll([int milliseconds = 0]) {
    Future.delayed(Duration(milliseconds: milliseconds), () {
      dismissAllToast(showAnim: false);
    });
    return const SizedBox.shrink();
  }

  /// 在屏幕顶部显示一个警告消息
  ///
  /// [message] 警告消息内容
  /// [title] 提示标题，默认为"警告"
  /// [duration] 显示持续时间，默认2秒
  static Widget showUpWarn(
    String message, {
    String title = '警告',
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.amber[50],
      colorText: Colors.amber[900],
      duration: duration ?? const Duration(seconds: 2),
      margin: EdgeInsets.all(10.w),
      borderRadius: 8.w,
      padding: EdgeInsets.symmetric(
        horizontal: 15.w,
        vertical: 10.w,
      ),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
    return const SizedBox.shrink();
  }

  /// 在屏幕顶部显示一个错误消息
  ///
  /// [message] 错误消息内容
  /// [title] 提示标题，默认为"错误"
  /// [duration] 显示持续时间，默认2秒
  static Widget showUpError(
    String message, {
    String title = '错误',
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFEBEE),
      colorText: const Color(0xFFB71C1C),
      duration: duration ?? const Duration(seconds: 2),
      margin: EdgeInsets.all(10.w),
      borderRadius: 8.w,
      padding: EdgeInsets.symmetric(
        horizontal: 15.w,
        vertical: 10.w,
      ),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
    return const SizedBox.shrink();
  }

  /// 在屏幕顶部显示一个信息提示
  ///
  /// [message] 提示消息内容
  /// [title] 提示标题，默认为"提示"
  /// [duration] 显示持续时间，默认2秒
  static Widget showUpInfo(
    String message, {
    String title = '提示',
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.lightBlue[50],
      colorText: Colors.lightBlue[900],
      duration: duration ?? const Duration(seconds: 2),
      margin: EdgeInsets.all(10.w),
      borderRadius: 8.w,
      padding: EdgeInsets.symmetric(
        horizontal: 15.w,
        vertical: 10.w,
      ),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
    return const SizedBox.shrink();
  }

  /// 在屏幕底部显示一个黑色样式的提示消息
  ///
  /// [message] 提示消息内容
  /// [duration] 显示持续时间，默认2秒
  /// [backgroundColor] 自定义背景颜色，默认为黑色半透明
  /// [textColor] 自定义文字颜色，默认为白色
  /// [opacity] 背景透明度，取值范围0.0-1.0，默认0.9
  static Widget showBottom(
    String message, {
    Duration? duration,
    Color? backgroundColor,
    Color? textColor,
    double opacity = 0.7,
  }) {
    assert(opacity >= 0.0 && opacity <= 1.0,
        'opacity must be between 0.0 and 1.0');

    final baseColor = backgroundColor ?? const Color(0xFF222222);
    final finalColor = baseColor.withOpacity(opacity);

    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: finalColor,
        messageText: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 16.sp,
          ),
        ),
        margin: EdgeInsets.zero,
        borderRadius: 0,
        padding: EdgeInsets.symmetric(
          horizontal: 15.w,
          vertical: 12.w,
        ),
        snackStyle: SnackStyle.GROUNDED,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
    return const SizedBox.shrink();
  }

  /// 显示一个加载动画指示器
  ///
  /// [message] 可选的提示文本
  /// [position] 显示位置，默认居中
  /// [messagePosition] 文本相对于加载动画的位置，默认在下方
  /// [spinnerSize] 加载动画的大小
  /// [spinnerColor] 加载动画的颜色
  /// [backgroundColor] 背景颜色
  /// [textStyle] 文本样式
  /// [spacing] 文本和加载动画之间的间距
  /// [duration] 显示持续时间，默认为null表示一直显示直到手动关闭
  static Widget showSpinner({
    String? message,
    ToastPosition position = ToastPosition.center,
    SpinnerMessagePosition messagePosition = SpinnerMessagePosition.bottom,
    double? spinnerSize,
    Color? spinnerColor,
    Color? backgroundColor,
    TextStyle? textStyle,
    double? spacing,
    Duration? duration,
  }) {
    final content = Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black87.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (messagePosition == SpinnerMessagePosition.top &&
              message != null) ...[
            Text(
              message,
              style:
                  textStyle ?? TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
            SizedBox(height: spacing ?? 8.w),
          ],
          SizedBox(
            width: spinnerSize ?? 40.w,
            height: spinnerSize ?? 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: AlwaysStoppedAnimation<Color>(
                spinnerColor ?? Colors.white,
              ),
            ),
          ),
          if (messagePosition == SpinnerMessagePosition.bottom &&
              message != null) ...[
            SizedBox(height: spacing ?? 8.w),
            Text(
              message,
              style:
                  textStyle ?? TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ],
        ],
      ),
    );

    // 使用 Future.microtask 来避免在 build 过程中触发 setState
    Future.microtask(() {
      showToastWidget(
        content,
        dismissOtherToast: true,
        duration: duration ?? const Duration(days: 365),
        position: position,
      );
    });

    // 返回一个空的占位 Widget
    return const SizedBox.shrink();
  }
}

/// 定义文本相对于加载动画的位置
enum SpinnerMessagePosition {
  /// 文本在加载动画上方
  top,

  /// 文本在加载动画下方
  bottom,
}
