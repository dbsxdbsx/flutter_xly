part of '../xly.dart';

// 新的数据模型：浮动面板的按钮定义
class FloatPanelIconBtn {
  final IconData icon;
  final String? id; // 参与联动时填写；不需要联动可为空
  final FutureOr<void> Function()? onTap;
  final String? tooltip;
  final bool? disabled; // 显式禁用优先于联动

  const FloatPanelIconBtn({
    required this.icon,
    this.id,
    this.onTap,
    this.tooltip,
    this.disabled,
  });
}

enum PanelShape { rectangle, rounded }

enum DockType { inside, outside }

enum PanelState { expanded, closed }

/// 禁用样式类型
enum DisabledStyleType { defaultX, dimOnly, custom }

/// 禁用样式配置
class DisabledStyle {
  final DisabledStyleType type;
  final Widget Function(double iconSize)? overlayBuilder;
  const DisabledStyle._(this.type, [this.overlayBuilder]);
  const DisabledStyle.defaultX() : this._(DisabledStyleType.defaultX);
  const DisabledStyle.dimOnly() : this._(DisabledStyleType.dimOnly);
  const DisabledStyle.custom(Widget Function(double iconSize) builder)
      : this._(DisabledStyleType.custom, builder);
}

/// 全局浮动面板管理器（类似 MyTray.to）
class FloatPanel extends GetxService {
  static FloatPanel get to => Get.find<FloatPanel>();

  // 内容（仅保留新方式）
  final RxList<FloatPanelIconBtn> items = <FloatPanelIconBtn>[].obs;

  // 当前“禁用联动”的 id 集合，支持多个
  final RxSet<String> disabledIds = <String>{}.obs;

  // 持久“常亮”集合（不影响启用状态）
  final RxSet<String> highlightedIds = <String>{}.obs;
  // 访问器（可用于订阅）
  RxSet<String> get highlightedIdsRx => highlightedIds;
  // 工具方法
  bool isHighlighted(String id) => highlightedIds.contains(id);

  // 显隐
  final RxBool visible = true.obs;
  void show() => visible.value = true;
  void hide() => visible.value = false;
  void toggle() => visible.value = !visible.value;

  // 样式（默认值与示例一致）
  final RxDouble panelWidth = 60.0.obs;
  final Rx<Color> backgroundColor = const Color(0xFF222222).obs;
  final Rx<PanelShape> panelShape = PanelShape.rectangle.obs;
  final Rx<BorderRadius> borderRadius = BorderRadius.circular(10).obs;
  final Rx<DockType> dockType = DockType.outside.obs;
  final Rx<Color> panelButtonColor = Colors.blueGrey.obs;
  final Rx<Color> customButtonColor = Colors.grey.obs;
  final RxBool dockActivate = true.obs;
  final Rx<Color> handleFocusColor = Colors.blue.obs; // handle按钮悬停蓝色
  final Rx<Color> focusColor = Colors.red.obs; // 其他按钮悬停红色

  // 新增：可配置但有默认值
  final Rx<Color> borderColor = const Color(0xFF333333).obs;
  final Rx<IconData> initialPanelIcon = Icons.add.obs;
  final RxInt panelAnimDuration = 600.obs;
  final Rx<Curve> panelAnimCurve = Curves.fastLinearToSlowEaseIn.obs;
  final RxInt dockAnimDuration = 300.obs;
  final Rx<Curve> dockAnimCurve = Curves.fastLinearToSlowEaseIn.obs;

  // 禁用样式（默认黄色X覆盖）
  final Rx<DisabledStyle> disabledStyle = const DisabledStyle.defaultX().obs;

