import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum PanelShape { rectangle, rounded }

enum DockType { inside, outside }

enum PanelState { expanded, closed }

// 在文件顶部添加新的枚举类型
enum MyFloatPanelItemType { button, divider }

class MyFloatPanelItem {
  final IconData? icon;
  final VoidCallback? onPressed;
  final MyFloatPanelItemType type;

  MyFloatPanelItem({
    this.icon,
    this.onPressed,
    this.type = MyFloatPanelItemType.button,
  }) : assert(
          (type == MyFloatPanelItemType.button &&
                  icon != null &&
                  onPressed != null) ||
              (type == MyFloatPanelItemType.divider),
          '按钮类型必须提供图标和点击事件，分隔符类型不需要提供',
        );

  // 创建分隔符的工厂方法
  factory MyFloatPanelItem.divider() {
    return MyFloatPanelItem(type: MyFloatPanelItemType.divider);
  }
}

class MyFloatPanel extends StatefulWidget {
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
  final List<MyFloatPanelItem> items;
  final Color innerButtonFocusColor;
  final Color customButtonFocusColor;
  final double hiddenRatio;
  final Offset? initialPosition;

  MyFloatPanel({
    super.key,
    this.items = const [],
    this.borderColor = Colors.grey,
    // this.borderColor = const Color(0xFF333333),
    this.borderWidth = 0,
    this.panelWidth = 60,
    this.iconSize = 24,
    this.initialPanelIcon = Icons.add,
    BorderRadius? borderRadius,
    this.panelOpenOffset = 5,
    this.panelAnimDuration = 600,
    this.panelAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.backgroundColor = Colors.grey,
    // this.backgroundColor = const Color(0xFF333333),
    this.panelButtonColor = Colors.white,
    this.customButtonColor = Colors.white,
    this.panelShape = PanelShape.rounded,
    this.dockType = DockType.outside,
    this.dockAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.dockAnimDuration = 300,
    this.innerButtonFocusColor = Colors.blue,
    this.customButtonFocusColor = Colors.red,
    this.dockActivate = false,
    this.hiddenRatio = 0.8, // 默认隐藏80%
    this.initialPosition,
  }) : borderRadius = borderRadius ?? BorderRadius.circular(30);

  @override
  _MyFloatPanelState createState() => _MyFloatPanelState();
}

