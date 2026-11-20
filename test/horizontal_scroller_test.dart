import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

Widget _wrapApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 640),
    builder: (_, __) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

List<Widget> _buildChips(int count, {double width = 70}) {
  return [
    for (var i = 0; i < count; i++)
      Container(
        width: width,
        height: 28,
        margin: const EdgeInsets.only(right: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('项$i'),
      ),
  ];
}

void main() {
  testWidgets('未溢出时不显示左右箭头，且垂直滚轮透传给外层列表', (tester) async {
    final outerCtrl = ScrollController();
    addTearDown(outerCtrl.dispose);

    await tester.pumpWidget(
      _wrapApp(
        SizedBox(
          width: 320,
          height: 240,
          child: ListView(
            controller: outerCtrl,
            children: [
              SizedBox(
                height: 36,
                child: MyHorizontalScroller(
                  child: Row(children: _buildChips(2, width: 60)),
                ),
              ),
              const SizedBox(height: 600),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MyHorizontalScroller.leadingIndicatorKey), findsNothing);
    expect(find.byKey(MyHorizontalScroller.trailingIndicatorKey), findsNothing);

    // 鼠标停在未溢出的横向条上滚轮，外层垂直列表正常竖滚
    final center = tester.getCenter(find.text('项0'));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    tester.binding.handlePointerEvent(pointer.hover(center));
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, 120)));
    await tester.pumpAndSettle();

    expect(outerCtrl.offset, greaterThan(0));
  });

  testWidgets('横向溢出时显示右侧箭头，悬停滚轮直接横滚且不带动外层竖滚', (tester) async {
    final outerCtrl = ScrollController();
    final innerCtrl = ScrollController();
    addTearDown(outerCtrl.dispose);
    addTearDown(innerCtrl.dispose);

    await tester.pumpWidget(
      _wrapApp(
        SizedBox(
          width: 240,
          height: 240,
          child: ListView(
            controller: outerCtrl,
            children: [
              SizedBox(
                height: 36,
                child: MyHorizontalScroller(
                  controller: innerCtrl,
                  child: Row(children: _buildChips(8, width: 70)),
                ),
              ),
              const SizedBox(height: 600),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MyHorizontalScroller.leadingIndicatorKey), findsNothing);
    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsOneWidget,
    );

    // 鼠标悬停在首个胶囊上滚垂直滚轮 → 横向滚动生效，外层不竖滚
    final center = tester.getCenter(find.text('项0'));
    final pointer = TestPointer(2, PointerDeviceKind.mouse);
    tester.binding.handlePointerEvent(pointer.hover(center));
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, 120)));
    await tester.pumpAndSettle();

    expect(innerCtrl.offset, closeTo(120, 1.0));
    expect(outerCtrl.offset, 0);
    expect(
      find.byKey(MyHorizontalScroller.leadingIndicatorKey),
      findsOneWidget,
    );
    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsOneWidget,
    );

    // 滚到底后右侧箭头自动消失
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, 1000)));
    await tester.pumpAndSettle();
    expect(innerCtrl.offset, closeTo(innerCtrl.position.maxScrollExtent, 1.0));
    expect(find.byKey(MyHorizontalScroller.trailingIndicatorKey), findsNothing);
    expect(
      find.byKey(MyHorizontalScroller.leadingIndicatorKey),
      findsOneWidget,
    );
  });

  testWidgets('点击左右箭头平滑翻页，长按持续步进滚动', (tester) async {
    final ctrl = ScrollController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      _wrapApp(
        SizedBox(
          width: 220,
          height: 36,
          child: MyHorizontalScroller(
            controller: ctrl,
            arrowTapScrollExtent: 100,
            arrowLongPressInitialDelay: const Duration(milliseconds: 120),
            arrowLongPressInterval: const Duration(milliseconds: 40),
            arrowLongPressStep: 30,
            child: Row(children: _buildChips(10, width: 70)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 单击右箭头步进 100px
    await tester.tapAt(
      tester.getCenter(find.byKey(MyHorizontalScroller.trailingIndicatorKey)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(ctrl.offset, closeTo(100, 1.0));

    // 单击左箭头回到起点
    await tester.tapAt(
      tester.getCenter(find.byKey(MyHorizontalScroller.leadingIndicatorKey)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(ctrl.offset, closeTo(0, 1.0));

    // 长按右箭头持续向前滚（长按先触发 onTapDown 100px，500ms 后进入长按再持续步进）
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(MyHorizontalScroller.trailingIndicatorKey)),
      kind: PointerDeviceKind.touch,
    );
    // 先等长按识别（kLongPressTimeout = 500ms）+ 初始延迟 + 数次周期步进
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump(const Duration(milliseconds: 220));
    final offsetAfterHold = ctrl.offset;
    await gesture.up();
    await tester.pumpAndSettle();

    expect(offsetAfterHold, greaterThan(180));
  });

  testWidgets('动态增删子项时边缘箭头自动响应更新', (tester) async {
    var count = 2;
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapApp(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SizedBox(
              width: 220,
              height: 36,
              child: MyHorizontalScroller(
                child: Row(children: _buildChips(count, width: 70)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(MyHorizontalScroller.trailingIndicatorKey), findsNothing);

    // 扩容到 8 项：右箭头出现
    setHostState(() => count = 8);
    await tester.pumpAndSettle();
    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsOneWidget,
    );

    // 缩回 2 项：右箭头消失
    setHostState(() => count = 2);
    await tester.pumpAndSettle();
    expect(find.byKey(MyHorizontalScroller.trailingIndicatorKey), findsNothing);
  });

  testWidgets('在 CustomDragArea 内连点箭头不触发窗口双击最大化，且排除窗口拖拽', (tester) async {
    var maximizeCount = 0;
    final ctrl = ScrollController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      _wrapApp(
        CustomDragArea(
          enableDoubleClickMaximize: true,
          draggable: true,
          onToggleMaximize: () async => maximizeCount++,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 220,
              height: 36,
              child: MyHorizontalScroller(
                controller: ctrl,
                arrowTapScrollExtent: 90,
                child: Row(children: _buildChips(10, width: 70)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final arrowCenter =
        tester.getCenter(find.byKey(MyHorizontalScroller.trailingIndicatorKey));
    expect(debugHitPathHasConsumeZone(arrowCenter), isTrue);
    expect(classifyDesktopHit(arrowCenter), MyDesktopHitKind.interactive);

    // 高速连点两次右箭头：应该连续滚两步，但不触发最大化
    await tester.tapAt(arrowCenter, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(arrowCenter, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    expect(maximizeCount, 0);
    expect(ctrl.offset, closeTo(180, 1.5));
    expect(debugWindowDragExcludedPointerCount, 0);
  });

  testWidgets('childIsScrollable=true 复用外部横向 ListView 正常工作', (tester) async {
    final ctrl = ScrollController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      _wrapApp(
        SizedBox(
          width: 220,
          height: 36,
          child: MyHorizontalScroller(
            controller: ctrl,
            childIsScrollable: true,
            child: ListView.builder(
              controller: ctrl,
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (_, index) => SizedBox(
                width: 70,
                child: Center(child: Text('列表$index')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsOneWidget,
    );

    final pointer = TestPointer(9, PointerDeviceKind.mouse);
    final pos = tester.getCenter(find.text('列表0'));
    tester.binding.handlePointerEvent(pointer.hover(pos));
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, 90)));
    await tester.pumpAndSettle();

    expect(ctrl.offset, closeTo(90, 1.0));
  });

  testWidgets('鼠标左键按住滑条横拖只在内部滚动：不触发母窗拖动、不误点胶囊；轻点正常点击', (tester) async {
    final ctrl = ScrollController();
    addTearDown(ctrl.dispose);

    var tappedChip = -1;
    var windowDragTriggered = false;

    await tester.pumpWidget(
      _wrapApp(
        RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            MyWindowDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                MyWindowDragGestureRecognizer>(
              () => MyWindowDragGestureRecognizer(isEnabled: () => true),
              (instance) {
                instance.onStart = (_) => windowDragTriggered = true;
              },
            ),
          },
          child: SizedBox.expand(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 220,
                height: 36,
                child: MyHorizontalScroller(
                  controller: ctrl,
                  child: Row(
                    children: [
                      for (var i = 0; i < 8; i++)
                        GestureDetector(
                          onTap: () => tappedChip = i,
                          child: Container(
                            width: 70,
                            height: 28,
                            margin: const EdgeInsets.only(right: 6),
                            alignment: Alignment.center,
                            color: Colors.blue.shade50,
                            child: Text('胶囊$i'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 轻点（小抖动 3px < 6px）→ 正常命中胶囊 onTap，不滚动也不拖窗
    final chipPos = tester.getCenter(find.text('胶囊0'));
    final lightTap = await tester.startGesture(
      chipPos,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await lightTap.moveBy(const Offset(-3, 0));
    await lightTap.up();
    await tester.pumpAndSettle();
    expect(tappedChip, 0);
    expect(ctrl.offset, 0);
    expect(windowDragTriggered, isFalse);

    // 2. 明确按住向左拖动 100px → 内部平滑滚动，绝不触发母窗拖动，也不误点胶囊
    tappedChip = -1;
    final dragPos = tester.getCenter(find.text('胶囊1'));
    final drag = await tester.startGesture(
      dragPos,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await drag.moveBy(const Offset(-20, 0));
    await tester.pump();
    await drag.moveBy(const Offset(-80, 0));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(ctrl.offset, greaterThan(50));
    expect(tappedChip, -1);
    expect(windowDragTriggered, isFalse);
    expect(debugWindowDragExcludedPointerCount, 0);
  });

  testWidgets('未溢出时放行外层母窗口拖动', (tester) async {
    var windowDragTriggered = false;

    await tester.pumpWidget(
      _wrapApp(
        RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            MyWindowDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                MyWindowDragGestureRecognizer>(
              () => MyWindowDragGestureRecognizer(isEnabled: () => true),
              (instance) {
                instance.onStart = (_) => windowDragTriggered = true;
              },
            ),
          },
          child: SizedBox.expand(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                height: 36,
                child: MyHorizontalScroller(
                  child: Row(children: _buildChips(2, width: 60)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final start = tester.getCenter(find.text('项0'));
    final drag = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await drag.moveBy(const Offset(40, 20));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(windowDragTriggered, isTrue);
  });

  testWidgets('头部增删按当前视图位置动态响应：停在头部直接推入，滚离头部同帧锚定不跳飞', (tester) async {
    final ctrl = MyHorizontalScrollerController();
    addTearDown(ctrl.dispose);

    final items = <String>['项1', '项2', '项3', '项4', '项5'];
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapApp(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 220,
                height: 36,
                child: MyHorizontalScroller(
                  controller: ctrl,
                  child: Row(
                    children: [
                      for (final label in items)
                        Container(
                          key: ValueKey<String>(label),
                          width: 70,
                          height: 28,
                          margin: const EdgeInsets.only(right: 6),
                          alignment: Alignment.center,
                          child: Text(label),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 停在头部（offset == 0）头部新增：不藏到左边，直接推入视野最左侧
    expect(ctrl.offset, closeTo(0, 0.5));
    ctrl.prepareLeadingChange();
    setHostState(() => items.insert(0, '头部0'));
    await tester.pumpAndSettle();

    expect(ctrl.offset, closeTo(0, 0.5));
    expect(tester.getTopLeft(find.text('头部0')).dx, greaterThanOrEqualTo(0));
    expect(find.byKey(MyHorizontalScroller.leadingIndicatorKey), findsNothing);
    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsOneWidget,
    );

    // 2. 向右滚离头部（浏览「项2」「项3」）：记录「项3」当前屏幕 x
    ctrl.jumpTo(152);
    await tester.pumpAndSettle();
    expect(
      find.byKey(MyHorizontalScroller.leadingIndicatorKey),
      findsOneWidget,
    );
    final anchorBeforeX = tester.getTopLeft(find.text('项3')).dx;

    // 3. 在已滚离头部状态下「头部新增」：同帧补偿偏移，眼前「项3」纹丝不动
    ctrl.prepareLeadingChange();
    setHostState(() => items.insert(0, '头部-1'));
    await tester.pump();
    // 就在当帧（不需等后续帧），「项3」屏幕坐标就已经像素级稳住！
    expect(
      tester.getTopLeft(find.text('项3')).dx,
      closeTo(anchorBeforeX, 0.5),
    );
    expect(ctrl.offset, closeTo(152 + 76, 1.0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(MyHorizontalScroller.leadingIndicatorKey),
      findsOneWidget,
    );

    // 4. 在已滚离头部状态下「移除头部」：偏移同步回退，眼前「项3」依然纹丝不动
    ctrl.prepareLeadingChange();
    setHostState(() => items.removeAt(0));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('项3')).dx,
      closeTo(anchorBeforeX, 0.5),
    );
    expect(ctrl.offset, closeTo(152, 1.0));

    // 5. 连续移除头部直到左侧隐藏区清空：左箭头自然消失
    ctrl.prepareLeadingChange();
    setHostState(() => items.removeAt(0));
    await tester.pump();
    ctrl.prepareLeadingChange();
    setHostState(() => items.removeAt(0));
    await tester.pumpAndSettle();
    expect(ctrl.offset, closeTo(0, 0.5));
    expect(find.byKey(MyHorizontalScroller.leadingIndicatorKey), findsNothing);

    // 6. 尾部追加通知会立刻结束头部锚定，scrollToEnd / scrollToStart 平滑直达两端
    ctrl.notifyTrailingChange();
    setHostState(() => items.add('尾部9'));
    await tester.pumpAndSettle();
    expect(ctrl.isAnchoringLeading, isFalse);

    final endFuture = ctrl.scrollToEnd();
    await tester.pumpAndSettle();
    await endFuture;
    expect(ctrl.offset, closeTo(ctrl.position.maxScrollExtent, 1.0));

    final startFuture = ctrl.scrollToStart();
    await tester.pumpAndSettle();
    await startFuture;
    expect(ctrl.offset, closeTo(0, 0.5));
  });

  testWidgets('尾部新增策略：ifAtEnd 仅贴尾跟随不打断前段浏览，always 始终平滑滚到尾部', (tester) async {
    final ctrl = MyHorizontalScrollerController();
    addTearDown(ctrl.dispose);

    final items = <String>['项1', '项2', '项3', '项4', '项5'];
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapApp(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 220,
                height: 36,
                child: MyHorizontalScroller(
                  controller: ctrl,
                  child: Row(
                    children: [
                      for (final label in items)
                        Container(
                          key: ValueKey<String>(label),
                          width: 70,
                          height: 28,
                          margin: const EdgeInsets.only(right: 6),
                          alignment: Alignment.center,
                          child: Text(label),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 当前停在头部（未到尾部）：默认 ifAtEnd 追加尾部项 → 绝不抢视角，offset 保持 0
    expect(ctrl.offset, closeTo(0, 0.5));
    ctrl.notifyTrailingChange(reveal: MyHorizontalTrailingReveal.ifAtEnd);
    setHostState(() => items.add('后台6'));
    await tester.pumpAndSettle();
    expect(ctrl.offset, closeTo(0, 0.5));
    expect(
      find.byKey(MyHorizontalScroller.trailingIndicatorKey),
      findsOneWidget,
    );

    // 2. 主动滚到尾部后，再用 ifAtEnd 追加 → 自动平滑粘尾露出「后台7」
    ctrl.jumpTo(ctrl.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final prevMax = ctrl.position.maxScrollExtent;
    ctrl.notifyTrailingChange(reveal: MyHorizontalTrailingReveal.ifAtEnd);
    setHostState(() => items.add('后台7'));
    await tester.pumpAndSettle();
    expect(ctrl.position.maxScrollExtent, greaterThan(prevMax + 60));
    expect(ctrl.offset, closeTo(ctrl.position.maxScrollExtent, 1.0));
    expect(find.byKey(MyHorizontalScroller.trailingIndicatorKey), findsNothing);

    // 3. 滚回头部（offset == 0），改用 always（用户主动点击尾部追加）→ 自动平滑滚到最右端露出「主动8」
    ctrl.jumpTo(0);
    await tester.pumpAndSettle();
    expect(ctrl.offset, closeTo(0, 0.5));

    ctrl.notifyTrailingChange(reveal: MyHorizontalTrailingReveal.always);
    setHostState(() => items.add('主动8'));
    await tester.pumpAndSettle();
    expect(ctrl.offset, closeTo(ctrl.position.maxScrollExtent, 1.0));
    expect(find.byKey(MyHorizontalScroller.trailingIndicatorKey), findsNothing);
  });
}