  // 新的配置入口
  void configure({
    List<FloatPanelIconBtn>? items,
    bool? visible,
    // 新增可选配置（全部有默认值）
    Color? borderColor,
    IconData? initialPanelIcon,
    int? panelAnimDuration,
    Curve? panelAnimCurve,
    int? dockAnimDuration,
    Curve? dockAnimCurve,
  }) {
    if (items != null) this.items.value = items;
    if (visible != null) this.visible.value = visible;
    if (borderColor != null) this.borderColor.value = borderColor;
    if (initialPanelIcon != null) {
      this.initialPanelIcon.value = initialPanelIcon;
    }
    if (panelAnimDuration != null) {
      this.panelAnimDuration.value = panelAnimDuration;
    }
    if (panelAnimCurve != null) this.panelAnimCurve.value = panelAnimCurve;
    if (dockAnimDuration != null) {
      this.dockAnimDuration.value = dockAnimDuration;
    }
    if (dockAnimCurve != null) this.dockAnimCurve.value = dockAnimCurve;
  }

  // 访问器：监听当前“禁用联动”的 id 集合（RxSet<String>）
  RxSet<String> get disabledIdsRx => disabledIds;

  // 实用便捷方法
  bool isDisabled(String id) => disabledIds.contains(id);

  // 针对单个图标按钮的链式控制句柄
  FloatPanelIconBtnCtrl iconBtn(String id) => FloatPanelIconBtnCtrl._(id);

  // 所有图标按钮的集合句柄
  FloatPanelIconBtnsCtrl get iconBtns => const FloatPanelIconBtnsCtrl._();
}

// 所有图标按钮的集合控制器（基于启用语义）
class FloatPanelIconBtnsCtrl {
  const FloatPanelIconBtnsCtrl._();

  // 启用全部（清空禁用集合）
  void enableAll() => FloatPanel.to.disabledIds.clear();

  // 为指定 id 设置启用状态（语法糖，等价于 iconBtn(id).setEnabled(value)）
  void setEnabled(String id, bool value) {
    FloatPanel.to.iconBtn(id).setEnabled(value);
  }

  // 切换指定 id 的启用状态（语法糖，等价于 iconBtn(id).toggleEnabled()）
  void toggleEnabled(String id) {
    FloatPanel.to.iconBtn(id).toggleEnabled();
  }
}

// 针对单个图标按钮的链式控制器（语法糖）
class FloatPanelIconBtnCtrl {
  final String id;
  FloatPanelIconBtnCtrl._(this.id);

  // 设置启用状态；true=启用（从禁用集合移除），false=禁用（加入禁用集合）
  FloatPanelIconBtnCtrl setEnabled(bool value) {
    final fp = FloatPanel.to;
    if (value) {
      fp.disabledIds.remove(id);
    } else {
      fp.disabledIds.add(id);
    }
    return this;
  }

  // 便捷切换启用状态（仅联动维度，不含显式 disabled: true）
  FloatPanelIconBtnCtrl toggleEnabled() {
    final fp = FloatPanel.to;
    if (fp.disabledIds.contains(id)) {
      fp.disabledIds.remove(id);
    } else {
      fp.disabledIds.add(id);
    }
    return this;
  }

  /// 设置该 id 的“常亮（高亮显示）”状态；不影响启用/禁用
  FloatPanelIconBtnCtrl setHighlighted(bool value) {
    final set = FloatPanel.to.highlightedIds;
    if (value) {
      set.add(id);
    } else {
      set.remove(id);
    }
    return this;
  }

  /// toggle highlighted state
  FloatPanelIconBtnCtrl toggleHighlighted() {
    final set = FloatPanel.to.highlightedIds;
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    return this;
  }

  /// whether current id is highlighted
  bool get isHighlighted => FloatPanel.to.highlightedIds.contains(id);

  // 查询当前是否处于启用（仅联动维度，不含显式 disabled: true）
  bool get isEnabled => !FloatPanel.to.isDisabled(id);
}

class FloatBoxController extends GetxController {
  // --- Base Design Configuration (不缩放的设计值) ---
  final List<FloatPanelIconBtn> items;
  final double basePanelWidth;
  final Color borderColor;
  final double baseBorderWidth;
  final double baseIconSize;
  final IconData initialPanelIcon;
  final BorderRadius baseBorderRadius;
  final Color backgroundColor;
  final Color panelButtonColor;
  final Color customButtonColor;
  final PanelShape panelShape;
  final double basePanelOpenOffset;
  final int panelAnimDuration;
  final Curve panelAnimCurve;
  final DockType dockType;
  final double baseDockOffset;
  final int dockAnimDuration;
  final Curve dockAnimCurve;
  final Color innerButtonFocusColor;
  final Color customButtonFocusColor;

