# 贡献者指南：日志系统规范

> **面向对象**：XLY 包的开发者和贡献者  
> **目的**：统一日志输出规范，避免包内部日志污染用户项目

## 概述

XLY 包使用统一的 `XlyLogger` 日志系统，确保：
- ✅ 用户项目默认不会看到包的调试日志
- ✅ 开发时可以完整地看到所有日志
- ✅ 用户可在需要时主动启用调试日志

## 日志工具类：`XlyLogger`

位置：`lib/src/logger.dart`

### 可用方法

```dart
// 调试级别（默认关闭） - 用于详细的内部状态跟踪
XlyLogger.debug('智能停靠：窗口已隐藏');

// 信息级别（默认关闭） - 用于一般性信息
XlyLogger.info('MyTray: 托盘初始化成功');

// 警告级别（默认关闭） - 用于潜在问题
XlyLogger.warning('原生窗口助手：设置失败，回退到标准方法');

// 错误级别（始终输出） - 用于严重错误
XlyLogger.error('智能停靠检查出错', error, stackTrace);
```

### 日志级别选择

| 场景 | 使用级别 | 是否受开关控制 |
|------|---------|--------------|
| 内部状态跟踪（如"窗口已隐藏"） | `debug()` | ✅ 是 |
| 功能初始化成功 | `info()` | ✅ 是 |
| 配置问题、降级处理 | `warning()` | ✅ 是 |
| 严重错误、异常 | `error()` | ❌ 否（始终显示） |

## 控制机制

### 开发时启用日志

在 `example/lib/main.dart` 中：

```dart
await MyApp.initialize(
  enableDebugLogging: true,  // 开发时启用
  // ... 其他参数
);
```

### 用户项目默认行为

```dart
await MyApp.initialize(
  // enableDebugLogging 默认为 false
  // 用户看不到任何包的调试日志
);
```

### 用户主动启用（用于排查问题）

```dart
await MyApp.initialize(
  enableDebugLogging: true,  // 用户可以主动启用
);
```

## 编码规范

### ✅ 正确示例

```dart
// 调试信息
XlyLogger.debug('触发智能边缘停靠到${edge.name}');

// 信息日志
XlyLogger.info('托盘初始化成功，使用图标: $iconPath');

// 警告日志
XlyLogger.warning('插件未初始化，无法显示通知');

// 错误日志（带异常）
try {
  // ... 代码
} catch (e, stackTrace) {
  XlyLogger.error('设置开机自启动时出错', e, stackTrace);
}

// 错误日志（简化形式）
} catch (e) {
  XlyLogger.error('智能停靠检查出错', e);
}
```

### ❌ 错误示例

```dart
// ❌ 不要使用原始的 debugPrint
debugPrint('智能停靠：窗口已隐藏');

// ❌ 不要使用 print
print('MyTray: 托盘初始化成功');

// ❌ 不要使用 kDebugMode 包裹
if (kDebugMode) {
  print('错误信息');
}

// ❌ 错误日志应使用 error() 而非 debug()
XlyLogger.debug('设置失败：$e');  // 应该用 error()
```

## 添加新功能时的最佳实践

### 1. Import 日志工具

```dart
import '../logger.dart';  // 根据文件层级调整路径
```

### 2. 选择合适的日志级别

- **频繁的状态变化** → `debug()`
- **一次性的成功事件** → `info()`
- **可恢复的问题** → `warning()`
- **严重错误** → `error()`

### 3. 提供有价值的上下文

```dart
// ✅ 好：提供足够的上下文
XlyLogger.debug('智能停靠到${edge.name}，超出屏幕：${overflow.toFixed(1)}px');

// ❌ 差：信息不足
XlyLogger.debug('停靠');
```

### 4. 错误日志必须包含异常对象

```dart
// ✅ 好：传递异常对象
} catch (e) {
  XlyLogger.error('操作失败', e);
}

// ❌ 差：只记录消息
} catch (e) {
  XlyLogger.error('操作失败：$e');  // 丢失了异常类型信息
}
```

## 已完成的工作

截至最新版本，以下模块已全部迁移到 `XlyLogger` 系统：

- ✅ Smart Dock 模块（72个日志）
- ✅ MyTray（21个日志）
- ✅ MyNotify（22个日志）
- ✅ MyApp（19个日志）
- ✅ 工具类（platform, auto_start, single_instance）（24个日志）

**总计**：158 个日志全部迁移完成 ✅

## 检查清单

在提交 PR 前，请确保：

- [ ] 所有新增日志使用 `XlyLogger` 而非 `print` 或 `debugPrint`
- [ ] 选择了合适的日志级别（debug/info/warning/error）
- [ ] 错误日志包含了异常对象
- [ ] 日志消息提供了足够的上下文信息
- [ ] 没有使用 `if (kDebugMode)` 包裹日志调用
- [ ] 已在 example 项目中测试，确认日志正常输出
- [ ] 已测试用户场景（`enableDebugLogging: false`），确认无日志泄漏

## 常见问题

### Q: 什么时候用 `debug()` vs `info()`？

**A:** 
- `debug()`: 频繁发生的事件（如鼠标位置检查、窗口状态变化）
- `info()`: 一次性事件或重要里程碑（如初始化成功、功能启用）

### Q: 错误日志一定要用 `error()` 吗？

**A:** 不一定。如果是可预期的、可恢复的问题，用 `warning()` 更合适。`error()` 应保留给真正的错误情况。

### Q: 可以在 `XlyLogger` 中使用多行字符串吗？

**A:** 可以，但建议简化为单行。如确需多行，使用普通字符串拼接而非三引号：

```dart
// ✅ 推荐
XlyLogger.debug('scaleFactor: $scaleFactor, edgeOffset: $edgeOffset');

// ⚠️ 可以但不推荐
XlyLogger.debug('''
scaleFactor: $scaleFactor
edgeOffset: $edgeOffset
''');
```

## 技术细节

### 日志前缀

所有 `XlyLogger` 输出都带有 `[Xly]` 前缀和级别标签：

```
[Xly] 调试日志已启用
[Xly] [DEBUG] 智能停靠：窗口已隐藏
[Xly] [INFO] MyTray: 托盘初始化成功
[Xly] [WARNING] 设置失败，回退到标准方法
[Xly] [ERROR] 智能停靠检查出错
```

### 底层实现

`XlyLogger` 内部使用 Flutter 的 `debugPrint`，这是正确的实现方式。只有 `XlyLogger` 本身可以使用 `debugPrint`，其他代码都应使用 `XlyLogger`。

---

**维护者**: XLY 包开发团队  
**更新时间**: 2025-10-30

