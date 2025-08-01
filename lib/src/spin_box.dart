import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 自定义编辑框组件，支持数字输入和增减按钮。
///
/// 该组件提供丰富的数字输入体验，具有以下特性：
/// * 增减按钮
/// * 自定义样式
/// * 数值范围验证
/// * 步长控制
class MySpinBox extends StatefulWidget {
  // Default style constants
  static double get defaultTitleFontSize => 15.sp;
  static double get defaultCenterFontSize => 12.sp;
  static double get defaultIconSize => 13.w;
  static double get defaultSuffixFontSize => 12.sp;
  static double get defaultButtonSize => 28.w;
  static double get defaultInSetVerticalPadding => 10.w;
  static double get defaultInSetHorizontalPadding => 10.w;
  static double get defaultBorderRadius => 4.r;

  final String label;
  final double initialValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final double? labelFontSize;
  final double? centerTextFontSize;
  final double? spinIconSize;
  final double? suffixFontSize;
  final double? spinButtonSize;
  final bool enableEdit;
  final double step;
  final double? inSetVerticalPadding;
  final double? inSetHorizontalPadding;

  const MySpinBox({
    super.key,
    required this.label,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enableEdit = false,
    this.step = 1.0,
    this.suffix,
    this.labelFontSize,
    this.centerTextFontSize,
    this.spinIconSize,
    this.suffixFontSize,
    this.spinButtonSize,
    this.inSetVerticalPadding,
    this.inSetHorizontalPadding,
  });

  @override
  State<MySpinBox> createState() => _MySpinBoxState();
}

class _MySpinBoxState extends State<MySpinBox> {
  late TextEditingController _textController;
  late double _currentValue;
  late FocusNode _focusNode;
  final ValueNotifier<bool> _showCursor = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _textController =
        TextEditingController(text: _currentValue.toInt().toString());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _stopContinuousUpdate();
    _textController.dispose();
    _focusNode.dispose();
    _showCursor.dispose();
    super.dispose();
  }

  void _handleSpinButtonTap(double newValue) {
    // 让输入框失去焦点
    _focusNode.unfocus();

    setState(() {
      _currentValue = newValue;
      _textController.text = newValue.toInt().toString();
    });
    widget.onChanged(newValue);
  }

  Widget _buildSpinButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final actualIconSize = widget.spinIconSize ?? MySpinBox.defaultIconSize;
    final actualButtonSize =
        widget.spinButtonSize ?? MySpinBox.defaultButtonSize;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTapDown: isEnabled
            ? (_) {
                _showCursor.value = false;
                onTap();
              }
            : null,
        onTapUp: isEnabled
            ? (_) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    _showCursor.value = true;
                  }
                });
              }
            : null,
        onLongPressStart: isEnabled
            ? (_) {
                _startContinuousUpdate(onTap);
              }
            : null,
        onLongPressEnd: isEnabled
            ? (_) {
                _stopContinuousUpdate();
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    _showCursor.value = true;
                  }
                });
              }
            : null,
        child: Container(
          width: actualButtonSize,
          height: actualButtonSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MySpinBox.defaultBorderRadius),
          ),
          child: Icon(
            icon,
            size: actualIconSize,
            color: isEnabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Timer? _continuousUpdateTimer;
  int _updateCount = 0;

  void _startContinuousUpdate(VoidCallback action) {
    _updateCount = 0;
    action(); // 立即执行一次

    // 开始定时器，随着持续时间增加更新速度
    _continuousUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        _stopContinuousUpdate();
        return;
      }

      _updateCount++;
      // 根据持续时间调整更新频率
      if (_updateCount < 20) {
        // 前1秒，每100ms更新一次
        if (timer.tick % 2 == 0) action();
      } else if (_updateCount < 40) {
        // 1-2秒，每50ms更新一次
        action();
      } else {
        // 2秒后，每25ms更新一次
        action();
        if (timer.tick % 2 == 0) action();
      }
    });
  }

  void _stopContinuousUpdate() {
    _continuousUpdateTimer?.cancel();
    _continuousUpdateTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _currentValue = widget.initialValue;
              _textController.text = _currentValue.toInt().toString();
            });
          }
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _showCursor,
        builder: (context, showCursor, child) => TextField(
          focusNode: _focusNode,
          readOnly: !widget.enableEdit,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            if (value.isEmpty) return;
            final newValue = double.tryParse(value);
            if (newValue != null) {
              final clampedValue = newValue.clamp(widget.min, widget.max);
              setState(() {
                _currentValue = clampedValue;
                if (clampedValue != newValue) {
                  _textController.text = clampedValue.toInt().toString();
                }
              });
              widget.onChanged(clampedValue);
            }
          },
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontSize: widget.labelFontSize ?? MySpinBox.defaultTitleFontSize,
              color: Colors.grey[700],
            ),
            isDense: true,
            contentPadding: _getContentPadding(),
            border: _buildBorder(Colors.grey[300]!),
            enabledBorder: _buildBorder(Colors.grey[300]!),
            focusedBorder: _buildBorder(Colors.blue[300]!),
            prefixIcon: _buildSpinButton(
              icon: Icons.remove,
              isEnabled: _currentValue > widget.min,
              onTap: () {
                final newValue =
                    (_currentValue - widget.step).clamp(widget.min, widget.max);
                _handleSpinButtonTap(newValue);
              },
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSpinButton(
                  icon: Icons.add,
                  isEnabled: _currentValue < widget.max,
                  onTap: () {
                    final newValue = (_currentValue + widget.step)
                        .clamp(widget.min, widget.max);
                    _handleSpinButtonTap(newValue);
                  },
                ),
                if (widget.suffix != null)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Text(
                      widget.suffix!,
                      style: TextStyle(
                        fontSize: widget.suffixFontSize ??
                            MySpinBox.defaultSuffixFontSize,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          controller: _textController,
          style: TextStyle(
            fontSize:
                widget.centerTextFontSize ?? MySpinBox.defaultCenterFontSize,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  EdgeInsetsGeometry _getContentPadding() {
    if (widget.inSetHorizontalPadding != null &&
        widget.inSetVerticalPadding != null) {
      return EdgeInsets.fromLTRB(
        widget.inSetHorizontalPadding!.w,
        widget.inSetVerticalPadding!.h,
        widget.inSetHorizontalPadding!.w,
        widget.inSetVerticalPadding!.h,
      );
    }
    if (widget.inSetHorizontalPadding != null) {
      return EdgeInsets.symmetric(horizontal: widget.inSetHorizontalPadding!.w);
    }
    if (widget.inSetVerticalPadding != null) {
      return EdgeInsets.symmetric(vertical: widget.inSetVerticalPadding!.h);
    }
    return EdgeInsets.symmetric(
      horizontal: MySpinBox.defaultInSetHorizontalPadding,
      vertical: MySpinBox.defaultInSetVerticalPadding,
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(MySpinBox.defaultBorderRadius),
      borderSide: BorderSide(color: color),
    );
  }
}