  // --- Current Scaled Values (运行时更新的缩放值) ---
  final RxDouble currentPanelWidth = 0.0.obs;
  final RxDouble currentBorderWidth = 0.0.obs;
  final RxDouble currentIconSize = 0.0.obs;
  final Rx<BorderRadius> currentBorderRadius = BorderRadius.zero.obs;
  final RxDouble currentPanelOpenOffset = 0.0.obs;
  final RxDouble currentDockOffset = 0.0.obs;

  // --- Reactive State ---
  final Rx<PanelState> panelState = PanelState.closed.obs;
  final RxDouble xOffset = 0.0.obs;
  final RxDouble yOffset = 0.0.obs;
  final Rx<IconData> panelIcon;
  final RxList<bool> isFocusColors = <bool>[].obs;
  final RxInt movementSpeed = 0.obs;

  // --- Screen Size ---
  final RxDouble _pageWidth = 0.0.obs;
  final RxDouble _pageHeight = 0.0.obs;

  // --- Internal ---
  double _xOffsetRatio = 0.0;
  double _yOffsetRatio = 1 / 3;
  double _mouseOffsetX = 0.0;
  double _mouseOffsetY = 0.0;
  double? _oldYOffset;
  double? _oldYOffsetRatio;
  bool _isFirstTimePositioning = true;

  FloatBoxController({
    required this.items,
    required this.basePanelWidth,
    required this.borderColor,
    required this.baseBorderWidth,
    required this.baseIconSize,
    required this.initialPanelIcon,
    required this.baseBorderRadius,
    required this.backgroundColor,
    required this.panelButtonColor,
    required this.customButtonColor,
    required this.panelShape,
    required this.basePanelOpenOffset,
    required this.panelAnimDuration,
    required this.panelAnimCurve,
    required this.dockType,
    required this.baseDockOffset,
    required this.dockAnimDuration,
    required this.dockAnimCurve,
    required this.innerButtonFocusColor,
    required this.customButtonFocusColor,
  }) : panelIcon = initialPanelIcon.obs {
    for (var i = 0; i < (items.length + 1); i++) {
      isFocusColors.add(false);
    }
    // 初始化当前缩放值（将在 updateScaledDimensions 中更新）
    currentPanelWidth.value = basePanelWidth;
    currentBorderWidth.value = baseBorderWidth;
    currentIconSize.value = baseIconSize;
    currentBorderRadius.value = baseBorderRadius;
    currentPanelOpenOffset.value = basePanelOpenOffset;
    currentDockOffset.value = baseDockOffset;
  }

  /// 更新缩放后的尺寸值（由 UI 层调用）
  void updateScaledDimensions({
    required double scaledPanelWidth,
    required double scaledBorderWidth,
    required double scaledIconSize,
    required BorderRadius scaledBorderRadius,
    required double scaledPanelOpenOffset,
    required double scaledDockOffset,
  }) {
    currentPanelWidth.value = scaledPanelWidth;
    currentBorderWidth.value = scaledBorderWidth;
    currentIconSize.value = scaledIconSize;
    currentBorderRadius.value = scaledBorderRadius;
    currentPanelOpenOffset.value = scaledPanelOpenOffset;
    currentDockOffset.value = scaledDockOffset;
  }

  void updateScreenSize(double pWidth, double pHeight) {
    bool screenSizeChanged =
        (_pageWidth.value != pWidth || _pageHeight.value != pHeight);
    if (pWidth <= 0 || pHeight <= 0) return;
    _pageWidth.value = pWidth;
    _pageHeight.value = pHeight;
    if (_isFirstTimePositioning) {
      _initializePosition();
      _isFirstTimePositioning = false;
    } else if (screenSizeChanged) {
      xOffset.value = _pageWidth.value * _xOffsetRatio;
      yOffset.value = _pageHeight.value * _yOffsetRatio;
      if (_oldYOffsetRatio != null) {
        _oldYOffset = _pageHeight.value * _oldYOffsetRatio!;
      }
      _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
      _calcOffsetWhenForceDock();
    }
  }

