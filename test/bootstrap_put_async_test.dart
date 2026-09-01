import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

class _AsyncProbeService extends GetxService {
  static _AsyncProbeService get to => Get.find();

  var inited = false;

  Future<_AsyncProbeService> init() async {
    inited = true;
    return this;
  }
}

void main() {
  setUp(() {
    Get.reset();
    MyApp.debugResetSplashGate();
  });
  tearDown(() {
    Get.reset();
    MyApp.debugResetSplashGate();
  });

  test('裸 Get.putAsync 收进 Future<void> 会登记成 void', () async {
    Future<void> run() => Get.putAsync(() => _AsyncProbeService().init());
    await run();

    expect(Get.isRegistered<_AsyncProbeService>(), isFalse);
    expect(Get.isRegistered<void>(), isTrue);
  });

  test('MyBootstrapTask.run 按闭包返回类型登记', () async {
    final task = MyBootstrapTask.run(
      () => Get.putAsync(() => _AsyncProbeService().init()),
    );
    await task.execute();

    expect(Get.isRegistered<_AsyncProbeService>(), isTrue);
    expect(Get.isRegistered<void>(), isFalse);
    expect(_AsyncProbeService.to.inited, isTrue);
  });

  test('MyBootstrapTask.putAsync 按真实类型登记', () async {
    final task = MyBootstrapTask.putAsync<_AsyncProbeService>(
      () => _AsyncProbeService().init(),
    );
    await task.execute();

    expect(Get.isRegistered<_AsyncProbeService>(), isTrue);
    expect(Get.isRegistered<void>(), isFalse);
    expect(_AsyncProbeService.to.inited, isTrue);
  });

  test('MyService.asyncService 仍然按 T 登记', () async {
    final service = MyService<_AsyncProbeService>(
      asyncService: () => _AsyncProbeService().init(),
      permanent: true,
    );
    await service.registerService();

    expect(Get.isRegistered<_AsyncProbeService>(), isTrue);
    expect(_AsyncProbeService.to.inited, isTrue);
  });

  test('预先收成 void 的闭包交给 run 会抛契约错误并清掉 void', () async {
    Future<void> dirty() => Get.putAsync(() => _AsyncProbeService().init());
    final task = MyBootstrapTask.run(dirty);

    await expectLater(task.execute(), throwsA(isA<MyBootstrapContractError>()));
    expect(Get.isRegistered<void>(), isFalse);
    expect(Get.isRegistered<_AsyncProbeService>(), isFalse);
  });

  test('async 块里 await putAsync 仍按真实类型登记', () async {
    final task = MyBootstrapTask.run(() async {
      await Get.putAsync(() => _AsyncProbeService().init());
    });
    await task.execute();

    expect(Get.isRegistered<_AsyncProbeService>(), isTrue);
    expect(Get.isRegistered<void>(), isFalse);
  });

  test('run 里带 tag 的 putAsync 按真实类型登记', () async {
    final task = MyBootstrapTask.run(
      () => Get.putAsync(() => _AsyncProbeService().init(), tag: 'probe'),
    );
    await task.execute();

    expect(Get.isRegistered<_AsyncProbeService>(tag: 'probe'), isTrue);
    expect(Get.isRegistered<void>(), isFalse);
  });

  test('显式 putAsync<void> 后即使再抛错也清掉 void', () async {
    final task = MyBootstrapTask.run(() async {
      await Get.putAsync<void>(() => _AsyncProbeService().init());
      throw StateError('later');
    });

    await expectLater(
      task.execute(),
      throwsA(
        isA<MyBootstrapContractError>().having(
          (e) => e.cause,
          'cause',
          isA<StateError>(),
        ),
      ),
    );
    expect(Get.isRegistered<void>(), isFalse);
  });

  test('预先收成 dynamic 的闭包交给 run 会抛契约错误', () async {
    Future<dynamic> dirty() => Get.putAsync(() => _AsyncProbeService().init());
    final task = MyBootstrapTask.run(dirty);

    await expectLater(task.execute(), throwsA(isA<MyBootstrapContractError>()));
    expect(Get.isRegistered<dynamic>(), isFalse);
    expect(Get.isRegistered<_AsyncProbeService>(), isFalse);
  });

  testWidgets('契约错误在 degraded 任务上也让门闩 fatal', (tester) async {
    Future<void> dirty() => Get.putAsync(() => _AsyncProbeService().init());
    final gate = MySplashGate(
      hasOverlay: true,
      hasBrandLottie: false,
      hasStaticBrandFace: true,
      minVisible: Duration.zero,
      brandTimeout: Duration.zero,
      bootstrapTimeout: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          dirty,
          severity: MyBootstrapSeverity.degraded,
        ),
      ],
    );
    gate.attachToApp();

    final ready = expectLater(MyApp.bootstrapReady, throwsA(isA<StateError>()));
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await ready;

    expect(MyApp.splashPhase.value, MySplashPhase.fatal);
    expect(MyApp.isSplashFinished.value, isFalse);
    expect(Get.isRegistered<void>(), isFalse);
  });
}
