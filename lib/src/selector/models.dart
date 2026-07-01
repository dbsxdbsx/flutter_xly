part of '../../selector.dart';

// ============================================================================
// 返回类型
// ============================================================================

/// [MySelector.show] 的返回结果，区分"关闭不做事"与"用户明确操作"。
///
/// ```dart
/// final result = await MySelector.show<String>(...);
/// switch (result) {
///   case MySelectorDismissed():
///     break; // 用户点外部或按 Escape，不做任何操作
///   case MySelectorValueChanged(:final value):
///     state = value; // null = 主动清除；非 null = 选中了某项
/// }
/// ```
sealed class MySelectorResult<T> {
  const MySelectorResult();
}

/// 用户关闭了面板但没有做出明确选择（点击外部区域或按 Escape）。
final class MySelectorDismissed<T> extends MySelectorResult<T> {
  const MySelectorDismissed();
}

/// 用户做出了明确操作：
/// - [value] 为 `null`：主动清除选中（通过清除项或复选取消），此时 [item] 也为 `null`
/// - [value] 非 `null`：选中了具体某项，[item] 为对应的完整列表项
final class MySelectorValueChanged<T> extends MySelectorResult<T> {
  final T? value;

  /// 选中的完整列表项；清除操作时为 `null`。
  ///
  /// 直接使用此字段可避免在调用方通过 `firstWhere` 反查 item。
  final MySelectorItem<T>? item;

  const MySelectorValueChanged(this.value, {this.item});
}

// ============================================================================
// 便捷扩展
// ============================================================================

extension MySelectorResultX<T> on MySelectorResult<T> {
  /// 用户是否点击了外部/按 Escape 关闭面板（未做出明确选择）。
  bool get isDismissed => this is MySelectorDismissed<T>;

  /// 用户做出了明确操作时返回 [MySelectorValueChanged]，否则返回 `null`。
  ///
  /// 比 `switch` 更简洁的用法：
  /// ```dart
  /// final result = await MySelector.show<String>(...);
  /// final changed = result.changed;
  /// if (changed != null) {
  ///   selectedItem = changed.item; // 直接获取完整 item，无需 firstWhere
  /// }
  /// ```
  MySelectorValueChanged<T>? get changed => this is MySelectorValueChanged<T>
      ? this as MySelectorValueChanged<T>
      : null;
}

// ============================================================================
// 弹出方向
// ============================================================================

/// 选择器面板相对触发按钮的弹出方向策略。
///
/// - [below] / [above] 为**智能**策略：优先按首选方向弹出，仅当首选方向放不下
///   面板（按内容估算）且反方向更宽裕时，才自动翻转。
/// - [forceBelow] / [forceAbove] 为**强制**策略：始终固定在该方向，不做翻转
///   （即使该方向空间不足，面板会被压缩/裁剪）。
///
/// 传给 [MySelector.show] 或 [MySelectorController] 的 `placement` 参数；
/// 默认 [below]（首选向下，不足才上翻）。
enum MyPanelPlacement {
  /// 首选向下，放不下则自动上翻（默认）。
  below,

  /// 首选向上，放不下则自动下翻。
  above,

  /// 强制向下，永不翻转。
  forceBelow,

  /// 强制向上，永不翻转。
  forceAbove,
}

// ============================================================================
// 清除项配置
// ============================================================================

/// 选择器列表顶部"清除"入口的配置。
///
/// 传给 [MySelector.show] 的 `clearOption` 参数；为 `null` 时不显示清除项。
///
/// ```dart
/// clearOption: MySelectorClearOption(label: '不选择'),
/// clearOption: MySelectorClearOption(
///   label: '不限国家',
///   leading: Icon(Icons.public_off, size: 14),
///   subtitle: '显示所有地区内容',
/// ),
/// ```
class MySelectorClearOption {
  /// 清除项的显示文字，如"不选择"、"清除"、"全部"。
  final String label;

  /// 可选前缀组件（图标、色块等），为 `null` 时显示默认的 `cancel_outlined` 图标。
  final Widget? leading;

  /// 可选副标题说明文字。
  final String? subtitle;

  const MySelectorClearOption({
    this.label = '清除',
    this.leading,
    this.subtitle,
  });
}

// ============================================================================
// 列表项 & 样式
// ============================================================================

/// 选择器列表项
///
/// 泛型 [T] 为选中后返回的值类型，需要正确实现 `==` 运算符。
class MySelectorItem<T> {
  final T value;
  final String title;
  final String? subtitle;

  /// 左侧自定义组件（图标、头像、色块等）
  final Widget? leading;

  /// 标题右侧的小徽章列表（能力图标等）
  final List<Widget>? badges;

  final bool enabled;

  const MySelectorItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.badges,
    this.enabled = true,
  });
}

/// 选择器样式配置
///
/// 除 [panelWidth] 外，传入的数值为设计稿尺寸（基于 ScreenUtil 初始化的设计稿宽度），
/// 构造时自动通过 `.h` / `.r` 转换。[panelWidth] 表示调用方已经换算后的固定宽度，
/// 不再内部 `.w`。
class MySelectorStyle {
  final double maxHeight;

  /// 面板宽度。
  ///
  /// - 为 `null`（默认）：**完全自适应**——面板宽度贴合内容（不窄于触发按钮），
  ///   内容更长时自动增长，最宽不超过屏内安全宽。默认条目用文本测宽；自定义
  ///   `itemBuilder` 会离屏布局测量。
  /// - 非 `null`：**固定宽度**，无视内容一律按此值显示（仍夹到屏内安全宽）。
  ///
  /// 注意：此值**不做** `.w` 缩放，请自行按需传入 ScreenUtil 表达式，
  /// 如 `panelWidth: 280.w`（要随屏适配）或 `panelWidth: 280`（固定逻辑像素）。
  final double? panelWidth;

  final double borderRadius;
  final double blurSigma;
  final Color selectedColor;
  final double shadowOpacity;

  /// 悬停背景色。
  ///
  /// 默认为 [MySelectorStyle.defaultHoverColor]（浅灰半透明叠加），
  /// 在浅色面板上提供中性、不干扰选中色的视觉反馈。
  /// 如需深色面板或特殊品牌色，可手动传入覆盖。
  final Color hoverColor;

  /// 默认悬停色：黑色 6% 透明叠加，适配浅色背景面板。
  static const Color defaultHoverColor = Color(0x0F000000);

  MySelectorStyle({
    double maxHeight = 360,
    this.panelWidth,
    double borderRadius = 14,
    double blurSigma = 28,
    this.selectedColor = const Color(0xFF4F6BFE),
    this.shadowOpacity = 0.12,
    this.hoverColor = defaultHoverColor,
  })  : maxHeight = maxHeight.h,
        borderRadius = borderRadius.r,
        blurSigma = blurSigma.r;
}
