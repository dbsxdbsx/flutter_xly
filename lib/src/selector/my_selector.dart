part of '../../selector.dart';

// 16.w 是面板距屏幕左右的安全边距（左右各 8.w）。
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
    // 弹出方向策略（默认首选向下、放不下才上翻），详见 [MyPanelPlacement]。
    MyPanelPlacement placement = MyPanelPlacement.below,
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

    // 捕获触发处的环境文字样式与文字缩放，供面板测宽时精确对齐实际渲染
    // （避免用默认字体/缩放测量导致偏差 → 内容被省略号截断）。
    final ambientTextStyle = DefaultTextStyle.of(triggerContext).style;
    final textScaler = MediaQuery.textScalerOf(triggerContext);
    final measuredContentWidth =
        effectiveStyle.panelWidth == null && itemBuilder != null
            ? await _measureItemBuilderContentWidth<T>(
                triggerContext: triggerContext,
                overlayState: overlayState,
                items: items,
                currentValue: currentValue,
                itemBuilder: itemBuilder,
                footerBuilder: footerBuilder,
              )
            : null;

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
        placement: placement,
        measuredContentWidth: measuredContentWidth,
        ambientTextStyle: ambientTextStyle,
        textScaler: textScaler,
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

/// 离屏测量自定义 [itemBuilder] 的自然宽度。
///
/// 默认条目可直接用文本测宽；自定义条目是不透明 Widget，库需要实际布局一次才知道
/// 它希望多宽。这里在 root overlay 中插入一个不可见测量节点，等待一帧布局完成后
/// 读取各条目的 [Size.width]，再移除测量节点。
///
/// 使用 [IntrinsicWidth] 是为了给 Row/Column 这类富布局一个“按内容收缩”的测量环境。
/// 如果某个自定义条目本身强依赖外部固定宽度，测量可能失败或退回 trigger 宽度；显式传
/// [MySelectorStyle.panelWidth] 时会完全跳过这套逻辑。
Future<double?> _measureItemBuilderContentWidth<T>({
  required BuildContext triggerContext,
  required OverlayState overlayState,
  required List<MySelectorItem<T>> items,
  required T? currentValue,
  required Widget Function(
    BuildContext context,
    MySelectorItem<T> item,
    bool isSelected,
  ) itemBuilder,
  required Widget Function(BuildContext context, VoidCallback dismiss)?
      footerBuilder,
}) async {
  if (items.isEmpty) return null;

  final overlayBox = overlayState.context.findRenderObject() as RenderBox;
  final screenSafe = math.max(
    0.0,
    overlayBox.size.width - _kPanelHorizontalSafe.w,
  );
  if (screenSafe <= 0) return null;

  final itemKeys = List.generate(items.length, (_) => GlobalKey());
  final footerKey = footerBuilder == null ? null : GlobalKey();
  late OverlayEntry measureEntry;

  measureEntry = OverlayEntry(
    builder: (context) {
      Widget measuredChild = Material(
        type: MaterialType.transparency,
        child: MediaQuery(
          data: MediaQuery.of(triggerContext),
          child: DefaultTextStyle(
            style: DefaultTextStyle.of(triggerContext).style,
            child: TickerMode(
              enabled: false,
              child: Offstage(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenSafe),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _SelectorIntrinsicMeasureBox(
                          key: itemKeys[i],
                          child: itemBuilder(
                            context,
                            items[i],
                            items[i].value == currentValue,
                          ),
                        ),
                      if (footerBuilder != null && footerKey != null)
                        _SelectorIntrinsicMeasureBox(
                          key: footerKey,
                          child: footerBuilder(context, () {}),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      measuredChild = InheritedTheme.captureAll(triggerContext, measuredChild);
      return Positioned.fill(child: measuredChild);
    },
  );

  overlayState.insert(measureEntry);
  try {
    await WidgetsBinding.instance.endOfFrame;

    double maxWidth = 0;
    for (final key in itemKeys) {
      final width = key.currentContext?.size?.width ?? 0;
      maxWidth = math.max(maxWidth, width);
    }
    final footerWidth = footerKey?.currentContext?.size?.width ?? 0;
    maxWidth = math.max(maxWidth, footerWidth);

    // 补一点余量抵消 IntrinsicWidth、亚像素舍入与 hover wrapper 的微小差异。
    return maxWidth > 0 ? math.min(maxWidth + 8.w, screenSafe) : null;
  } finally {
    measureEntry.remove();
  }
}

class _SelectorIntrinsicMeasureBox extends StatelessWidget {
  final Widget child;

  const _SelectorIntrinsicMeasureBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: child);
  }
}
