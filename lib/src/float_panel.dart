import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum PanelShape { rectangle, rounded }

enum DockType { inside, outside }

enum PanelState { expanded, closed }

class FloatPanel extends StatefulWidget {
  final Color borderColor;
  final double borderWidth;
  final double panelWidth;
  final double iconSize;
  final IconData initialPanelIcon;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color panelButtonColor;
  final Color customButtonColor;
  final PanelShape panelShape;
  final double panelOpenOffset;
  final int panelAnimDuration;
  final Curve panelAnimCurve;
  final DockType dockType;
  final bool dockActivate;
  final int dockAnimDuration;
  final Curve dockAnimCurve;
  final List<IconData> buttons;
  final void Function(int)? onPressed;
  final Color innerButtonFocusColor;
  final Color customButtonFocusColor;
  final double hiddenRatio;

  FloatPanel({
    Key? key,
    this.buttons = const [],
    this.borderColor = const Color(0xFF333333),
    this.borderWidth = 0,
    this.panelWidth = 60,
    this.iconSize = 24,
    this.initialPanelIcon = Icons.add,
    BorderRadius? borderRadius,
    this.panelOpenOffset = 5,
    this.panelAnimDuration = 600,
    this.panelAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.backgroundColor = const Color(0xFF333333),
    this.panelButtonColor = Colors.white,
    this.customButtonColor = Colors.white,
    this.panelShape = PanelShape.rounded,
    this.dockType = DockType.outside,
    this.dockAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.dockAnimDuration = 300,
    this.onPressed,
    this.innerButtonFocusColor = Colors.blue,
    this.customButtonFocusColor = Colors.red,
    this.dockActivate = false,
    this.hiddenRatio = 0.8, // 默认隐藏80%
  })  : borderRadius = borderRadius ?? BorderRadius.circular(30),
        super(key: key);

  @override
  _FloatPanelState createState() => _FloatPanelState();
}

