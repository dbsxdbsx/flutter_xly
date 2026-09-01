import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  setUp(MyApp.debugResetSplashGate);
  tearDown(MyApp.debugResetSplashGate);

  MySplashGate attachGate({
    bool overlay = true,
    bool lottie = false,
    bool staticBrand = true,
    Duration minVisible = Duration.zero,
    Duration brandTimeout = Duration.zero,
    List<MyBootstrapTask>? tasks,
  }) {
    final gate = MySplashGate(
      hasOverlay: overlay,
      hasBrandLottie: lottie,
      hasStaticBrandFace: staticBrand,
      minVisible: minVisible,
      brandTimeout: brandTimeout,
      bootstrapTimeout: Duration.zero,
      tasks: tasks,
    );
    gate.attachToApp();
    return gate;
  }

  testWidgets('无叠层时 attach 即视为揭开，bootstrap 仍会跑', (tester) async {
    var ran = false;
    final gate = attachGate(
      overlay: false,
      lottie: false,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async {
          ran = true;
        }),
      ],
    );

    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isFalse);

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(ran, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
    await MyApp.bootstrapReady;
  });

  testWidgets('有 Lottie 时 bootstrap 先结束也不揭开', (tester) async {
    final gate = attachGate(lottie: true, staticBrand: false);

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse);

    MyApp.reportBrandAnimationDone();
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
  });

  testWidgets('动画先结束时等 bootstrap', (tester) async {
    final started = Completer<void>();
    final release = Completer<void>();
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async {
          started.complete();
          await release.future;
        }),
      ],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await started.future;
    MyApp.reportBrandAnimationDone();
    expect(MyApp.isSplashFinished.value, isFalse);

    release.complete();
    await bootstrap;
    await tester.pump();

    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('静态品牌脸未到 minVisible 不揭开', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: const Duration(milliseconds: 40),
    );

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isFalse);

    await tester.pump(const Duration(milliseconds: 50));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('brandTimeout 视为动画结束', (tester) async {
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      brandTimeout: const Duration(milliseconds: 20),
    );

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isFalse);

    await tester.pump(const Duration(milliseconds: 30));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('fatal 任务不揭开且 bootstrapReady 失败', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('boom'),
          severity: MyBootstrapSeverity.fatal,
          debugLabel: 'fatal-task',
        ),
      ],
    );

    final ready = expectLater(MyApp.bootstrapReady, throwsA(isA<StateError>()));
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await ready;

    expect(MyApp.splashPhase.value, MySplashPhase.fatal);
    expect(MyApp.isSplashFinished.value, isFalse);
    expect(MyApp.isBootstrapReady.value, isFalse);
  });

  testWidgets('degraded 失败仍揭开', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('soft'),
          severity: MyBootstrapSeverity.degraded,
        ),
      ],
    );

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(MyApp.splashPhase.value, MySplashPhase.finished);
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
    await MyApp.bootstrapReady;
  });

  testWidgets('optional 失败仍是 ready', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('skip'),
          severity: MyBootstrapSeverity.optional,
        ),
      ],
    );

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
  });

  testWidgets('无 Lottie 的叠层会立刻上报动画结束', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(800, 600),
        builder: (_, __) => const MaterialApp(
          home: MySplash(appTitle: 'Hi'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(MySplash.overlayKey), findsOneWidget);

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isFalse);
    await tester.pump(const Duration(milliseconds: 30));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('二次 attach 会重置上一次已揭开的状态', (tester) async {
    final first =
        attachGate(lottie: false, staticBrand: true, minVisible: Duration.zero);
    await first.debugOnFirstFrameSubmitted();
    await tester.pump();
    expect(MyApp.isSplashFinished.value, isTrue);

    final second = attachGate(lottie: true, staticBrand: false);
    expect(MyApp.isSplashFinished.value, isFalse);
    expect(MyApp.splashPhase.value, MySplashPhase.running);
    expect(second.isFinished, isFalse);
  });
}
