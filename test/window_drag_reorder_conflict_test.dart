import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

/// 锁住「桌面整窗拖拽不得从可拖卡片列表里漏出去」。
///
/// 0.58.1 起 [MyCard] 用 [ReorderableDelayedDragStartListener]（长按约 500ms
/// 才认）。根部 [CustomDragArea] 的窗口拖拽识别器只要鼠标挪过
/// [kMyWindowDragSlop] 就赢下竞技场，于是按住卡片一拖，搬走的是整扇窗口。
/// 现在鼠标按下即拖、触屏仍长按，两种情况都不得漏成拖窗。
final _windows = TargetPlatformVariant.only(TargetPlatform.windows);

void main() {
  late int startDraggingCalls;
  late List<(int, int)> reorders;

  setUp(() {
    startDraggingCalls = 0;
    reorders = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'),
            (call) async {
      if (call.method == 'startDragging') startDraggingCalls++;
      // Windows 宿主上 startDragging 会先问 isFullScreen，必须回 bool。
      if (call.method == 'isFullScreen') return false;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
    Get.reset();
  });

  Widget host({Widget? extra}) {
    return ScreenUtilInit(
      designSize: const Size(400, 600),
      builder: (_, __) => MaterialApp(
        home: Obx(
          () => CustomDragArea(
            enableDoubleClickMaximize: false,
            draggable: MyApp.isDraggableEnabled(),
            child: Scaffold(
              body: Column(
                children: [
                  // 模拟隐藏系统标题栏后的自绘顶栏：空白处应能拖窗口。
                  const SizedBox(
                    key: Key('title-bar'),
                    width: double.infinity,
                    height: 48,
                    child: ColoredBox(color: Colors.blueGrey),
                  ),
                  if (extra != null) extra,
                  Expanded(
                    child: MyCardList(
                      itemCount: 4,
                      cardHeight: 60,
                      onCardReordered: (a, b) => reorders.add((a, b)),
                      cardBody: (i) => Text('card $i'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<TestGesture> mouseDown(WidgetTester tester, Offset at) {
    return tester.startGesture(at, kind: PointerDeviceKind.mouse);
  }

  Future<void> moveDown(TestGesture g, double dy, {int steps = 10}) async {
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(0, dy / steps));
    }
  }

  testWidgets('按住卡片立刻拖：不得搬动整扇窗口', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await mouseDown(tester, tester.getCenter(find.text('card 0')));
    await moveDown(g, 80);
    await g.up();
    await tester.pumpAndSettle();

    expect(startDraggingCalls, 0);
  }, variant: _windows);

  testWidgets('长按卡片后拖：重排生效，且不搬动窗口', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await mouseDown(tester, tester.getCenter(find.text('card 0')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await moveDown(g, 150);
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();

    expect(startDraggingCalls, 0);
    expect(reorders, isNotEmpty);
    expect(reorders.single.$1, 0);
  }, variant: _windows);

  testWidgets('鼠标按下即拖：不用长按就重排，且不搬动窗口', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await mouseDown(tester, tester.getCenter(find.text('card 0')));
    await moveDown(g, 150);
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();

    expect(startDraggingCalls, 0);
    expect(reorders, isNotEmpty);
    expect(reorders.single.$1, 0);
    expect(debugWindowDragExcludedPointerCount, 0);
  }, variant: _windows);

  testWidgets('鼠标单击可拖卡片：仍触发 onPressed，不重排', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(400, 600),
      builder: (_, __) => MaterialApp(
        home: CustomDragArea(
          enableDoubleClickMaximize: false,
          draggable: true,
          child: Scaffold(
            body: MyCardList(
              itemCount: 3,
              cardHeight: 60,
              onCardReordered: (a, b) => reorders.add((a, b)),
              onCardPressed: (_) => pressed++,
              cardBody: (i) => Text('card $i'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('card 1'), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    expect(pressed, 1);
    expect(reorders, isEmpty);
    expect(startDraggingCalls, 0);
  }, variant: _windows);

  testWidgets('触屏按住立刻拖：不重排（仍要长按），也不搬动窗口', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await tester.startGesture(
      tester.getCenter(find.text('card 0')),
      kind: PointerDeviceKind.touch,
    );
    await moveDown(g, 150);
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();

    expect(reorders, isEmpty);
    expect(startDraggingCalls, 0);
  }, variant: _windows);

  testWidgets('触屏长按后拖：重排生效', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await tester.startGesture(
      tester.getCenter(find.text('card 0')),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await moveDown(g, 150);
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();

    expect(reorders, isNotEmpty);
    expect(reorders.single.$1, 0);
    expect(startDraggingCalls, 0);
  }, variant: _windows);

  testWidgets('拖自绘标题栏空白处：仍然搬动窗口', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await mouseDown(
        tester, tester.getCenter(find.byKey(const Key('title-bar'))));
    await moveDown(g, 40);
    await g.up();
    await tester.pumpAndSettle();

    expect(startDraggingCalls, 1);
  }, variant: _windows);

  testWidgets('卡片里拖过一次后，标题栏拖窗口不受影响', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g1 = await mouseDown(tester, tester.getCenter(find.text('card 1')));
    await moveDown(g1, 60);
    await g1.up();
    await tester.pumpAndSettle();

    final g2 = await mouseDown(
        tester, tester.getCenter(find.byKey(const Key('title-bar'))));
    await moveDown(g2, 40);
    await g2.up();
    await tester.pumpAndSettle();

    expect(startDraggingCalls, 1);
  }, variant: _windows);

  testWidgets('拖动后排除表不残留 pointer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final g = await mouseDown(tester, tester.getCenter(find.text('card 2')));
    await moveDown(g, 30);
    await g.up();
    await tester.pumpAndSettle();

    expect(debugWindowDragExcludedPointerCount, 0);
  }, variant: _windows);

  testWidgets('关掉拖窗再打开：App 子树不重挂，开关即时生效', (tester) async {
    await tester.pumpWidget(host(
      extra: const _CounterProbe(key: Key('probe')),
    ));
    await tester.pumpAndSettle();
    final state =
        tester.state<_CounterProbeState>(find.byKey(const Key('probe')));

    await MyApp.setDraggableEnabled(false);
    await tester.pump();
    var g = await mouseDown(
        tester,
        tester.getTopRight(find.byKey(const Key('title-bar'))) +
            const Offset(0, 24) -
            const Offset(10, 0));
    await moveDown(g, 40);
    await g.up();
    await tester.pumpAndSettle();
    expect(startDraggingCalls, 0);

    await MyApp.setDraggableEnabled(true);
    await tester.pump();
    // 双击判定用真实时钟：第二次按在离第一次 >kDoubleTapSlop 处，免得被当成双击第二击。
    g = await mouseDown(
        tester,
        tester.getTopLeft(find.byKey(const Key('title-bar'))) +
            const Offset(0, 24) +
            const Offset(10, 0));
    await moveDown(g, 40);
    await g.up();
    await tester.pumpAndSettle();
    expect(startDraggingCalls, 1);

    expect(
      identical(
          tester.state<_CounterProbeState>(find.byKey(const Key('probe'))),
          state),
      isTrue,
    );
  }, variant: _windows);

  testWidgets('ReorderableDragStartListener 手柄（立即拖）本来就不漏', (tester) async {
    final items = [0, 1, 2];
    await tester.pumpWidget(MaterialApp(
      home: CustomDragArea(
        enableDoubleClickMaximize: false,
        draggable: true,
        child: Scaffold(
          body: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorderItem: (a, b) => reorders.add((a, b)),
            itemBuilder: (_, i) => SizedBox(
              key: ValueKey(items[i]),
              height: 60,
              child: Row(children: [
                ReorderableDragStartListener(
                  index: i,
                  child: SizedBox(
                    key: Key('handle-$i'),
                    width: 24,
                    height: 24,
                    child: const ColoredBox(color: Colors.black),
                  ),
                ),
                Text('sub $i'),
              ]),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final g = await mouseDown(
        tester, tester.getCenter(find.byKey(const Key('handle-0'))));
    await moveDown(g, 130);
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();

    expect(startDraggingCalls, 0);
    expect(reorders, isNotEmpty);
  }, variant: _windows);

  testWidgets('MyDragProtectedArea 按下时不得让整个 App 子树重建丢状态', (tester) async {
    await tester.pumpWidget(host(
      extra: const MyDragProtectedArea(
        child: _CounterProbe(key: Key('probe')),
      ),
    ));
    await tester.pumpAndSettle();

    final state =
        tester.state<_CounterProbeState>(find.byKey(const Key('probe')));
    state.bump();
    await tester.pump();

    final g = await mouseDown(
        tester, tester.getCenter(find.byKey(const Key('probe'))));
    await tester.pump();
    await moveDown(g, 40);
    await g.up();
    await tester.pumpAndSettle();

    final after =
        tester.state<_CounterProbeState>(find.byKey(const Key('probe')));
    expect(identical(after, state), isTrue, reason: '按下保护区后整棵子树被重挂载');
    expect(after.count, 1);
    expect(startDraggingCalls, 0);
    expect(MyApp.isDraggableEnabled(), isTrue);
  }, variant: _windows);
}

class _CounterProbe extends StatefulWidget {
  const _CounterProbe({super.key});

  @override
  State<_CounterProbe> createState() => _CounterProbeState();
}

class _CounterProbeState extends State<_CounterProbe> {
  int count = 0;
  void bump() => setState(() => count++);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ColoredBox(color: Colors.amber, child: Text('probe $count')),
    );
  }
}
