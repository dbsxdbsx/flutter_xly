import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:xly/xly.dart';

/// 400×200、60 帧（30 fps，2 秒）。唯一的图层到第 50 帧消失，位置关键帧到第 30 帧。
/// 推出来：定格第 49 帧（49/60），大动作到第 30 帧（0.5）。
const _clipJson = '''
{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":400,"h":200,"nm":"t","ddd":0,"assets":[],
 "layers":[{"ddd":0,"ind":1,"ty":4,"nm":"dot","sr":1,
   "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},
         "p":{"a":1,"k":[{"t":0,"s":[0,100,0]},{"t":30,"s":[400,100,0]}]},
         "a":{"a":0,"k":[0,0,0]},"s":{"a":0,"k":[100,100,100]}},
   "ao":0,"shapes":[],"ip":0,"op":50,"st":0,"bm":0}]}
''';

MySplashClip _clip() => MySplashClip(
      LottieComposition.parseJsonBytes(utf8.encode(_clipJson)),
      timing: MySplashAnimationTiming.fromLottieJson(
        jsonDecode(_clipJson) as Map<String, Object?>,
      ),
    );

MyBootstrapTask _fatal(String label) => MyBootstrapTask.run(
      () async => throw StateError('boom'),
      severity: MyBootstrapSeverity.fatal,
      debugLabel: label,
    );

/// 当前拿着焦点的按钮上的字。
String? _focusedButtonLabel(WidgetTester tester) {
  final focused = find.byWidgetPredicate(
    (widget) => widget is Focus && widget.focusNode?.hasPrimaryFocus == true,
  );
  if (focused.evaluate().isEmpty) return null;
  return tester
      .widget<Text>(find.descendant(of: focused, matching: find.byType(Text)))
      .data;
}