class _MyFloatPanelState extends State<MyFloatPanel>
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
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _initializeExpandAnimation();

    // 添加这个延迟调用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePanelPosition();
      _adjustPanelPosition(); // 再次调用以确保位置正确
    });
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
    _isCustomButtonHovered = List.generate(widget.items.length, (_) => false);
    _lastScreenSize = Size.zero;
    if (widget.initialPosition != null) {
      _xOffset = widget.initialPosition!.dx;
      _yOffset = widget.initialPosition!.dy;
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initializePanelPosition());
  }

  void _initializePanelPosition() {
    final size = MediaQuery.of(context).size;
    _lastScreenSize = size;
    setState(() {
      if (widget.initialPosition == null) {
        // 默认将面板放在右侧
        _isRightSide = true;
        _xOffset = size.width - widget.panelWidth.w / 2;
      } else {
        // 如果提供了初始位置，则使用它
        _xOffset = widget.initialPosition!.dx;
        _yOffset = widget.initialPosition!.dy;
        _isRightSide = _xOffset > size.width / 2;
      }

      // 使用与 _adjustPanelPosition 相同的逻辑
      if (_isRightSide) {
        _xOffset = size.width - widget.panelWidth.w / 2;
      } else {
        _xOffset = -widget.panelWidth.w / 2;
      }

      // 如果没有指定初始 y 位置，则将面板垂直居中
      if (widget.initialPosition == null) {
        _yOffset = size.height / 2 - widget.panelWidth.w / 2;
      }

      // 确保 y 位置在有效范围内
      _yOffset = _yOffset.clamp(0.0, size.height - _panelHeight());
    });
  }

  void _initializeExpandAnimation() {
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.panelAnimCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _adjustToScreenSize();
    // 确保面板在初始化时正确隐藏
    if (_panelState == PanelState.closed && _xOffset == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _adjustPanelPosition());
    }
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
      return _isRightSide ? _xOffset : _xOffset + widget.panelWidth.w / 2;
    }
    return _xOffset;
  }

  void _adjustPositionOnResize(Size newSize) {
    final widthRatio = newSize.width / _lastScreenSize.width;
    final heightRatio = newSize.height / _lastScreenSize.height;

    setState(() {
      _xOffset =
          (_xOffset * widthRatio).clamp(0, newSize.width - widget.panelWidth.w);
      _yOffset =
          (_yOffset * heightRatio).clamp(0, newSize.height - _panelHeight());
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
      _adjustPanelPosition();
    } else {
      _constrainPosition();
    }
  }

  void _animateToEdge() {
    final size = MediaQuery.of(context).size;
    final centerX = _xOffset + widget.panelWidth.w / 2;
    _isRightSide = centerX > size.width / 2;
    final targetX = _isRightSide
        ? size.width - widget.panelWidth.w / 2 // 修改这里，隐藏一半
        : -widget.panelWidth.w / 2; // 修改这里，隐藏一半
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
      if (_panelState == PanelState.closed) {
        _xOffset = _xOffset.clamp(
          -widget.panelWidth.w / 2, // 修改这里
          size.width - widget.panelWidth.w / 2, // 修改这里
        );
      } else {
        _xOffset = _xOffset.clamp(
          0,
          size.width - widget.panelWidth.w,
        );
      }
      _yOffset = _yOffset.clamp(0, size.height - panelHeight);
    });
  }

  Widget _buildPanel() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          width: widget.panelWidth.w,
          height: _panelHeight(),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius, // 直接使用 widget.borderRadius
          ),
          child: SingleChildScrollView(
            child: Wrap(
              direction: Axis.vertical,
              children: [
                _buildInnerButton(),
                if (_panelState == PanelState.expanded)
                  ..._buildCustomButtons(_expandAnimation.value),
              ],
            ),
          ),
        );
      },
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

  List<Widget> _buildCustomButtons(double animationValue) {
    return widget.items.map((item) {
      if (item.type == MyFloatPanelItemType.divider) {
        return SizedBox(
          height: widget.panelWidth.w * 0.2 * animationValue,
          child: Opacity(
            opacity: animationValue,
            child: Center(
              child: Container(
                height: 1,
                width: widget.panelWidth.w * 0.8,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(
                      color: widget.backgroundColor.brighten(20),
                      width: 0.5,
                    ),
                    bottom: BorderSide(
                      color: widget.backgroundColor.darken(20),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.darken(30),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                    BoxShadow(
                      color: widget.backgroundColor.brighten(30),
                      offset: const Offset(0, -1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: MouseRegion(
              onEnter: (_) => setState(() =>
                  _isCustomButtonHovered[widget.items.indexOf(item)] = true),
              onExit: (_) => setState(() =>
                  _isCustomButtonHovered[widget.items.indexOf(item)] = false),
              child: GestureDetector(
                onTap: item.onPressed,
                child: _FloatButton(
                  icon: item.icon!,
                  color: _isCustomButtonHovered[widget.items.indexOf(item)]
                      ? widget.customButtonFocusColor
                      : widget.customButtonColor,
                  size: widget.panelWidth.w,
                  iconSize: widget.iconSize.sp,
                ),
              ),
            ),
          ),
        );
      }
    }).toList();
  }

  void _onInnerButtonTapGesture() {
    setState(() {
      if (_panelState == PanelState.expanded) {
        _panelState = PanelState.closed;
        _panelIcon = Icons.add;
        _adjustPanelPosition();
        _animationController.reverse();
      } else {
        _panelState = PanelState.expanded;
        _panelIcon = CupertinoIcons.minus_circle_fill;
        _constrainPosition();
        _animationController.forward();
      }
    });
  }

  double _panelHeight() {
    if (_panelState == PanelState.expanded) {
      double height = widget.panelWidth.w; // 主按钮的高度
      for (var item in widget.items) {
        height += item.type == MyFloatPanelItemType.divider
            ? widget.panelWidth.w * 0.2 * _expandAnimation.value // 分隔符的高度
            : widget.panelWidth.w * _expandAnimation.value; // 普通按钮的高度
      }
      return height;
    }
    return widget.panelWidth.w;
  }

  double get _hiddenWidth => widget.panelWidth.w / 2; // 隐藏一半

  // 在 _MyFloatPanelState 类中添加一个新方法
  void _adjustPanelPosition() {
    final size = MediaQuery.of(context).size;
    setState(() {
      if (_panelState == PanelState.closed) {
        if (_isRightSide) {
          _xOffset = size.width - widget.panelWidth.w / 2;
        } else {
          _xOffset = -widget.panelWidth.w / 2;
        }
      } else {
        _xOffset = _xOffset.clamp(0.0, size.width - widget.panelWidth.w);
      }
      _yOffset = _yOffset.clamp(0.0, size.height - _panelHeight());
    });
  }
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
    return SizedBox(
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

// 在文件顶部添加以下扩展方法
extension ColorBrightness on Color {
  Color brighten([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var p = percent / 100;
    return Color.fromARGB(
      alpha,
      red + ((255 - red) * p).round(),
      green + ((255 - green) * p).round(),
      blue + ((255 - blue) * p).round(),
    );
  }

  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var p = percent / 100;
    return Color.fromARGB(
      alpha,
      (red * (1 - p)).round(),
      (green * (1 - p)).round(),
      (blue * (1 - p)).round(),
    );
  }
}
