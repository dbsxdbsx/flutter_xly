import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/text_editor.dart';
import 'package:xly/xly.dart';

const _designSize = Size(350, 600);
const _testSize = Size(700, 1200);

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('显式图标、按钮与菜单尺寸按逻辑像素直接使用', (tester) async {
    _configureView(tester);
    await _pumpScaled(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MyIcon(icon: Icons.settings, size: 19),
          MyButton(
            text: '按钮',
            onPressed: () {},
            shape: MyButtonShape.cube,
            size: 100,
          ),
          const MyMenuButton(
            icon: Icons.menu,
            iconSize: 17,
            menuItems: [],
          ),
        ],
      ),
    );

    expect(tester.widget<Icon>(find.byIcon(Icons.settings)).size, 19);
    expect(tester.getSize(find.byType(MyButton)), const Size(100, 100));
    expect(tester.widget<Icon>(find.byIcon(Icons.menu)).size, 17);
  });

  testWidgets('MyButton 全屏四等分布局不产生横向溢出', (tester) async {
    tester.view
      ..physicalSize = const Size(1920, 1080)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(900, 700),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                child: Row(
                  children: [
                    for (var index = 0; index < 4; index++) ...[
                      if (index > 0) const SizedBox(width: 25),
                      Expanded(
                        child: MyButton(
                          text: switch (index) {
                            0 => '停靠到左上角',
                            1 => '停靠到右上角',
                            2 => '停靠到左下角',
                            _ => '停靠到右下角',
                          },
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('MyIcon 显式触控区按逻辑像素直接使用', (tester) async {
    _configureView(tester);
    await _pumpScaled(
      tester,
      const MyIcon(
        icon: Icons.settings,
        tapTargetSize: kMinInteractiveDimension,
      ),
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.constraints!.minWidth, kMinInteractiveDimension);
    expect(button.constraints!.minHeight, kMinInteractiveDimension);
  });

  testWidgets('MyMenuDivider 默认值缩放一次且显式值直接使用', (tester) async {
    _configureView(tester);
    final defaultDivider = MyMenuDivider();
    final explicitDivider = MyMenuDivider(
      height: 3,
      margin: const EdgeInsets.fromLTRB(1, 2, 3, 4),
    );
    await _pumpScaled(tester, const SizedBox.shrink());

    expect(defaultDivider.height, 2);
    expect(defaultDivider.margin, const EdgeInsets.symmetric(horizontal: 16));
    expect(explicitDivider.height, 3);
    expect(explicitDivider.margin, const EdgeInsets.fromLTRB(1, 2, 3, 4));
  });

  testWidgets('MyCard 显式 margin、间距与 elevation 不再二次缩放', (tester) async {
    _configureView(tester);
    const margin = EdgeInsets.fromLTRB(7, 8, 9, 10);
    await _pumpScaled(
      tester,
      MyCard(
        margin: margin,
        leadingAndBodySpacing: 11,
        cardElevation: 3,
        child: const Text('card'),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(card.margin, margin);
    expect(card.elevation, 3);
    expect(tile.horizontalTitleGap, 11);
  });

  testWidgets('MyGroupBox 默认值缩放一次且显式值直接使用', (tester) async {
    _configureView(tester);
    await _pumpScaled(
      tester,
      const MyGroupBox(
        title: '默认',
        child: Text('content'),
      ),
    );

    var decoration = _groupBoxDecoration(tester);
    expect(decoration.border!.top.width, 2);
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(
      tester.widgetList<Padding>(
        find.descendant(
          of: find.byType(MyGroupBox),
          matching: find.byType(Padding),
        ),
      ),
      contains(
        isA<Padding>().having(
          (widget) => widget.padding,
          'padding',
          const EdgeInsets.only(top: 20),
        ),
      ),
    );

    await _pumpScaled(
      tester,
      const MyGroupBox(
        title: '显式',
        borderWidth: 1.25,
        borderRadius: 7,
        padding: EdgeInsets.all(9),
        child: Text('content'),
      ),
    );

    decoration = _groupBoxDecoration(tester);
    expect(decoration.border!.top.width, 1.25);
    expect(decoration.borderRadius, BorderRadius.circular(7));
  });

  testWidgets('MyTextEditor 显式字体、圆角与 inset 使用逻辑像素', (tester) async {
    _configureView(tester);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpScaled(
      tester,
      MyTextEditor(
        textController: controller,
        label: '标签',
        hint: '提示',
        textFontSize: 12,
        labelFontSize: 15,
        hintFontSize: 11,
        borderRadius: 7,
        inSetHorizontalPadding: 9,
        inSetVerticalPadding: 10,
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!;
    final border = decoration.enabledBorder! as OutlineInputBorder;
    expect(field.style!.fontSize, 12);
    expect(decoration.labelStyle!.fontSize, 15);
    expect(decoration.hintStyle!.fontSize, 11);
    expect(
        decoration.contentPadding,
        const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 10,
        ));
    expect(border.borderRadius.topLeft.x, 7);
  });

  testWidgets('MyTextEditor 默认尺寸只缩放一次', (tester) async {
    _configureView(tester);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpScaled(
      tester,
      MyTextEditor(
        textController: controller,
        label: '标签',
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    final border = field.decoration!.enabledBorder! as OutlineInputBorder;
    final scaleWidth = _testSize.width / _designSize.width;
    expect(field.style!.fontSize, closeTo(12 * scaleWidth, 0.001));
    expect(border.borderRadius.topLeft.x, closeTo(4 * scaleWidth, 0.001));
  });

  testWidgets('MyTextEditor 其余公开布局参数参与实际渲染', (tester) async {
    _configureView(tester);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpScaled(
      tester,
      MyTextEditor(
        textController: controller,
        label: '标签',
        height: 53,
        borderWidth: 2,
        contentPadding: 6,
        isDense: false,
        textAlignVertical: TextAlignVertical.bottom,
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!;
    final border = decoration.enabledBorder! as OutlineInputBorder;
    expect(tester.getSize(find.byType(TextField)).height, 53);
    expect(field.textAlignVertical, TextAlignVertical.bottom);
    expect(decoration.isDense, isFalse);
    expect(decoration.contentPadding, const EdgeInsets.all(6));
    expect(border.borderSide.width, 2);
  });

  testWidgets('MySpinBox 显式字体与 inset 使用逻辑像素', (tester) async {
    _configureView(tester);
    await _pumpScaled(
      tester,
      MySpinBox(
        label: '间隔',
        initialValue: 1,
        min: 1,
        max: 60,
        onChanged: (_) {},
        centerTextFontSize: 12,
        inSetHorizontalPadding: 9,
        inSetVerticalPadding: 10,
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style!.fontSize, 12);
    expect(
        field.decoration!.contentPadding,
        const EdgeInsets.fromLTRB(
          9,
          10,
          9,
          10,
        ));
  });
}

void _configureView(WidgetTester tester) {
  tester.view
    ..physicalSize = _testSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpScaled(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _designSize,
      builder: (_, __) => GetMaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

BoxDecoration _groupBoxDecoration(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(MyGroupBox),
          matching: find.byType(Container),
        ),
      )
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((decoration) => decoration.border != null);
}
