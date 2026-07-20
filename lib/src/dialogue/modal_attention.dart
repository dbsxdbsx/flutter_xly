import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 模态对话框「点击遮罩无效」时的注意力反馈效果。
///
/// 语义参考 macOS 模态窗口的 attention shake（拒绝抖动）：
/// 用一个短促、自动回位的动画告诉用户"点击已收到，但此处无效，
/// 请回到窗口内做显式选择"，避免完全无反应让用户误以为界面卡死。
enum MyModalAttentionEffect {
  /// 水平抖动（正弦衰减，默认）
  shake,

  /// 微弱放大回弹
  pulse,

  /// 关闭反馈（点击遮罩静默无效）
  none,
}

/// 模态对话框的注意力反馈包装器。
///
/// 在 `barrierDismissible: false` 的路由中，Flutter 的 `ModalBarrier`
/// 会吞掉遮罩点击且不提供回调；本组件通过在对话框下方铺一层全屏
/// 透明手势层接管这些点击，并对 [child]（对话框本体）播放 [effect] 动画。
///
/// `MyDialogSheet.showCenter` 与 `MyDialog.show/showIos` 在
/// `barrierDismissible: false` 时已自动套用本组件；直接使用
/// `Get.dialog` / `showDialog` 的调用方也可以手动包裹：
///
/// ```dart
/// Get.dialog(
///   MyModalAttention(child: myDialogWidget),
///   barrierDismissible: false,
/// );
/// ```
///
/// 尺寸契约：[amplitude] 为逻辑像素，调用方如需响应式请显式传 `.w`；
/// 缺省时内部按设计稿 8px 延迟换算（`8.w`），随窗口尺寸变化更新。
class MyModalAttention extends StatefulWidget {
  const MyModalAttention({
    super.key,
    required this.child,
    this.effect = MyModalAttentionEffect.shake,
    this.amplitude,
    this.duration = const Duration(milliseconds: 350),
  });

  /// 对话框本体（通常为 `Dialog` / `AlertDialog` 等自带居中布局的组件）
  final Widget child;

  /// 点击遮罩时播放的反馈效果
  final MyModalAttentionEffect effect;

  /// 抖动振幅（逻辑像素）。null 时使用默认值（设计稿 8px，内部 `.w` 换算）
  final double? amplitude;

  /// 单次反馈动画时长
  final Duration duration;

  @override
  State<MyModalAttention> createState() => _MyModalAttentionState();
}

class _MyModalAttentionState extends State<MyModalAttention>
    with SingleTickerProviderStateMixin {
  /// pulse 效果的最大缩放增量
  static const double _pulseScaleDelta = 0.02;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarrierTap() {
    if (widget.effect == MyModalAttentionEffect.none) return;
    // 尊重系统"减弱动效"设置
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    // 动画进行中忽略重复触发：避免相位重置导致对话框位置瞬间跳变
    if (_controller.isAnimating) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // 注意：builder 在任何时刻都必须返回相同结构的 widget 树（Transform
    // 常驻、空闲时位移/缩放取恒等值）。若空闲时直接返回 child、动画中才
    // 包 Transform，动画首尾两次结构切换会导致 Element 无法复用，整个
    // 对话框子树被销毁重建——内部进度条等动画会随每次抖动重播一遍。
    final animated = AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final animating = t > 0 && t < 1;
        switch (widget.effect) {
          case MyModalAttentionEffect.shake:
            // 正弦衰减：晃两个完整来回，幅度随时间线性收敛到 0
            final amplitude = widget.amplitude ?? 8.w;
            final dx = animating
                ? math.sin(t * math.pi * 4) * (1 - t) * amplitude
                : 0.0;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          case MyModalAttentionEffect.pulse:
            final scale = animating
                ? 1.0 + _pulseScaleDelta * math.sin(t * math.pi)
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          case MyModalAttentionEffect.none:
            return child!;
        }
      },
    );

    // 全屏 Stack：底层透明手势层接住对话框之外的点击（对话框自身的
    // Material 会先吸收命中，不受影响），令其不再穿透到 ModalBarrier。
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: _onBarrierTap,
        ),
        animated,
      ],
    );
  }
}
