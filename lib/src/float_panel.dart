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

/// 上下停靠时的展开方向
enum HorizontalExpandMode {
  /// 不横向展开，保持竖向展开
  none,

  /// 从左到右展开（handle 在左端，默认）
  leftToRight,

  /// 从右到左展开（handle 在右端）
  rightToLeft,
}

/// 面板停靠边缘方向（内部使用）
enum _DockEdge { left, right, top, bottom }

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

  // 位置持久化（通过 GetStorage 保存/恢复面板位置和展开收起状态）
  final RxBool enablePersistence = true.obs;

  // 是否允许四边停靠（true：上下左右均可；false：仅左右停靠）
  final RxBool dockToAllEdges = true.obs;

  // 上下停靠时的展开方向
  final Rx<HorizontalExpandMode> horizontalExpandMode =
      HorizontalExpandMode.leftToRight.obs;

  // --- 默认配置快照（第一次 configure 后自动保存） ---
  bool _hasDefaultSnapshot = false;
  List<FloatPanelIconBtn> _defaultItems = [];
  bool _defaultVisible = true;
  bool _defaultEnablePersistence = true;
  bool _defaultDockToAllEdges = true;
  HorizontalExpandMode _defaultHorizontalExpandMode =
      HorizontalExpandMode.leftToRight;
  Color _defaultBorderColor = const Color(0xFF333333);
  IconData _defaultInitialPanelIcon = Icons.add;
  int _defaultPanelAnimDuration = 600;
  Curve _defaultPanelAnimCurve = Curves.fastLinearToSlowEaseIn;
  int _defaultDockAnimDuration = 300;
  Curve _defaultDockAnimCurve = Curves.fastLinearToSlowEaseIn;

  // 统一配置入口
  void configure({
    List<FloatPanelIconBtn>? items,
    bool? visible,
    // 停靠与持久化
    bool? enablePersistence,
    bool? dockToAllEdges,
    HorizontalExpandMode? horizontalExpandMode,
    // 样式与动画
    Color? borderColor,
    IconData? initialPanelIcon,
    int? panelAnimDuration,
    Curve? panelAnimCurve,
    int? dockAnimDuration,
    Curve? dockAnimCurve,
  }) {
    if (items != null) this.items.value = items;
    if (visible != null) this.visible.value = visible;
    if (enablePersistence != null) {
      this.enablePersistence.value = enablePersistence;
    }
    if (dockToAllEdges != null) this.dockToAllEdges.value = dockToAllEdges;
    if (horizontalExpandMode != null) {
      this.horizontalExpandMode.value = horizontalExpandMode;
    }
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

    // 首次 configure 后自动保存默认快照
    if (!_hasDefaultSnapshot) {
      _snapshotDefaults();
      _hasDefaultSnapshot = true;
    }
  }

  /// 恢复到首次 configure() 时的默认配置
  void resetToDefault() {
    if (!_hasDefaultSnapshot) return;
    items.value = List.of(_defaultItems);
    visible.value = _defaultVisible;
    enablePersistence.value = _defaultEnablePersistence;
    dockToAllEdges.value = _defaultDockToAllEdges;
    horizontalExpandMode.value = _defaultHorizontalExpandMode;
    borderColor.value = _defaultBorderColor;
    initialPanelIcon.value = _defaultInitialPanelIcon;
    panelAnimDuration.value = _defaultPanelAnimDuration;
    panelAnimCurve.value = _defaultPanelAnimCurve;
    dockAnimDuration.value = _defaultDockAnimDuration;
    dockAnimCurve.value = _defaultDockAnimCurve;
    // 清除运行时状态
    disabledIds.clear();
    highlightedIds.clear();
  }

  void _snapshotDefaults() {
    _defaultItems = List.of(items);
    _defaultVisible = visible.value;
    _defaultEnablePersistence = enablePersistence.value;
    _defaultDockToAllEdges = dockToAllEdges.value;
    _defaultHorizontalExpandMode = horizontalExpandMode.value;
    _defaultBorderColor = borderColor.value;
    _defaultInitialPanelIcon = initialPanelIcon.value;
    _defaultPanelAnimDuration = panelAnimDuration.value;
    _defaultPanelAnimCurve = panelAnimCurve.value;
    _defaultDockAnimDuration = dockAnimDuration.value;
    _defaultDockAnimCurve = dockAnimCurve.value;
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
  // --- 从 FloatPanel.to 实时读取的配置（支持运行时修改） ---
  FloatPanel get _fp => FloatPanel.to;
  List<FloatPanelIconBtn> get items => _fp.items;
  bool get _enablePersistence => _fp.enablePersistence.value;
  bool get _dockToAllEdges => _fp.dockToAllEdges.value;
  HorizontalExpandMode get _horizontalExpandMode =>
      _fp.horizontalExpandMode.value;
  Color get borderColor => _fp.borderColor.value;
  Color get backgroundColor => _fp.backgroundColor.value;
  Color get panelButtonColor => _fp.panelButtonColor.value;
  Color get customButtonColor => _fp.customButtonColor.value;
  PanelShape get panelShape => _fp.panelShape.value;
  int get panelAnimDuration => _fp.panelAnimDuration.value;
  Curve get panelAnimCurve => _fp.panelAnimCurve.value;
  DockType get dockType => _fp.dockType.value;
  int get dockAnimDuration => _fp.dockAnimDuration.value;
  Curve get dockAnimCurve => _fp.dockAnimCurve.value;
  Color get innerButtonFocusColor => _fp.handleFocusColor.value;
  Color get customButtonFocusColor => _fp.focusColor.value;
  IconData get initialPanelIcon => _fp.initialPanelIcon.value;

  // --- Current Scaled Values (运行时更新的缩放值，由 UI 层推送) ---
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
  static const String _kPersistPrefix = '_xly_float_panel';
  double _xOffsetRatio = 0.0;
  double _yOffsetRatio = 1 / 3;
  double _mouseOffsetX = 0.0;
  double _mouseOffsetY = 0.0;
  double? _oldYOffset;
  double? _oldYOffsetRatio;
  bool _isFirstTimePositioning = true;
  _DockEdge _currentDockEdge = _DockEdge.right; // 默认停靠右侧

  FloatBoxController() : panelIcon = FloatPanel.to.initialPanelIcon.value.obs {
    _syncFocusColorsList();
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
      // 按比例恢复大致位置
      xOffset.value = _pageWidth.value * _xOffsetRatio;
      yOffset.value = _pageHeight.value * _yOffsetRatio;
      if (_oldYOffsetRatio != null) {
        _oldYOffset = _pageHeight.value * _oldYOffsetRatio!;
      }
      _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
      if (panelState.value != PanelState.expanded) {
        _calcOffsetWhenForceDock();
      }
      // 同步比例，确保后续缩放事件使用正确的位置
      _syncOffsetRatios();
    }
  }

  void _initializePosition() {
    if (_pageWidth.value == 0 || _pageHeight.value == 0) return;

    // 尝试从持久化存储恢复
    if (_restoreFromPersistence()) return;

    // 默认初始化：放到右侧、垂直方向 1/3 处
    xOffset.value = _pageWidth.value;
    yOffset.value = _pageHeight.value * _yOffsetRatio;
    _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
    _calcOffsetWhenForceDock();
    _syncOffsetRatios();
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
    // 展开/收起后同步位置比例，确保窗口缩放时使用正确的位置还原
    _syncOffsetRatios();
    _persistPosition();
    _persistPanelState();
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
    if (newX > (_pageWidth.value - effectivePanelWidth) - _dockBoundary()) {
      newX = (_pageWidth.value - effectivePanelWidth) - _dockBoundary();
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
    _syncOffsetRatios();
    _persistPosition();
  }

  /// 同步位置比例，确保窗口缩放时能正确还原面板位置
  void _syncOffsetRatios() {
    if (_pageWidth.value > 0) {
      _xOffsetRatio = xOffset.value / _pageWidth.value;
    }
    if (_pageHeight.value > 0) {
      _yOffsetRatio = yOffset.value / _pageHeight.value;
    }
  }

  // --- 持久化方法 ---

  /// 持久化当前状态下的位置比例到 GetStorage
  void _persistPosition() {
    if (!_enablePersistence) return;
    final storage = GetStorage();
    if (panelState.value == PanelState.closed) {
      storage.write('${_kPersistPrefix}_closed_x_ratio', _xOffsetRatio);
      storage.write('${_kPersistPrefix}_closed_y_ratio', _yOffsetRatio);
    } else {
      storage.write('${_kPersistPrefix}_expanded_x_ratio', _xOffsetRatio);
      storage.write('${_kPersistPrefix}_expanded_y_ratio', _yOffsetRatio);
    }
  }

  /// 持久化面板展开/收起状态
  void _persistPanelState() {
    if (!_enablePersistence) return;
    final storage = GetStorage();
    storage.write('${_kPersistPrefix}_state', panelState.value.name);
  }

  /// 从持久化存储恢复位置和状态，返回是否成功恢复
  bool _restoreFromPersistence() {
    if (!_enablePersistence) return false;
    final storage = GetStorage();

    final savedClosedXRatio =
        storage.read<double>('${_kPersistPrefix}_closed_x_ratio');
    final savedClosedYRatio =
        storage.read<double>('${_kPersistPrefix}_closed_y_ratio');
    final savedStateName = storage.read<String>('${_kPersistPrefix}_state');

    // 至少需要关闭状态的位置数据才能恢复
    if (savedClosedXRatio == null || savedClosedYRatio == null) return false;

    final isExpanded = savedStateName == PanelState.expanded.name;

    if (isExpanded) {
      // 恢复展开状态：先设置状态以确保 effectivePanelHeight 使用展开高度
      panelState.value = PanelState.expanded;
      panelIcon.value = CupertinoIcons.minus_circle_fill;

      final savedExpandedXRatio =
          storage.read<double>('${_kPersistPrefix}_expanded_x_ratio');
      final savedExpandedYRatio =
          storage.read<double>('${_kPersistPrefix}_expanded_y_ratio');

      if (savedExpandedXRatio != null && savedExpandedYRatio != null) {
        _xOffsetRatio = savedExpandedXRatio;
        _yOffsetRatio = savedExpandedYRatio;
      } else {
        // 没有保存的展开位置，基于关闭位置计算
        _xOffsetRatio = savedClosedXRatio;
        _yOffsetRatio = savedClosedYRatio;
      }

      xOffset.value = _pageWidth.value * _xOffsetRatio;
      yOffset.value = _pageHeight.value * _yOffsetRatio;
      _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);

      // 如果没有保存的展开位置，从当前位置计算合适的展开位置
      if (savedExpandedXRatio == null || savedExpandedYRatio == null) {
        _calcOffsetWhenExpand();
      }
    } else {
      // 恢复关闭状态
      _xOffsetRatio = savedClosedXRatio;
      _yOffsetRatio = savedClosedYRatio;
      xOffset.value = _pageWidth.value * _xOffsetRatio;
      yOffset.value = _pageHeight.value * _yOffsetRatio;
      _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
      _calcOffsetWhenForceDock();
    }

    _syncOffsetRatios();
    return true;
  }

  /// 同步 isFocusColors 列表长度与当前 items 数量
  void _syncFocusColorsList() {
    final needed = items.length + 1;
    while (isFocusColors.length < needed) {
      isFocusColors.add(false);
    }
    while (isFocusColors.length > needed) {
      isFocusColors.removeLast();
    }
  }

  void setButtonFocus(int index, bool focused) {
    _syncFocusColorsList();
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

  /// 当前是否处于横向展开模式（上下停靠 + 非 none 模式）
  bool get _isHorizontalExpand =>
      _horizontalExpandMode != HorizontalExpandMode.none &&
      panelState.value == PanelState.expanded &&
      (_currentDockEdge == _DockEdge.top ||
          _currentDockEdge == _DockEdge.bottom);

  /// 当前横向展开是否为从右到左
  bool get _isRtlExpand =>
      _isHorizontalExpand &&
      _horizontalExpandMode == HorizontalExpandMode.rightToLeft;

  double get effectivePanelWidth => _isHorizontalExpand
      ? currentPanelWidth.value * (items.length + 1) + currentBorderWidth.value
      : currentPanelWidth.value + (currentBorderWidth.value * 2);

  double get effectivePanelHeight => _isHorizontalExpand
      ? currentPanelWidth.value + (currentBorderWidth.value * 2)
      : (panelState.value == PanelState.expanded
          ? currentPanelWidth.value * (items.length + 1) +
              currentBorderWidth.value
          : currentPanelWidth.value + (currentBorderWidth.value * 2));

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
      _getProperDockOffset();
      // 左右停靠时恢复展开前保存的 Y 位置
      if (_currentDockEdge == _DockEdge.left ||
          _currentDockEdge == _DockEdge.right) {
        if (_oldYOffset != null && yOffset.value != _oldYOffset!) {
          yOffset.value = _oldYOffset!;
        }
      }
    }
  }

  /// 根据面板中心到各边的距离，就近选择停靠边并应用偏移
  void _getProperDockOffset() {
    if (_pageWidth.value == 0 || _pageHeight.value == 0) return;

    final centerX = xOffset.value + (currentPanelWidth.value / 2);
    final distLeft = centerX;
    final distRight = _pageWidth.value - centerX;

    if (_dockToAllEdges) {
      // 四边停靠：比较到上下左右四条边的距离
      final centerY = yOffset.value + (effectivePanelHeight / 2);
      final distTop = centerY;
      final distBottom = _pageHeight.value - centerY;

      if (distLeft <= distRight &&
          distLeft <= distTop &&
          distLeft <= distBottom) {
        _currentDockEdge = _DockEdge.left;
        xOffset.value = -currentPanelWidth.value - _dockBoundary();
      } else if (distRight <= distLeft &&
          distRight <= distTop &&
          distRight <= distBottom) {
        _currentDockEdge = _DockEdge.right;
        xOffset.value =
            (_pageWidth.value - currentPanelWidth.value) - _dockBoundary();
      } else if (distTop <= distLeft &&
          distTop <= distRight &&
          distTop <= distBottom) {
        _currentDockEdge = _DockEdge.top;
        yOffset.value = -effectivePanelHeight - _dockBoundary();
      } else {
        _currentDockEdge = _DockEdge.bottom;
        yOffset.value =
            (_pageHeight.value - effectivePanelHeight) - _dockBoundary();
      }
    } else {
      // 仅左右停靠
      if (distLeft <= distRight) {
        _currentDockEdge = _DockEdge.left;
        xOffset.value = -currentPanelWidth.value - _dockBoundary();
      } else {
        _currentDockEdge = _DockEdge.right;
        xOffset.value =
            (_pageWidth.value - currentPanelWidth.value) - _dockBoundary();
      }
    }
  }

  void _calcOffsetWhenExpand() {
    if (_currentDockEdge == _DockEdge.left ||
        _currentDockEdge == _DockEdge.right) {
      // 左右停靠：X 移到屏幕内展开位置，Y 由 _calcPanelYOffsetWhenOpening 处理
      xOffset.value = _openDockLeft();
      _calcPanelYOffsetWhenOpening();
    } else {
      // 上下停靠：Y 贴近停靠边，X 调整确保横向展开不溢出
      _updateOldYOffset();
      if (_currentDockEdge == _DockEdge.top) {
        yOffset.value = currentPanelOpenOffset.value;
      } else {
        yOffset.value = _pageHeight.value -
            effectivePanelHeight -
            currentPanelOpenOffset.value;
      }
      _calcPanelXOffsetWhenOpeningHorizontal();
    }
  }

  /// 横向展开时调整 X 位置，确保面板不溢出屏幕
  void _calcPanelXOffsetWhenOpeningHorizontal() {
    if (_pageWidth.value == 0) return;
    // 展开后的总宽度
    final expandedWidth = effectivePanelWidth;
    // 如果当前 X + 展开宽度超出右边缘，向左推
    if (xOffset.value + expandedWidth > _pageWidth.value + _dockBoundary()) {
      xOffset.value = _pageWidth.value - expandedWidth + _dockBoundary();
    }
    // 如果推过左边缘，贴左
    if (xOffset.value < currentPanelOpenOffset.value) {
      xOffset.value = currentPanelOpenOffset.value;
    }
  }
}

