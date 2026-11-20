import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

Widget _wrapToggle(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 640),
    builder: (_, __) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('点击切换时滑块平滑水平移动，且首帧即就位', (tester) async {
    var mode = 'manual';
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return MySegmentedToggle<String>(
              value: mode,
              onChanged: (next) => setHostState(() => mode = next),
              options: const [
                MyToggleOption(
                  key: Key('seg-manual'),
                  value: 'manual',
                  label: '手动',
                  icon: Icons.lock_outline,
                  activeColor: Color(0xFF455A64),
                ),
                MyToggleOption(
                  key: Key('seg-auto'),
                  value: 'auto',
                  label: '智能',
                  icon: Icons.auto_awesome,
                  activeColor: Color(0xFF1E88E5),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    final startRect = tester.getRect(find.byKey(MySegmentedToggle.thumbKey));
    final manualRect = tester.getRect(find.byKey(const Key('seg-manual')));
    final autoRect = tester.getRect(find.byKey(const Key('seg-auto')));
    expect(startRect.center.dx, closeTo(manualRect.center.dx, 1.0));

    // 点击右侧「智能」
    await tester.tap(find.byKey(const Key('seg-auto')));
    await tester.pump();
    // 动画中段（100ms）：滑块位于左右两段之间（正在滑行，不是瞬间跳变）
    await tester.pump(const Duration(milliseconds: 100));
    final midRect = tester.getRect(find.byKey(MySegmentedToggle.thumbKey));
    expect(midRect.left, greaterThan(startRect.left + 2));

    // 动画结束后稳稳停在「智能」处
    await tester.pumpAndSettle();
    final endRect = tester.getRect(find.byKey(MySegmentedToggle.thumbKey));
    expect(mode, 'auto');
    expect(endRect.center.dx, closeTo(autoRect.center.dx, 1.0));
    expect(endRect.left, greaterThan(midRect.left));
  });

  testWidgets('支持鼠标/手指轻拨滑动切换，且不触发外层母窗口拖动', (tester) async {
    var mode = 'manual';
    var windowDragTriggered = false;
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
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
            child: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  setHostState = setState;
                  return MySegmentedToggle<String>(
                    value: mode,
                    onChanged: (next) => setHostState(() => mode = next),
                    options: const [
                      MyToggleOption(value: 'manual', label: '手动'),
                      MyToggleOption(value: 'auto', label: '智能'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 鼠标按住「手动」往右轻拨 50px → 切到「智能」，不拉动母窗口
    final start = tester.getCenter(find.text('手动'));
    final gesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(mode, 'auto');
    expect(windowDragTriggered, isFalse);
    expect(debugWindowDragExcludedPointerCount, 0);
  });

  testWidgets('value 为 null 时滑块隐藏，notifyOnReselect 控制重选回调', (tester) async {
    String? current;
    var callbacks = 0;
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return MySegmentedToggle<String>(
              value: current,
              notifyOnReselect: true,
              onChanged: (next) {
                callbacks++;
                setHostState(() => current = next);
              },
              options: const [
                MyToggleOption(value: 'a', label: '甲'),
                MyToggleOption(value: 'b', label: '乙'),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hiddenOpacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(MySegmentedToggle.thumbKey),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(hiddenOpacity.opacity, 0.0);

    await tester.tap(find.text('乙'));
    await tester.pumpAndSettle();
    expect(current, 'b');
    expect(callbacks, 1);

    final shownOpacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(MySegmentedToggle.thumbKey),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(shownOpacity.opacity, 1.0);

    // 再次点击当前已选项：notifyOnReselect=true 仍会通知
    await tester.tap(find.text('乙'));
    await tester.pumpAndSettle();
    expect(callbacks, 2);
  });

  testWidgets('在 CustomDragArea 内连点开关不触发窗口双击最大化', (tester) async {
    var maximizeCount = 0;
    var mode = 'a';
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        CustomDragArea(
          enableDoubleClickMaximize: true,
          draggable: true,
          onToggleMaximize: () async => maximizeCount++,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return MySegmentedToggle<String>(
                  value: mode,
                  onChanged: (next) => setHostState(() => mode = next),
                  options: const [
                    MyToggleOption(value: 'a', label: '手动'),
                    MyToggleOption(value: 'b', label: '智能'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pos = tester.getCenter(find.text('智能'));
    expect(debugHitPathHasConsumeZone(pos), isTrue);

    await tester.tapAt(pos, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(pos, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    expect(maximizeCount, 0);
  });

  testWidgets('equalWidth=false 紧凑模式按实际宽度贴合滑行', (tester) async {
    var val = 'short';
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return MySegmentedToggle<String>(
              equalWidth: false,
              value: val,
              onChanged: (next) => setHostState(() => val = next),
              options: const [
                MyToggleOption(value: 'short', label: '短'),
                MyToggleOption(value: 'long', label: '非常长的选项文案'),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shortThumb = tester.getSize(find.byKey(MySegmentedToggle.thumbKey));
    await tester.tap(find.text('非常长的选项文案'));
    await tester.pumpAndSettle();
    final longThumb = tester.getSize(find.byKey(MySegmentedToggle.thumbKey));

    expect(longThumb.width, greaterThan(shortThumb.width + 30));
  });

  testWidgets('3 段开关满程拖滑可一口气跨段到达末端，不卡在 0.9', (tester) async {
    var choice = 'first';
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return MySegmentedToggle<String>(
              value: choice,
              onChanged: (next) => setHostState(() => choice = next),
              options: const [
                MyToggleOption(
                  key: Key('s0'),
                  value: 'first',
                  label: '第一段',
                  activeColor: Color(0xFF00897B),
                ),
                MyToggleOption(
                  key: Key('s1'),
                  value: 'second',
                  label: '第二段',
                  activeColor: Color(0xFFFB8C00),
                ),
                MyToggleOption(
                  key: Key('s2'),
                  value: 'third',
                  label: '第三段',
                  activeColor: Color(0xFF3949AB),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final r0 = tester.getRect(find.byKey(const Key('s0')));
    final r2 = tester.getRect(find.byKey(const Key('s2')));
    final gesture = await tester.startGesture(
      r0.center,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    // 分步拖动到第 3 段中心（超过 1.9 段宽）
    final totalDx = r2.center.dx - r0.center.dx;
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(totalDx / 10, 0));
      await tester.pump();
    }

    // 松手前滑块就已经跟手滑到第 3 段附近，绝不卡在 0.9 段
    final draggedThumb = tester.getRect(find.byKey(MySegmentedToggle.thumbKey));
    expect(draggedThumb.center.dx, closeTo(r2.center.dx, 4.0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(choice, 'third');
  });

  testWidgets('紧凑模式从短段拖向长段不卡墙，拖动中滑块宽度实时拉伸', (tester) async {
    var choice = 'short';
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return MySegmentedToggle<String>(
              equalWidth: false,
              value: choice,
              onChanged: (next) => setHostState(() => choice = next),
              options: const [
                MyToggleOption(key: Key('c0'), value: 'short', label: '全部'),
                MyToggleOption(
                  key: Key('c1'),
                  value: 'long',
                  label: '仅看未读消息',
                ),
                MyToggleOption(key: Key('c2'), value: 'star', label: '星标'),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final r0 = tester.getRect(find.byKey(const Key('c0')));
    final r1 = tester.getRect(find.byKey(const Key('c1')));
    final startThumbW =
        tester.getSize(find.byKey(MySegmentedToggle.thumbKey)).width;

    final gesture = await tester.startGesture(
      r0.center,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    final totalDx = r1.center.dx - r0.center.dx;
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(Offset(totalDx / 8, 0));
      await tester.pump();
    }

    // 拖到长段正上方时，松手前滑块宽度已明显拉宽贴合长段
    final midThumbW =
        tester.getSize(find.byKey(MySegmentedToggle.thumbKey)).width;
    expect(midThumbW, greaterThan(startThumbW + 25));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(choice, 'long');
  });

  testWidgets('拖过中线松手：同步更新零倒车，被外部拒绝时从停点平滑回弹', (tester) async {
    var mode = 'a';
    var allowChange = true;
    late StateSetter setHostState;

    await tester.pumpWidget(
      _wrapToggle(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return MySegmentedToggle<String>(
              value: mode,
              onChanged: (next) {
                if (allowChange) {
                  setHostState(() => mode = next);
                }
              },
              options: const [
                MyToggleOption(key: Key('ta'), value: 'a', label: '手动'),
                MyToggleOption(key: Key('tb'), value: 'b', label: '智能'),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ra = tester.getRect(find.byKey(const Key('ta')));
    final rb = tester.getRect(find.byKey(const Key('tb')));
    final span = rb.center.dx - ra.center.dx;

    // 1. 允许切换：拖到 65% 松手，松手后下一帧只能继续向前，不得倒车回 0%
    final g1 = await tester.startGesture(
      ra.center,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    for (var i = 0; i < 6; i++) {
      await g1.moveBy(Offset(span * 0.65 / 6, 0));
      await tester.pump();
    }
    final releaseX =
        tester.getRect(find.byKey(MySegmentedToggle.thumbKey)).center.dx;
    await g1.up();
    await tester.pump(const Duration(milliseconds: 16));
    final nextFrameX =
        tester.getRect(find.byKey(MySegmentedToggle.thumbKey)).center.dx;
    expect(nextFrameX, greaterThanOrEqualTo(releaseX - 0.5));
    await tester.pumpAndSettle();
    expect(mode, 'b');

    // 2. 外部拒绝切换：从 b 往左拖 65% 松手，应平滑回弹回 b
    allowChange = false;
    final g2 = await tester.startGesture(
      rb.center,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    for (var i = 0; i < 6; i++) {
      await g2.moveBy(Offset(-span * 0.65 / 6, 0));
      await tester.pump();
    }
    await g2.up();
    await tester.pumpAndSettle();
    expect(mode, 'b');
    expect(
      tester.getRect(find.byKey(MySegmentedToggle.thumbKey)).center.dx,
      closeTo(rb.center.dx, 1.0),
    );
  });

  testWidgets(
      '窗口放大 X/Y 轴再缩小后，紧凑模式 MySegmentedToggle 与 MySegmentedControl 滑块 0 错位',
      (tester) async {
    tester.view
      ..physicalSize = const Size(420, 640)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var compactVal = 'all';
    final tabCtrl = MyTabController(length: 3, initialIndex: 0);
    addTearDown(tabCtrl.dispose);
    late StateSetter setHostState;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 640),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  setHostState = setState;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: MySegmentedToggle<String>(
                          equalWidth: false,
                          value: compactVal,
                          onChanged: (next) =>
                              setHostState(() => compactVal = next),
                          options: const [
                            MyToggleOption(
                              key: Key('r-all'),
                              value: 'all',
                              label: '全部',
                            ),
                            MyToggleOption(
                              key: Key('r-unread'),
                              value: 'unread',
                              label: '仅看未读消息',
                            ),
                            MyToggleOption(
                              key: Key('r-star'),
                              value: 'star',
                              label: '星标',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      MySegmentedControl(
                        fit: MyTabBarFit.compact,
                        controller: tabCtrl,
                        tabs: const [
                          MyTab(label: '全部'),
                          MyTab(label: '仅看未读消息'),
                          MyTab(label: '星标'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    void expectAligned(Key segKey, String stage) {
      final segRect = tester.getRect(find.byKey(segKey));
      final thumbRect = tester.getRect(find.byKey(MySegmentedToggle.thumbKey));
      expect(
        thumbRect.left,
        closeTo(segRect.left, 0.8),
        reason: '$stage: 滑块左边界必须紧贴目标段',
      );
      expect(
        thumbRect.right,
        closeTo(segRect.right, 0.8),
        reason: '$stage: 滑块右边界必须紧贴目标段',
      );
      expect(
        thumbRect.width,
        closeTo(segRect.width, 0.8),
        reason: '$stage: 滑块宽度必须与目标段一致',
      );
    }

    // 1. 初始尺寸对齐
    expectAligned(const Key('r-all'), '初始尺寸(420x640)');

    // 2. 同时大幅放大 X 轴与 Y 轴，再切到中间长段「仅看未读消息」
    tester.view.physicalSize = const Size(1280, 1280);
    await tester.pumpAndSettle();
    expectAligned(const Key('r-all'), '放大后未切换(1280x1280)');

    await tester.tap(find.byKey(const Key('r-unread')));
    await tester.pumpAndSettle();
    expectAligned(const Key('r-unread'), '放大后切到长段(1280x1280)');
    tabCtrl.index = 1;
    await tester.pumpAndSettle();

    // 3. 缩回小窗口，再切回首段「全部」：不得残留大窗口时的超宽滑块
    tester.view.physicalSize = const Size(360, 600);
    await tester.pumpAndSettle();
    expectAligned(const Key('r-unread'), '缩小后未切换(360x600)');

    await tester.tap(find.byKey(const Key('r-all')));
    await tester.pumpAndSettle();
    expectAligned(const Key('r-all'), '缩小后切回首段(360x600)');
    tabCtrl.index = 0;
    await tester.pumpAndSettle();
  });
}
