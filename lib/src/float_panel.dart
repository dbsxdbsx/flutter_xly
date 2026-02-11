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

  FloatBoxController()
      : panelIcon = FloatPanel.to.initialPanelIcon.value.obs {
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
    if (xOffset.value + expandedWidth >
        _pageWidth.value + _dockBoundary()) {
      xOffset.value =
          _pageWidth.value - expandedWidth + _dockBoundary();
    }
    // 如果推过左边缘，贴左
    if (xOffset.value < currentPanelOpenOffset.value) {
      xOffset.value = currentPanelOpenOffset.value;
    }
  }
}

class _FloatBoxPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ctrl = Get.find<FloatBoxController>(tag: panelKey?.toString());

    // 先计算并更新缩放值，确保后续 updateScreenSize 中的位置限位
    // 使用正确的 effectivePanelHeight（依赖 currentPanelWidth）
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
        return GestureDetector(
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
      });

      // RTL 模式下反转按钮视觉顺序，使 btn1 紧挨 handle
      final orderedList =
          ctrl._isRtlExpand ? buttonList.reversed.toList() : buttonList;

      return Visibility(
        visible: ctrl.panelState.value == PanelState.expanded,
        child: Flex(
          direction:
              ctrl._isHorizontalExpand ? Axis.horizontal : Axis.vertical,
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