class _FloatBoxPanel extends StatefulWidget {
  final Key? panelKey;
  // 缩放基础值（用于 ScreenUtil 计算）
  final double panelWidthInput;
  final double borderWidthInput;
  final double iconSizeInput;
  final BorderRadius? borderRadiusInput;
  final double panelOpenOffsetInput;

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
    this.panelWidthInput = _kDefaultPanelWidth,
    this.borderWidthInput = 0,
    this.iconSizeInput = 24,
    this.borderRadiusInput,
    this.panelOpenOffsetInput = 5.0,
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
      FloatBoxController(),
      tag: panelKey?.toString(),
    );
  }

  @override
  State<_FloatBoxPanel> createState() => _FloatBoxPanelState();
}

class _FloatBoxPanelState extends State<_FloatBoxPanel> {
  final GlobalKey _panelRenderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FloatBoxController>(tag: widget.panelKey?.toString());

    // 先计算并更新缩放值，确保后续 updateScreenSize 中的位置限位
    // 使用正确的 effectivePanelHeight（依赖 currentPanelWidth）
    final scaledPanelWidth = widget.finalPanelWidth.w;
    final scaledBorderWidth = widget.finalBorderWidth.w;
    final scaledIconSize = widget.finalIconSize.sp;
    final scaledBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.finalBorderRadius.topLeft.x.r),
      topRight: Radius.circular(widget.finalBorderRadius.topRight.x.r),
      bottomLeft: Radius.circular(widget.finalBorderRadius.bottomLeft.x.r),
      bottomRight: Radius.circular(widget.finalBorderRadius.bottomRight.x.r),
    );
    final scaledPanelOpenOffset = widget.finalPanelOpenOffset.w;
    final scaledDockOffset = widget.finalDockOffset.w;

    ctrl.updateScaledDimensions(
      scaledPanelWidth: scaledPanelWidth,
      scaledBorderWidth: scaledBorderWidth,
      scaledIconSize: scaledIconSize,
      scaledBorderRadius: scaledBorderRadius,
      scaledPanelOpenOffset: scaledPanelOpenOffset,
      scaledDockOffset: scaledDockOffset,
    );

    // 在缩放值更新后再更新屏幕尺寸，此时位置限位能正确使用新的面板高度
    ctrl.updateScreenSize(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Obx(() => AnimatedPositioned(
          duration: Duration(milliseconds: ctrl.movementSpeed.value),
          top: ctrl.yOffset.value,
          left: ctrl.xOffset.value,
          curve: ctrl.dockAnimCurve,
          child: AnimatedContainer(
            key: _panelRenderKey,
            duration: Duration(milliseconds: ctrl.panelAnimDuration),
            width: ctrl.effectivePanelWidth,
            height: ctrl.effectivePanelHeight,
            decoration: BoxDecoration(
              color: ctrl.backgroundColor,
              borderRadius: ctrl.effectiveBorderRadius,
              border: ctrl.effectivePanelBorder,
            ),
            curve: ctrl.panelAnimCurve,
            child: _buildPanelLayout(ctrl),
          ),
        ));
  }

  /// 构建面板内部布局（handle + items），根据展开方向和 RTL 排列
  Widget _buildPanelLayout(FloatBoxController ctrl) {
    final handleButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
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
              hightLight:
                  ctrl.isFocusColors.isNotEmpty ? ctrl.isFocusColors[0] : false,
              iconSize: ctrl.currentIconSize.value,
            )),
      ),
    );

    final itemsWidget = Obx(() {
      final currentItems = FloatPanel.to.items;
      final buttonList = List.generate(currentItems.length, (index) {
        final item = currentItems[index];
        final disabledSet = FloatPanel.to.disabledIds;
        final highlightedSet = FloatPanel.to.highlightedIds;
        final bool iconBtnDisabledMatch =
            item.id != null && disabledSet.contains(item.id);
        final bool explicitDisabled = item.disabled == true;
        final bool isEnabled = !(iconBtnDisabledMatch || explicitDisabled);
        final bool isDisabledLinked = iconBtnDisabledMatch;
        final bool forcedHighlighted =
            item.id != null && highlightedSet.contains(item.id);
        final Widget gestureWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: (_) => ctrl.onPanEndGesture(),
          onPanStart: (d) => ctrl.onPanStartGesture(d.globalPosition),
          onPanUpdate: (d) => ctrl.onPanUpdateGesture(d.globalPosition),
          onTap: () async {
            if (!isEnabled) return;
            if (item.onTap != null) {
              try {
                await item.onTap!();
              } catch (e, s) {
                XlyLogger.error('FloatPanelIconBtn.onTap error', e, s);
              }
            }
          },
          child: MouseRegion(
            onEnter: (_) => ctrl.setButtonFocus(index + 1, true),
            onExit: (_) => ctrl.setButtonFocus(index + 1, false),
            cursor: SystemMouseCursors.click,
            child: _FloatButton(
              key: ValueKey('float_button_${index}_$isEnabled'),
              focusColor: ctrl.customButtonFocusColor,
              size: ctrl.currentPanelWidth.value,
              icon: item.icon,
              color: ctrl.customButtonColor,
              hightLight: ctrl.isFocusColors.length > index + 1
                  ? ctrl.isFocusColors[index + 1]
                  : false,
              iconSize: ctrl.currentIconSize.value,
              enabled: isEnabled,
              isHighlighted: forcedHighlighted || isDisabledLinked,
            ),
          ),
        );
        // 仅在 tooltip 非空时套 Tooltip，避免无意义的 widget 开销。
        // 0.38.0 起 FloatPanelIconBtn.tooltip 完整渲染与智能避让（此前字段未使用）。
        final tip = item.tooltip;
        return (tip != null && tip.isNotEmpty)
            ? _FloatPanelTooltip(
                message: tip,
                controller: ctrl,
                panelKey: _panelRenderKey,
                child: gestureWidget,
              )
            : gestureWidget;
      });

      // RTL 模式下反转按钮视觉顺序，使 btn1 紧挨 handle
      final orderedList =
          ctrl._isRtlExpand ? buttonList.reversed.toList() : buttonList;

      return Visibility(
        visible: ctrl.panelState.value == PanelState.expanded,
        child: Flex(
          direction: ctrl._isHorizontalExpand ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: orderedList,
        ),
      );
    });

    // RTL 模式下 handle 在右端：调换 handle 和 items 的顺序
    final children = ctrl._isRtlExpand
        ? [itemsWidget, handleButton]
        : [handleButton, itemsWidget];

    return Wrap(
      direction: ctrl._isHorizontalExpand ? Axis.vertical : Axis.horizontal,
      children: children,
    );
  }
}

