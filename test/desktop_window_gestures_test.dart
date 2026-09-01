import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('空白区域判定为 background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ColoredBox(color: Colors.grey),
          ),
        ),
      ),
    );

    expect(
      classifyDesktopHit(const Offset(200, 200)),
      MyDesktopHitKind.background,
    );
  });

  testWidgets('TextField 判定为 editable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: TextField(),
            ),
          ),
        ),
      ),
    );

    expect(
      classifyDesktopHit(tester.getCenter(find.byType(TextField))),
      MyDesktopHitKind.editable,
    );
  });

  testWidgets('仅有 onTapDown 的 GestureDetector 判定为 interactive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onTapDown: (_) {},
              child: const SizedBox(
                key: Key('spin-btn'),
                width: 48,
                height: 48,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      classifyDesktopHit(tester.getCenter(find.byKey(const Key('spin-btn')))),
      MyDesktopHitKind.interactive,
    );
  });

  testWidgets('MyDoubleClickConsumeZone 把 Listener-only 区域标成 interactive',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MyDoubleClickConsumeZone(
              child: Listener(
                onPointerDown: (_) {},
                child: const SizedBox(
                  key: Key('listener-only'),
                  width: 48,
                  height: 48,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final pos = tester.getCenter(find.byKey(const Key('listener-only')));
    expect(debugHitPathHasConsumeZone(pos), isTrue);
    expect(classifyDesktopHit(pos), MyDesktopHitKind.interactive);
  });

  testWidgets('MySpinBox 加减按钮命中 interactive，中心数字命中 editable', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 640),
        builder: (_, __) => GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: MySpinBox(
                label: '间隔',
                initialValue: 50,
                min: 0,
                max: 100,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      classifyDesktopHit(tester.getCenter(find.byIcon(Icons.add))),
      MyDesktopHitKind.interactive,
    );
    expect(
      classifyDesktopHit(tester.getCenter(find.byType(TextField))),
      MyDesktopHitKind.editable,
    );
  });

  testWidgets('整页 showRightMenu 仍是 background，双击会最大化', (tester) async {
    var maximizeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return CustomDragArea(
              enableDoubleClickMaximize: true,
              draggable: false,
              onToggleMaximize: () async => maximizeCount++,
              child: const SizedBox.expand(
                child: ColoredBox(
                  key: Key('page-blank'),
                  color: Colors.grey,
                ),
              ).showRightMenu(
                context: context,
                menuElements: [
                  MyMenuItem(text: '项', onTap: () {}),
                ],
              ),
            );
          },
        ),
      ),
    );

    final pos = tester.getCenter(find.byKey(const Key('page-blank')));
    expect(classifyDesktopHit(pos), MyDesktopHitKind.background);

    await _mouseDoubleClick(tester, find.byKey(const Key('page-blank')));
    expect(maximizeCount, 1);
  });

  testWidgets('连点交互控件不触发窗口最大化，空白处双击仍会', (tester) async {
    var maximizeCount = 0;
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: CustomDragArea(
          enableDoubleClickMaximize: true,
          draggable: false,
          onToggleMaximize: () async => maximizeCount++,
          child: Column(
            children: [
              GestureDetector(
                onTapDown: (_) => tapCount++,
                child: const SizedBox(
                  key: Key('btn'),
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
              const SizedBox(
                key: Key('blank'),
                width: 200,
                height: 120,
                child: ColoredBox(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    await _mouseDoubleClick(tester, find.byKey(const Key('btn')));
    expect(tapCount, 2);
    expect(maximizeCount, 0);

    await tester.pump(const Duration(milliseconds: 400));
    await _mouseDoubleClick(tester, find.byKey(const Key('blank')));
    expect(maximizeCount, 1);
    expect(tapCount, 2);
  });

  testWidgets('外层不再注册 DoubleTapGestureRecognizer，内层单击零延迟落地', (tester) async {
    var tapCount = 0;
    final tapTimes = <Duration>[];
    late Stopwatch watch;

    await tester.pumpWidget(
      MaterialApp(
        home: CustomDragArea(
          enableDoubleClickMaximize: true,
          draggable: false,
          onToggleMaximize: () async {},
          child: GestureDetector(
            onTap: () {
              tapCount++;
              tapTimes.add(watch.elapsed);
            },
            child: const SizedBox.expand(
              child: ColoredBox(
                key: Key('tap-surface'),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    watch = Stopwatch()..start();
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('tap-surface'))),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(tapCount, 1);
    expect(
      tapTimes.single,
      lessThan(const Duration(milliseconds: 50)),
      reason: '窗口层若挂了 onDoubleTap，单击会被 hold 约 300ms',
    );
  });
}

Future<void> _mouseDoubleClick(WidgetTester tester, Finder finder) async {
  final center = tester.getCenter(finder);
  await tester.tapAt(center, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tapAt(center, kind: PointerDeviceKind.mouse);
  await tester.pump();
}
