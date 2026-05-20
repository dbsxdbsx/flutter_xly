part of '../../selector.dart';

// 默认面板宽度的设计稿基准（在 ScreenUtil 下经 `.w` 缩放为当前 px）。
// - 280.w 是常见下拉宽度，能容纳"图标 + 标题 + 副标题"三段；
// - 220.w 作为下界，避免 trigger 太窄时面板挤成一条；
// - 16.w 是面板距屏幕左右的安全边距（左右各 8.w）。
const double _kPanelDefaultMaxW = 280.0;
const double _kPanelMinW = 220.0;
const double _kPanelHorizontalSafe = 16.0;

// ============================================================================
// 公开 API
// ============================================================================

/// 通用选择器浮层
///
/// 在 [triggerContext] 所指 Widget 附近弹出一个面板，面板内含可选搜索框、
/// 富格式列表和可选底部区域。
///
/// 返回 [MySelectorResult]：
/// - [MySelectorDismissed]：用户点击外部或按 Escape，不做任何操作
/// - [MySelectorValueChanged]：用户做出了明确操作；
///   `value == null` 表示主动清除，`value != null` 表示选中了某项
///
/// ```dart
/// final result = await MySelector.show<String>(
///   triggerContext: context,
///   items: [...],
///   currentValue: selected,
///   showSearch: true,
///   clearOption: MySelectorClearOption(label: '不选择'),
///   allowReselect: true,
/// );
/// switch (result) {
///   case MySelectorDismissed(): break;
///   case MySelectorValueChanged(:final value):
///     state = value; // null = cleared, non-null = selected
/// }
/// ```
class MySelector {
  MySelector._();

  /// 弹出选择器面板，返回 [MySelectorResult] 告知调用方用户的操作意图。
  static Future<MySelectorResult<T>> show<T>({
    required BuildContext triggerContext,
    required List<MySelectorItem<T>> items,
    T? currentValue,
    // 清除 & 复选取消
    MySelectorClearOption? clearOption,
    bool allowReselect = false,
    // 弹出方向：null = 自动（根据可用空间判断），true = 强制上方，false = 强制下方
    bool? showPanelAbove,
    // 搜索
    bool showSearch = false,
    String searchHint = '搜索…',
    bool Function(MySelectorItem<T> item, String query)? searchFilter,
    // 自定义渲染
    Widget Function(
      BuildContext context,
      MySelectorItem<T> item,
      bool isSelected,
    )? itemBuilder,
    Widget Function(BuildContext context, VoidCallback dismiss)? footerBuilder,
    // 样式
    MySelectorStyle? style,
  }) async {
    assert(items.isNotEmpty, 'items 不能为空');

    final effectiveStyle = style ?? MySelectorStyle();
    final completer = Completer<MySelectorResult<T>>();

    final renderBox = triggerContext.findRenderObject() as RenderBox;
    final overlayState = Overlay.of(triggerContext, rootOverlay: true);

    late OverlayEntry entry;

    void dismiss(MySelectorResult<T> result) {
      entry.remove();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    entry = OverlayEntry(
      builder: (_) => _SelectorOverlay<T>(
        renderBox: renderBox,
        overlayState: overlayState,
        items: items,
        currentValue: currentValue,
        clearOption: clearOption,
        allowReselect: allowReselect,
        showPanelAbove: showPanelAbove,
        showSearch: showSearch,
        searchHint: searchHint,
        searchFilter: searchFilter,
        itemBuilder: itemBuilder,
        footerBuilder: footerBuilder,
        style: effectiveStyle,
        onSelected: (item) =>
            dismiss(MySelectorValueChanged(item.value, item: item)),
        onCleared: () => dismiss(MySelectorValueChanged(null)),
        onDismiss: () => dismiss(MySelectorDismissed()),
      ),
    );

    overlayState.insert(entry);
    return completer.future;
  }
}