  void _initializePosition() {
    if (_pageWidth.value == 0 || _pageHeight.value == 0) return;
    xOffset.value = _pageWidth.value;
    _getProperDockXOffset();
    _xOffsetRatio = xOffset.value / _pageWidth.value;
    yOffset.value = _pageHeight.value * _yOffsetRatio;
    _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
    _calcOffsetWhenForceDock();
  }

  void onInnerButtonTap() {
    movementSpeed.value = panelAnimDuration;
    if (panelState.value == PanelState.expanded) {
      panelState.value = PanelState.closed;
      _calcOffsetWhenForceDock();
      panelIcon.value = initialPanelIcon;
    } else {
      panelState.value = PanelState.expanded;
      _calcOffsetWhenExpand();
      panelIcon.value = CupertinoIcons.minus_circle_fill;
    }
  }

  void onPanStartGesture(Offset globalPosition) {
    _mouseOffsetX = globalPosition.dx - xOffset.value;
    _mouseOffsetY = globalPosition.dy - yOffset.value;
  }

  void onPanUpdateGesture(Offset globalPosition) {
    _adjustPositionOnPanUpdate(globalPosition.dx, globalPosition.dy);
    if (_pageWidth.value > 0) {
      _xOffsetRatio = xOffset.value / _pageWidth.value;
    }
    if (_pageHeight.value > 0) {
      _yOffsetRatio = yOffset.value / _pageHeight.value;
    }
  }

  void _adjustPositionOnPanUpdate(double globalDx, double globalDy,
      {bool isReScale = false}) {
    movementSpeed.value = 0;
    double newY = isReScale ? globalDy : globalDy - _mouseOffsetY;
    if (newY < 0 + _dockBoundary()) newY = 0 + _dockBoundary();
    if (newY > (_pageHeight.value - effectivePanelHeight) - _dockBoundary()) {
      newY = (_pageHeight.value - effectivePanelHeight) - _dockBoundary();
    }
    yOffset.value = newY;

    double newX = isReScale ? globalDx : globalDx - _mouseOffsetX;
    if (newX < 0 + _dockBoundary()) newX = 0 + _dockBoundary();
    if (newX > (_pageWidth.value - currentPanelWidth.value) - _dockBoundary()) {
      newX = (_pageWidth.value - currentPanelWidth.value) - _dockBoundary();
    }
    xOffset.value = newX;

    if (!isReScale) {
      _oldYOffset = null;
      _oldYOffsetRatio = null;
    } else if (_oldYOffsetRatio != null && _pageHeight.value > 0) {
      _oldYOffset = _oldYOffsetRatio! * _pageHeight.value;
    }
  }

  void onPanEndGesture() {
    _calcOffsetWhenForceDock();
    if (_pageWidth.value > 0) {
      _xOffsetRatio = xOffset.value / _pageWidth.value;
    }
    if (_pageHeight.value > 0) {
      _yOffsetRatio = yOffset.value / _pageHeight.value;
    }
  }

  void setButtonFocus(int index, bool focused) {
    if (index >= 0 && index < isFocusColors.length) {
      isFocusColors[index] = focused;
    }
  }

  double _dockBoundary() => dockType == DockType.inside
      ? currentDockOffset.value
      : -currentDockOffset.value;

  BorderRadius get effectiveBorderRadius => panelShape == PanelShape.rectangle
      ? currentBorderRadius.value
      : BorderRadius.circular(currentPanelWidth.value);

  double get effectivePanelHeight => panelState.value == PanelState.expanded
      ? currentPanelWidth.value * (items.length + 1) + currentBorderWidth.value
      : currentPanelWidth.value + (currentBorderWidth.value * 2);

  void _calcPanelYOffsetWhenOpening() {
    if (yOffset.value < 0) {
      _updateOldYOffset();
      yOffset.value = 0.0 +
          currentPanelWidth.value +
          currentBorderWidth.value +
          _dockBoundary();
    } else {
      if (yOffset.value + effectivePanelHeight >
          _pageHeight.value + _dockBoundary()) {
        final newYOffsetValue =
            _pageHeight.value - effectivePanelHeight + _dockBoundary();
        if (newYOffsetValue != yOffset.value) {
          _updateOldYOffset();
          yOffset.value = newYOffsetValue;
        }
      } else {
        _oldYOffset = null;
        _updateOldYOffset();
      }
    }
  }

