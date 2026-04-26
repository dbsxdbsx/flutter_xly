import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

/// 模拟"trigger 是整页 RenderBox"场景的最小宿主：
/// - 全屏 [Builder] 把自己的 BuildContext 暴露给外层；
/// - 外层把这个 context 传给 [MySelector.show] 当 triggerContext。
///
/// 这正是 `Get.context`/`Navigator.of(context)` 在业务里被传进去时的形态——
/// renderBox.size 等于整个屏幕，sz.width ≈ screen.width。
class _FullScreenTriggerHost extends StatelessWidget {
  final void Function(BuildContext ctx) onReady;
  const _FullScreenTriggerHost({required this.onReady});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(705, 547),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onReady(ctx));
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  group('MySelector layout - trigger 是整页 RenderBox', () {
    testWidgets(
      '默认 panelWidth 时不应抛 ArgumentError（regression: 0.36/0.37 clamp 浮点边界）',
      (tester) async {
        // 选一个能让 8.w 出现浮点尾数的窗口宽度，复现报错场景：
        // designSize.width = 705 时，screen.width ≈ 698.55 → 8.w ≈ 7.925。
        // 这正是 0.36.1 在 chinese_chess 项目里捕获到的报错值。
        tester.view
          ..physicalSize = const Size(698.55, 547)
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        BuildContext? captured;
        await tester.pumpWidget(_FullScreenTriggerHost(
          onReady: (ctx) => captured = ctx,
        ));
        await tester.pumpAndSettle();
        expect(captured, isNotNull);

        // 用整页 context 当 triggerContext —— sz.width ≈ screen.width
        unawaited(MySelector.show<String>(
          triggerContext: captured!,
          items: const [
            MySelectorItem(value: 'a', title: '选项 A'),
            MySelectorItem(value: 'b', title: '选项 B'),
          ],
        ));

        // 让 OverlayEntry 完成 build：之前会在第一次 build 阶段抛
        // ArgumentError(7.925106382978723)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '极端窄屏（screen < 220.w + 16.w）也不应抛 ArgumentError',
      (tester) async {
        // 设计稿 705，screen.width = 200 时 220.w ≈ 62.4，screen - 16.w ≈ 195.5。
        // 220.w < screen - 16.w 仍然成立，所以这里再压到更窄触发反向区间。
        tester.view
          ..physicalSize = const Size(120, 547)
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        BuildContext? captured;
        await tester.pumpWidget(_FullScreenTriggerHost(
          onReady: (ctx) => captured = ctx,
        ));
        await tester.pumpAndSettle();

        unawaited(MySelector.show<String>(
          triggerContext: captured!,
          items: const [
            MySelectorItem(value: 'a', title: '选项 A'),
          ],
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '显式指定 panelWidth 大于安全可用宽度时也应被自动夹回，不抛错',
      (tester) async {
        tester.view
          ..physicalSize = const Size(400, 547)
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        BuildContext? captured;
        await tester.pumpWidget(_FullScreenTriggerHost(
          onReady: (ctx) => captured = ctx,
        ));
        await tester.pumpAndSettle();

        unawaited(MySelector.show<String>(
          triggerContext: captured!,
          // 故意给一个比屏宽还大的 panelWidth，实测应被压回 screen-16.w 内
          style: MySelectorStyle(panelWidth: 9999),
          items: const [
            MySelectorItem(value: 'a', title: '选项 A'),
          ],
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '整屏 trigger 应自动居中显示，面板必须在屏幕可视范围内（regression: 0.37.1 上还会被推到屏幕底外）',
      (tester) async {
        const Size screen = Size(800, 600);
        tester.view
          ..physicalSize = screen
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        BuildContext? captured;
        await tester.pumpWidget(_FullScreenTriggerHost(
          onReady: (ctx) => captured = ctx,
        ));
        await tester.pumpAndSettle();

        unawaited(MySelector.show<String>(
          triggerContext: captured!,
          items: const [
            MySelectorItem(value: 'a', title: '选项 A'),
            MySelectorItem(value: 'b', title: '选项 B'),
          ],
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);

        // 0.37.1 行为：showAbove=false → top = 0 + screen.height + gap
        //              → 面板被 Positioned 到 dy ≈ 600+gap，'选项 A' 不可见 / 不可点
        // 0.37.2 行为：centered=true → 面板水平 + 垂直居中，落在 [0, screen] 内
        final Finder textFinder = find.text('选项 A');
        expect(textFinder, findsOneWidget);
        final Offset center = tester.getCenter(textFinder);
        expect(
          center.dx >= 0 && center.dx <= screen.width,
          isTrue,
          reason: '面板水平应在屏幕内，实际 dx=${center.dx}',
        );
        expect(
          center.dy >= 0 && center.dy <= screen.height,
          isTrue,
          reason: '面板垂直应在屏幕内，实际 dy=${center.dy}（屏幕高 ${screen.height}）',
        );
      },
    );
  });
}

// `unawaited` helper —— 避免 future 未 await 的 lint。
void unawaited(Future<void> _) {}
