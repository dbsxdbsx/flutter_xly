import 'package:example/pages/page15_horizontal_scroller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(Page15HorizontalScrollerController());
  });

  tearDown(Get.reset);

  testWidgets('Page15HorizontalScrollerView 正常渲染、滑块切换、拖滑与动态增删标签',
      (tester) async {
    tester.view
      ..physicalSize = const Size(900, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(900, 700),
        builder: (_, __) => const GetMaterialApp(
          home: Scaffold(body: Page15HorizontalScrollerView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前状态：智能自动 · 地区：全局不限'), findsOneWidget);
    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsWidgets,
    );

    // 点右侧地区胶囊
    await tester.tap(find.text('日本'));
    await tester.pumpAndSettle();
    expect(find.text('当前状态：智能自动 · 地区：日本'), findsOneWidget);

    // 点左侧 MySegmentedToggle「手动」滑过去
    await tester.tap(find.text('手动').first);
    await tester.pumpAndSettle();
    expect(find.text('当前状态：手动锁定 · 地区：全局不限'), findsOneWidget);

    // 悬停滚轮横滚正常，不抛异常
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final pos = tester.getCenter(find.text('日本'));
    tester.binding.handlePointerEvent(pointer.hover(pos));
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, 80)));
    await tester.pumpAndSettle();

    // 第 3 节异步演示：勾选失败回滚后点「智能」，800ms 后平滑回弹回「手动」
    await tester.tap(find.text('模拟后台失败回滚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('智能').last);
    await tester.pump();
    expect(find.text('后台切换「智能」中…（800ms）'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();
    expect(find.text('切换失败，已回弹至：手动'), findsOneWidget);

    // 第 4 节双向动态增删：头部新增、尾部追加、移除头部、移除末尾
    await tester.tap(find.text('头部新增'));
    await tester.pumpAndSettle();
    expect(find.text('head-1: 新左侧1'), findsOneWidget);

    await tester.tap(find.text('尾部追加'));
    await tester.pumpAndSettle();
    expect(find.text('channel-4: 节点4'), findsOneWidget);

    await tester.tap(find.text('移除头部'));
    await tester.pumpAndSettle();
    expect(find.text('head-1: 新左侧1'), findsNothing);

    await tester.tap(find.text('移除末尾'));
    await tester.pumpAndSettle();
    expect(find.text('channel-4: 节点4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Page15HorizontalScrollerView 极窄内容区(220dp)下零溢出', (tester) async {
    tester.view
      ..physicalSize = const Size(220, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(900, 700),
        builder: (_, __) => const GetMaterialApp(
          home: Scaffold(body: Page15HorizontalScrollerView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
