import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

/// 测试用的异步服务
class AsyncTestService extends GetxService {
  static AsyncTestService get to => Get.find();

  late String configValue;
  final isInitialized = false.obs;

  // 私有构造函数
  AsyncTestService._();

  // 异步工厂方法
  static Future<AsyncTestService> create() async {
    final service = AsyncTestService._();
    // 模拟异步初始化
    await Future.delayed(const Duration(milliseconds: 100));
    service.configValue = 'async-loaded-config';
    service.isInitialized.value = true;
    return service;
  }
}

/// 测试用的同步服务
class SyncTestService extends GetxService {
  static SyncTestService get to => Get.find();

  final String configValue = 'sync-config';
}

void main() {
  group('MyService 异步服务测试', () {
    setUp(() {
      // 清理GetX注册的服务
      Get.reset();
    });

    test('同步服务应该正常注册', () async {
      final service = MyService<SyncTestService>(
        service: () => SyncTestService(),
        permanent: true,
      );

      await service.registerService();

      expect(Get.isRegistered<SyncTestService>(), true);
      expect(SyncTestService.to.configValue, 'sync-config');
    });

    test('异步服务应该正常注册并等待初始化', () async {
      final service = MyService<AsyncTestService>(
        asyncService: () async => await AsyncTestService.create(),
        permanent: true,
      );

      await service.registerService();

      expect(Get.isRegistered<AsyncTestService>(), true);
      expect(AsyncTestService.to.configValue, 'async-loaded-config');
      expect(AsyncTestService.to.isInitialized.value, true);
    });

    test('不能同时提供 service 和 asyncService', () {
      expect(
        () => MyService<SyncTestService>(
          service: () => SyncTestService(),
          asyncService: () async => SyncTestService(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('必须提供 service 或 asyncService 之一', () {
      expect(
        () => MyService<SyncTestService>(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('多个服务并行注册应该正常工作', () async {
      final services = [
        MyService<SyncTestService>(
          service: () => SyncTestService(),
          permanent: true,
        ),
        MyService<AsyncTestService>(
          asyncService: () async => await AsyncTestService.create(),
          permanent: true,
        ),
      ];

      // 并行注册（模拟 MyApp.initialize 中的行为）
      await Future.wait(
        services.map((service) => service.registerService()),
      );

      expect(Get.isRegistered<SyncTestService>(), true);
      expect(Get.isRegistered<AsyncTestService>(), true);
      expect(AsyncTestService.to.isInitialized.value, true);
    });
  });
}
