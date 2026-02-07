import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../logger.dart';

/// 统一的对话框管理类
class MyDialogSheet {
  /// 显示底部弹出菜单
  ///
  /// [designHeight] 设计稿高度（默认 250），在 builder 内部通过 `.h` 动态转换，
  /// 确保窗口缩放时高度等比例变化。调用方只需传设计值（如 300），无需自行 `.h`。
  ///
  /// [maxWidthRatio] 控制 Sheet 宽度占窗口宽度的比例（默认 0.85），
  /// 避免 Material 3 默认的固定 640px maxWidth 导致缩放体验不一致。
  ///
  /// 实现说明：使用 Flutter 原生 `showModalBottomSheet` 而非 GetX 的
  /// `Get.bottomSheet`，因为后者不支持 `constraints` 参数，无法覆盖
  /// Material 3 的 `maxWidth: 640` 硬编码默认值。
  static Future<T?> showBottom<T>({
    required Widget child,
    double designHeight = 250,
    Color backgroundColor = Colors.white,
    double designBorderRadius = 20,
    double maxWidthRatio = 0.85,
  }) {
    return showModalBottomSheet<T>(
      context: Get.context!,
      // 禁用 Material 3 默认的 maxWidth: 640 硬编码约束，
      // 让 FractionallySizedBox 能基于真实屏幕宽度按比例计算
      constraints: const BoxConstraints(),
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 所有尺寸在 builder 内动态计算，确保窗口变化时等比例更新
        final actualHeight = designHeight.h;
        final actualBorderRadius = designBorderRadius.r;
        return FractionallySizedBox(
          widthFactor: maxWidthRatio,
          child: _BottomSheetContainer(
            height: actualHeight,
            backgroundColor: backgroundColor,
            borderRadius: actualBorderRadius,
            child: child,
          ),
        );
      },
    );
  }

  /// 显示中心弹出对话框
  static Future<T?> showCenter<T>({
    String? title,
    required Widget content,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? titlePadding,
    EdgeInsetsGeometry? actionsPadding,
    EdgeInsets? insetPadding,
    double? titleFontSize,
    bool centerTitle = true,
    FutureOr<void> Function()? onConfirm,
    FutureOr<void> Function()? onExit,
    String confirmText = '确定',
    String exitText = '取消',
    bool barrierDismissible = true,
  }) {
    return Get.dialog(
      _CenterDialogSheet(
        title: title,
        content: content,
        contentPadding: contentPadding,
        titlePadding: titlePadding,
        actionsPadding: actionsPadding,
        insetPadding: insetPadding,
        titleFontSize: titleFontSize,
        centerTitle: centerTitle,
        onConfirm: onConfirm,
        onExit: onExit,
        confirmText: confirmText,
        exitText: exitText,
      ),
      barrierDismissible: barrierDismissible,
      useSafeArea: true,
    );
  }
}

/// 内部使用的底部菜单容器组件
class _BottomSheetContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final Color backgroundColor;
  final double borderRadius;

  const _BottomSheetContainer({
    required this.child,
    required this.height,
    required this.backgroundColor,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          // SingleChildScrollView 作为安全网：
          // 内容不超出时正常显示，超出时自动可滚动，避免 overflow
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

/// 中心弹出对话框组件
class _CenterDialogSheet extends StatelessWidget {
  static const double _baseWidth = 350.0;
  static const double _baseHeight = 600.0;
  static const double _baseDialogWidthRatio = 0.95;
  static const double _baseDialogMaxHeightRatio = 0.95;
  static const double _baseInsetRatio = 0.07;

  final String? title;
  final Widget content;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsets? insetPadding;
  final double? titleFontSize;
  final bool centerTitle;
  final FutureOr<void> Function()? onConfirm;
  final FutureOr<void> Function()? onExit;
  final String confirmText;
  final String exitText;

  const _CenterDialogSheet({
    this.title,
    required this.content,
    this.contentPadding,
    this.titlePadding,
    this.actionsPadding,
    this.insetPadding,
    this.titleFontSize,
    this.centerTitle = true,
    this.onConfirm,
    this.onExit,
    this.confirmText = '确定',
    this.exitText = '取消',
  });

  double _getAdaptiveSize(BuildContext context, double baseSize) {
    final designSize = MediaQuery.of(context).size;
    final scaleFactor =
        (designSize.width + designSize.height) / (_baseWidth + _baseHeight);
    return baseSize * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    final designSize = MediaQuery.of(context).size;

    // 计算对话框尺寸
    final dialogWidth = designSize.width * _baseDialogWidthRatio;
    final dialogMaxHeight = designSize.height * _baseDialogMaxHeightRatio;

    // 计算inset尺寸
    final insetWidthSize = designSize.width * _baseInsetRatio;
    final insetHeightSize = designSize.height * _baseInsetRatio;

    final titleWidget = title != null
        ? Text(
            title!,
            style: TextStyle(
              fontSize: titleFontSize ?? _getAdaptiveSize(context, 18.0).sp,
            ),
          )
        : null;

    Widget dialogContent = Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleWidget != null)
            Padding(
              padding: titlePadding ??
                  EdgeInsets.symmetric(
                    vertical: _getAdaptiveSize(context, 8.0).w,
                    horizontal: _getAdaptiveSize(context, 8.0).w,
                  ),
              child: centerTitle ? Center(child: titleWidget) : titleWidget,
            ),
          Flexible(
            child: Container(
              padding: contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: _getAdaptiveSize(context, 4.0).w,
                  ),
              child: content,
            ),
          ),
          if (onConfirm != null)
            Padding(
              padding: actionsPadding ??
                  EdgeInsets.all(_getAdaptiveSize(context, 8.0).w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      if (onExit != null) {
                        try {
                          await onExit!();
                        } catch (e, s) {
                          XlyLogger.error('onExit error', e, s);
                        }
                      } else {
                        Get.back();
                      }
                    },
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(
                        Colors.black54.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      exitText,
                      style: TextStyle(
                        fontSize: _getAdaptiveSize(context, 14.0).sp,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onConfirm != null
                        ? () async {
                            try {
                              await onConfirm!();
                            } catch (e, s) {
                              XlyLogger.error('onConfirm error', e, s);
                            }
                          }
                        : null,
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(
                        Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: _getAdaptiveSize(context, 14.0).sp,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    dialogContent = Container(
      width: dialogWidth.w,
      constraints: BoxConstraints(
        maxHeight: dialogMaxHeight.h,
      ),
      decoration: ShapeDecoration(
        color: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _getAdaptiveSize(context, 28.0).r,
          ),
        ),
      ),
      child: dialogContent,
    );

    return Dialog(
      insetPadding: insetPadding ??
          EdgeInsets.symmetric(
            horizontal: insetWidthSize.w,
            vertical: insetHeightSize.h,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          _getAdaptiveSize(context, 28.0).r,
        ),
      ),
      child: dialogContent,
    );
  }
}
