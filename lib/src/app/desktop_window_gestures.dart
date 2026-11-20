import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 整窗拖拽的判定阈值（逻辑像素）。
///
/// Flutter 给鼠标定的 [kPrecisePointerPanSlop] 只有 2px，拿来判定「用户想搬动
/// 整扇窗口」太灵敏：点击手抖就会触发 `windowManager.startDragging()`，pointer
/// 随即交给操作系统原生移动循环，这一击的 `PointerUpEvent` 不再回到 Flutter，
/// 窗口级双击判定也就凑不齐两击。
const double kMyWindowDragSlop = 12.0;

/// 只把明确的拖拽认成搬动窗口，避免把点击手抖判成拖窗口。
///
/// 还必须打开 [onlyAcceptDragOnThreshold]：竞技场会在 pointer UP 时 sweep，
/// 把无人认领的手势判给唯一成员。窗口拖拽层盖在整个 App 之上，空白处点击
/// 往往只有它一个竞争者；不开这个开关，每一次静止点击都会在抬手瞬间收到
/// `onStart`。
class MyWindowDragGestureRecognizer extends PanGestureRecognizer {
  MyWindowDragGestureRecognizer({super.debugOwner, this.isEnabled}) {
    onlyAcceptDragOnThreshold = true;
  }

  /// 为 false 时整个识别器不进竞技场（不只是不调 startDragging），
  /// 否则关掉拖窗后它照样会赢下 pan，把子组件的拖拽吞掉。
  bool Function()? isEnabled;

  /// 按下点落在 [MyWindowDragExcludeZone]、输入框、按钮、开关、滑块等自有拖拽/
  /// 点击取消语义的控件，或非鼠标主键时，不追踪该 pointer：
  /// 让卡片长按拖动、文本划选、滑块、按钮拉出取消等原生交互独自走竞技场，
  /// 而不是被外层整窗拖拽劫持。
  @override
  bool isPointerAllowed(PointerEvent event) {
    if (isEnabled != null && !isEnabled!()) return false;
    if (_windowDragExcludedPointers.contains(event.pointer)) return false;
    if (event.kind == PointerDeviceKind.mouse &&
        event is PointerDownEvent &&
        event.buttons != kPrimaryMouseButton) {
      return false;
    }
    if (event is PointerDownEvent &&
        _shouldExcludeWindowDragAt(event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    if (pointerDeviceKind == PointerDeviceKind.mouse) {
      return globalDistanceMoved.abs() > kMyWindowDragSlop;
    }
    return super.hasSufficientGlobalDistanceToAccept(
      pointerDeviceKind,
      deviceTouchSlop,
    );
  }
}

/// 双击位置相对窗口级最大化的交互分类。
enum MyDesktopHitKind {
  /// 可编辑文本，双击应留给选词 / 获焦，不最大化。
  editable,

  /// 可点击或显式标记的交互区，双击语义留给内部组件。
  interactive,

  /// 空白 / 非交互区域，可切换窗口最大化。
  background,
}

/// 通过 hit test 分类 [globalPosition] 的交互属性。
///
/// 检测顺序：
/// 1. [RenderEditable] / `Semantics(textField: true)` → 输入框（`editable`）
/// 2. [RenderMyDoubleClickConsumeZone] → 显式标记（`interactive`）
/// 3. [RenderSemanticsGestureHandler]（`onTap != null || onLongPress != null`）→
///    带点击/长按的 [GestureDetector]
/// 4. [RenderSemanticsAnnotations]（`button` / `link` / `slider` / `toggled` /
///    `checked` / `mixed` / `onTap` / `onLongPress` / `onIncrease` / `onDecrease`）→
///    `ElevatedButton` / `MyButton` / `IconButton` / `InkWell` / `MyCard` /
///    `FilterChip` / `Switch` / `Checkbox` / `Radio` 等全部标准交互控件
///    （注：Flutter 的 `InkWell` 会给内部 `GestureDetector` 传
///    `excludeFromSemantics: true`，改由外层 `Semantics` + `MouseRegion`
///    表达交互，因此必须检测本层）
/// 5. [MouseTrackerAnnotation]（含 [RenderMouseRegion] 与可点击 `TextSpan`）的
///    交互光标（`click` / `grab` / `grabbing` / `text` / `move` / `resize*`）→
///    覆盖 `Slider`、可点击富文本链接等自定义指针控件
///
/// [Scrollable] 等只有 scroll/drag 语义的 handler（`onTap == null`）以及
/// 仅有 `scopesRoute` / `label` / `MouseCursor.defer` 的容器仍判为 `background`，
/// 保证页面空白处、列表空白处、整页 `showRightMenu` 仍能正常双击最大化。
///
/// 若自定义控件既不用标准交互组件、也没挂交互光标、只靠 [Listener] 或仅
/// `GestureDetector(onDoubleTap: ...)` 响应，请套 [MyDoubleClickConsumeZone]。
MyDesktopHitKind classifyDesktopHit(Offset globalPosition) {
  final viewId =
      WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
  if (viewId == null) return MyDesktopHitKind.background;

  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);

  var hasEditable = false;
  var hasInteractive = false;

  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderEditable) {
      hasEditable = true;
      continue;
    }
    if (target is RenderMyDoubleClickConsumeZone) {
      hasInteractive = true;
      continue;
    }
    if (target is RenderSemanticsGestureHandler &&
        (target.onTap != null || target.onLongPress != null)) {
      hasInteractive = true;
      continue;
    }
    if (target is RenderSemanticsAnnotations) {
      final props = target.properties;
      if (props.textField == true) {
        hasEditable = true;
      } else if (_hasInteractiveSemantics(props)) {
        hasInteractive = true;
      }
      continue;
    }
    if (target case MouseTrackerAnnotation(:final cursor)
        when _isInteractiveCursor(cursor)) {
      hasInteractive = true;
    }
  }

  if (hasEditable) return MyDesktopHitKind.editable;
  if (hasInteractive) return MyDesktopHitKind.interactive;
  return MyDesktopHitKind.background;
}

