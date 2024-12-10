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
  // 添加常用样式配置
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 500);
  static const Curve _defaultAnimationCurve = Curves.easeOutCubic;

  // 常用边距
  static final EdgeInsets _defaultPadding = EdgeInsets.symmetric(
    horizontal: 24.w,
    vertical: 16.w,
  );
  static final EdgeInsets _defaultSnackBarPadding = EdgeInsets.symmetric(
    horizontal: 15.w,
    vertical: 10.w,
  );
  static final double _defaultMargin = 10.w;
  static final double _defaultBorderRadius = 8.w;

  // 常用文本样式
  static final TextStyle _defaultTextStyle = TextStyle(
    fontSize: 16.sp,
    color: Colors.white,
  );

  // 常用背景色
  static final Color _defaultBackgroundColor = Colors.black87.withOpacity(0.7);
  static const Color _defaultErrorBackgroundColor = Color(0xFFFFEBEE);
  static const Color _defaultErrorTextColor = Color(0xFFB71C1C);
  static final Color _defaultInfoBackgroundColor = Colors.lightBlue[50]!;
  static final Color _defaultInfoTextColor = Colors.lightBlue[900]!;
  static final Color _defaultWarnBackgroundColor = Colors.amber[50]!;
  static final Color _defaultWarnTextColor = Colors.amber[900]!;

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
  /// [stackPreviousToasts] 是否堆叠显示多条Toast
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
    bool stackPreviousToasts = false,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    Toast.show(
      BaseToastWidget(
        message: message,
        textStyle: textStyle ?? _defaultTextStyle,
        backgroundColor: backgroundColor ?? _defaultBackgroundColor,
        radius: radius ?? _defaultBorderRadius,
        padding: textPadding ?? _defaultPadding,
      ),
      dismissOthers: !stackPreviousToasts,
      duration: forever == true
          ? const Duration(days: 365)
          : duration ?? _defaultDuration,
      alignment: _getAlignmentFromPosition(position ?? ToastPosition.center),
      animationDuration: animationDuration ?? _defaultAnimationDuration,
      animationCurve: animationCurve ?? _defaultAnimationCurve,
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
      backgroundColor: _defaultWarnBackgroundColor,
      colorText: _defaultWarnTextColor,
      duration: duration ?? _defaultDuration,
      margin: EdgeInsets.all(_defaultMargin),
      borderRadius: _defaultBorderRadius,
      padding: _defaultSnackBarPadding,
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: _defaultAnimationCurve,
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
  /// [duration] ��示持续时间
  /// [stackPreviousToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showWarn(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackPreviousToasts = false,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      WarningToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackPreviousToasts,
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
  /// [stackPreviousToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showError(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackPreviousToasts = false,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      ErrorToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackPreviousToasts,
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
  /// [stackPreviousToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showOk(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackPreviousToasts = false,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      OkToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackPreviousToasts,
      alignment: _getAlignmentFromPosition(position),
    );

    return const SizedBox.shrink();
  }

  /// 显示加载动画，执行任务后显示结果提示
  ///
  /// [loadingMessage] 加载过程中显示的消息
  /// [task] 要执行的异步任务，返回 (bool, String?) 元组，bool表示是否成功，String为提示消息（为null时不显示toast）
  /// [spinnerColor] 加载动画的颜色
  /// [backgroundColor] 背景颜色
  /// [stackPreviousToasts] 是否堆叠显示Toast
  /// [onOk] 自定义成功提示处理函数
  /// [onWarn] 自定义警告提示处理函数
  /// [onError] 自定义错误提示处理函数
  static Future<bool> showLoadingThenToast({
    required String loadingMessage,
    required Future<(bool, String?)> Function() task,
    Color? spinnerColor,
    Color? backgroundColor,
    bool stackPreviousToasts = false,
    void Function(String)? onOk,
    void Function(String)? onWarn,
    void Function(String)? onError,
  }) async {
    // 为当前加载动画创建一个唯一的key
    final spinnerKey = UniqueKey();

    // 显示加载动画
    Toast.show(
      LoadingWidget(
        message: loadingMessage,
        spinnerColor: spinnerColor,
        backgroundColor: backgroundColor ?? _defaultBackgroundColor,
      ),
      key: spinnerKey,
      dismissOthers: !stackPreviousToasts,
      duration: const Duration(days: 365),
      alignment: Alignment.center,
    );

    try {
      final (success, message) = await task();

      // 移除加载动画
      Toast.dismiss(spinnerKey);
      // 添加短暂延迟确保动画平滑过渡
      await Future.delayed(const Duration(milliseconds: 100));

      // 只在消息不为 null 时显示结果 toast
      if (message != null) {
        if (success) {
          if (onOk != null) {
            onOk(message);
          } else {
            Toast.show(
              OkToastWidget(
                message: message,
                backgroundColor: backgroundColor ?? _defaultBackgroundColor,
              ),
              dismissOthers: !stackPreviousToasts,
              duration: message.isEmpty ? const Duration(milliseconds: 800) : const Duration(seconds: 3),
              alignment: Alignment.center,
            );
          }
        } else {
          if (onWarn != null) {
            onWarn(message);
          } else {
            Toast.show(
              WarningToastWidget(
                message: message,
                backgroundColor: backgroundColor ?? _defaultBackgroundColor,
              ),
              dismissOthers: !stackPreviousToasts,
              duration: message.isEmpty ? const Duration(milliseconds: 800) : const Duration(seconds: 3),
              alignment: Alignment.center,
            );
          }
        }
      }

      return success;
    } catch (e) {
      // 移除加载动画
      Toast.dismiss(spinnerKey);
      await Future.delayed(const Duration(milliseconds: 100));

      final errorMessage = e.toString();
      if (onError != null) {
        onError(errorMessage);
      } else {
        Toast.show(
          ErrorToastWidget(
            message: errorMessage,
            backgroundColor: backgroundColor ?? _defaultBackgroundColor,
          ),
          dismissOthers: !stackPreviousToasts,
          duration: errorMessage.isEmpty ? const Duration(milliseconds: 800) : const Duration(seconds: 3),
          alignment: Alignment.center,
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
  /// [stackPreviousToasts] 是否堆叠显示
  /// [position] 显示位置
  static Widget showInfo(
    String message, {
    TextStyle? textStyle,
    Color? backgroundColor,
    Duration? duration,
    bool stackPreviousToasts = false,
    ToastPosition position = ToastPosition.center,
  }) {
    Toast.show(
      InfoToastWidget(
        message: message,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
      ),
      duration: duration ?? const Duration(seconds: 3),
      dismissOthers: !stackPreviousToasts,
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
