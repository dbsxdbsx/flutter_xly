import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  testWidgets('MyList 向后移动仍传移除前插入下标', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    (int, int)? received;

    await tester.pumpWidget(
      MaterialApp(
        home: MyList<int>(
          items: const [1, 2, 3],
          itemBuilder: (_, index) => SizedBox(
            key: ValueKey(index),
            height: 40,
            child: Text('$index'),
          ),
          scrollController: scrollController,
          isDraggable: true,
          onCardReordered: (oldIndex, newIndex) {
            received = (oldIndex, newIndex);
          },
        ),
      ),
    );

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(0, 2);
    expect(received, (0, 3));
  });

  testWidgets('可拖卡片长按后才开始拖', (tester) async {
    tester.view
      ..physicalSize = const Size(700, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(350, 600),
        ensureScreenSize: false,
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: MyList<int>(
                items: const [0],
                itemBuilder: (_, index) => MyCard(
                  key: ValueKey(index),
                  index: index,
                  isDraggable: true,
                  child: const Text('card'),
                ),
                scrollController: scrollController,
                isDraggable: true,
                onCardReordered: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ReorderableDelayedDragStartListener), findsOneWidget);
  });

  testWidgets('快速一甩会滚动可拖列表', (tester) async {
    tester.view
      ..physicalSize = const Size(700, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    var reordered = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(350, 600),
        ensureScreenSize: false,
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: MyList<int>(
                items: List<int>.generate(30, (index) => index),
                itemBuilder: (_, index) => MyCard(
                  key: ValueKey(index),
                  index: index,
                  isDraggable: true,
                  child: SizedBox(
                    height: 48,
                    child: Text('card $index'),
                  ),
                ),
                scrollController: scrollController,
                isDraggable: true,
                onCardReordered: (_, __) {
                  reordered = true;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('card 0')),
    );
    await gesture.moveBy(const Offset(0, -220));
    await gesture.up();
    await tester.pump();

    expect(scrollController.offset, greaterThan(40));
    expect(reordered, isFalse);
  });

  testWidgets('快滑松手后按速度惯性滑行', (tester) async {
    tester.view
      ..physicalSize = const Size(700, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(350, 600),
        ensureScreenSize: false,
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: MyList<int>(
                items: List<int>.generate(40, (index) => index),
                itemBuilder: (_, index) => MyCard(
                  key: ValueKey(index),
                  index: index,
                  isDraggable: true,
                  child: SizedBox(height: 56, child: Text('card $index')),
                ),
                scrollController: scrollController,
                isDraggable: true,
                onCardReordered: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('card 0')),
    );
    // 50ms 内划过 120px，约 2400 px/s，应明显超过手指路程。
    const travel = 120.0;
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      await gesture.moveBy(
        const Offset(0, -travel / steps),
        timeStamp: Duration(milliseconds: 50 * i ~/ steps),
      );
    }
    await gesture.up(timeStamp: const Duration(milliseconds: 50));
    final atRelease = scrollController.offset;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(scrollController.offset, greaterThan(atRelease + 80));
  });
}
