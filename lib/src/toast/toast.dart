import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'toast_widget/middle_toast_style_widgets/base_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/error_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/info_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/loading_widget.dart';
import 'toast_widget/middle_toast_style_widgets/ok_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/warning_toast_widget.dart';
import 'toast_widget/toast_core.dart';

/// Toast显示位置枚举
enum ToastPosition {
  top,
  center,
  bottom,
}

/// MyToast 提供了一个统一的 Toast 显示组件
class MyToast extends StatelessWidget {
  final Widget child;

  const MyToast({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Toast(
      duration: const Duration(seconds: 2),
      alignment: Alignment.center,
      child: child,
    );
  }

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
  }) {
    Toast.show(
      BaseToastWidget(
        message: message,
        textStyle: textStyle ?? TextStyle(fontSize: 25.sp, color: Colors.white),
        backgroundColor: backgroundColor ?? Colors.black87.withOpacity(0.7),
        radius: radius ?? 20.0,
        padding: textPadding ??
            EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
      ),
      dismissOthers: !stackToasts,
      duration: forever == true
          ? const Duration(days: 365)
          : duration ?? const Duration(seconds: 3),
      alignment: _getAlignmentFromPosition(position ?? ToastPosition.center),
      animationDuration: animationDuration,
      animationCurve: animationCurve,
    );

    return const SizedBox.shrink();
  }

  /// 隐藏所有显示的 Toast
  static Widget hideAll([int milliseconds = 0]) {
    Future.delayed(Duration(milliseconds: milliseconds), () {
      Toast.dismissAll();
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
  /// [textColor] 自定义文字颜色，认为白色
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
    final loadingWidget = LoadingWidget(
      message: message,
      spinnerColor: spinnerColor,
      backgroundColor: backgroundColor,
      spinnerSize: spinnerSize,
      textStyle: textStyle,
    );

    Future.microtask(() {
      Toast.show(
        loadingWidget,
        dismissOthers: true,
        duration: duration ?? const Duration(days: 365),
        alignment: _getAlignmentFromPosition(position),
      );
    });

    return const SizedBox.shrink();
  }

  /// 将 ToastPosition 转换为 Alignment
  static Alignment _getAlignmentFromPosition(ToastPosition position) {
    switch (position) {
      case ToastPosition.top:
        return Alignment.topCenter;
      case ToastPosition.center:
        return Alignment.center;
      case ToastPosition.bottom:
        return Alignment.bottomCenter;
    }
  }

  /// 显示一个警告提示（用于预期内的失败状态）
  ///
  /// [message] 警告消息内容
  /// [textStyle] 文本样式
  /// [backgroundColor] 背景颜色
  /// [duration] 显示持续时间
  /// [stackToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showWarn(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackToasts = true,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      WarningToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackToasts,
      alignment: _getAlignmentFromPosition(position),
    );

    return const SizedBox.shrink();
  }

  /// 显示一个错误提示（用于异常错误）
  ///
  /// [message] 错误消息内容
  /// [textStyle] 文本样式
  /// [backgroundColor] 背景颜色
  /// [duration] 显示持续时间
  /// [stackToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showError(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackToasts = true,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      ErrorToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackToasts,
      alignment: _getAlignmentFromPosition(position),
    );

    return const SizedBox.shrink();
  }

  /// 显示一个成功提示（用于操作完成）
  ///
  /// [message] 成功消息内容
  /// [textStyle] 文本样式
  /// [backgroundColor] 背景颜色
  /// [duration] 显示持续时间
  /// [stackToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showOk(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackToasts = true,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      OkToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackToasts,
      alignment: _getAlignmentFromPosition(position),
    );

    return const SizedBox.shrink();
  }

  /// 显示一个加载动画，并在任务完成时显示Toast消息
  ///
  /// [loadingMessage] 加载中显示的消息
  /// [task] 需要执行的异步任务，返回(bool, String)元组
  /// [spinnerColor] 加载动画的颜色
  /// [backgroundColor] 背景颜色
  /// [textStyle] 文本样式
  /// [toastDuration] 完成消息的显示时间
  /// [stackToasts] 是否堆叠显示Toast消息
  /// [onOk] 成功时的回调，如果不提供则显示默认成功提示
  /// [onWarn] 未完成时的回调，如果不提供则显示默认警告提示
  /// [onError] 错误处理回调，如果不提供则显示默认错误消息
  static Future<bool> showLoadingThenToast({
    required String loadingMessage,
    required Future<(bool, String)> Function() task,
    Color? spinnerColor,
    Color? backgroundColor,
    TextStyle? textStyle,
    Duration? toastDuration,
    bool stackToasts = false,
    void Function(String message)? onOk,
    void Function(String message)? onWarn,
    void Function(dynamic error)? onError,
  }) async {
    final spinnerKey = UniqueKey();

    Toast.show(
      LoadingWidget(
        message: loadingMessage,
        spinnerColor: spinnerColor,
        backgroundColor: backgroundColor,
        textStyle: textStyle,
      ),
      key: spinnerKey,
      dismissOthers: !stackToasts,
      duration: const Duration(days: 365),
      alignment: Alignment.center,
    );

    try {
      final (success, message) = await task();
      Toast.dismiss(spinnerKey);
      await Future.delayed(const Duration(milliseconds: 100));

      if (success) {
        if (onOk != null) {
          onOk(message);
        } else {
          showOk(
            message,
            textStyle: textStyle,
            backgroundColor: backgroundColor,
            duration: toastDuration,
            stackToasts: stackToasts,
          );
        }
      } else {
        if (onWarn != null) {
          onWarn(message);
        } else {
          showWarn(
            message,
            textStyle: textStyle,
            backgroundColor: backgroundColor,
            duration: toastDuration,
            stackToasts: stackToasts,
          );
        }
      }

      return success;
    } catch (e) {
      Toast.dismiss(spinnerKey);
      await Future.delayed(const Duration(milliseconds: 100));

      if (onError != null) {
        onError(e);
      } else {
        showError(
          '异常报错: $e',
          textStyle: textStyle,
          backgroundColor: backgroundColor,
          duration: toastDuration,
          stackToasts: stackToasts,
        );
      }
      return false;
    }
  }

  /// 显示一个信息提示（用于普通信息展示）
  ///
  /// [message] 信息内容
  /// [textStyle] 文本样式
  /// [backgroundColor] 背景颜色
  /// [duration] 显示持续时间
  /// [stackToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showInfo(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackToasts = true,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      InfoToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackToasts,
      alignment: _getAlignmentFromPosition(position),
    );

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