class _FloatPanelState extends State<FloatPanel>
    with SingleTickerProviderStateMixin {
  PanelState _panelState = PanelState.closed;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  IconData _panelIcon = Icons.add;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isMainButtonHovered = false;
  late List<bool> _isCustomButtonHovered;
  late Size _lastScreenSize;
  bool _isRightSide = true;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _panelIcon = widget.initialPanelIcon;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.dockAnimDuration),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.dockAnimCurve,
    );
    _isCustomButtonHovered = List.generate(widget.buttons.length, (_) => false);
    _lastScreenSize = Size.zero;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePanelPosition());
  }

  void _initializePanelPosition() {
    final size = MediaQuery.of(context).size;
    _lastScreenSize = size;
    setState(() {
      _xOffset = size.width - widget.panelWidth.w;
      _yOffset = size.height / 2 - widget.panelWidth.w / 2;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _adjustToScreenSize();
    return Positioned(
      left: _getAdjustedXOffset(),
      top: _yOffset,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: _buildPanel(),
      ),
    );
  }

  void _adjustToScreenSize() {
    final currentSize = MediaQuery.of(context).size;
    if (currentSize != _lastScreenSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _adjustPositionOnResize(currentSize);
      });
    }
  }

  double _getAdjustedXOffset() {
    if (_panelState == PanelState.closed) {
      return _isRightSide ? _xOffset + _hiddenWidth : _xOffset - _hiddenWidth;
    }
    return _xOffset;
  }

  void _adjustPositionOnResize(Size newSize) {
    final widthRatio = newSize.width / _lastScreenSize.width;
    final heightRatio = newSize.height / _lastScreenSize.height;

    setState(() {
      _xOffset = (_xOffset * widthRatio).clamp(0, newSize.width - widget.panelWidth.w);
      _yOffset = (_yOffset * heightRatio).clamp(0, newSize.height - _panelHeight());
      _lastScreenSize = newSize;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _xOffset += details.delta.dx;
      _yOffset += details.delta.dy;
      _constrainPosition();
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panelState == PanelState.closed) {
      _animateToEdge();
    }
  }

  void _animateToEdge() {
    if (_panelState == PanelState.expanded) return;

    final size = MediaQuery.of(context).size;
    final centerX = _xOffset + widget.panelWidth.w / 2;
    _isRightSide = centerX > size.width / 2;
    final targetX = _isRightSide
        ? size.width - widget.panelWidth.w + _hiddenWidth
        : -_hiddenWidth;
    final targetY = _yOffset.clamp(0, size.height - _panelHeight());

    _animatePosition(targetX.toDouble(), targetY.toDouble());
  }

  void _animatePosition(double targetX, double targetY) {
    _animationController.reset();
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {
          _xOffset = lerpDouble(_xOffset, targetX, _animation.value)!;
          _yOffset = lerpDouble(_yOffset, targetY, _animation.value)!;
        });
      });
    _animationController.forward();
  }

  void _constrainPosition() {
    final size = MediaQuery.of(context).size;
    final panelHeight = _panelHeight();

    setState(() {
      _xOffset = _xOffset.clamp(
        -_hiddenWidth,
        size.width - widget.panelWidth.w + _hiddenWidth,
      );
      _yOffset = _yOffset.clamp(0, size.height - panelHeight);
    });
  }

  Widget _buildPanel() {
    return Container(
      width: widget.panelWidth.w,
      height: _panelHeight(),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: _borderRadius(),
        border: _panelBorder(),
      ),
      child: Wrap(
        direction: Axis.vertical,
        children: [
          _buildInnerButton(),
          if (_panelState == PanelState.expanded) ..._buildCustomButtons(),
        ],
      ),
    );
  }

  Widget _buildInnerButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isMainButtonHovered = true),
      onExit: (_) => setState(() => _isMainButtonHovered = false),
      child: GestureDetector(
        onTap: _onInnerButtonTapGesture,
        child: _FloatButton(
          icon: _panelIcon,
          color: _isMainButtonHovered
              ? widget.innerButtonFocusColor
              : widget.panelButtonColor,
          size: widget.panelWidth.w,
          iconSize: widget.iconSize.sp,
        ),
      ),
    );
  }

  List<Widget> _buildCustomButtons() {
    return List.generate(
      widget.buttons.length,
      (index) => MouseRegion(
        onEnter: (_) => setState(() => _isCustomButtonHovered[index] = true),
        onExit: (_) => setState(() => _isCustomButtonHovered[index] = false),
        child: GestureDetector(
          onTap: () => widget.onPressed?.call(index),
          child: _FloatButton(
            icon: widget.buttons[index],
            color: _isCustomButtonHovered[index]
                ? widget.customButtonFocusColor
                : widget.customButtonColor,
            size: widget.panelWidth.w,
            iconSize: widget.iconSize.sp,
          ),
        ),
      ),
    );
  }

  void _onInnerButtonTapGesture() {
    setState(() {
      _panelState = _panelState == PanelState.expanded
          ? PanelState.closed
          : PanelState.expanded;
      _panelIcon = _panelState == PanelState.expanded
          ? CupertinoIcons.minus_circle_fill
          : Icons.add;
      if (_panelState == PanelState.closed) {
        _animateToEdge();
      } else {
        _constrainPosition();
      }
    });
  }

  double _panelHeight() {
    return _panelState == PanelState.expanded
        ? widget.panelWidth.w * (widget.buttons.length + 1)
        : widget.panelWidth.w;
  }

  BorderRadius _borderRadius() {
    return widget.panelShape == PanelShape.rounded
        ? BorderRadius.circular(widget.panelWidth.w / 2)
        : widget.borderRadius;
  }

  Border? _panelBorder() {
    return widget.borderWidth > 0
        ? Border.all(
            color: widget.borderColor,
            width: widget.borderWidth.w,
          )
        : null;
  }

  double get _hiddenWidth => widget.panelWidth.w * 0.2; // 只隐藏20%
}

class _FloatButton extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;
  final double iconSize;

  const _FloatButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}
