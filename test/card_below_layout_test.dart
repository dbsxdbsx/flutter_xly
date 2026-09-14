import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  testWidgets('MyCard.below 左对齐标题并伸到 trailing 底下', (tester) async {
    tester.view
      ..physicalSize = const Size(700, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(350, 600),
        builder: (_, __) => GetMaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: MyCard(
                leading: const Icon(Icons.language, key: Key('lead')),
                trailing: const Icon(Icons.delete, key: Key('trail')),
                subtitle: const Text('副标题'),
                below: const Text('这是一条足够长的底部告警，应该伸到删除按钮底下'),
                child: const Text('主标题'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final title = tester.getRect(find.text('主标题'));
    final subtitle = tester.getRect(find.text('副标题'));
    final below = tester.getRect(find.text('这是一条足够长的底部告警，应该伸到删除按钮底下'));
    final leading = tester.getRect(find.byKey(const Key('lead')));
    final trailing = tester.getRect(find.byKey(const Key('trail')));

    expect((below.left - title.left).abs(), lessThan(8));
    expect(below.left, greaterThan(leading.right));
    expect(below.right, greaterThan(trailing.left));
    expect(below.top, greaterThan(subtitle.bottom - 2));

    final identityMid = (title.top + subtitle.bottom) / 2;
    expect((trailing.center.dy - identityMid).abs(), lessThan(8));
  });

  testWidgets('无 leading 时 below 与标题同左缘', (tester) async {
    tester.view
      ..physicalSize = const Size(700, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(350, 600),
        builder: (_, __) => GetMaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: MyCard(
                trailing: const Icon(Icons.delete),
                subtitle: const Text('已选择 2 个'),
                below: const Text('部分不可用'),
                child: const Text('github'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final title = tester.getRect(find.text('github'));
    final below = tester.getRect(find.text('部分不可用'));
    final trailing = tester.getRect(find.byIcon(Icons.delete));
    expect((below.left - title.left).abs(), lessThan(8));
    expect(below.right, greaterThan(trailing.left));
  });
}
