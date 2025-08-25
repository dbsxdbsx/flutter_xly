/// 多点动态加载指示器（通用版）
///
/// 设计目标：
/// - 覆盖聊天“正在输入”与通用加载（按钮、列表尾部、覆盖层）
/// - 单控制器驱动多点相位，低开销
/// - 可选变体：fade/bounce/scale/wave（后续可扩展）
/// - 自适应容器宽度，尽量不越界
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 预设动画类型
enum MyLoadingDotAnimation { fade, bounce, scale, wave }

class MyLoadingDot extends StatefulWidget {
  /// 单个圆点直径（建议用 .w 传入）
  final double size;

  /// 圆点间距（建议用 .w 传入）
  final double gap;

  /// 点数量
  final int dotCount;

  /// 颜色（可通过外层主题或直接传）
  final Color color;

  /// 动画周期
  final Duration period;

  /// 动画类型
  final MyLoadingDotAnimation dotAnimation;

  /// 相位偏移（0~1），用于整体移动波形
  final double phaseShift;

  /// 是否随机化起始相位，避免多实例同相位
  final bool randomizeStartPhase;

  const MyLoadingDot({
    super.key,
    this.size = 6.0,
    this.gap = 2.0,
    this.dotCount = 3,
    this.color = const Color(0xFF666666),
    this.period = const Duration(milliseconds: 900),
    this.dotAnimation = MyLoadingDotAnimation.fade,
    this.phaseShift = 0.0,
    this.randomizeStartPhase = true,
  }) : assert(dotCount > 0, 'dotCount 必须大于 0');

  /// 兼容“正在输入”快捷工厂（与 TypingDots 视觉近似）
  factory MyLoadingDot.typing({
    Key? key,
    double size = 6.0,
    double gap = 2.0,
    Color color = const Color(0xFF666666),
    Duration period = const Duration(milliseconds: 900),
  }) =>
      MyLoadingDot(
        key: key,
        size: size,
        gap: gap,
        color: color,
        period: period,
        dotAnimation: MyLoadingDotAnimation.fade,
        dotCount: 3,
      );

  @override
  State<MyLoadingDot> createState() => _MyLoadingDotState();
}

class _MyLoadingDotState extends State<MyLoadingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _startOffset;

  @override
  void initState() {
    super.initState();
    _startOffset =
        widget.randomizeStartPhase ? (math.Random().nextDouble()) : 0.0;
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant MyLoadingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        double dotSize = widget.size;
        double gap = widget.gap;
        final n = widget.dotCount;

        if (maxW.isFinite) {
          // 实际布局：n个点 + (n-1)个gap间距 + 首尾各一个gap
          // 总宽 = n*size + (n+1)*gap
          final totalGapWidth = (n + 1) * gap;
          final availableForDots = maxW - totalGapWidth;

          if (availableForDots > 0) {
            final maxDotSize = availableForDots / n;
            if (maxDotSize < dotSize) {
              dotSize = maxDotSize.clamp(1.0, widget.size);
            }
          }

          // 如果点太小，尝试压缩gap
          if (dotSize <= 2.0 && maxW > n * 2.0) {
            final minDotsWidth = n * 2.0; // 最小点宽度
            final availableForGaps = maxW - minDotsWidth;
            final maxGapSize = availableForGaps / (n + 1);
            gap = maxGapSize.clamp(0.5, gap);
            dotSize = 2.0;
          }
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(n, (i) {
                // 相位：控制每个点的错峰，i/n 为基础相位偏移
                final t = (_controller.value +
                        widget.phaseShift +
                        _startOffset +
                        i / n) %
                    1.0;

                switch (widget.dotAnimation) {
                  case MyLoadingDotAnimation.fade:
                    return _buildFadeDot(t, dotSize, gap);
                  case MyLoadingDotAnimation.bounce:
                    return _buildBounceDot(t, dotSize, gap);
                  case MyLoadingDotAnimation.scale:
                    return _buildScaleDot(t, dotSize, gap);
                  case MyLoadingDotAnimation.wave:
                    return _buildWaveDot(t, dotSize, gap);
                }
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildFadeDot(double t, double size, double gap) {
    final s = math.sin(2 * math.pi * t); // [-1,1]
    final opacity = 0.3 + 0.7 * (0.5 * (s + 1)); // [0.3,1.0]
    return _dot(size, gap, opacity: opacity);
  }

  Widget _buildBounceDot(double t, double size, double gap) {
    // y 位移：0 -> -amp -> 0，正弦半周期
    final amp = size * 0.6;
    final y = -amp * math.sin(math.pi * t).clamp(0, 1);
    final opacity = 0.6 + 0.4 * math.sin(math.pi * t).abs();
    return Transform.translate(
      offset: Offset(0, y.isNaN ? 0 : y),
      child: _dot(size, gap, opacity: opacity),
    );
  }

  Widget _buildScaleDot(double t, double size, double gap) {
    // scale 在 [0.6, 1.0] 波动
    final scale = 0.6 + 0.4 * (0.5 * (math.sin(2 * math.pi * t) + 1));
    final opacity = 0.5 + 0.5 * (scale - 0.6) / 0.4;
    return Transform.scale(
      scale: scale,
      child: _dot(size, gap, opacity: opacity),
    );
  }

  Widget _buildWaveDot(double t, double size, double gap) {
    // 轻微纵向波动 + 透明度
    final amp = size * 0.4;
    final y = -amp * math.sin(2 * math.pi * t);
    final opacity = 0.4 + 0.6 * (0.5 * (math.sin(2 * math.pi * t) + 1));
    return Transform.translate(
      offset: Offset(0, y),
      child: _dot(size, gap, opacity: opacity),
    );
  }

  Widget _dot(double size, double gap, {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: gap),
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
