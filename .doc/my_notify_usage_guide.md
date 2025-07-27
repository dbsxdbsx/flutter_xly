# MyNotify 使用指南

## 概述

MyNotify 是 xly_flutter_package 中的系统通知管理器，基于 `flutter_local_notifications` 包封装，提供跨平台的系统通知功能。

## 主要特性

- **跨平台支持**：Android、iOS、macOS、Windows、Linux
- **多种通知类型**：信息、警告、错误、成功
- **定时通知**：支持指定时间显示通知
- **权限管理**：自动处理通知权限请求
- **状态监控**：实时监控初始化和权限状态
- **通知管理**：支持取消单个或所有通知

## 快速开始

### 1. 注册服务

在 `main.dart` 中注册 MyNotify 服务：

```dart
void main() async {
  await MyApp.initialize(
    appName: "我的应用",
    services: [
      MyService<MyNotify>(
        service: () => MyNotify(),
        permanent: true,
      ),
    ],
  );
}
```

### 2. 基础使用

```dart
// 获取 MyNotify 实例
final myNotify = MyNotify.to;

// 显示基础通知
await myNotify.show("标题", "消息内容");

// 显示不同类型的通知
await myNotify.show("信息", "这是一条信息通知", type: MyNotifyType.info);
await myNotify.show("警告", "这是一条警告通知", type: MyNotifyType.warning);
await myNotify.show("错误", "这是一条错误通知", type: MyNotifyType.error);
await myNotify.show("成功", "这是一条成功通知", type: MyNotifyType.success);
```

## 高级功能

### 定时通知

```dart
// 5秒后显示通知
final scheduledTime = DateTime.now().add(Duration(seconds: 5));
await myNotify.schedule(
  "定时通知",
  "这是一条定时通知",
  scheduledTime,
  type: MyNotifyType.info,
);
```

### 权限管理

```dart
// 检查权限状态
bool hasPermission = myNotify.permissionGranted;
bool isInitialized = myNotify.isInitialized;

// 请求通知权限
bool granted = await myNotify.requestPermissions();
if (granted) {
  print("通知权限已获得");
} else {
  print("通知权限被拒绝");
}
```

### 通知管理

```dart
// 取消指定ID的通知
await myNotify.cancel(0);

// 取消所有通知
await myNotify.cancelAll();

// 获取待处理的通知
List<PendingNotificationRequest> pending = await myNotify.getPendingNotificationRequests();

// 获取活跃的通知
List<ActiveNotification> active = await myNotify.getActiveNotifications();
```

## 通知类型说明

### MyNotifyType 枚举

- `MyNotifyType.info`：信息通知（蓝色，普通优先级）
- `MyNotifyType.warning`：警告通知（橙色，高优先级）
- `MyNotifyType.error`：错误通知（红色，最高优先级）
- `MyNotifyType.success`：成功通知（绿色，高优先级）

### 平台差异

不同平台的通知表现可能略有不同：

- **Android**：支持重要性级别、优先级、振动等
- **iOS/macOS**：支持横幅、声音、角标等
- **Windows**：支持 Toast 通知
- **Linux**：支持桌面通知规范

## 与 MyTray 的集成

MyNotify 可以与 MyTray 配合使用，但两者职责分离：

- **MyTray**：专注托盘图标、菜单管理
- **MyNotify**：专注系统通知显示

```dart
// 推荐做法：直接使用 MyNotify
final myNotify = MyNotify.to;
await myNotify.show("已隐藏到托盘", "点击托盘图标可恢复窗口");

// 而不是通过 MyTray 转发
// myTray.notify(...) // 此方法已移除
```

## 最佳实践

1. **权限检查**：在显示通知前检查权限状态
2. **错误处理**：妥善处理权限被拒绝的情况
3. **通知管理**：及时清理不需要的通知
4. **用户体验**：避免过度通知，影响用户体验
5. **平台适配**：考虑不同平台的通知行为差异

## 故障排除

### 通知不显示

1. 检查权限是否已授权
2. 确认服务是否正确初始化
3. 查看控制台错误信息
4. 检查平台特定的通知设置

### Android 特殊情况

- Android 13+ 需要用户手动授权通知权限
- 某些厂商的系统可能限制后台通知
- 定时通知可能受到电池优化影响

### iOS/macOS 特殊情况

- 首次使用会弹出权限请求对话框
- 通知样式受系统设置影响
- 应用在前台时通知行为可能不同

## 示例代码

完整的使用示例可以参考 `example/lib/pages/page8.dart` 文件，其中包含了 MyNotify 的各种使用场景和最佳实践。
