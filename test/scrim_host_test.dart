import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xly/xly.dart' show MyDialogSheet, MyScrimHost, MyToast;

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(800, 600),
    builder: (_, __) => GetMaterialApp(home: child),
  );
}

/// 遮罩内含无限旋转的进度指示器，不能用 pumpAndSettle（永不静止），
/// 用两帧定长 pump 让 AnimatedSwitcher 的 200ms 过渡走完。
Future<void> _pumpScrimTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('showScrim/hideScrim 在最近宿主上显示与关闭默认卡片', (tester) async {
    await tester.pumpWidget(_wrap(
      const MyScrimHost(child: Scaffold(body: Text('content'))),
    ));

    expect(MyToast.isScrimShowing, isFalse);

    MyToast.showScrim(message: '处理中', detail: '0/3');
    await _pumpScrimTransition(tester);
    expect(find.text('处理中'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(MyToast.isScrimShowing, isTrue);

    MyToast.updateScrim(detail: '2/3');
    await _pumpScrimTransition(tester);
    expect(find.text('2/3'), findsOneWidget);

    MyToast.hideScrim();
    await _pumpScrimTransition(tester);
    expect(find.text('处理中'), findsNothing);
    expect(MyToast.isScrimShowing, isFalse);
  });

  testWidgets('不传 context 时遮罩落在最上层（最后挂载）的宿主内', (tester) async {
    await tester.pumpWidget(_wrap(
      MyScrimHost(
        key: const Key('outer'),
        child: Scaffold(
          body: MyScrimHost(
            key: const Key('inner'),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ));

    MyToast.showScrim(message: 'busy');
    await _pumpScrimTransition(tester);

    // 遮罩文本应位于 inner 宿主子树内
    expect(
      find.ancestor(
        of: find.text('busy'),
        matching: find.byKey(const Key('inner')),
      ),
      findsOneWidget,
    );

    MyToast.hideScrim();
    await _pumpScrimTransition(tester);
  });

  testWidgets('onCancel 显示取消按钮且点击后回调', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(_wrap(
      const MyScrimHost(child: Scaffold(body: SizedBox.expand())),
    ));

    MyToast.showScrim(
      message: '加载中',
      onCancel: () => cancelled = true,
      cancelText: '停止',
    );
    await _pumpScrimTransition(tester);

    await tester.tap(find.text('停止'));
    expect(cancelled, isTrue);

    MyToast.hideScrim();
    await _pumpScrimTransition(tester);
  });

  testWidgets('宿主表面比默认卡片小：卡片自动缩放，不产生像素溢出', (tester) async {
    await tester.pumpWidget(_wrap(
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: MyScrimHost(child: Container(color: Colors.white)),
          ),
        ),
      ),
    ));

    MyToast.showScrim(
      message: '处理中...',
      detail: '2/3',
      onCancel: () {},
    );
    await _pumpScrimTransition(tester);

    // 溢出会以 FlutterError 形式抛出，这里应保持干净
    expect(tester.takeException(), isNull);
    expect(find.text('处理中...'), findsOneWidget);

    MyToast.hideScrim();
    await _pumpScrimTransition(tester);
  });

  testWidgets('MyDialogSheet.showCenter 内置宿主：遮罩位于 Dialog 表面之内且表面启用裁剪',
      (tester) async {
    await tester.pumpWidget(_wrap(const Scaffold(body: SizedBox.expand())));

    MyDialogSheet.showCenter(content: const Text('dialog body'));
    await tester.pumpAndSettle();
    expect(find.text('dialog body'), findsOneWidget);

    // 表面 = 白底 + 遮罩 + 内容合成单层后 saveLayer 一次裁剪，
    // 且 Dialog 自身透明（消除圆角边缘二次抗锯齿混合的细边）
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, Colors.transparent);
    final clip = tester.widget<ClipRRect>(find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(ClipRRect),
    ));
    expect(clip.clipBehavior, Clip.antiAliasWithSaveLayer);

    MyToast.showScrim(message: '智选中');
    await _pumpScrimTransition(tester);

    // 遮罩应挂在 Dialog 内置宿主里，而不是根宿主 / 全屏
    expect(
      find.ancestor(
        of: find.text('智选中'),
        matching: find.byType(Dialog),
      ),
      findsWidgets,
    );

    MyToast.hideScrim();
    await _pumpScrimTransition(tester);
    Get.back();
    await tester.pumpAndSettle();
  });
}
