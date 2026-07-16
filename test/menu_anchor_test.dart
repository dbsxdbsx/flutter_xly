import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  testWidgets('MyMenuStyle 延迟适配窗口并保留稳定的材质参数', (tester) async {
    final style = MyMenuStyle();
    _configureTestView(tester);

    await _pumpApp(tester, const Scaffold());
    expect(style.fontSize, 15);
    expect(style.itemHeight, 48);
    expect(style.surfaceColor, const Color(0xB8F9FAFC));
    expect(style.shadowRatio, 0.3);

    // 仅纵向变高时，菜单行高不应像旧 `.h` 实现一样被拉长。
    tester.view.physicalSize = const Size(500, 1200);
    await tester.pumpAndSettle();
    expect(style.fontSize, 15);
    expect(style.itemHeight, 48);

    tester.view.physicalSize = const Size(1000, 1200);
    await tester.pumpAndSettle();
    expect(style.fontSize, 30);
    expect(style.itemHeight, 96);
    expect(style.blurSigma, 16);
    expect(style.borderRadius, 10);
    expect(style.borderWidth, 1);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(MyMenuStyle.adaptive().itemHeight, 80);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(MyMenuStyle.adaptive().itemHeight, 96);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('根菜单根据最终象限从对应边角展开', (tester) async {
    _configureTestView(tester);
    await _pumpContextMenuTarget(tester);

    Future<void> verify(Offset point, Alignment fixedCorner) async {
      await tester.tapAt(
        point,
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      _expectRevealFrom(tester, fixedCorner);
      MyMenu.closeAll();
      await tester.pump();
    }

    await verify(const Offset(100, 100), Alignment.topLeft);
    await verify(const Offset(400, 100), Alignment.topRight);
    await verify(const Offset(100, 590), Alignment.bottomLeft);
    await verify(const Offset(400, 590), Alignment.bottomRight);
  });

  testWidgets('向右下放置的子菜单从左上角展开', (tester) async {
    _configureTestView(tester);
    await _pumpSubMenuAnchor(
      tester,
      alignment: Alignment.topLeft,
      subItemCount: 2,
    );

    await tester.tap(find.byKey(const Key('sub-menu-anchor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('父菜单项'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));

    expect(find.byType(BackdropFilter), findsNWidgets(2));
    final parentRect = tester.getRect(find.byType(BackdropFilter).first);
    final subMenuRect = tester.getRect(find.byType(BackdropFilter).last);
    expect(subMenuRect.left, closeTo(parentRect.right, 0.01));
    expect(subMenuRect.overlaps(parentRect), isFalse);
    _expectRevealFrom(
      tester,
      Alignment.topLeft,
      backdropFinder: find.byType(BackdropFilter).last,
    );
  });

  testWidgets('向左上放置的子菜单从右下角展开', (tester) async {
    _configureTestView(tester);
    await _pumpSubMenuAnchor(
      tester,
      alignment: Alignment.bottomRight,
      subItemCount: 6,
    );

    await tester.tap(find.byKey(const Key('sub-menu-anchor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('父菜单项'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));

    expect(find.byType(BackdropFilter), findsNWidgets(2));
    final parentRect = tester.getRect(find.byType(BackdropFilter).first);
    final subMenuRect = tester.getRect(find.byType(BackdropFilter).last);
    expect(subMenuRect.right, closeTo(parentRect.left, 0.01));
    expect(subMenuRect.overlaps(parentRect), isFalse);
    _expectRevealFrom(
      tester,
      Alignment.bottomRight,
      backdropFinder: find.byType(BackdropFilter).last,
    );
  });

  testWidgets('右侧锚点按右边缘对齐并使用半透明磨砂表面', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        key: const Key('page'),
        appBar: AppBar(
          actions: [
            MyMenuAnchor(
              menuElements: [
                MyMenuItem(text: '订阅管理', onTap: () {}),
              ],
              builder: (_, showMenu) => IconButton(
                key: const Key('menu-button'),
                icon: const Icon(Icons.menu),
                onPressed: showMenu,
              ),
            ),
          ],
        ),
      ),
    );

    final buttonFinder = find.byKey(const Key('menu-button'));
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('订阅管理'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    final buttonRect = tester.getRect(buttonFinder);
    final menuRect = tester.getRect(find.byType(BackdropFilter));
    expect(menuRect.right, closeTo(buttonRect.right, 0.01));
    expect(menuRect.top, closeTo(buttonRect.bottom + 4, 0.01));

    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter, isA<ImageFilter>());

    final surfaceFinder = find
        .descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        )
        .first;
    final surface = tester.widget<Container>(surfaceFinder);
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xB8F9FAFC));
  });

  testWidgets('底部锚点空间不足时翻转到上方', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomRight,
          child: MyMenuAnchor(
            menuElements: [
              for (var i = 0; i < 4; i++)
                MyMenuItem(text: '菜单项$i', onTap: () {}),
            ],
            builder: (_, showMenu) => GestureDetector(
              key: const Key('bottom-anchor'),
              behavior: HitTestBehavior.opaque,
              onTap: showMenu,
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );

    final anchorFinder = find.byKey(const Key('bottom-anchor'));
    await tester.tap(anchorFinder);
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(anchorFinder);
    final menuRect = tester.getRect(find.byType(BackdropFilter));
    expect(menuRect.right, closeTo(anchorRect.right, 0.01));
    expect(menuRect.bottom, closeTo(anchorRect.top - 4, 0.01));
  });

  testWidgets('禁用菜单项不执行，启用项正常关闭菜单', (tester) async {
    _configureTestView(tester);
    var disabledTapCount = 0;
    var enabledTapCount = 0;

    await _pumpApp(
      tester,
      Scaffold(
        appBar: AppBar(
          actions: [
            MyMenuAnchor(
              menuElements: [
                MyMenuItem(
                  text: '禁用项',
                  enabled: false,
                  onTap: () => disabledTapCount++,
                ),
                MyMenuItem(
                  text: '启用项',
                  onTap: () => enabledTapCount++,
                ),
              ],
              builder: (_, showMenu) => IconButton(
                key: const Key('enabled-menu-button'),
                icon: const Icon(Icons.menu),
                onPressed: showMenu,
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('enabled-menu-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('禁用项'));
    await tester.pump();
    expect(disabledTapCount, 0);
    expect(find.text('启用项'), findsOneWidget);

    await tester.tap(find.text('启用项'));
    await tester.pumpAndSettle();
    expect(enabledTapCount, 1);
    expect(find.text('启用项'), findsNothing);
  });

  testWidgets('正常关闭会清理 LocalHistoryEntry，返回键也能关闭菜单', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        key: const Key('history-page'),
        appBar: AppBar(
          actions: [
            MyMenuAnchor(
              menuElements: [
                MyMenuItem(text: '历史菜单项', onTap: () {}),
              ],
              builder: (_, showMenu) => IconButton(
                key: const Key('history-menu-button'),
                icon: const Icon(Icons.menu),
                onPressed: showMenu,
              ),
            ),
          ],
        ),
      ),
    );

    final route = ModalRoute.of(
      tester.element(find.byKey(const Key('history-page'))),
    )!;
    final buttonFinder = find.byKey(const Key('history-menu-button'));

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(route.willHandlePopInternally, isTrue);

    MyMenu.closeAll();
    await tester.pumpAndSettle();
    expect(route.willHandlePopInternally, isFalse);

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('历史菜单项'), findsNothing);
    expect(route.willHandlePopInternally, isFalse);
  });

  testWidgets('锚定菜单外部右键只关闭，不在鼠标位置重开', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        appBar: AppBar(
          actions: [
            MyMenuAnchor(
              menuElements: [
                MyMenuItem(text: '锚定菜单项', onTap: () {}),
              ],
              builder: (_, showMenu) => IconButton(
                key: const Key('anchored-menu-button'),
                icon: const Icon(Icons.menu),
                onPressed: showMenu,
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('anchored-menu-button')));
    await tester.pumpAndSettle();
    expect(find.text('锚定菜单项'), findsOneWidget);

    await tester.tapAt(
      const Offset(10, 300),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('锚定菜单项'), findsNothing);
  });

  testWidgets('右键菜单仍可在新的鼠标位置重开', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Listener(
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ).showRightMenu(
            context: context,
            menuElements: [
              MyMenuItem(text: '右键菜单项', onTap: _noop),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(
      const Offset(100, 100),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byType(BackdropFilter)), const Offset(100, 100));

    await tester.tapAt(
      const Offset(300, 300),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byType(BackdropFilter)), const Offset(300, 300));
  });

  testWidgets('MyMenuButton 复用锚点入口并支持分隔线', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: MyMenuButton(
            menuItems: [
              MyMenuItem(text: '第一项', onTap: () {}),
              MyMenuDivider(),
              MyMenuItem(text: '第二项', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MyMenuButton));
    await tester.pumpAndSettle();
    expect(find.text('第一项'), findsOneWidget);
    expect(find.text('第二项'), findsOneWidget);
  });

  testWidgets('center 模式菜单从锚点中心象限引出', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MyMenuAnchor(
              anchorOrigin: MyMenuAnchorOrigin.center,
              menuElements: [
                MyMenuItem(text: '象限菜单项', onTap: () {}),
              ],
              builder: (_, showMenu) => GestureDetector(
                key: const Key('center-anchor'),
                behavior: HitTestBehavior.opaque,
                onTap: showMenu,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    final anchorFinder = find.byKey(const Key('center-anchor'));
    await tester.tap(anchorFinder);
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(anchorFinder);
    final menuRect = tester.getRect(find.byType(BackdropFilter));

    // 左上角锚点 → 菜单向右下展开 → 菜单左边 ≈ 锚点中心 x + gap
    expect(menuRect.left, closeTo(anchorRect.center.dx + 4, 1));
    // 菜单顶边 ≈ 锚点中心 y + gap
    expect(menuRect.top, closeTo(anchorRect.center.dy + 4, 1));
  });

  testWidgets('center 模式在右下锚点向左上展开', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MyMenuAnchor(
              anchorOrigin: MyMenuAnchorOrigin.center,
              menuElements: [
                for (var i = 0; i < 4; i++)
                  MyMenuItem(text: '菜单项$i', onTap: () {}),
              ],
              builder: (_, showMenu) => GestureDetector(
                key: const Key('center-br-anchor'),
                behavior: HitTestBehavior.opaque,
                onTap: showMenu,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    final anchorFinder = find.byKey(const Key('center-br-anchor'));
    await tester.tap(anchorFinder);
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(anchorFinder);
    final menuRect = tester.getRect(find.byType(BackdropFilter));

    // 右下角锚点 → 菜单向左上展开 → 菜单右边 ≈ 锚点中心 x - gap
    expect(menuRect.right, closeTo(anchorRect.center.dx - 4, 1));
    // 菜单底边 ≈ 锚点中心 y - gap
    expect(menuRect.bottom, closeTo(anchorRect.center.dy - 4, 1));
  });

  testWidgets('edge 模式仍从锚点边缘弹出', (tester) async {
    _configureTestView(tester);

    await _pumpApp(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MyMenuAnchor(
              anchorOrigin: MyMenuAnchorOrigin.edge,
              menuElements: [
                MyMenuItem(text: '边缘菜单项', onTap: () {}),
              ],
              builder: (_, showMenu) => GestureDetector(
                key: const Key('edge-anchor'),
                behavior: HitTestBehavior.opaque,
                onTap: showMenu,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    final anchorFinder = find.byKey(const Key('edge-anchor'));
    await tester.tap(anchorFinder);
    await tester.pumpAndSettle();

    final anchorRect = tester.getRect(anchorFinder);
    final menuRect = tester.getRect(find.byType(BackdropFilter));

    // edge 模式：菜单左边 ≈ 锚点左边（左半侧 → 左对齐）
    expect(menuRect.left, closeTo(anchorRect.left, 0.01));
    // 菜单顶边 ≈ 锚点底边 + gap
    expect(menuRect.top, closeTo(anchorRect.bottom + 4, 0.01));
  });
}

void _configureTestView(
  WidgetTester tester, {
  Size size = const Size(500, 600),
}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    debugDefaultTargetPlatformOverride = null;
    MyMenu.closeAll();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpApp(WidgetTester tester, Widget home) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(500, 600),
      builder: (_, __) => MaterialApp(home: home),
    ),
  );
}

Future<void> _pumpContextMenuTarget(WidgetTester tester) {
  return _pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Listener(
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ).showRightMenu(
          context: context,
          menuElements: [
            MyMenuItem(text: '方向菜单项', onTap: _noop),
          ],
        ),
      ),
    ),
  );
}

Future<void> _pumpSubMenuAnchor(
  WidgetTester tester, {
  required Alignment alignment,
  required int subItemCount,
}) {
  return _pumpApp(
    tester,
    Scaffold(
      body: Align(
        alignment: alignment,
        child: MyMenuAnchor(
          menuElements: [
            MyMenuItem(
              text: '父菜单项',
              subItems: [
                for (var i = 0; i < subItemCount; i++)
                  MyMenuItem(text: '子菜单项$i', onTap: _noop),
              ],
            ),
          ],
          builder: (_, showMenu) => GestureDetector(
            key: const Key('sub-menu-anchor'),
            behavior: HitTestBehavior.opaque,
            onTap: showMenu,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    ),
  );
}

void _expectRevealFrom(
  WidgetTester tester,
  Alignment fixedCorner, {
  Finder? backdropFinder,
}) {
  final clipFinder = find.byType(ClipRect);
  expect(clipFinder, findsOneWidget);
  final clipWidget = tester.widget<ClipRect>(clipFinder);
  final backdrop = backdropFinder ?? find.byType(BackdropFilter);
  final size = tester.getSize(backdrop);
  final clip = clipWidget.clipper!.getClip(size);

  expect(clip.width, greaterThan(0));
  expect(clip.width, lessThan(size.width));
  expect(clip.height, greaterThan(0));
  expect(clip.height, lessThan(size.height));

  if (fixedCorner.x < 0) {
    expect(clip.left, closeTo(0, 0.01));
  } else {
    expect(clip.right, closeTo(size.width, 0.01));
  }
  if (fixedCorner.y < 0) {
    expect(clip.top, closeTo(0, 0.01));
  } else {
    expect(clip.bottom, closeTo(size.height, 0.01));
  }
}

void _noop() {}