  void _updateOldYOffset({bool setNull = false}) {
    if (setNull || _pageHeight.value == 0) {
      _oldYOffset = null;
      _oldYOffsetRatio = null;
    } else {
      _oldYOffset = yOffset.value;
      _oldYOffsetRatio = _oldYOffset! / _pageHeight.value;
    }
  }

  double _openDockLeft() {
    if (_pageWidth.value == 0) return xOffset.value;
    if (xOffset.value < (_pageWidth.value / 2)) {
      return currentPanelOpenOffset.value;
    }
    return ((_pageWidth.value - currentPanelWidth.value)) -
        (currentPanelOpenOffset.value);
  }

  Border? get effectivePanelBorder => currentBorderWidth.value <= 0
      ? null
      : Border.all(color: borderColor, width: currentBorderWidth.value);

  void _calcOffsetWhenForceDock() {
    if (panelState.value == PanelState.closed) {
      movementSpeed.value = dockAnimDuration;
      _getProperDockXOffset();
      if (_oldYOffset != null && yOffset.value != _oldYOffset!) {
        yOffset.value = _oldYOffset!;
      }
    }
  }

  void _getProperDockXOffset() {
    if (_pageWidth.value == 0) return;
    double center = xOffset.value + (currentPanelWidth.value / 2);
    final dockEdgeOffset = (center < _pageWidth.value / 2)
        ? -currentPanelWidth.value
        : (_pageWidth.value - currentPanelWidth.value);
    xOffset.value = dockEdgeOffset - _dockBoundary();
  }

  void _calcOffsetWhenExpand() {
    xOffset.value = _openDockLeft();
    _calcPanelYOffsetWhenOpening();
  }
}

class _FloatBoxPanel extends StatelessWidget {
  final Key? panelKey;
  final Color borderColor;
  final double borderWidthInput;
  final double panelWidthInput;
  final double iconSizeInput;
  final IconData initialPanelIcon;
  final BorderRadius? borderRadiusInput;
  final Color backgroundColor;
  final Color panelButtonColor;
  final Color customButtonColor;
  final PanelShape panelShape;
  final double panelOpenOffsetInput;
  final int panelAnimDuration;
  final Curve panelAnimCurve;
  final DockType dockType;
  final bool dockActivate;
  final int dockAnimDuration;
  final Curve dockAnimCurve;
  final List<FloatPanelIconBtn> items;
  final Color innerButtonFocusColor;
  final Color customButtonFocusColor;

  // defaults (avoid dependency on user_code/global.dart)
  static const double _kDefaultPanelWidth = 50.0;
  static const double _kDefaultBorderRadius = 10.0;

  // Calculated properties
  final double finalPanelWidth;
  final double finalBorderWidth;
  final double finalIconSize;
  final BorderRadius finalBorderRadius;
  final double finalPanelOpenOffset;
  final double finalDockOffset;