class _FloatPanelTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final FloatBoxController controller;
  final GlobalKey panelKey;

  const _FloatPanelTooltip({
    required this.message,
    required this.child,
    required this.controller,
    required this.panelKey,
  });

  @override
  State<_FloatPanelTooltip> createState() => _FloatPanelTooltipState();
}

class _FloatPanelTooltipState extends State<_FloatPanelTooltip> {
  static const Duration _waitDuration = Duration(milliseconds: 400);
  static const Duration _fadeInDuration = Duration(milliseconds: 120);
  static const Duration _fadeOutDuration = Duration(milliseconds: 120);

  // 用 ValueNotifier 通知 overlay 触发 AnimatedOpacity 淡入/淡出。
  final ValueNotifier<bool> _visibility = ValueNotifier<bool>(false);

  Timer? _showTimer;
  Timer? _removeTimer;
  OverlayEntry? _overlayEntry;
  Worker? _xWorker;
  Worker? _yWorker;

  @override
  void didUpdateWidget(covariant _FloatPanelTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _hideImmediately();
    }
  }

  @override
  void dispose() {
    _hideImmediately();
    _visibility.dispose();
    super.dispose();
  }

  void _scheduleTooltip() {
    _showTimer?.cancel();
    _showTimer = Timer(_waitDuration, _showTooltip);
  }

  void _showTooltip() {
    if (!mounted || _overlayEntry != null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final overlayObject = overlay.context.findRenderObject();
    final targetObject = context.findRenderObject();
    final panelObject = widget.panelKey.currentContext?.findRenderObject();
    if (overlayObject is! RenderBox ||
        targetObject is! RenderBox ||
        panelObject is! RenderBox ||
        !overlayObject.hasSize ||
        !targetObject.hasSize ||
        !panelObject.hasSize) {
      return;
    }

    final targetRect = _rectInOverlay(targetObject, overlayObject);
    final panelRect = _rectInOverlay(panelObject, overlayObject);
    final preferVerticalPlacement = widget.controller._isHorizontalExpand;

    _removeTimer?.cancel();
    _removeTimer = null;
    _visibility.value = false;
    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatPanelTooltipOverlay(
        message: widget.message,
        targetRect: targetRect,
        panelRect: panelRect,
        preferVerticalPlacement: preferVerticalPlacement,
        visibility: _visibility,
        fadeInDuration: _fadeInDuration,
        fadeOutDuration: _fadeOutDuration,
      ),
    );
    overlay.insert(_overlayEntry!);
    // 第一帧 opacity=0，post-frame 再切到 true 触发淡入动画。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry != null) _visibility.value = true;
    });

    // 浮动条任意位置变化都视为"用户开始操作"，立刻淡出 tooltip，
    // 避免气泡和按钮位置错位。停靠/展开收起也会改 xOffset/yOffset。
    _xWorker = ever<double>(
      widget.controller.xOffset,
      (_) => _startHide(),
    );
    _yWorker = ever<double>(
      widget.controller.yOffset,
      (_) => _startHide(),
    );
  }

  Rect _rectInOverlay(RenderBox box, RenderBox overlayBox) {
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & box.size;
  }

  /// 触发淡出动画，等动画结束再真正 remove overlay。
  void _startHide() {
    _showTimer?.cancel();
    _showTimer = null;
    _disposeMovementWatchers();
    if (_overlayEntry == null) return;
    _setVisibility(false);
    _removeTimer?.cancel();
    _removeTimer = Timer(_fadeOutDuration, _removeOverlay);
  }

  /// 不走动画直接销毁（用于 dispose / message 变化场景）。
  void _hideImmediately() {
    _showTimer?.cancel();
    _showTimer = null;
    _removeTimer?.cancel();
    _removeTimer = null;
    _disposeMovementWatchers();
    _setVisibility(false);
    _removeOverlay();
  }

  void _setVisibility(bool visible) {
    if (_visibility.value == visible) return;

    void apply() {
      if (!mounted || _visibility.value == visible) return;
      _visibility.value = visible;
    }

    // 窗口缩放会在 FloatBoxPanel.build 期间同步更新位置；位置监听此时隐藏
    // tooltip 会要求 overlay 重建，必须延后到本帧结束后再通知。
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }
    apply();
  }

  void _disposeMovementWatchers() {
    _xWorker?.dispose();
    _yWorker?.dispose();
    _xWorker = null;
    _yWorker = null;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.message,
      child: MouseRegion(
        onEnter: (_) => _scheduleTooltip(),
        onExit: (_) => _startHide(),
        child: widget.child,
      ),
    );
  }
}