bool _hasInteractiveSemantics(SemanticsProperties props) {
  return props.button == true ||
      props.link == true ||
      props.slider == true ||
      props.toggled != null ||
      props.checked != null ||
      props.mixed == true ||
      props.onTap != null ||
      props.onLongPress != null ||
      props.onIncrease != null ||
      props.onDecrease != null;
}

bool _isInteractiveCursor(MouseCursor cursor) {
  return cursor == SystemMouseCursors.click ||
      cursor == SystemMouseCursors.grab ||
      cursor == SystemMouseCursors.grabbing ||
      cursor == SystemMouseCursors.text ||
      cursor == SystemMouseCursors.verticalText ||
      cursor == SystemMouseCursors.move ||
      cursor == SystemMouseCursors.resizeLeftRight ||
      cursor == SystemMouseCursors.resizeUpDown ||
      cursor == SystemMouseCursors.resizeColumn ||
      cursor == SystemMouseCursors.resizeRow ||
      cursor == SystemMouseCursors.resizeUpLeftDownRight ||
      cursor == SystemMouseCursors.resizeUpRightDownLeft;
}

bool _isDragConflictCursor(MouseCursor cursor) {
  return cursor == SystemMouseCursors.text ||
      cursor == SystemMouseCursors.verticalText ||
      cursor == SystemMouseCursors.grab ||
      cursor == SystemMouseCursors.grabbing ||
      cursor == SystemMouseCursors.move ||
      cursor == SystemMouseCursors.resizeLeftRight ||
      cursor == SystemMouseCursors.resizeUpDown ||
      cursor == SystemMouseCursors.resizeColumn ||
      cursor == SystemMouseCursors.resizeRow ||
      cursor == SystemMouseCursors.resizeUpLeftDownRight ||
      cursor == SystemMouseCursors.resizeUpRightDownLeft;
}