  _FloatBoxPanel({
    this.panelKey,
    this.items = const [],
    this.borderColor = const Color(0xFF333333),
    this.borderWidthInput = 0,
    this.panelWidthInput = _kDefaultPanelWidth,
    this.iconSizeInput = 24,
    this.initialPanelIcon = Icons.add,
    this.borderRadiusInput,
    this.backgroundColor = const Color(0xFF333333),
    this.panelButtonColor = Colors.white,
    this.customButtonColor = Colors.white,
    this.panelShape = PanelShape.rounded,
    this.panelOpenOffsetInput = 5.0,
    this.panelAnimDuration = 600,
    this.panelAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.dockType = DockType.outside,
    this.dockAnimDuration = 300,
    this.dockAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.innerButtonFocusColor = Colors.blue,
    this.customButtonFocusColor = Colors.red,
    this.dockActivate = false,
  })  : finalPanelWidth = panelWidthInput,
        finalBorderWidth =
            borderWidthInput * (panelWidthInput / _kDefaultPanelWidth),
        finalIconSize = iconSizeInput * (panelWidthInput / _kDefaultPanelWidth),
        finalBorderRadius = borderRadiusInput ??
            BorderRadius.circular(_kDefaultBorderRadius *
                (panelWidthInput / _kDefaultPanelWidth)),
        finalPanelOpenOffset =
            panelOpenOffsetInput * (panelWidthInput / _kDefaultPanelWidth),
        finalDockOffset = panelWidthInput / 2,
        super(key: panelKey) {
    Get.put(
      FloatBoxController(
        items: items,
        basePanelWidth: finalPanelWidth,
        borderColor: borderColor,
        baseBorderWidth: finalBorderWidth,
        baseIconSize: finalIconSize,
        initialPanelIcon: initialPanelIcon,
        baseBorderRadius: finalBorderRadius,
        backgroundColor: backgroundColor,
        panelButtonColor: panelButtonColor,
        customButtonColor: customButtonColor,
        panelShape: panelShape,
        basePanelOpenOffset: finalPanelOpenOffset,
        panelAnimDuration: panelAnimDuration,
        panelAnimCurve: panelAnimCurve,
        dockType: dockType,
        baseDockOffset: finalDockOffset,
        dockAnimDuration: dockAnimDuration,
        dockAnimCurve: dockAnimCurve,
        innerButtonFocusColor: innerButtonFocusColor,
        customButtonFocusColor: customButtonFocusColor,
      ),
      tag: panelKey?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FloatBoxController>(tag: panelKey?.toString());
    ctrl.updateScreenSize(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    // 在每次 build 时计算当前缩放值并更新控制器
    final scaledPanelWidth = finalPanelWidth.w;
    final scaledBorderWidth = finalBorderWidth.w;
    final scaledIconSize = finalIconSize.sp;
    final scaledBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(finalBorderRadius.topLeft.x.r),
      topRight: Radius.circular(finalBorderRadius.topRight.x.r),
      bottomLeft: Radius.circular(finalBorderRadius.bottomLeft.x.r),
      bottomRight: Radius.circular(finalBorderRadius.bottomRight.x.r),
    );
    final scaledPanelOpenOffset = finalPanelOpenOffset.w;
    final scaledDockOffset = finalDockOffset.w;

    // 更新控制器的当前缩放值
    ctrl.updateScaledDimensions(
      scaledPanelWidth: scaledPanelWidth,
      scaledBorderWidth: scaledBorderWidth,
      scaledIconSize: scaledIconSize,
      scaledBorderRadius: scaledBorderRadius,
      scaledPanelOpenOffset: scaledPanelOpenOffset,
      scaledDockOffset: scaledDockOffset,
    );

    return Obx(() => AnimatedPositioned(
          duration: Duration(milliseconds: ctrl.movementSpeed.value),
          top: ctrl.yOffset.value,
          left: ctrl.xOffset.value,
          curve: ctrl.dockAnimCurve,
          child: AnimatedContainer(
            duration: Duration(milliseconds: ctrl.panelAnimDuration),
            width: ctrl.currentPanelWidth.value,
            height: ctrl.effectivePanelHeight,
            decoration: BoxDecoration(
              color: ctrl.backgroundColor,
              borderRadius: ctrl.effectiveBorderRadius,
              border: ctrl.effectivePanelBorder,
            ),
            curve: ctrl.panelAnimCurve,
            child: Wrap(
              direction: Axis.horizontal,
              children: [
                GestureDetector(
                  onPanEnd: (_) => ctrl.onPanEndGesture(),
                  onPanStart: (d) => ctrl.onPanStartGesture(d.globalPosition),
                  onPanUpdate: (d) => ctrl.onPanUpdateGesture(d.globalPosition),
                  onTap: () => ctrl.onInnerButtonTap(),
                  child: MouseRegion(
                    onEnter: (_) => ctrl.setButtonFocus(0, true),
                    onExit: (_) => ctrl.setButtonFocus(0, false),
                    cursor: SystemMouseCursors.click,
                    child: Obx(() => _FloatButton(
                          focusColor: ctrl.innerButtonFocusColor,
                          size: ctrl.currentPanelWidth.value,
                          icon: ctrl.panelIcon.value,
                          color: ctrl.panelButtonColor,
                          hightLight: ctrl.isFocusColors.isNotEmpty
                              ? ctrl.isFocusColors[0]
                              : false,
                          iconSize: ctrl.currentIconSize.value,
                        )),
                  ),
                ),
                Obx(() => Visibility(
                      visible: ctrl.panelState.value == PanelState.expanded,
                      child: Column(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final disabledSet = FloatPanel.to.disabledIds;
                          final highlightedSet = FloatPanel.to.highlightedIds;
                          final bool iconBtnDisabledMatch =
                              item.id != null && disabledSet.contains(item.id);
                          final bool explicitDisabled = item.disabled == true;
                          final bool isEnabled =
                              !(iconBtnDisabledMatch || explicitDisabled);
                          final bool isDisabledLinked = iconBtnDisabledMatch;
                          final bool forcedHighlighted = item.id != null &&
                              highlightedSet.contains(item.id);
                          return GestureDetector(
                            onPanStart: (d) =>
                                ctrl.onPanStartGesture(d.globalPosition),
                            onPanUpdate: (d) =>
                                ctrl.onPanUpdateGesture(d.globalPosition),
                            onTap: () async {
                              if (!isEnabled) return;
                              if (item.onTap != null) {
                                try {
                                  await item.onTap!();
                                } catch (e, s) {
                                  XlyLogger.error(
                                      'FloatPanelIconBtn.onTap error', e, s);
                                }
                              }
                            },
                            child: MouseRegion(
                              onEnter: (_) =>
                                  ctrl.setButtonFocus(index + 1, true),
                              onExit: (_) =>
                                  ctrl.setButtonFocus(index + 1, false),
                              cursor: SystemMouseCursors.click,
                              child: _FloatButton(
                                key: ValueKey(
                                    'float_button_${index}_$isEnabled'),
                                focusColor: ctrl.customButtonFocusColor,
                                size: ctrl.currentPanelWidth.value,
                                icon: item.icon,
                                color: ctrl.customButtonColor,
                                hightLight:
                                    ctrl.isFocusColors.length > index + 1
                                        ? ctrl.isFocusColors[index + 1]
                                        : false,
                                iconSize: ctrl.currentIconSize.value,
                                enabled: isEnabled,
                                isHighlighted:
                                    forcedHighlighted || isDisabledLinked,
                              ),
                            ),
                          );
                        }),
                      ),
                    )),
              ],
            ),
          ),
        ));
  }
}

