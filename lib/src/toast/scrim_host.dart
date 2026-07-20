import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// 作用域遮罩宿主（Scrim Host）。
///
/// 遮罩不是全屏浮层，而是渲染在**宿主自己的表面**内：谁包了 [MyScrimHost]，
/// 遮罩就正好盖住谁，并随宿主一起被裁剪（圆角、阴影天然正确）、随宿主
/// 一起销毁（对话框关闭时遮罩自动消失，无需手动清理）。
///
/// xly 内置的表面组件（`MyDialogSheet.showCenter` / `showBottom`、
/// `MyApp` 根节点）已自带宿主；业务方也可以用它包裹任意自定义表面。
///
/// 业务侧通常不直接操作本组件，而是通过 Toast 家族门面调用：
/// ```dart
/// MyToast.showScrim(message: '处理中...', onCancel: cancel);
/// MyToast.updateScrim(detail: '3/10');
/// MyToast.hideScrim();
/// ```
/// 不传 context 时自动定位到**最近挂载的宿主**（即最上层表面），
/// 与"遮住上一级"的直觉一致；传 context 则精确定位到最近的祖先宿主。
class MyScrimHost extends StatefulWidget {
  final Widget child;

  const MyScrimHost({super.key, required this.child});

  /// 查找最近的祖先宿主（没有则返回 null）
  static MyScrimHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MyScrimHostState>();

  @override
  State<MyScrimHost> createState() => MyScrimHostState();
}

class MyScrimHostState extends State<MyScrimHost> {
  /// 按挂载顺序登记的宿主栈：越晚挂载的表面越靠近用户（对话框叠对话框
  /// 时后开的在栈顶），所以"最上层表面"就是列表末尾，无需几何嗅探。
  static final List<MyScrimHostState> _registry = [];

  /// 解析目标宿主：优先 context 的祖先宿主，否则取最上层宿主。
  static MyScrimHostState? resolve([BuildContext? context]) {
    if (context != null) {
      final nearest = MyScrimHost.maybeOf(context);
      if (nearest != null) return nearest;
    }
    return _registry.isEmpty ? null : _registry.last;
  }

  /// 从栈顶往下找当前正在显示遮罩的宿主（用于 update / hide）。
  static MyScrimHostState? topmostActive() {
    for (var i = _registry.length - 1; i >= 0; i--) {
      if (_registry[i].isShowing) return _registry[i];
    }
    return null;
  }

  final Rxn<_ScrimRequest> _request = Rxn();

  bool get isShowing => _request.value != null;

  @override
  void initState() {
    super.initState();
    _registry.add(this);
  }

  @override
  void dispose() {
    _registry.remove(this);
    super.dispose();
  }

  /// 显示遮罩。[builder] 非空时完全接管中央内容（居中由宿主负责）；
  /// 否则使用默认的「转圈 + 消息 + 取消」卡片。
  void show({
    String? message,
    String? detail,
    VoidCallback? onCancel,
    String cancelText = '取消',
    WidgetBuilder? builder,
    Color? barrierColor,
  }) {
    _request.value = _ScrimRequest(
      message: RxnString(message),
      detail: RxnString(detail),
      onCancel: onCancel,
      cancelText: cancelText,
      builder: builder,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.6),
    );
  }

  /// 更新默认卡片的文案（自定义 builder 的内容请用自己的响应式状态驱动）。
  void update({String? message, String? detail}) {
    final request = _request.value;
    if (request == null) return;
    if (message != null) request.message.value = message;
    if (detail != null) request.detail.value = detail;
  }

  void hide() => _request.value = null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // passthrough：把父级约束原样传给宿主内容，保证 Column/Expanded 等
      // 布局行为与未包裹宿主时完全一致。
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: Obx(() {
            final request = _request.value;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: request == null
                  ? const SizedBox.shrink()
                  : _ScrimSurface(request: request),
            );
          }),
        ),
      ],
    );
  }
}

/// 深色遮罩卡片上的高对比按钮样式（默认取消按钮使用，业务自定义卡片可复用）。
///
/// Material TextButton 默认 hover overlay 只有前景色 8% 透明度，在深色
/// 半透明卡片上几乎不可见；这里加强为：悬停/按下/聚焦时前景变纯白，
/// 底色为清晰可辨的白色半透明药丸。
///
/// 注意不要给按钮内的 Icon/Text 显式指定颜色，否则会覆盖前景色的
/// 状态联动，悬停时文字/图标不会变亮。
ButtonStyle scrimButtonStyle({
  Color idleForeground = Colors.white70,
  EdgeInsetsGeometry? padding,
}) {
  return ButtonStyle(
    padding: padding == null ? null : WidgetStateProperty.all(padding),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.focused)) {
        return Colors.white;
      }
      return idleForeground;
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withValues(alpha: 0.28);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return Colors.white.withValues(alpha: 0.18);
      }
      return null;
    }),
  );
}

/// 一次遮罩请求的数据载体。文案用 Rx 承载以支持 update() 动态刷新。
class _ScrimRequest {
  final RxnString message;
  final RxnString detail;
  final VoidCallback? onCancel;
  final String cancelText;
  final WidgetBuilder? builder;
  final Color barrierColor;

  _ScrimRequest({
    required this.message,
    required this.detail,
    required this.onCancel,
    required this.cancelText,
    required this.builder,
    required this.barrierColor,
  });
}

class _ScrimSurface extends StatelessWidget {
  final _ScrimRequest request;

  const _ScrimSurface({required this.request});

  @override
  Widget build(BuildContext context) {
    // 遮罩画成纯矩形即可：宿主表面（如 Dialog）负责统一裁剪圆角，
    // 遮罩自己不再声明圆角，避免同一形状被多层抗锯齿叠出浅色细边。
    return GestureDetector(
      // 吞掉所有点击，锁住宿主表面的交互
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Material(
        type: MaterialType.transparency,
        child: ColoredBox(
          color: request.barrierColor,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              // 宿主表面可能比卡片还小（如低矮的对话框）：
              // scaleDown 让卡片按需整体缩小，避免像素溢出
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: request.builder?.call(context) ??
                    _DefaultScrimCard(request: request),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 默认的遮罩中央卡片：转圈 + 主消息 + 细节 + 可选取消按钮
class _DefaultScrimCard extends StatelessWidget {
  final _ScrimRequest request;

  const _DefaultScrimCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36.w,
            height: 36.w,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Obx(() {
            final message = request.message.value;
            if (message == null || message.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: 12.w),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          Obx(() {
            final detail = request.detail.value;
            if (detail == null || detail.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: 6.w),
              child: Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13.sp,
                ),
              ),
            );
          }),
          if (request.onCancel != null)
            Padding(
              padding: EdgeInsets.only(top: 12.w),
              child: TextButton.icon(
                onPressed: request.onCancel,
                style: scrimButtonStyle(),
                icon: Icon(Icons.close, size: 16.sp),
                label: Text(
                  request.cancelText,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