/// 气泡相对浮动条的位置（"哪一侧的尾巴指向按钮"）。
enum _FloatPanelTooltipSide { left, right, top, bottom }

/// Tooltip overlay：先离屏测量气泡尺寸，再按计算好的位置和尾巴绘制。
class _FloatPanelTooltipOverlay extends StatefulWidget {
  final String message;
  final Rect targetRect;
  final Rect panelRect;
  final bool preferVerticalPlacement;
  final ValueListenable<bool> visibility;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  const _FloatPanelTooltipOverlay({
    required this.message,
    required this.targetRect,
    required this.panelRect,
    required this.preferVerticalPlacement,
    required this.visibility,
    required this.fadeInDuration,
    required this.fadeOutDuration,
  });

  @override
  State<_FloatPanelTooltipOverlay> createState() =>
      _FloatPanelTooltipOverlayState();
}

class _FloatPanelTooltipOverlayState extends State<_FloatPanelTooltipOverlay> {
  // --- 设计稿基础值（与 Material 默认 Tooltip 风格一致）---
  // 通过 ScreenUtil 在运行时缩放，避免在窗口缩放后 tooltip 游离于 FloatPanel
  // 主体的尺寸体系外。横向 layout 用 .w，对称几何与圆角用 .r，字号用 .sp。
  static const double _kBaseGap = 6.0;
  static const double _kBaseScreenMargin = 8.0;
  // 默认"理智上限"：足够装下大多数 tooltip 一行，太长才换行。
  // 调用方可通过 TooltipTheme.constraints.maxWidth 覆盖此默认值。
  static const double _kBaseMaxBubbleWidth = 320.0;
  // _kBaseMinBubbleWidth 仅用于"哪一侧空间够"的判断阈值，不再作用到气泡的
  // BoxConstraints.minWidth，避免短文本被强行撑宽。
  static const double _kBaseMinBubbleWidth = 60.0;
  static const double _kBaseTailLength = 6.0;
  static const double _kBaseTailHalfWidth = 5.0;
  static const double _kBaseBubbleCornerRadius = 4.0;
  static const double _kBaseTailSafeMargin = 2.0;
  static const double _kBaseDefaultFontSize = 14.0;
  static const double _kBaseDefaultPaddingH = 16.0;
  static const double _kBaseDefaultPaddingV = 4.0;
  // 与 Material 默认 Tooltip 一致的颜色（亮色主题 / 暗色主题）
  static const Color _bubbleColorLight = Color(0xE6616161);
  static const Color _bubbleColorDark = Color(0xE6FFFFFF);

