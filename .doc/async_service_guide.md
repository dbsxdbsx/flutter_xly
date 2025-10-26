# XLY 异步服务完整指南

本文档详细说明 XLY 包中的异步服务（`asyncService`）功能，包括设计理念、使用场景、最佳实践和常见问题。

## 目录

- [快速开始](#快速开始)
- [使用场景对比](#使用场景对比)
- [设计模式说明](#设计模式说明)
- [两种模式详解](#两种模式详解)
- [实际应用案例](#实际应用案例)
- [技术原理](#技术原理)
- [常见问题 FAQ](#常见问题faq)
- [用户反馈](#用户反馈)

## 快速开始

### 同步服务示例

```dart
class CacheService extends GetxService {
  static CacheService get to => Get.find();

  final data = <String, dynamic>{}.obs;

  void set(String key, dynamic value) => data[key] = value;
  dynamic get(String key) => data[key];
}

// 注册
MyService<CacheService>(
  service: () => CacheService(),
  permanent: true,
)
```

### 异步服务示例

```dart
class ChatService extends GetxService {
  static ChatService get to => Get.find();

  late String apiKey;

  ChatService._();

  static Future<ChatService> create() async {
    final service = ChatService._();
    service.apiKey = await service._loadApiKey();
    return service;
  }

  Future<String> _loadApiKey() async {
    await Future.delayed(const Duration(seconds: 1));
    return 'your-api-key';
  }
}

// 注册
MyService<ChatService>(
  asyncService: ChatService.create,
  permanent: true,
)
```

## 使用场景对比

### 何时使用 `service`（同步服务）

✅ **适用场景**：

1. **轻量级服务**：无需异步初始化，可以立即创建

   ```dart
   class CounterService extends GetxService {
     final count = 0.obs;
     void increment() => count++;
   }
   ```

2. **惰性加载**：可以在 `onInit()` 中后台加载数据

   ```dart
   class ConfigService extends GetxService {
     String? _config;

     @override
     void onInit() {
       super.onInit();
       _loadConfig();  // 非阻塞
     }

     Future<void> _loadConfig() async {
       _config = await fetchConfig();
     }
   }
   ```

3. **可空字段**：接受字段为可空类型，每次使用前检查

   ```dart
   class UserService extends GetxService {
     User? currentUser;

     Future<void> ensureLoggedIn() async {
       if (currentUser == null) {
         currentUser = await login();
       }
     }
   }
   ```

### 何时使用 `asyncService`（异步服务）

✅ **适用场景**：

1. **必须预先初始化**：服务在使用前必须完成异步准备

   ```dart
   class DatabaseService extends GetxService {
     late Database db;  // 非空，必须在使用前初始化

     static Future<DatabaseService> create() async {
       final service = DatabaseService._();
       service.db = await openDatabase('app.db');
       return service;
     }
   }
   ```

2. **复杂初始化逻辑**：需要多步异步操作

   ```dart
   class AIService extends GetxService {
     late AiEngine engine;
     late ModelConfig config;

     static Future<AIService> create() async {
       final service = AIService._();
       service.config = await loadModelConfig();
       service.engine = await initializeEngine(service.config);
       await service.engine.warmup();
       return service;
     }
   }
   ```

3. **类型安全优先**：避免空值检查，提升代码质量

   ```dart
   class NetworkService extends GetxService {
     late HttpClient client;  // 直接使用，无需检查 null

     Future<Response> get(String url) async {
       return await client.get(url);  // 安全使用
     }
   }
   ```

## 设计模式说明

### 为什么需要静态工厂方法？

`asyncService` 采用**静态工厂方法模式**，这是适应 GetX 框架设计约束的正确做法。

#### GetX 的设计限制

```dart
// GetX 的 putAsync 实现（简化版）
Future<S> putAsync<S>(Future<S> Function() builder) async {
  final instance = await builder();  // ✅ 等待实例创建
  _register(instance);
  instance.onInit();  // ❌ 不等待 onInit() 完成
  return instance;
}
```

**核心问题**：`Get.putAsync` 只保证工厂函数返回实例，**不会等待** `onInit()` 完成。

#### 两种应对策略

**策略 1：接受限制，使用可空类型**（同步服务）

```dart
class Service extends GetxService {
  String? _data;  // 可空

  @override
  void onInit() {
    super.onInit();
    _loadData();  // 非阻塞调用
  }

  Future<void> _loadData() async {
    _data = await fetch();
  }

  // 每次使用都要检查
  Future<String> getData() async {
    while (_data == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    return _data!;
  }
}
```

**策略 2：绕过限制，使用静态工厂**（异步服务）

```dart
class Service extends GetxService {
  late String _data;  // 非空

  Service._();  // 私有构造

  // 在返回实例前完成异步初始化
  static Future<Service> create() async {
    final service = Service._();
    service._data = await fetch();
    return service;  // 返回时已完全可用
  }

  // 直接使用，无需检查
  String getData() => _data;
}
```

### 为什么这不是 Workaround？

1. **框架设计决策**

   - GetX 有意设计 `putAsync` 不等待 `onInit()`
   - 目的是保持启动性能，避免阻塞主线程
   - 这是框架级别的权衡，不是缺陷

2. **成熟的设计模式**

   - 静态工厂方法是 GoF 23 种设计模式之一
   - 广泛用于需要复杂初始化的对象创建
   - Dart SDK 自身也大量使用（如 `Future.value()`, `Stream.fromIterable()`）

3. **类型安全优势**

   - 允许使用 `late` 而非可空类型（`?`）
   - 减少运行时空值检查
   - 编译时保证字段已初始化

4. **语义清晰**
   - 明确区分"可以惰性加载"和"必须预先初始化"
   - 代码意图一目了然
   - 降低维护成本

## 两种模式详解

### 模式 1：惰性初始化（适用于同步服务）

**特征**：

- 字段可空（`?`）
- `onInit()` 中非阻塞加载
- 每次使用前检查初始化状态

**完整示例**：

```dart
class UserPreferenceService extends GetxService {
  static UserPreferenceService get to => Get.find();

  Map<String, dynamic>? _preferences;  // 可空
  bool _isLoading = false;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();  // 非阻塞
  }

  Future<void> _loadPreferences() async {
    _isLoading = true;
    await Future.delayed(Duration(seconds: 1));
    _preferences = {'theme': 'dark', 'language': 'zh'};
    _isLoading = false;
  }

  // 每次使用都要检查
  Future<String> getTheme() async {
    while (_preferences == null && _isLoading) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    return _preferences?['theme'] ?? 'light';
  }

  void setTheme(String theme) {
    _preferences ??= {};
    _preferences!['theme'] = theme;
  }
}

// 注册
MyService<UserPreferenceService>(
  service: () => UserPreferenceService(),
  permanent: true,
)
```

**优点**：

- ✅ 不阻塞应用启动
- ✅ 符合 GetX 哲学

**缺点**：

- ❌ 每个方法都需要检查初始化状态
- ❌ 代码冗余，容易出错
- ❌ 运行时空值检查

### 模式 2：预先初始化（适用于异步服务）

**特征**：

- 字段非空（`late`）
- 静态工厂方法完成初始化
- 返回时已完全可用

**完整示例**：

```dart
class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find();

  late Database db;  // 非空
  late Box settingsBox;

  // 私有构造函数
  DatabaseService._();

  // 静态工厂方法
  static Future<DatabaseService> create() async {
    final service = DatabaseService._();

    // 步骤 1: 打开数据库
    service.db = await openDatabase('app.db', version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT,
            email TEXT
          )
        ''');
      },
    );

    // 步骤 2: 初始化 Hive box
    service.settingsBox = await Hive.openBox('settings');

    // 步骤 3: 预加载关键数据
    await service._preloadData();

    return service;  // 返回时已完全可用
  }

  Future<void> _preloadData() async {
    final count = await db.rawQuery('SELECT COUNT(*) FROM users');
    debugPrint('数据库中有 $count 个用户');
  }

  // 所有方法可以直接使用，无需检查
  Future<List<User>> getUsers() async {
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> addUser(User user) async {
    await db.insert('users', user.toMap());
  }

  String getSetting(String key, String defaultValue) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }
}

// 注册
MyService<DatabaseService>(
  asyncService: DatabaseService.create,
  permanent: true,
)
```

**优点**：

- ✅ 类型安全，无需空值检查
- ✅ 代码简洁，可读性高
- ✅ 确保服务完全可用

**缺点**：

- ❌ 可能增加应用启动时间（但 XLY 会并行注册所有异步服务）

## 实际应用案例

### 案例 1：AI 聊天服务

```dart
class ChatService extends GetxService {
  static ChatService get to => Get.find();

  late AiEngine engine;
  late String apiKey;
  late ChatHistory history;

  ChatService._();

  static Future<ChatService> create() async {
    final service = ChatService._();

    // 从安全存储加载 API Key
    service.apiKey = await SecureStorage.read('openai_api_key') ?? '';

    // 初始化 AI 引擎
    service.engine = AiEngine(apiKey: service.apiKey);
    await service.engine.initialize();

    // 加载历史记录
    service.history = await ChatHistory.load();

    // 预热模型
    await service.engine.warmup();

    debugPrint('ChatService 初始化完成');
    return service;
  }

  Future<String> sendMessage(String message) async {
    final response = await engine.chat(message);
    await history.add(message, response);
    return response;
  }

  Future<bool> checkReadiness() async {
    return await engine.checkReadiness();
  }
}
```

### 案例 2：本地数据库服务

```dart
class LocalStorageService extends GetxService {
  static LocalStorageService get to => Get.find();

  late Database sqliteDb;
  late Box hiveBox;
  late SharedPreferences prefs;

  LocalStorageService._();

  static Future<LocalStorageService> create() async {
    final service = LocalStorageService._();

    // 并行初始化多个存储
    await Future.wait([
      _initSqlite(service),
      _initHive(service),
      _initSharedPreferences(service),
    ]);

    return service;
  }

  static Future<void> _initSqlite(LocalStorageService service) async {
    service.sqliteDb = await openDatabase(
      'app.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE cache (key TEXT PRIMARY KEY, value TEXT)');
      },
    );
  }

  static Future<void> _initHive(LocalStorageService service) async {
    await Hive.initFlutter();
    service.hiveBox = await Hive.openBox('settings');
  }

  static Future<void> _initSharedPreferences(LocalStorageService service) async {
    service.prefs = await SharedPreferences.getInstance();
  }

  // 所有方法直接使用已初始化的存储
  Future<void> cacheData(String key, String value) async {
    await sqliteDb.insert('cache', {'key': key, 'value': value});
  }

  T getSetting<T>(String key, T defaultValue) {
    return hiveBox.get(key, defaultValue: defaultValue);
  }

  bool getPreference(String key, bool defaultValue) {
    return prefs.getBool(key) ?? defaultValue;
  }
}
```

### 案例 3：网络配置服务

```dart
class NetworkConfigService extends GetxService {
  static NetworkConfigService get to => Get.find();

  late Dio dio;
  late String baseUrl;
  late Map<String, String> defaultHeaders;

  NetworkConfigService._();

  static Future<NetworkConfigService> create() async {
    final service = NetworkConfigService._();

    // 从远程加载配置
    final config = await _fetchRemoteConfig();
    service.baseUrl = config['baseUrl'];
    service.defaultHeaders = Map<String, String>.from(config['headers']);

    // 配置 Dio
    service.dio = Dio(BaseOptions(
      baseUrl: service.baseUrl,
      headers: service.defaultHeaders,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));

    // 添加拦截器
    service.dio.interceptors.add(LogInterceptor());
    service.dio.interceptors.add(AuthInterceptor());

    return service;
  }

  static Future<Map<String, dynamic>> _fetchRemoteConfig() async {
    // 从配置服务器加载
    final response = await http.get(Uri.parse('https://config.example.com/app'));
    return jsonDecode(response.body);
  }

  Future<Response> get(String path) async {
    return await dio.get(path);
  }

  Future<Response> post(String path, dynamic data) async {
    return await dio.post(path, data: data);
  }
}
```

## 技术原理

### XLY 如何处理异步服务

```dart
// lib/src/app.dart（简化版）
class _ServiceRegistration {
  static Future<void> registerServices(List<MyService> services) async {
    // 分离同步和异步服务
    final syncServices = services.where((s) => s.service != null).toList();
    final asyncServices = services.where((s) => s.asyncService != null).toList();

    // 1. 先注册同步服务
    for (final service in syncServices) {
      Get.put(service.service!(), permanent: service.permanent ?? false);
    }

    // 2. 并行注册异步服务（性能优化）
    await Future.wait(
      asyncServices.map((service) async {
        try {
          final instance = await service.asyncService!();
          Get.put(instance,
            permanent: service.permanent ?? false,
            tag: service.tag,
          );
        } catch (e) {
          debugPrint('异步服务注册失败: $e');
        }
      }),
    );
  }
}
```

**关键特性**：

1. **并行注册**：所有异步服务同时初始化，最大化性能
2. **错误隔离**：单个服务失败不影响其他服务
3. **顺序保证**：同步服务先于异步服务注册

### 性能对比

假设有 3 个异步服务，每个初始化需要 1 秒：

**串行注册**（如果不并行）：

```
Service A: [████████████] 1s
Service B:              [████████████] 1s
Service C:                           [████████████] 1s
总耗时: 3s
```

**并行注册**（XLY 实现）：

```
Service A: [████████████] 1s
Service B: [████████████] 1s
Service C: [████████████] 1s
总耗时: 1s
```

## 常见问题 FAQ

### Q1: 可以在 `onInit()` 中完成异步初始化吗？

**A**: 技术上可以，但不推荐用于必须预先初始化的服务。

```dart
// ❌ 不推荐：字段必须可空
class Service extends GetxService {
  Database? db;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    db = await openDatabase('app.db');
  }

  // 每次都要检查
  Future<void> query() async {
    if (db == null) {
      await _init();
    }
    await db!.query('users');
  }
}

// ✅ 推荐：字段非空，直接使用
class Service extends GetxService {
  late Database db;

  Service._();

  static Future<Service> create() async {
    final service = Service._();
    service.db = await openDatabase('app.db');
    return service;
  }

  Future<void> query() async {
    await db.query('users');  // 直接使用
  }
}
```

### Q2: 异步服务会阻塞应用启动吗？

**A**: 会有轻微延迟，但 XLY 采用并行注册优化性能。

```dart
// 所有异步服务并行初始化
await MyApp.initialize(
  services: [
    MyService<DatabaseService>(asyncService: DatabaseService.create),  // 1s
    MyService<NetworkService>(asyncService: NetworkService.create),    // 1s
    MyService<CacheService>(asyncService: CacheService.create),        // 1s
  ],
);
// 总耗时: ~1s（而非 3s）
```

**优化建议**：

1. 只对必需服务使用 `asyncService`
2. 轻量级服务使用 `service` + 惰性加载
3. 考虑在 splash 页面展示加载进度

### Q3: 如果异步服务初始化失败怎么办？

**A**: XLY 会捕获异常并打印错误，应用继续运行。

```dart
// 建议：在服务内部处理初始化失败
class DatabaseService extends GetxService {
  Database? db;  // 允许为空
  String? error;

  static Future<DatabaseService> create() async {
    final service = DatabaseService._();
    try {
      service.db = await openDatabase('app.db');
    } catch (e) {
      service.error = e.toString();
      debugPrint('数据库初始化失败: $e');
    }
    return service;
  }

  Future<List<User>> getUsers() async {
    if (db == null) {
      throw StateError('数据库未初始化: $error');
    }
    return await db!.query('users');
  }
}
```

### Q4: 可以混用 `service` 和 `asyncService` 吗？

**A**: 完全可以，这是推荐的做法。

```dart
await MyApp.initialize(
  services: [
    // 轻量级服务 - 同步
    MyService<ThemeService>(
      service: () => ThemeService(),
      permanent: true,
    ),

    // 需要预先初始化 - 异步
    MyService<DatabaseService>(
      asyncService: DatabaseService.create,
      permanent: true,
    ),

    // 可以惰性加载 - 同步
    MyService<CacheService>(
      service: () => CacheService(),
      fenix: true,
    ),

    // 复杂初始化 - 异步
    MyService<AIService>(
      asyncService: AIService.create,
      permanent: true,
    ),
  ],
);
```

### Q5: 静态工厂方法必须叫 `create` 吗？

**A**: 不必须，但推荐使用统一命名。

```dart
// ✅ 推荐：统一使用 create
static Future<Service> create() async { ... }

// ✅ 也可以：更具体的命名
static Future<Service> initialize() async { ... }
static Future<Service> build() async { ... }

// 注册时使用方法引用
MyService<Service>(asyncService: Service.create)
MyService<Service>(asyncService: Service.initialize)
```

### Q6: 可以在静态工厂方法中访问其他服务吗？

**A**: 可以，但要注意依赖顺序。

```dart
class ChatService extends GetxService {
  late AiEngine engine;

  static Future<ChatService> create() async {
    final service = ChatService._();

    // ✅ 访问已注册的服务
    final database = Get.find<DatabaseService>();
    final apiKey = await database.getSetting('api_key');

    service.engine = AiEngine(apiKey: apiKey);
    return service;
  }
}

// 注册时注意顺序
services: [
  MyService<DatabaseService>(asyncService: DatabaseService.create),  // 先注册
  MyService<ChatService>(asyncService: ChatService.create),          // 后注册（依赖 Database）
]
```

## 用户反馈

以下是来自真实用户的反馈，验证了 `asyncService` 设计的合理性：

---

**用户问题**：

> 在使用 `MyService<ChatService>(service: () => ChatService())` 时遇到问题。ChatService 需要在 `onInit()` 中异步初始化 `AiEngine`，但因为 `onInit()` 是非阻塞的，导致服务的其他方法在 `AiEngine` 初始化完成前就被调用，抛出 late initialization error。
>
> 临时解决方案是使用静态工厂方法 `asyncService: ChatService.create`。但这是否是 workaround？xly 包是否可以进一步改进？

**技术分析**（用户提供）：

### GetX 的设计限制

**根本原因**：

- `Get.putAsync` 只等待**工厂函数返回实例**
- **不会等待** `onInit()` 完成
- `onInit()` 是非阻塞的生命周期回调

这是 GetX 框架的设计决策，不是 xly 包的问题。

### 两种设计模式对比

**模式 1：惰性初始化（GetX 推荐）**

```dart
class ChatService extends GetxService {
  AiEngine? _engine;  // 可空，延迟初始化

  @override
  void onInit() {
    _initializeEngine();  // 非阻塞
  }

  Future<void> checkReadiness() async {
    await _ensureInitialized();  // 每次使用前检查
    return _engine!.checkReadiness();
  }
}
```

- ✅ 符合 GetX 哲学
- ❌ 需要在每个方法中检查初始化状态

**模式 2：预先初始化（我们的方案）**

```dart
class ChatService extends GetxService {
  late AiEngine _engine;  // 非空，预先初始化

  static Future<ChatService> create() async {
    final service = ChatService._();
    await service._initializeEngine();
    return service;
  }
}

// 使用
MyService<ChatService>(asyncService: ChatService.create)
```

- ✅ 更直观，实例始终可用
- ✅ 无需在每个方法中检查
- ⚠️ 需要静态工厂方法

### 是否可以改进？

**xly 0.27 已经做得很好了**。进一步改进的障碍：

1. GetX **没有公开 API** 来等待 `onInit()` 完成
2. 改变这个需要修改 GetX 核心，而非 xly 包

### 给包作者的建议

**在文档中说明两种模式的适用场景**：

- 如果服务可以惰性初始化 → 使用 `service: () => Service()`
- 如果服务必须预先初始化 → 使用 `asyncService: Service.create`

**结论**：

当前方案（`asyncService: ChatService.create`）是**合理且推荐的**，这不是 workaround，而是在 GetX 框架约束下的**正确设计模式**。这种需求在实际项目中很常见（如需要等待数据库、网络配置等异步操作完成）。

---

**XLY 包作者回应**：

感谢详细的反馈！您的分析非常准确。`asyncService` 确实是为了解决"必须预先初始化"的场景而设计的。它不是 workaround，而是基于以下考虑的正确设计：

1. **尊重 GetX 设计哲学**：不强行修改框架行为
2. **提供清晰的选择**：让开发者根据实际需求选择合适的模式
3. **保证类型安全**：支持 `late` 字段，减少空值检查
4. **优化性能**：并行注册所有异步服务

我们会在文档中详细说明这两种模式的适用场景和最佳实践。

## 总结

### 快速决策表

| 需求                       | 使用方案       | 字段类型 | 检查初始化 |
| -------------------------- | -------------- | -------- | ---------- |
| 轻量级服务，无异步初始化   | `service`      | 非空     | 不需要     |
| 可以后台加载，接受可空字段 | `service`      | 可空     | 需要       |
| 必须预先初始化，字段非空   | `asyncService` | 非空     | 不需要     |
| 复杂多步异步初始化         | `asyncService` | 非空     | 不需要     |
| 依赖其他异步服务           | `asyncService` | 非空     | 不需要     |

### 最佳实践建议

1. **优先使用 `service`**：除非确实需要预先初始化
2. **明确服务依赖**：在注册时注意依赖顺序
3. **处理初始化失败**：在服务内部捕获异常
4. **监控启动性能**：避免过多异步服务阻塞启动
5. **文档化决策**：在代码注释中说明为什么选择某种模式

### 相关资源

- [XLY 主文档](../README.md)
- [GetX 官方文档](https://github.com/jonataslaw/getx)
- [Dart 设计模式](https://refactoring.guru/design-patterns/factory-method)
