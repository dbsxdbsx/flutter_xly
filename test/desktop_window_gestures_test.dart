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

  testWidgets('标准按钮/开关/芯片/滑块/卡片全部识别为 interactive，双击 MyButton 不触发全屏且两次均响应',
      (tester) async {
    tester.view
      ..physicalSize = const Size(640, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var maximizeCount = 0;
    var normalBtnClicks = 0;
    var cubeBtnClicks = 0;
    var filterSelected = false;
    var switchVal = false;
    var checkVal = false;
    var sliderVal = 0.5;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(640, 640),
        builder: (_, __) => MaterialApp(
          home: CustomDragArea(
            enableDoubleClickMaximize: true,
            draggable: false,
            onToggleMaximize: () async => maximizeCount++,
            child: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyButton(
                    key: const Key('green-btn'),
                    text: '绿色按钮',
                    onPressed: () => normalBtnClicks++,
                  ),
                  MyButton(
                    key: const Key('cube-btn'),
                    shape: MyButtonShape.cube,
                    text: '方块',
                    onPressed: () => cubeBtnClicks++,
                  ),
                  TextButton(
                    key: const Key('text-btn'),
                    onPressed: () {},
                    child: const Text('文本按钮'),
                  ),
                  IconButton(
                    key: const Key('icon-btn'),
                    onPressed: () {},
                    icon: const Icon(Icons.star),
                  ),
                  FilterChip(
                    key: const Key('filter-chip'),
                    label: const Text('筛选'),
                    selected: filterSelected,
                    onSelected: (v) => filterSelected = v,
                  ),
                  Switch(
                    key: const Key('switch'),
                    value: switchVal,
                    onChanged: (v) => switchVal = v,
                  ),
                  Checkbox(
                    key: const Key('checkbox'),
                    value: checkVal,
                    onChanged: (v) => checkVal = v ?? false,
                  ),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      key: const Key('slider'),
                      value: sliderVal,
                      onChanged: (v) => sliderVal = v,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    height: 44,
                    child: MyCard(
                      key: const Key('clickable-card'),
                      onPressed: () {},
                      child: const Text('可点卡片'),
                    ),
                  ),
                  const SizedBox(
                    width: 180,
                    height: 44,
                    child: MyCard(
                      key: Key('static-card'),
                      child: Text('纯展示卡片'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 所有交互控件都必须命中 interactive（彻底杜绝 InkWell excludeFromSemantics 漏检）
    for (final keyName in const [
      'green-btn',
      'cube-btn',
      'text-btn',
      'icon-btn',
      'filter-chip',
      'switch',
      'checkbox',
      'slider',
      'clickable-card',
    ]) {
      expect(
        classifyDesktopHit(tester.getCenter(find.byKey(Key(keyName)))),
        MyDesktopHitKind.interactive,
        reason: '$keyName 必须判定为 interactive，禁止双击穿透最大化',
      );
    }

    // 不可点击纯展示卡片仍算 background
    expect(
      classifyDesktopHit(
          tester.getCenter(find.byKey(const Key('static-card')))),
      MyDesktopHitKind.background,
    );

    // 在绿色 MyButton 上连续双击：两次点击都正常响应，0 次窗口最大化
    await _mouseDoubleClick(tester, find.byKey(const Key('green-btn')));
    expect(normalBtnClicks, 2);
    expect(maximizeCount, 0);

    await tester.pump(const Duration(milliseconds: 400));
    await _mouseDoubleClick(tester, find.byKey(const Key('cube-btn')));
    expect(cubeBtnClicks, 2);
    expect(maximizeCount, 0);
  });

  testWidgets('第 1 击点掉消失型按钮后，第 2 击落在露出的背景上不误触发最大化；右键双击不触发最大化', (tester) async {
    var maximizeCount = 0;
    var showBtn = true;
    late StateSetter setHostState;

    await tester.pumpWidget(
      MaterialApp(
        home: CustomDragArea(
          enableDoubleClickMaximize: true,
          draggable: false,
          onToggleMaximize: () async => maximizeCount++,
          child: Scaffold(
            body: Stack(
              children: [
                const SizedBox.expand(
                  child: ColoredBox(
                    key: Key('bg'),
                    color: Colors.white,
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) {
                    setHostState = setState;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: showBtn
                          ? ElevatedButton(
                              key: const Key('vanish-btn'),
                              onPressed: () =>
                                  setHostState(() => showBtn = false),
                              child: const Text('点一下就消失'),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final btnPos = tester.getCenter(find.byKey(const Key('vanish-btn')));
    // 第 1 击点在按钮上 → 按钮消失；40ms 后同坐标第 2 击落在空白背景上 → 不得当双击最大化
    await tester.tapAt(btnPos, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 40));
    expect(showBtn, isFalse);
    await tester.tapAt(btnPos, kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(maximizeCount, 0);

    // 右键双击空白处：绝不触发最大化
    await tester.pump(const Duration(milliseconds: 400));
    final bgPos = tester.getCenter(find.byKey(const Key('bg')));
    await tester.tapAt(
      bgPos,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(
      bgPos,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    expect(maximizeCount, 0);
  });

  testWidgets('整窗拖拽自动避开 TextField / 按钮与非左键，空白处拖窗仍正常', (tester) async {
    var windowDragCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: <Type, GestureRecognizerFactory>{
            MyWindowDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                MyWindowDragGestureRecognizer>(
              () => MyWindowDragGestureRecognizer(isEnabled: () => true),
              (instance) => instance.onStart = (_) => windowDragCount++,
            ),
          },
          child: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  key: Key('drag-blank'),
                  width: 240,
                  height: 60,
                  child: ColoredBox(color: Colors.grey),
                ),
                const SizedBox(
                  width: 240,
                  child: TextField(key: Key('drag-input')),
                ),
                ElevatedButton(
                  key: const Key('drag-btn'),
                  onPressed: () {},
                  child: const Text('按钮'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> dragFrom(Offset start,
        {int buttons = kPrimaryMouseButton}) async {
      final g = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
        buttons: buttons,
      );
      await g.moveBy(const Offset(40, 20));
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();
    }

    // 1. 输入框划选文字 → 不拖窗
    await dragFrom(tester.getCenter(find.byKey(const Key('drag-input'))));
    expect(windowDragCount, 0);

    // 2. 按钮拉出取消 → 不拖窗
    await dragFrom(tester.getCenter(find.byKey(const Key('drag-btn'))));
    expect(windowDragCount, 0);

    // 3. 右键拖空白处 → 不拖窗
    await dragFrom(
      tester.getCenter(find.byKey(const Key('drag-blank'))),
      buttons: kSecondaryMouseButton,
    );
    expect(windowDragCount, 0);

    // 4. 左键拖空白处 → 正常拖窗
    await dragFrom(tester.getCenter(find.byKey(const Key('drag-blank'))));
    expect(windowDragCount, 1);
  });
}

Future<void> _mouseDoubleClick(WidgetTester tester, Finder finder) async {
  final center = tester.getCenter(finder);
  await tester.tapAt(center, kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tapAt(center, kind: PointerDeviceKind.mouse);
  await tester.pump();
}