void main() {
  setUp(() {
    MyApp.debugResetSplashGate();
    MySplash.debugFirstFrameShown = () async {};
  });

  tearDown(() {
    MyApp.debugResetSplashGate();
    MySplash.debugFirstFrameShown = null;
    MySplashClip.debugClear();
  });

  MySplashGate attach({
    bool lottie = false,
    Duration bootstrapSlowAfter = Duration.zero,
    List<MyBootstrapTask>? tasks,
  }) {
    final gate = MySplashGate(
      hasOverlay: true,
      hasBrandLottie: lottie,
      hasStaticBrandFace: !lottie,
      minVisible: Duration.zero,
      brandTimeout: Duration.zero,
      bootstrapTimeout: Duration.zero,
      bootstrapSlowAfter: bootstrapSlowAfter,
      tasks: tasks,
    );
    gate.attachToApp();
    return gate;
  }

  Future<void> pumpSplash(WidgetTester tester, MySplash splash) {
    return tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(800, 600),
        builder: (_, __) => MaterialApp(home: splash),
      ),
    );
  }

  testWidgets('预载到的动画按素材比例留位置，大动作做完才放行重活，停到定格帧后淡出揭开', (tester) async {
    MySplashClip.debugSeed('clip.json', _clip());
    final order = <String>[];
    final gate = attach(
      lottie: true,
      tasks: [
        MyBootstrapTask.run(
          () async => order.add('heavy'),
          afterSplashMotion: true,
        ),
      ],
    );

    await pumpSplash(
      tester,
      const MySplash(lottieAssetPath: 'clip.json', appTitle: 'Hi'),
    );
    expect(tester.getSize(find.byKey(MySplash.animationKey)),
        const Size(200, 100));
    expect(find.byType(Lottie), findsOneWidget);

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    // 第一帧只是给动画起表。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(order, isEmpty, reason: '大动作要到 1 秒才做完');

    await tester.pump(const Duration(milliseconds: 200));
    await bootstrap;
    expect(order, ['heavy']);
    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse, reason: '还没停到定格帧');

    await tester.pump(const Duration(milliseconds: 600));
    final lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.controller!.value, closeTo(49 / 60, 1e-9));
    expect(gate.isDismissing, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse, reason: '淡出还没走完');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
  });

  testWidgets('动画被暂停（TickerMode 关掉）时，到「播到定格的时长 + 2 秒」按播完处理', (tester) async {
    MySplashClip.debugSeed('clip.json', _clip());
    final gate = attach(lottie: true);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(800, 600),
        builder: (_, __) => const MaterialApp(
          home: TickerMode(
            enabled: false,
            child: MySplash(lottieAssetPath: 'clip.json'),
          ),
        ),
      ),
    );
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    // 播到定格 2 秒 × 49/60 ≈ 1.633 秒，再加 2 秒。
    await tester.pump(const Duration(milliseconds: 3500));
    expect(gate.isDismissing, isFalse);
    await tester.pump(const Duration(milliseconds: 200));
    expect(gate.isDismissing, isTrue);

    // 淡出也被暂停，走淡出的兜底。
    await tester.pump(const Duration(milliseconds: 1300));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('淡出途中画面被拆掉：离场推到这一帧之后，拆树时不写 Rx', (tester) async {
    final gate = attach();
    final show = true.obs;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(800, 600),
        builder: (_, __) => MaterialApp(
          home: Obx(() {
            // 和 MyApp 的 builder 一样读着 isSplashFinished。
            MyApp.isSplashFinished.value;
            return show.value
                ? const MySplash(appTitle: 'Hi')
                : const SizedBox.shrink();
          }),
        ),
      ),
    );
    await gate.debugOnFirstFrameSubmitted();
    expect(gate.isDismissing, isTrue);

    show.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('素材还没载好时按正方形留位置，给了 lottieHeight 就按它', (tester) async {
    attach(lottie: true);

    await pumpSplash(
      tester,
      const MySplash(lottieAssetPath: 'not-loaded.json', appTitle: 'Hi'),
    );
    expect(tester.getSize(find.byKey(MySplash.animationKey)),
        const Size(200, 200));
    expect(find.byType(Lottie), findsNothing);

    await pumpSplash(
      tester,
      const MySplash(
        lottieAssetPath: 'not-loaded.json',
        appTitle: 'Hi',
        lottieWidth: 160,
        lottieHeight: 90,
      ),
    );
    expect(
        tester.getSize(find.byKey(MySplash.animationKey)), const Size(160, 90));
  });

  testWidgets('标题只排一行，太长时整行缩小，不换行也不溢出', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    attach();
    const title = '一个特别特别长的应用名字，在窄屏上一行放不下';

    await pumpSplash(tester, const MySplash(appTitle: title));

    final text = tester.widget<Text>(find.text(title));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    final fitted = find.ancestor(
      of: find.text(title),
      matching: find.byType(FittedBox),
    );
    expect(tester.getSize(fitted).width, lessThanOrEqualTo(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('失败页：说明、出错详情和两个按钮；重启没成功时提示手动重开', (tester) async {
    var restarts = 0;
    final gate = attach(tasks: [_fatal('load-config')]);

    await pumpSplash(
      tester,
      MySplash(
        appTitle: 'Hi',
        showExitButton: true,
        onRestart: () async {
          restarts++;
          return false;
        },
      ),
    );
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await tester.pump();

    expect(find.text('启动没有完成，请重新启动'), findsOneWidget);
    expect(find.text('load-config：Bad state: boom'), findsOneWidget);
    expect(find.text('重新启动'), findsOneWidget);
    expect(find.text('退出'), findsOneWidget);
    // 遥控一进来就能按确定；按下去之前确认焦点不在「退出」上。
    expect(_focusedButtonLabel(tester), '重新启动');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(restarts, 1);
    expect(find.text('没能自动重启，请手动关掉再打开'), findsOneWidget);
    expect(find.text('重新启动'), findsOneWidget);
  });

  testWidgets('上下键留在失败页里，不漏到下面的首页', (tester) async {
    final gate = attach(tasks: [_fatal('db')]);
    await pumpSplash(
      tester,
      MySplash(
          appTitle: 'Hi', showExitButton: true, onRestart: () async => false),
    );
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await tester.pump();
    expect(_focusedButtonLabel(tester), '重新启动');

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown), isTrue);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp), isTrue);
    expect(_focusedButtonLabel(tester), '重新启动');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_focusedButtonLabel(tester), '退出');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_focusedButtonLabel(tester), '重新启动');
  });

  testWidgets('没传 onRestart 时失败页只有退出，焦点落在退出上', (tester) async {
    final gate = attach(tasks: [_fatal('db')]);
    await pumpSplash(
        tester, const MySplash(appTitle: 'Hi', showExitButton: true));
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await tester.pump();

    expect(find.text('启动没有完成，请退出后重新打开'), findsOneWidget);
    expect(find.text('重新启动'), findsNothing);
    expect(_focusedButtonLabel(tester), '退出');
  });

  testWidgets(
    'iOS 上默认不给退出按钮',
    (tester) async {
      final gate = attach(tasks: [_fatal('db')]);
      await pumpSplash(tester, const MySplash(appTitle: 'Hi'));
      await gate.debugOnFirstFrameSubmitted();
      await tester.pump();

      expect(find.text('启动没有完成，请退出后重新打开'), findsOneWidget);
      expect(find.text('退出'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('启动慢时提示，有 onRestart 时给重启按钮；到终态后提示收起', (tester) async {
    final release = Completer<void>();
    final gate = attach(
      bootstrapSlowAfter: const Duration(milliseconds: 50),
      tasks: [MyBootstrapTask.run(() => release.future)],
    );
    await pumpSplash(
      tester,
      MySplash(appTitle: 'Hi', onRestart: () async => false),
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.text('启动比平时慢，可以再等等，或者重新启动'), findsOneWidget);
    expect(find.text('重新启动'), findsOneWidget);
    expect(find.text('退出'), findsNothing);

    release.complete();
    await bootstrap;
    await tester.pump();
    expect(find.text('重新启动'), findsNothing);
  });

  testWidgets('画面播完后迟迟没揭开时显示「正在启动…」', (tester) async {
    final release = Completer<void>();
    final gate = attach(tasks: [MyBootstrapTask.run(() => release.future)]);
    await pumpSplash(tester, const MySplash(appTitle: 'Hi'));

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.text('正在启动…'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('正在启动…'), findsOneWidget);

    release.complete();
    await bootstrap;
    // 一帧让首页按就绪状态画完，一帧开始淡出，再走完淡出。
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(find.text('正在启动…'), findsOneWidget, reason: '淡出时不换字，免得最后一下闪');
  });

  testWidgets('captionBuilder 拿到当前状态，替换内置提示', (tester) async {
    final gate = attach(tasks: [_fatal('db')]);
    await pumpSplash(
      tester,
      MySplash(
        appTitle: 'Hi',
        captionBuilder: (context, status) => Text(
          '${status.phase.name} ${status.fatalDetail} ${status.canRestart}',
        ),
      ),
    );
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(find.text('fatal db：Bad state: boom false'), findsOneWidget);
    expect(find.text('启动没有完成，请退出后重新打开'), findsNothing);
  });

  testWidgets('brandBuilder 自己上报播完；没上报前不揭开', (tester) async {
    late MySplashHandle handle;
    final gate = attach(lottie: true);
    await pumpSplash(
      tester,
      MySplash(
        brandAnimates: true,
        brandBuilder: (context, splashHandle) {
          handle = splashHandle;
          return const Text('brand');
        },
      ),
    );
    expect(find.text('brand'), findsOneWidget);

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 100));
    expect(MyApp.isSplashFinished.value, isFalse);

    handle.reportPresentationDone();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(MyApp.isSplashFinished.value, isTrue);
  });
}