/// 命中点落在输入框、按钮、开关、滑块或拖拽/文本光标区域时，禁止外层整窗拖拽劫持。
///
/// 刻意不排除仅带 `InkWell(onTap)` + `click` 光标的普通大面积卡片（如 `MyCard`），
/// 以便隐藏系统标题栏的桌面页仍可在非可排序卡片上拖窗。
bool _shouldExcludeWindowDragAt(Offset globalPosition) {
  final viewId =
      WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
  if (viewId == null) return false;

  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);

  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderEditable) return true;
    if (target is RenderSemanticsAnnotations) {
      final props = target.properties;
      if (props.textField == true ||
          props.button == true ||
          props.slider == true ||
          props.toggled != null ||
          props.checked != null ||
          props.mixed == true ||
          props.onIncrease != null ||
          props.onDecrease != null) {
        return true;
      }
    }
    if (target case MouseTrackerAnnotation(:final cursor)
        when _isDragConflictCursor(cursor)) {
      return true;
    }
  }
  return false;
}

/// 双击消费区域：标记子树为交互区，阻止桌面端双击穿透到窗口最大化。
///
/// 窗口拖拽层已能自动识别大部分带 tap 语义的组件和 [RenderEditable]。
/// 仅在自动检测覆盖不到时使用，例如只通过 [Listener] 处理指针、没有
/// `GestureDetector.onTap` / `onTapDown` 的自定义控件。
class MyDoubleClickConsumeZone extends SingleChildRenderObjectWidget {
  const MyDoubleClickConsumeZone({super.key, super.child});

  @override
  RenderMyDoubleClickConsumeZone createRenderObject(BuildContext context) {
    return RenderMyDoubleClickConsumeZone();
  }
}

/// [MyDoubleClickConsumeZone] 的渲染对象，供 [classifyDesktopHit] 识别。
class RenderMyDoubleClickConsumeZone extends RenderProxyBox {
  RenderMyDoubleClickConsumeZone({RenderBox? child}) : super(child);
}

/// 供测试观察 [classifyDesktopHit] 是否看到了消费区标记。
@visibleForTesting
bool debugHitPathHasConsumeZone(Offset globalPosition) {
  final viewId =
      WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
  if (viewId == null) return false;
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);
  return result.path.any((e) => e.target is RenderMyDoubleClickConsumeZone);
}

/// 本次按下落在排除区里的 pointer。
///
/// 命中路径按「最深 → 根」派发 [PointerDownEvent]，排除区的 [Listener] 比根部
/// 窗口拖拽层的 [RawGestureDetector] 先收到同一个按下，所以识别器在
/// [MyWindowDragGestureRecognizer.isPointerAllowed] 里查这张表时一定已登记。
final Set<int> _windowDragExcludedPointers = <int>{};

/// 窗口拖拽排除区：子树里按下的 pointer 不会触发整窗拖拽。
///
/// 只影响这一次 pointer，不改全局开关、不触发任何重建；抬起或取消即注销。
/// 用于自带拖拽语义的子组件（长按排序卡片、[Draggable]、自绘滑块等）。
/// [MyCard] 可拖时已自动套上，一般无需手动使用。
class MyWindowDragExcludeZone extends StatelessWidget {
  const MyWindowDragExcludeZone({
    super.key,
    required this.child,
    this.behavior = HitTestBehavior.deferToChild,
    this.enabled = true,
  });

  final Widget child;
  final HitTestBehavior behavior;

  /// 为 `false` 时不拦截整窗拖拽，同时保持子树结构稳定不重挂。
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: behavior,
      onPointerDown: (e) {
        if (enabled) _windowDragExcludedPointers.add(e.pointer);
      },
      onPointerUp: (e) => _windowDragExcludedPointers.remove(e.pointer),
      onPointerCancel: (e) => _windowDragExcludedPointers.remove(e.pointer),
      child: child,
    );
  }
}

/// 供测试确认排除表没有残留 pointer。
@visibleForTesting
int get debugWindowDragExcludedPointerCount =>
    _windowDragExcludedPointers.length;
