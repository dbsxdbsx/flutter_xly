import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xly/xly.dart' show MyDialogSheet, MyModalAttentionEffect;

/// 带内部状态的计数器：用于验证抖动动画不会导致对话框子树重建
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('count: $count'),
    );
  }
}

Widget _app({required VoidCallback onPressed}) {
  return ScreenUtilInit(
    designSize: const Size(800, 600),
    builder: (_, __) => GetMaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(onPressed: onPressed, child: const Text('打开')),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('模态对话框点击遮罩不关闭且播放抖动动画', (tester) async {
    await tester.pumpWidget(_app(onPressed: () {
      MyDialogSheet.showCenter(
        title: '订阅管理',
        content: const Text('内容'),
        onConfirm: Get.back,
        barrierDismissible: false,
      );
    }));

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('订阅管理'), findsOneWidget);

    final restingTopLeft = tester.getTopLeft(find.text('订阅管理'));

    // 点击左上角遮罩区域（对话框之外）
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    // 动画中段应产生水平位移
    await tester.pump(const Duration(milliseconds: 100));
    final midTopLeft = tester.getTopLeft(find.text('订阅管理'));
    expect(find.text('订阅管理'), findsOneWidget);
    expect(midTopLeft.dx, isNot(moreOrLessEquals(restingTopLeft.dx)));
    expect(midTopLeft.dy, moreOrLessEquals(restingTopLeft.dy));

    // 动画结束后回到原位，对话框仍然存在
    await tester.pumpAndSettle();
    final settledTopLeft = tester.getTopLeft(find.text('订阅管理'));
    expect(settledTopLeft.dx, moreOrLessEquals(restingTopLeft.dx));
    expect(find.text('订阅管理'), findsOneWidget);

    // 显式点「确定」才能关闭
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('订阅管理'), findsNothing);
  });

  testWidgets('抖动动画不重建对话框子树（内部 State 保留）', (tester) async {
    await tester.pumpWidget(_app(onPressed: () {
      MyDialogSheet.showCenter(
        title: '状态保持',
        content: const _Counter(),
        onConfirm: Get.back,
        barrierDismissible: false,
      );
    }));

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    // 先把内部状态改掉
    await tester.tap(find.text('count: 0'));
    await tester.pump();
    expect(find.text('count: 1'), findsOneWidget);

    // 点遮罩触发抖动：动画中段与结束后状态都必须保留
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('count: 1'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('count: 1'), findsOneWidget);
  });

  testWidgets('barrierAttentionEffect.none 时点击遮罩静默无效', (tester) async {
    await tester.pumpWidget(_app(onPressed: () {
      MyDialogSheet.showCenter(
        title: '静默模态',
        content: const Text('内容'),
        onConfirm: Get.back,
        barrierDismissible: false,
        barrierAttentionEffect: MyModalAttentionEffect.none,
      );
    }));

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    final restingTopLeft = tester.getTopLeft(find.text('静默模态'));

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midTopLeft = tester.getTopLeft(find.text('静默模态'));
    expect(find.text('静默模态'), findsOneWidget);
    expect(midTopLeft, restingTopLeft);
    await tester.pumpAndSettle();
  });

  testWidgets('非模态（barrierDismissible: true）点击遮罩直接关闭', (tester) async {
    await tester.pumpWidget(_app(onPressed: () {
      MyDialogSheet.showCenter(
        title: '普通对话框',
        content: const Text('内容'),
        onConfirm: Get.back,
      );
    }));

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('普通对话框'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('普通对话框'), findsNothing);
  });
}