  // --- 运行时缩放后的尺寸（每次 build 重取，跟随 ScreenUtil 当前比例）---
  double get _gap => _kBaseGap.w;
  double get _screenMargin => _kBaseScreenMargin.w;
  double get _maxBubbleWidth => _kBaseMaxBubbleWidth.w;
  double get _minBubbleWidth => _kBaseMinBubbleWidth.w;
  double get _tailLength => _kBaseTailLength.r;
  double get _tailHalfWidth => _kBaseTailHalfWidth.r;
  double get _bubbleCornerRadius => _kBaseBubbleCornerRadius.r;
  double get _tailSafeMargin => _kBaseTailSafeMargin.r;

  final GlobalKey _bubbleKey = GlobalKey();
  Size? _bubbleSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBubble());
  }

  void _measureBubble() {
    if (!mounted) return;
    final renderObject = _bubbleKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final size = renderObject.size;
    if (_bubbleSize == size) return;
    setState(() => _bubbleSize = size);
  }

  /// 根据浮动条所在一侧 + 当前 hover 按钮的位置，决定气泡可用最大宽度。
  /// 不能跨过浮动条本身，否则气泡会盖在浮动条上。
  ///
  /// [effectiveMax] 是"理智上限"，由 [TooltipTheme.constraints.maxWidth]
  /// 覆盖（若设置）或回落到 [_maxBubbleWidth]。最终 maxWidth = min(可用空间, effectiveMax)，
  /// 兜底不小于 [_minBubbleWidth]，避免极窄屏幕下算出 0/负值。
  double _resolveMaxWidth(Size overlaySize, double effectiveMax) {
    if (widget.preferVerticalPlacement) {
      final available = overlaySize.width - (_screenMargin * 2);
      return _clampMaxWidth(available, effectiveMax);
    }

    final leftSpace =
        widget.panelRect.left - _screenMargin - _gap - _tailLength;
    final rightSpace = overlaySize.width -
        widget.panelRect.right -
        _screenMargin -
        _gap -
        _tailLength;
    final preferRight = widget.panelRect.center.dx < overlaySize.width / 2;
    final preferred = preferRight ? rightSpace : leftSpace;
    final fallback = rightSpace > leftSpace ? rightSpace : leftSpace;
    final available = preferred >= _minBubbleWidth ? preferred : fallback;
    return _clampMaxWidth(available, effectiveMax);
  }

  /// 取 min(available, effectiveMax)，并兜底不小于 [_minBubbleWidth]。
  /// 不再像旧实现那样把过短的可用空间硬撑回 [_minBubbleWidth] 之上当 max 用——
  /// 那会让气泡比可用空间更宽并撞到浮动条。这里只在算出 0/负值时兜底。
  double _clampMaxWidth(double available, double effectiveMax) {
    final upper = available < effectiveMax ? available : effectiveMax;
    return upper < _minBubbleWidth ? _minBubbleWidth : upper;
  }

  /// 选定气泡放在哪一侧。preferVerticalPlacement = true 时只考虑上下，否则只考虑左右。
  /// 优先放在浮动条远离屏幕中心的反方向，避免和浮动条重叠。
  _FloatPanelTooltipSide _resolveSide(Size overlaySize, Size bubbleSize) {
    if (widget.preferVerticalPlacement) {
      final spaceBelow = overlaySize.height -
          widget.panelRect.bottom -
          _gap -
          _tailLength -
          _screenMargin;
      final spaceAbove =
          widget.panelRect.top - _gap - _tailLength - _screenMargin;
      final preferBelow = widget.panelRect.center.dy < overlaySize.height / 2;

      if (preferBelow && spaceBelow >= bubbleSize.height) {
        return _FloatPanelTooltipSide.bottom;
      }
      if (!preferBelow && spaceAbove >= bubbleSize.height) {
        return _FloatPanelTooltipSide.top;
      }
      if (spaceBelow >= bubbleSize.height) return _FloatPanelTooltipSide.bottom;
      if (spaceAbove >= bubbleSize.height) return _FloatPanelTooltipSide.top;
      return spaceBelow >= spaceAbove
          ? _FloatPanelTooltipSide.bottom
          : _FloatPanelTooltipSide.top;
    }

    final spaceRight = overlaySize.width -
        widget.panelRect.right -
        _gap -
        _tailLength -
        _screenMargin;
    final spaceLeft =
        widget.panelRect.left - _gap - _tailLength - _screenMargin;
    final preferRight = widget.panelRect.center.dx < overlaySize.width / 2;

    if (preferRight && spaceRight >= bubbleSize.width) {
      return _FloatPanelTooltipSide.right;
    }
    if (!preferRight && spaceLeft >= bubbleSize.width) {
      return _FloatPanelTooltipSide.left;
    }
    if (spaceRight >= bubbleSize.width) return _FloatPanelTooltipSide.right;
    if (spaceLeft >= bubbleSize.width) return _FloatPanelTooltipSide.left;
    return spaceRight >= spaceLeft
        ? _FloatPanelTooltipSide.right
        : _FloatPanelTooltipSide.left;
  }

  /// 计算气泡左上角在 overlay 内的位置。垂直方向上按按钮中心对齐，
  /// 水平方向上按按钮中心对齐；越界时夹回到屏幕安全区。
  Offset _calculateBubbleOrigin(
      Size overlaySize, Size bubbleSize, _FloatPanelTooltipSide side) {
    double left;
    double top;
    switch (side) {
      case _FloatPanelTooltipSide.right:
        left = widget.panelRect.right + _gap + _tailLength;
        top = widget.targetRect.center.dy - bubbleSize.height / 2;
        break;
      case _FloatPanelTooltipSide.left:
        left = widget.panelRect.left - _gap - _tailLength - bubbleSize.width;
        top = widget.targetRect.center.dy - bubbleSize.height / 2;
        break;
      case _FloatPanelTooltipSide.bottom:
        left = widget.targetRect.center.dx - bubbleSize.width / 2;
        top = widget.panelRect.bottom + _gap + _tailLength;
        break;
      case _FloatPanelTooltipSide.top:
        left = widget.targetRect.center.dx - bubbleSize.width / 2;
        top = widget.panelRect.top - _gap - _tailLength - bubbleSize.height;
        break;
    }

    final maxLeft = overlaySize.width - _screenMargin - bubbleSize.width;
    final maxTop = overlaySize.height - _screenMargin - bubbleSize.height;
    final clampedLeft =
        maxLeft >= _screenMargin ? left.clamp(_screenMargin, maxLeft) : left;
    final clampedTop =
        maxTop >= _screenMargin ? top.clamp(_screenMargin, maxTop) : top;
    return Offset(clampedLeft.toDouble(), clampedTop.toDouble());
  }

  /// 尾巴尖端在 overlay 内的全局坐标，应正对按钮中心一侧的浮动条边缘。
  Offset _tailTipGlobal(_FloatPanelTooltipSide side) {
    switch (side) {
      case _FloatPanelTooltipSide.right:
        return Offset(widget.panelRect.right, widget.targetRect.center.dy);
      case _FloatPanelTooltipSide.left:
        return Offset(widget.panelRect.left, widget.targetRect.center.dy);
      case _FloatPanelTooltipSide.bottom:
        return Offset(widget.targetRect.center.dx, widget.panelRect.bottom);
      case _FloatPanelTooltipSide.top:
        return Offset(widget.targetRect.center.dx, widget.panelRect.top);
    }
  }

  Widget _buildBubbleContent(BuildContext context, double maxWidth) {
    final tooltipTheme = TooltipTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.black : Colors.white;
    // 调用方未通过 TooltipTheme 接管时，用 ScreenUtil 缩放过的默认字号 / padding；
    // 一旦 TooltipTheme.textStyle / padding 显式给值，认为外部要自己控制，不二次缩放。
    final defaultFontSize = _kBaseDefaultFontSize.sp;
    final defaultTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: defaultTextColor,
              fontSize: defaultFontSize,
            ) ??
        TextStyle(color: defaultTextColor, fontSize: defaultFontSize);
    final textStyle = tooltipTheme.textStyle ?? defaultTextStyle;
    final padding = tooltipTheme.padding ??
        EdgeInsets.symmetric(
          horizontal: _kBaseDefaultPaddingH.w,
          vertical: _kBaseDefaultPaddingV.h,
        );

    // 对齐 Material Tooltip：仅约束 maxWidth，让气泡按文本 intrinsic 宽度展示。
    // 短文本紧贴文字，长文本自动换行。
    return Container(
      key: _bubbleKey,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      child: Text(
        widget.message,
        style: textStyle,
        softWrap: true,
      ),
    );
  }

  /// 解析气泡背景色：优先取 TooltipTheme.decoration 上的颜色，否则按主题给默认值。
  Color _resolveBubbleColor(BuildContext context) {
    final tooltipTheme = TooltipTheme.of(context);
    final decoration = tooltipTheme.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color!;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _bubbleColorDark : _bubbleColorLight;
  }

  /// 解析"理智上限"：优先取 [TooltipTheme.constraints.maxWidth]（若设置且有限），
  /// 否则用 [_kBaseMaxBubbleWidth] 经 ScreenUtil 缩放后的值。
  /// 这样下游 App 调 `TooltipTheme(data: TooltipThemeData(constraints: ...))`
  /// 控制官方 Tooltip 时，FloatPanel 上的气泡也跟着变。
  double _resolveEffectiveMaxWidth(BuildContext context) {
    final themeMax = TooltipTheme.of(context).constraints?.maxWidth;
    if (themeMax != null && themeMax.isFinite) return themeMax;
    return _maxBubbleWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final overlaySize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final effectiveMax = _resolveEffectiveMaxWidth(context);
            final maxWidth = _resolveMaxWidth(overlaySize, effectiveMax);
            final bubbleContent = _buildBubbleContent(context, maxWidth);
            final bubbleColor = _resolveBubbleColor(context);

            // 第一帧：用 Offstage 让气泡走 layout 但不绘制，从而拿到真实尺寸。
            if (_bubbleSize == null) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Offstage(
                      offstage: true,
                      child: bubbleContent,
                    ),
                  ),
                ],
              );
            }

            // 第二帧：按测量结果定位 + 画带尾巴的气泡。
            final bubbleSize = _bubbleSize!;
            final side = _resolveSide(overlaySize, bubbleSize);
            final origin =
                _calculateBubbleOrigin(overlaySize, bubbleSize, side);
            final tailTipGlobal = _tailTipGlobal(side);
            final tailTipLocal = tailTipGlobal - origin;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: origin.dx,
                  top: origin.dy,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget.visibility,
                    builder: (context, visible, child) => AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: visible
                          ? widget.fadeInDuration
                          : widget.fadeOutDuration,
                      curve: Curves.easeOut,
                      child: child,
                    ),
                    child: CustomPaint(
                      painter: _FloatPanelTooltipBubblePainter(
                        side: side,
                        tailTipLocal: tailTipLocal,
                        tailHalfWidth: _tailHalfWidth,
                        cornerRadius: _bubbleCornerRadius,
                        tailSafeMargin: _tailSafeMargin,
                        color: bubbleColor,
                      ),
                      child: bubbleContent,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 把圆角矩形和小尾巴合并成一个 Path 一次性绘制，避免接缝。
class _FloatPanelTooltipBubblePainter extends CustomPainter {
  final _FloatPanelTooltipSide side;
  final Offset tailTipLocal;
  final double tailHalfWidth;
  final double cornerRadius;
  // 尾巴基线避开圆角的安全裕度；和圆角一起缩放，避免小窗下尾巴撞圆角。
  final double tailSafeMargin;
  final Color color;

  const _FloatPanelTooltipBubblePainter({
    required this.side,
    required this.tailTipLocal,
    required this.tailHalfWidth,
    required this.cornerRadius,
    required this.tailSafeMargin,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(cornerRadius),
        ),
      );

    final tailPath = _buildTailPath(size);
    final combined = Path.combine(PathOperation.union, bubblePath, tailPath);
    canvas.drawPath(combined, paint);
  }

  Path _buildTailPath(Size size) {
    final path = Path();
    final minBaseAxis = cornerRadius + tailSafeMargin;

    switch (side) {
      case _FloatPanelTooltipSide.right:
        // 气泡在浮动条右侧；尾巴从气泡左边缘指向浮动条边缘。
        final maxBase = size.height - cornerRadius - tailSafeMargin;
        final baseY = maxBase >= minBaseAxis
            ? tailTipLocal.dy.clamp(minBaseAxis, maxBase)
            : size.height / 2;
        path.moveTo(0, baseY - tailHalfWidth);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(0, baseY + tailHalfWidth);
        path.close();
        break;
      case _FloatPanelTooltipSide.left:
        final maxBase = size.height - cornerRadius - tailSafeMargin;
        final baseY = maxBase >= minBaseAxis
            ? tailTipLocal.dy.clamp(minBaseAxis, maxBase)
            : size.height / 2;
        path.moveTo(size.width, baseY - tailHalfWidth);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(size.width, baseY + tailHalfWidth);
        path.close();
        break;
      case _FloatPanelTooltipSide.bottom:
        final maxBase = size.width - cornerRadius - tailSafeMargin;
        final baseX = maxBase >= minBaseAxis
            ? tailTipLocal.dx.clamp(minBaseAxis, maxBase)
            : size.width / 2;
        path.moveTo(baseX - tailHalfWidth, 0);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(baseX + tailHalfWidth, 0);
        path.close();
        break;
      case _FloatPanelTooltipSide.top:
        final maxBase = size.width - cornerRadius - tailSafeMargin;
        final baseX = maxBase >= minBaseAxis
            ? tailTipLocal.dx.clamp(minBaseAxis, maxBase)
            : size.width / 2;
        path.moveTo(baseX - tailHalfWidth, size.height);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(baseX + tailHalfWidth, size.height);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _FloatPanelTooltipBubblePainter oldDelegate) {
    return side != oldDelegate.side ||
        tailTipLocal != oldDelegate.tailTipLocal ||
        tailHalfWidth != oldDelegate.tailHalfWidth ||
        cornerRadius != oldDelegate.cornerRadius ||
        tailSafeMargin != oldDelegate.tailSafeMargin ||
        color != oldDelegate.color;
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
