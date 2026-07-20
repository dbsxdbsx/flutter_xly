import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../logger.dart';
import '../toast/scrim_host.dart';

/// 统一的对话框管理类
class MyDialogSheet {
  /// 显示底部弹出菜单
  ///
  /// 高度指定方式（二选一，[heightRatio] 优先）：
  /// - [heightRatio] 屏幕高度比例（0.0~1.0），如 `2/3` 表示占屏幕 2/3。
  /// - [designHeight] 设计稿高度（默认 250），在 builder 内部通过 `.h` 动态转换，
  ///   调用方只需传设计值（如 300），无需自行 `.h`。
  ///
  /// [maxWidthRatio] 控制 Sheet 宽度占窗口宽度的比例（默认 0.85），
  /// 避免 Material 3 默认的固定 640px maxWidth 导致缩放体验不一致。
  ///
  /// 实现说明：使用 Flutter 原生 `showModalBottomSheet` 而非 GetX 的
  /// `Get.bottomSheet`，因为后者不支持 `constraints` 参数，无法覆盖
  /// Material 3 的 `maxWidth: 640` 硬编码默认值。
  /// 始终启用 `isScrollControlled: true` 以突破 Flutter 默认的 9/16 高度上限。
  static Future<T?> showBottom<T>({
    required Widget child,
    double designHeight = 250,
    double? heightRatio,
    Color backgroundColor = Colors.white,
    double designBorderRadius = 20,
    double maxWidthRatio = 0.85,
  }) {
    return showModalBottomSheet<T>(
      context: Get.context!,
      // 启用滚动控制，突破默认 9/16 高度上限，让调用方自由控制面板高度
      isScrollControlled: true,
      // 禁用 Material 3 默认的 maxWidth: 640 硬编码约束，
      // 让 FractionallySizedBox 能基于真实屏幕宽度按比例计算
      constraints: const BoxConstraints(),
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 所有尺寸在 builder 内动态计算，确保窗口变化时等比例更新
        final double actualHeight;
        if (heightRatio != null) {
          actualHeight =
              MediaQuery.of(context).size.height * heightRatio.clamp(0.0, 1.0);
        } else {
          actualHeight = designHeight.h;
        }
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
    // 与中心对话框同理：白底矩形 + 遮罩 + 内容先合成同一图层，再用
    // saveLayer 统一裁顶部圆角，避免遮罩显示时边缘二次混合出细边。
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: ColoredBox(
          color: backgroundColor,
          child: MyScrimHost(
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
          ),
        ),
      ),
    );
  }
}

/// 中心弹出对话框组件
class _CenterDialogSheet extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final viewportSize = MediaQuery.sizeOf(context);

    // MediaQuery 返回的已经是当前视口的逻辑像素，不能再套 .w/.h，
    // 否则在非设计尺寸设备上会二次缩放，导致移动端对话框异常放大。
    final dialogWidth = viewportSize.width * _baseDialogWidthRatio;
    final dialogMaxHeight = viewportSize.height * _baseDialogMaxHeightRatio;

    final insetWidthSize = viewportSize.width * _baseInsetRatio;
    final insetHeightSize = viewportSize.height * _baseInsetRatio;

    final titleWidget = title != null
        ? Text(
            title!,
            style: TextStyle(
              fontSize: titleFontSize ?? 18.sp,
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
                    vertical: 8.w,
                    horizontal: 8.w,
                  ),
              child: centerTitle ? Center(child: titleWidget) : titleWidget,
            ),
          Flexible(
            child: Container(
              padding: contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: 4.w,
                  ),
              child: content,
            ),
          ),
          if (onConfirm != null)
            Padding(
              padding: actionsPadding ?? EdgeInsets.all(8.w),
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
                        fontSize: 14.sp,
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
                        fontSize: 14.sp,
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

    // 表面绘制策略：白底画成"矩形"，与遮罩（MyScrimHost）、内容一起先
    // 合成为同一图层，最后用 saveLayer 对整层做一次圆角裁剪。
    //
    // 若让 Dialog/Container 各自按圆角画白底、再裁剪半透明遮罩，同一条
    // 圆角边缘会被抗锯齿混合两次（白底一次、遮罩/裁剪一次），在深色
    // barrier 上会析出一圈亮度偏高的细边；单层合成后边缘只混合一次，
    // 数学上不存在细边。saveLayer 只在对话框存续期间占一个离屏层，可接受。
    dialogContent = Container(
      width: dialogWidth,
      constraints: BoxConstraints(
        maxHeight: dialogMaxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: ColoredBox(
          color: Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          // 宿主放在裁剪边界之内：遮罩随表面形状裁剪，圆角天然正确
          child: MyScrimHost(child: dialogContent),
        ),
      ),
    );

    return Dialog(
      // 表面已由上方 ColoredBox + ClipRRect 单层绘制，Dialog 自身完全透明，
      // 避免再叠一层带抗锯齿边缘的背景。
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding ??
          EdgeInsets.symmetric(
            horizontal: insetWidthSize,
            vertical: insetHeightSize,
          ),
      child: dialogContent,
    );
  }
}
