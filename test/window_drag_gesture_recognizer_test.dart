import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/app.dart';

/// 锁住「整窗拖拽不得被点击手抖触发」。
void main() {
  late int starts;

  Widget host() {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        MyWindowDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<MyWindowDragGestureRecognizer>(
          MyWindowDragGestureRecognizer.new,
          (instance) => instance.onStart = (_) => starts++,
        ),
      },
      child: const SizedBox.expand(),
    );
  }

  setUp(() => starts = 0);

  Future<void> dragBy(
    WidgetTester tester,
    double dx, {
    PointerDeviceKind kind = PointerDeviceKind.mouse,
    int steps = 8,
  }) async {
    final gesture = await tester.startGesture(
      const Offset(100, 100),
      kind: kind,
    );
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(dx / steps, 0));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('鼠标位移 5px（点击手抖量级）不算拖拽', (tester) async {
    await tester.pumpWidget(host());

    await dragBy(tester, 5);

    expect(starts, 0);
  });

  testWidgets('鼠标位移超过阈值才算拖拽', (tester) async {
    await tester.pumpWidget(host());

    await dragBy(tester, kMyWindowDragSlop + 8);

    expect(starts, 1);
  });

  testWidgets('触屏仍用 Flutter 默认阈值，不受抬高影响', (tester) async {
    await tester.pumpWidget(host());

    await dragBy(tester, 14, kind: PointerDeviceKind.touch);

    expect(starts, 0);
  });
}
