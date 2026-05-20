part of '../../float_panel.dart';

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
