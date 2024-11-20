import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:xly/src/buttons/button.dart';

class XlyFocusController extends GetxController {
  final _currentFocus = ''.obs;

  void setFocus(String key) => _currentFocus.value = key;
  String get currentFocus => _currentFocus.value;
}

extension XlyFocusableExtension on Widget {
  Widget setFocus({
    String? focusKey,
    VoidCallback? onPressed,
    bool opacity = false,
    Color focusedBorderColor = Colors.grey,
    double borderWidth = 1.5,
    Duration animationDuration = const Duration(milliseconds: 350),
    double opacityBeginScale = 0.65,
  }) {
    return _XlyFocusableWidget(
      focusKey: focusKey,
      onPressed: onPressed,
      opacity: opacity,
      focusedBorderColor: focusedBorderColor,
      borderWidth: borderWidth,
      animationDuration: animationDuration,
      opacityBeginScale: opacityBeginScale,
      child: this,
    );
  }
}

class _XlyFocusableWidget extends StatefulWidget {
  final Widget child;
  final String? focusKey;
  final VoidCallback? onPressed;
  final bool opacity;
  final Color focusedBorderColor;
  final double borderWidth;
  final Duration animationDuration;
  final double opacityBeginScale;

  const _XlyFocusableWidget({
    required this.child,
    this.focusKey,
    this.onPressed,
    this.opacity = false,
    this.focusedBorderColor = Colors.white,
    this.borderWidth = 1.5,
    this.animationDuration = const Duration(milliseconds: 350),
    this.opacityBeginScale = 0.65,
  });

  @override
  _XlyFocusableWidgetState createState() => _XlyFocusableWidgetState();
}

class _XlyFocusableWidgetState extends State<_XlyFocusableWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;
  bool _isHovering = false;

  @override
  void initState() {
    _focusNode.addListener(_onFocusChange);
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    if (_hasFocus && widget.focusKey != null) {
      Get.find<XlyFocusController>().setFocus(widget.focusKey!);
    }
  }

  void _handleOnPressed() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      // Try to find and call the onPressed of the host widget
      final hostOnPressed = _findHostOnPressed(widget.child);
      if (hostOnPressed != null) {
        hostOnPressed();
      }
    }
  }

  VoidCallback? _findHostOnPressed(Widget child) {
    if (child is MyButton) {
      return child.onPressed;
    } else if (child is ElevatedButton ||
        child is TextButton ||
        child is OutlinedButton) {
      return (child as dynamic).onPressed as VoidCallback?;
    }
    // Add more widget types as needed
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            event is KeyUpEvent) {
          _handleOnPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.opacity
          ? TweenAnimationBuilder(
              duration: widget.animationDuration,
              tween: _getTween(),
              curve: Curves.ease,
              builder: (context, double value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: _buildCoreWidget(),
            )
          : _buildCoreWidget(),
    );
  }

  MouseRegion _buildCoreWidget() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _handleOnPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _hasFocus || _isHovering
                  ? widget.focusedBorderColor
                  : Colors.transparent,
              width: widget.borderWidth.w,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  Tween<double> _getTween() {
    return _hasFocus
        ? Tween(begin: widget.opacityBeginScale, end: 1)
        : Tween(begin: 1.0, end: widget.opacityBeginScale);
  }
}
