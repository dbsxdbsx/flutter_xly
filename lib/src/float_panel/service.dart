part of '../../xly.dart';

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
