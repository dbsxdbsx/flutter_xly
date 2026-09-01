import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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
  MyWindowDragGestureRecognizer({super.debugOwner}) {
    onlyAcceptDragOnThreshold = true;
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
/// 1. [RenderEditable] → 输入框
/// 2. [RenderMyDoubleClickConsumeZone] → 显式标记
/// 3. [RenderSemanticsGestureHandler.onTap] 非空 → InkWell / 带 onTap 或
///    onTapDown 的 [GestureDetector] 等
///
/// [Scrollable] 等只有 scroll/drag 语义的 handler（`onTap == null`）不算交互，
/// 这样列表空白处仍能双击最大化。
///
/// Flutter 只要存在 [TapGestureRecognizer]（包括仅 `onSecondaryTapDown`）
/// 就会填上非空 `onTap`。整页右键请用 `showRightMenu`（内部是 Listener），
/// 不要自行用 `GestureDetector(onSecondaryTapDown)` 包一整页。整页
/// `GestureDetector(onTap: unfocus)` 同样会关掉空白处最大化。
MyDesktopHitKind classifyDesktopHit(Offset globalPosition) {
  final viewId =
      WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
  if (viewId == null) return MyDesktopHitKind.background;

  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);

  var hasEditable = false;
  var hasConsumeZone = false;
  var hasTapInteractive = false;

  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderEditable) hasEditable = true;
    if (target is RenderMyDoubleClickConsumeZone) hasConsumeZone = true;
    if (target is RenderSemanticsGestureHandler && target.onTap != null) {
      hasTapInteractive = true;
    }
  }

  if (hasEditable) return MyDesktopHitKind.editable;
  if (hasConsumeZone || hasTapInteractive) {
    return MyDesktopHitKind.interactive;
  }
  return MyDesktopHitKind.background;
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
