import 'dart:math' as math;
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
    this.dockAnimDuration = 500, // 将停靠动画时间从300ms增加到500ms
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
    with TickerProviderStateMixin {
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
  late AnimationController _dockAnimationController;
  late Animation<double> _dockAnimation;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _initializeExpandAnimation();
    _initializeDockAnimation();

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
      duration: Duration(
          milliseconds: widget.panelAnimDuration), // 使用 panelAnimDuration
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
        _isRightSide = _xOffset + widget.panelWidth.w / 2 > size.width / 2;
      }

      // 根据 _isRightSide 调整 _xOffset
      if (_isRightSide) {
        _xOffset = size.width - widget.panelWidth.w / 2;
      } else {
        _xOffset = -widget.panelWidth.w / 2;
      }

      // 如果没有指定初始 y 位置，则面板垂直居中
      if (widget.initialPosition == null) {
        _yOffset = size.height / 2 - widget.panelWidth.w / 2;
      }

      // 确保 y 位置在有效范围内
      _yOffset = _yOffset.clamp(0.0, size.height - _panelHeight());
    });
  }

  void _initializeExpandAnimation() {
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: widget.panelAnimCurve,
    );
  }

  void _initializeDockAnimation() {
    _dockAnimationController = AnimationController(
      duration: Duration(milliseconds: widget.dockAnimDuration),
      vsync: this,
    );
    _dockAnimation = CurvedAnimation(
      parent: _dockAnimationController,
      curve: widget.dockAnimCurve,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dockAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _adjustToScreenSize();
    if (_panelState == PanelState.closed && _xOffset == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _animateToEdge());
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_expandAnimation, _dockAnimation]),
      builder: (context, child) {
        return Positioned(
          left: _getAdjustedXOffset(),
          top: _yOffset,
          child: GestureDetector(
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: _buildPanel(),
          ),
        );
      },
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
      return _xOffset;
    }
    return math.max(_xOffset, 0);
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
      double newXOffset = _xOffset + details.delta.dx;
      double newYOffset = _yOffset + details.delta.dy;

      // 允许面板在左侧时也能被拖出
      if (_panelState == PanelState.closed) {
        if (_isRightSide) {
          newXOffset = newXOffset.clamp(
            widget.panelWidth.w / 2,
            MediaQuery.of(context).size.width - widget.panelWidth.w / 2,
          );
        } else {
          newXOffset = newXOffset.clamp(
            -widget.panelWidth.w / 2,
            MediaQuery.of(context).size.width - widget.panelWidth.w / 2,
          );
        }
      } else {
        newXOffset = newXOffset.clamp(
          0,
          MediaQuery.of(context).size.width - widget.panelWidth.w,
        );
      }

      _xOffset = newXOffset;
      _yOffset = newYOffset;
      _constrainPosition();
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panelState == PanelState.closed) {
      _animateToEdge();
    } else {
      _constrainPosition();
    }
  }

  void _animateToEdge() {
    if (_panelState != PanelState.closed) return;

    final size = MediaQuery.of(context).size;
    _isRightSide = _xOffset + widget.panelWidth.w / 2 > size.width / 2;
    final targetX = _isRightSide
        ? size.width - widget.panelWidth.w / 2
        : -widget.panelWidth.w / 2;
    final targetY = _yOffset.clamp(0, size.height - _panelHeight());

    _dockAnimationController.reset();
    _dockAnimation =
        Tween<double>(begin: 0, end: 1).animate(_dockAnimationController)
          ..addListener(() {
            setState(() {
              _xOffset = lerpDouble(_xOffset, targetX, _dockAnimation.value)!;
              _yOffset = lerpDouble(_yOffset, targetY, _dockAnimation.value)!;
            });
          });
    _dockAnimationController.forward();
  }

  void _animatePosition(double targetX, double targetY) {
    _animationController.reset();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, // 使用更平滑的缓动曲线
      ),
    )..addListener(() {
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
          -widget.panelWidth.w / 2,
          size.width - widget.panelWidth.w / 2,
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

  double get _hiddenWidth => widget.panelWidth.w / 2; // 隐藏半

  // 在 _MyFloatPanelState 类中添加一个新方法
  void _adjustPanelPosition() {
    final size = MediaQuery.of(context).size;
    setState(() {
      if (_panelState == PanelState.closed) {
        _isRightSide = _xOffset + widget.panelWidth.w / 2 > size.width / 2;
        if (_isRightSide) {
          _xOffset = size.width - widget.panelWidth.w / 2;
        } else {
          _xOffset = widget.panelWidth.w / 2;
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
