import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'models.dart';
import 'widget.dart';

// ============================================================================
// MySelectorController
// ============================================================================

/// 选择器控制器，封装状态与配置，适合"同页面多选择器"场景。
///
/// 与 Flutter 的 [TextEditingController] 类似：每个选择器对应一个
/// [MySelectorController] 实例，控制器持有选中状态，外部可直接操控。
///
/// ### 基础用法
///
/// ```dart
/// // 在 GetxController 或 StatefulWidget 的 State 里声明
/// final colorCtrl = MySelectorController<String>(
///   items: [
///     MySelectorItem(value: 'red',   title: '红色'),
///     MySelectorItem(value: 'green', title: '绿色'),
///     MySelectorItem(value: 'blue',  title: '蓝色'),
///   ],
/// );
///
/// // 触发弹出（仍需 BuildContext 定位浮层）
/// GestureDetector(
///   onTap: () => colorCtrl.show(context),
///   child: Obx(() => Text(colorCtrl.selectedTitle ?? '请选择颜色')),
/// )
///
/// // 外部直接修改选中状态
/// colorCtrl.setValue('blue');
/// colorCtrl.clear();
/// ```
///
/// ### 监听变化
///
/// ```dart
/// // 方式一：onChanged 回调（声明时传入）
/// final ctrl = MySelectorController<String>(
///   items: [...],
///   onChanged: (item) => print(item?.title),
/// );
///
/// // 方式二：在 UI 中用 Obx 响应式读取
/// Obx(() => Text(ctrl.selectedTitle ?? '未选'))
/// ```
class MySelectorController<T> {
  // ---- 列表数据（不可变）----

  /// 选项列表，初始化后不可变更；若需动态列表，直接用 [MySelector.show]。
  final List<MySelectorItem<T>> items;

  // ---- 弹出面板配置 ----

  final MySelectorClearOption? clearOption;
  final bool allowReselect;
  final bool? showPanelAbove;
  final bool showSearch;
  final String searchHint;
  final bool Function(MySelectorItem<T> item, String query)? searchFilter;
  final Widget Function(BuildContext, MySelectorItem<T>, bool)? itemBuilder;
  final Widget Function(BuildContext, VoidCallback)? footerBuilder;
  final MySelectorStyle? style;

  // ---- 变化回调 ----

  /// 用户在面板内做出操作（选中或清除）后触发；点击外部关闭时**不**触发。
  final void Function(MySelectorItem<T>? item)? onChanged;

  // ---- 响应式状态 ----

  final _selected = Rxn<MySelectorItem<T>>();

  // ============================================================
  // 构造
  // ============================================================

  MySelectorController({
    required this.items,
    MySelectorItem<T>? initialItem,
    T? initialValue,
    this.clearOption,
    this.allowReselect = false,
    this.showPanelAbove,
    this.showSearch = false,
    this.searchHint = '搜索…',
    this.searchFilter,
    this.itemBuilder,
    this.footerBuilder,
    this.style,
    this.onChanged,
  }) {
    assert(items.isNotEmpty, 'MySelectorController: items 不能为空');
    if (initialItem != null) {
      _selected.value = initialItem;
    } else if (initialValue != null) {
      _selected.value = _findByValue(initialValue);
    }
  }

  // ============================================================
  // 只读状态
  // ============================================================

  /// 当前选中项（可在 [Obx] 内读取以响应变化）。
  MySelectorItem<T>? get selectedItem => _selected.value;

  /// 当前选中的值，等同于 `selectedItem?.value`。
  T? get selectedValue => _selected.value?.value;

  /// 当前选中项的标题，等同于 `selectedItem?.title`。
  String? get selectedTitle => _selected.value?.title;

  /// 暴露底层 [Rxn]，便于在 Obx 外部直接监听或绑定复杂逻辑。
  Rxn<MySelectorItem<T>> get rx => _selected;

  // ============================================================
  // 状态操作（可从外部随时调用）
  // ============================================================

  /// 按 [value] 设置选中项；找不到对应项时效果等同于 [clear]。
  void setValue(T? value) {
    if (value == null) {
      clear();
    } else {
      setItem(_findByValue(value));
    }
  }

  /// 直接设置选中项；传 `null` 等同于 [clear]。
  void setItem(MySelectorItem<T>? item) {
    _selected.value = item;
    onChanged?.call(item);
  }

  /// 清除选中状态。
  void clear() {
    _selected.value = null;
    onChanged?.call(null);
  }

  // ============================================================
  // 弹出面板
  // ============================================================

  /// 在 [context] 所对应的 Widget 附近弹出选择面板。
  ///
  /// 用户做出选择或清除后，控制器状态自动更新；点击外部关闭不触发任何变化。
  Future<void> show(BuildContext context) async {
    final result = await MySelector.show<T>(
      triggerContext: context,
      items: items,
      currentValue: selectedValue,
      clearOption: clearOption,
      allowReselect: allowReselect,
      showPanelAbove: showPanelAbove,
      showSearch: showSearch,
      searchHint: searchHint,
      searchFilter: searchFilter,
      itemBuilder: itemBuilder,
      footerBuilder: footerBuilder,
      style: style,
    );
    final changed = result.changed;
    if (changed != null) {
      setItem(changed.item);
    }
  }

  // ============================================================
  // 内部工具
  // ============================================================

  MySelectorItem<T>? _findByValue(T value) {
    for (final item in items) {
      if (item.value == value) return item;
    }
    return null;
  }
}
