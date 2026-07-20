import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../logger.dart';
import 'scrim_host.dart';
import 'toast_widget/middle_toast_style_widgets/base_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/error_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/info_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/loading_widget.dart';
import 'toast_widget/middle_toast_style_widgets/ok_toast_widget.dart';
import 'toast_widget/middle_toast_style_widgets/warning_toast_widget.dart';
import 'toast_widget/toast_core.dart';

/// 加载消息更新回调函数类型
///
/// 用于在 [MyToast.showLoadingThenToast] 任务执行期间动态更新显示的消息
typedef LoadingMessageUpdater = void Function(String message);

/// Toast显示位置枚举
enum ToastPosition {
  top,
  center,
  bottom,
}

/// MyToast 提供了一个统一的 Toast 显示组件
class MyToast extends StatelessWidget {
  // 常用样式配置 - 使用 getter 以支持热重载
  static Duration get _defaultDuration => const Duration(seconds: 3);
  static Duration get _defaultAnimationDuration =>
      const Duration(milliseconds: 500);
  static Curve get _defaultAnimationCurve => Curves.easeOutCubic;

  // 常用边距
  static EdgeInsets get _defaultPadding => EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 16.w,
      );
  static EdgeInsets get _defaultSnackBarPadding => EdgeInsets.symmetric(
        horizontal: 15.w,
        vertical: 10.w,
      );
  static double get _defaultMargin => 10.w;
  static double get _defaultBorderRadius => 8.w;

  // 常用文本样式
  static TextStyle get _defaultTextStyle => TextStyle(
        fontSize: 16.sp,
        color: Colors.white,
      );

  // 常用背景色
  static Color get _defaultBackgroundColor =>
      Colors.black87.withValues(alpha: 0.7);
  static Color get _defaultWarnBackgroundColor => Colors.amber[50]!;
  static Color get _defaultWarnTextColor => Colors.amber[900]!;

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
      // 根级遮罩宿主兜底：没有更近的表面宿主（对话框 / Sheet）时，
      // showScrim 会降级为覆盖整个应用；Toast 通知层始终位于遮罩之上。
      child: MyScrimHost(child: child),
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

  /// 显示一个黑色通栏样式的提示消息
  ///
  /// [message] 提示消息内容
  /// [duration] 显示持续时间，默认2秒
  /// [backgroundColor] 自定义背景颜色，默认为黑色半透明
  /// [textColor] 自定义文字颜色，默认为白色
  /// [opacity] 背景透明度，取值范围0.0-1.0，默认0.7
  /// [atTop] 为 true 时从顶部滑入（避免遮挡底栏等 UI），默认从底部滑入
  static Widget showBottom(
    String message, {
    Duration? duration,
    Color? backgroundColor,
    Color? textColor,
    double opacity = 0.7,
    bool atTop = false,
  }) {
    assert(opacity >= 0.0 && opacity <= 1.0,
        'opacity must be between 0.0 and 1.0');

    final baseColor = backgroundColor ?? const Color(0xFF222222);
    final finalColor = baseColor.withValues(alpha: opacity);

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
        snackPosition: atTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
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
  /// [loadingMessage] 加载过程中显示的初始消息
  /// [task] 要执行的异步任务，接收一个可选的消息更新回调，返回 (bool, String?) 元组
  ///        - 第一个参数 `updateMessage` 可用于在任务执行期间动态更新加载消息
  ///        - 返回值的 bool 表示是否成功，String 为提示消息（为 null 时不显示 toast）
  /// [spinnerColor] 加载动画的颜色
  /// [backgroundColor] 背景颜色
  /// [stackPreviousToasts] 是否堆叠显示Toast
  /// [onOk] 自定义成功提示处理函数
  /// [onWarn] 自定义警告提示处理函数
  /// [onError] 自定义错误提示处理函数
  ///
  /// 示例：
  /// ```dart
  /// await MyToast.showLoadingThenToast(
  ///   loadingMessage: '正在测试 0/10 ...',
  ///   task: (updateMessage) async {
  ///     for (var i = 0; i < 10; i++) {
  ///       await doSomething(i);
  ///       updateMessage?.call('正在测试 ${i + 1}/10 ...');
  ///     }
  ///     return (true, '测试完成');
  ///   },
  /// );
  /// ```
  static Future<bool> showLoadingThenToast({
    required String loadingMessage,
    required Future<(bool, String?)> Function(
            void Function(String)? updateMessage)
        task,
    Color? spinnerColor,
    Color? backgroundColor,
    bool stackPreviousToasts = false,
    void Function(String)? onOk,
    void Function(String)? onWarn,
    void Function(String)? onError,
  }) async {
    // 为当前加载动画创建一个唯一的key
    final spinnerKey = UniqueKey();

    // 创建消息 ValueNotifier 用于动态更新
    final messageNotifier = ValueNotifier<String>(loadingMessage);

    // 显示可动态更新的加载动画
    Toast.show(
      ValueListenableBuilder<String>(
        valueListenable: messageNotifier,
        builder: (context, message, _) => LoadingWidget(
          message: message,
          spinnerColor: spinnerColor,
          backgroundColor: backgroundColor ?? _defaultBackgroundColor,
        ),
      ),
      key: spinnerKey,
      dismissOthers: !stackPreviousToasts,
      duration: const Duration(days: 365),
      alignment: Alignment.center,
    );

    try {
      // 传入消息更新函数给 task
      final (success, message) = await task((newMessage) {
        messageNotifier.value = newMessage;
      });

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
              duration: message.isEmpty
                  ? const Duration(milliseconds: 800)
                  : const Duration(seconds: 3),
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
              duration: message.isEmpty
                  ? const Duration(milliseconds: 800)
                  : const Duration(seconds: 3),
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
          duration: errorMessage.isEmpty
              ? const Duration(milliseconds: 800)
              : const Duration(seconds: 3),
          alignment: Alignment.center,
        );
      }
      return false;
    } finally {
      // 清理资源
      messageNotifier.dispose();
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

  // ---------------------------------------------------------------------
  // Scrim（作用域遮罩）：Toast 家族中唯一"阻塞型"成员
  // ---------------------------------------------------------------------

  /// 显示作用域遮罩（阻塞型加载指示）。
  ///
  /// 与其他 Toast 的区别：普通 Toast 是非阻塞的瞬时通知；Scrim 是持续的
  /// 交互锁，会盖住并锁死它所属的表面，需调用 [hideScrim] 手动关闭。
  ///
  /// 遮罩只覆盖"最近的表面"而非全屏：不传 [context] 时自动定位到最上层
  /// 的 [MyScrimHost]（`MyDialogSheet.showCenter` / `showBottom` 与 MyApp
  /// 根节点均已内置宿主，即最上层对话框 / Sheet / 页面）；传 [context]
  /// 则精确定位到该 context 最近的祖先宿主。
  ///
  /// [message] / [detail] 为默认卡片的主文案与细节行（如进度 `3/16`），
  /// 可通过 [updateScrim] 动态刷新；[onCancel] 非空时显示取消按钮；
  /// [builder] 非空时完全接管中央内容（居中由宿主负责，此时
  /// message/detail/onCancel 失效，内容刷新请用自己的响应式状态驱动）。
  ///
  /// 示例：
  /// ```dart
  /// MyToast.showScrim(message: '智选中...', onCancel: cancel);
  /// MyToast.updateScrim(detail: '$done/$total');
  /// MyToast.hideScrim();
  /// ```
  static void showScrim({
    BuildContext? context,
    String? message,
    String? detail,
    VoidCallback? onCancel,
    String cancelText = '取消',
    WidgetBuilder? builder,
    Color? barrierColor,
  }) {
    final host = MyScrimHostState.resolve(context);
    if (host == null) {
      XlyLogger.error('MyToast.showScrim: 未找到 MyScrimHost 宿主，遮罩未显示。'
          '请确认使用了 MyApp / MyDialogSheet，或手动包裹 MyScrimHost。');
      return;
    }
    host.show(
      message: message,
      detail: detail,
      onCancel: onCancel,
      cancelText: cancelText,
      builder: builder,
      barrierColor: barrierColor,
    );
  }

  /// 更新当前遮罩默认卡片的文案（未显示遮罩时静默忽略）
  static void updateScrim({String? message, String? detail}) {
    MyScrimHostState.topmostActive()?.update(message: message, detail: detail);
  }

  /// 关闭当前遮罩（未显示遮罩时静默忽略）
  static void hideScrim() {
    MyScrimHostState.topmostActive()?.hide();
  }

  /// 当前是否有遮罩正在显示
  static bool get isScrimShowing => MyScrimHostState.topmostActive() != null;
}

/// 定义文本相对于加载动画的位置
enum SpinnerMessagePosition {
  /// 文本在加载动画上方
  top,

  /// 文本在加载动画下方
  bottom,
}
