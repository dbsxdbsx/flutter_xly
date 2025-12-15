import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../logger.dart';

/// 统一的对话框管理类
class MyDialogSheet {
  /// 显示底部弹出菜单
  static Future<T?> showBottom<T>({
    required Widget child,
    double? height,
    Color backgroundColor = Colors.white,
    double? borderRadius,
  }) {
    final actualHeight = height ?? 250.h;
    final actualBorderRadius = borderRadius ?? 20.r;

    return Get.bottomSheet(
      _BottomSheetContainer(
        height: actualHeight,
        backgroundColor: backgroundColor,
        borderRadius: actualBorderRadius,
        child: child,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(actualBorderRadius)),
      ),
      backgroundColor: Colors.transparent,
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
          Expanded(child: child),
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