class _FloatButton extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;
  final double iconSize;
  final bool hightLight;
  final Color focusColor;
  final bool enabled;
  final bool isHighlighted;

  const _FloatButton({
    super.key,
    required this.icon,
    required this.color,
    required this.focusColor,
    this.size = 70,
    this.iconSize = 24,
    this.hightLight = false,
    this.enabled = true,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColorToShow = (hightLight || isHighlighted) ? focusColor : color;
    if (!enabled) {
      iconColorToShow =
          iconColorToShow.withValues(alpha: (iconColorToShow.a * 0.4));
    }
    final iconDisplay = Icon(icon, color: iconColorToShow, size: iconSize);

    if (!enabled) {
      // 仅在禁用态时订阅样式变化，避免GetX空订阅错误
      return Obx(() {
        final style = FloatPanel.to.disabledStyle.value;
        if (style.type == DisabledStyleType.dimOnly) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(child: iconDisplay),
          );
        }
        if (style.type == DisabledStyleType.custom &&
            style.overlayBuilder != null) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                iconDisplay,
                style.overlayBuilder!(iconSize),
              ],
            ),
          );
        }
        // defaultX
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              iconDisplay,
              Icon(
                CupertinoIcons.xmark,
                color: Colors.yellowAccent
                    .withValues(alpha: Colors.yellowAccent.a * 0.85),
                size: iconSize * 0.9,
              ),
            ],
          ),
        );
      });
    }

    return SizedBox(
        width: size, height: size, child: Center(child: iconDisplay));
  }
}
