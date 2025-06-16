# XLY包

XLY 是一个Flutter懒人工具包，提供了一些常用的功能和组件。虽然目前仍在开发中，但已经可以在项目中使用许多实用功能。

## 功能

当前，这个包提供了以下功能：

1. 基于GetX的状态管理(不用再加入"get"包了)
2. 基于ScreenUtil的屏幕适配(不用再加入"flutter_screenutil"包了)
3. 基于window_manager的窗口管理(不用再加入"window_manager"包了)
4. 基于screen_retriever的屏幕信息获取(不用再加入"screen_retriever"包了)
5. Toast消息显示(内置实现，支持自定义动画和样式)
6. 导航辅助函数
7. 自定义按钮组件
8. 自定义菜单组件
9. 焦点管理(针对只能键盘或遥控操作的App很有用)
10. 自定义文本编辑器(支持下拉建议和样式自定义)
11. 自定义数字输入框(支持步进调节和范围控制)
12. 跨平台工具类(支持文件操作、权限管理、窗口控制等)
13. 开机自启动管理(支持桌面和Android平台)
14. 窗口停靠功能(支持停靠到屏幕四个角落，自动避开任务栏)

## 内置依赖包

使用本包后，您无需再单独导入以下包：

### 已重导出的包（可直接使用）
- `get: ^4.6.6` - GetX状态管理
- `flutter_screenutil: ^5.9.3` - 屏幕适配
- `window_manager: ^0.4.2` - 窗口管理
- `screen_retriever: ^0.2.0` - 屏幕信息获取

### 内部使用的包（多数情况无需关心，本xly包有相应功能可直接使用）
- `lottie: ^3.1.2` - Lottie动画
- `path_provider: ^2.1.2` - 路径管理
- `permission_handler: ^11.3.0` - 权限管理
- `autostart_settings: ^0.1.4` - 自启动设置（Android）
- `launch_at_startup: ^0.3.0` - 开机自启动（桌面）
- `package_info_plus: ^8.0.0` - 应用信息
- `flutter_inset_shadow: ^2.0.3` - 内阴影
- `url_launcher: ^6.2.5` - URL启动器
- `path: ^1.8.0` - 路径操作
- `xml: ^6.5.0` - XML解析
- `icons_launcher: ^3.0.0` - 图标生成

## TODO
float panel bar ：git stash pop?
right menu 子菜单issue
静默启动？
tray pop msg
MyToggleBtn?
permission功能？

## 使用示例

### 初始化应用

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';

void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    splash: const MySplash(
      nextRoute: Routes.page1,
      lottieAssetPath: 'assets/animation/splash_loading.json',
      appTitle: 'My Awesome App',
      backgroundColor: Colors.blueGrey,
      splashDuration: Duration(seconds: 3),
      textColor: Colors.white,
      fontSize: 60,
      fontWeight: FontWeight.bold,
      lottieWidth: 250,
      spaceBetween: 30,
    ),
    routes: [
      MyRoute<Page1Controller>(
        path: Routes.page1,
        page: const Page1View(),
        controller: () => Page1Controller(),
      ),
      MyRoute<Page2Controller>(
        path: Routes.page2,
        page: const Page2View(),
        controller: () => Page2Controller(),
      ),
      MyRoute<Page3Controller>(
        path: Routes.page3,
        page: const Page3View(),
        controller: () => Page3Controller(),
      ),
    ],
    keyToRollBack: LogicalKeyboardKey.backspace,
    exitInfoText: '自定义: 再按一次退出App',
    backInfoText: '自定义: 再按一次返回上一页',
    pageTransitionStyle: Transition.fade,
  );
}

class Routes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
}
```

### 显示 Toast 消息

MyToast 提供了多种类型的消息提示：

```dart
// 1. 中间位置的状态提示（带图标）
MyToast.showOk('操作成功完成！');     // 绿色对勾图标
MyToast.showInfo('这是一条信息提示'); // 蓝色信息图标
MyToast.showWarn('请检查输入数据');   // 黄色警告图标
MyToast.showError('发生错误：无法连接服务器'); // 红色错误图标

// 2. 顶部通知栏样式
MyToast.showUpInfo('这是一条信息提示');  // 蓝色背景
MyToast.showUpWarn('这是一条警告消息');  // 黄色背景
MyToast.showUpError('这是一条错误消息');  // 红色背景

// 3. 底部通知栏样式
MyToast.showBottom(
  '这是一条底部提示消息',
  opacity: 0.9,               // 背景透明度
  backgroundColor: Colors.black, // 自定义背景色
  textColor: Colors.white,    // 自定义文字颜色
);

// 4. 基础 Toast（可自定义位置）
MyToast.show(
  '这是一条自定义Toast消息',
  position: ToastPosition.center,  // 显示位置：top/center/bottom
  duration: Duration(seconds: 2),  // 显示时长
  backgroundColor: Colors.black87.withOpacity(0.7),  // 背景颜色
  textStyle: TextStyle(fontSize: 16, color: Colors.white),  // 文本样式
  radius: 8.0,  // 圆角半径
  stackToasts: true,  // 是否堆叠显示
  forever: false,     // 是否永久显示
  animationDuration: Duration(milliseconds: 500),  // 动画时长
  animationCurve: Curves.easeOutCubic,  // 动画曲线
);

// 5. 加载提示
// 5.1 显示永久加载动画
MyToast.showSpinner(
  message: '加载中...',
  spinnerColor: Colors.blue,  // 加载动画颜色
  backgroundColor: Colors.black.withOpacity(0.8),
  textStyle: TextStyle(fontSize: 16, color: Colors.white),
);

// 5.2 自动关闭的加载动画
MyToast.showSpinner(
  message: '加载中...',
  duration: Duration(seconds: 3), // 3秒后自动关闭
);

// 5.3 加载完成后显示结果
await MyToast.showLoadingThenToast(
  loadingMessage: '正在加载数据...',
  task: () async {
    await Future.delayed(Duration(seconds: 1));
    return (true, '数据加载完成！'); // 返回(成功状态, 提示消息)
  },
  spinnerColor: Colors.blue,
  stackToasts: true,  // 是否堆叠显示结果消息
  // 可选：自定义成功/警告/错误回调
  onOk: (message) => MyToast.showBottom(message),
  onWarn: (message) => MyToast.showUpWarn(message),
  onError: (error) => MyToast.showUpError('错误：$error'),
);

// 6. 关闭所有显示的 Toast
MyToast.hideAll();
// 或延迟关闭
MyToast.hideAll(1000); // 1秒后关闭
```

Toast 特性：
- 支持多种预设样式：成功、信息、警告、错误
- 支持多个显示位置：顶部、中间、底部
- 支持堆叠显示或替换显示
- 支持自定义样式：背景色、文字样式、图标等
- 支持加载动画显示
- 支持异步任务加载提示
- 支持自动关闭和手动关闭
- 支持动画效果和自定义动画时长

### 使用自定义按钮
```dart
Widget buildCustomButton() {
  return MyButton(
    text: '点击我',
    onPressed: () => print('按钮被点击'),
    icon: Icons.star,
    shape: MyButtonShape.normal,
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  );
}
```

### 使用菜单按钮
```dart
Widget buildMenuButton() {
  return MyMenuButton(
    icon: Icons.more_vert,
    iconSize: 30.0,
    iconColor: Colors.green,
    menuItems: [
      MyMenuItem(
        text: '选项A',
        icon: Icons.star,
        onTap: () => toast('选择了选项A'),
      ),
      MyMenuItem(
        text: '选项B',
        icon: Icons.favorite,
        onTap: () => toast('选择了选项B'),
      ),
    ],
  );
}
```


### 使用焦点管理
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('可聚焦的文本').setFocus(
      focusKey: 'focusable_text',
      onPressed: () => toast('文本被聚焦并点击'),
      opacity: true,
      focusedBorderColor: Colors.green,
      borderWidth: 2,
    );
  }
}
```


### 导航到新页面
```dart
goToPage(context, Routes.page2);
```

### 显示对话框
```dart
MyDialog.show(
  content: '这是一个测试对话框',
  onLeftButtonPressed: () => toast('选择了左按钮'),
  onRightButtonPressed: () => toast('选择了右按钮'),
);

MyDialog.showIos(
  content: '这是一个测试对话框',
  onLeftButtonPressed: () => toast('选择了左按钮'),
  onRightButtonPressed: () => toast('选择了右按钮'),
);
```

### 使用底部菜单
```dart
MyDialogSheet.showBottom(
  child: Text('这是一个测试底部菜单'),
  height: 300.h,
  backgroundColor: Colors.white,
  borderRadius: 20.r,
);
```

### 右键菜单
```dart
Widget buildRightMenu() {
  return Text('这是一个测试右键菜单').showRightMenu(
    context: context,
    menuElements: [
      MyMenuItem(text: '选项A', onTap: () => toast('选择了选项A')),
      MyMenuItem(text: '选项B', onTap: () => toast('选择了选项B')),
    ],
  );
}
```

### 使用自定义文本编辑器
```dart
Widget buildTextEditor() {
  return MyTextEditor(
    textController: TextEditingController(),
    label: '输入文本',
    hint: '请输入...',
    clearable: true,
    onChanged: (value) => print('文本已更改: $value'),
    getDropDownOptions: () async {
      // 返回下拉建议列表
      return ['选项1', '选项2', '选项3'];
    },
    onOptionSelected: (option) => print('选择了: $option'),
    // 自定义样式
    labelFontSize: 15.0,
    textFontSize: 12.0,
    borderRadius: 4.0,
    focusedBorderColor: Colors.blue,
  );
}
```

### 使用自定义数字输入框
```dart
Widget buildSpinBox() {
  return MySpinBox(
    label: '数量',
    initialValue: 0,
    min: 0,
    max: 100,
    step: 1.0,
    enableEdit: true,
    suffix: '个',
    onChanged: (value) => print('数值已更改: $value'),
    // 自定义样式
    labelFontSize: 15.0,
    centerTextFontSize: 12.0,
    spinIconSize: 13.0,
    spinButtonSize: 28.0,
  );
}
```

### 使用平台工具类
```dart
// 判断平台类型
if (MyPlatform.isDesktopOs()) {
  // 桌面平台特有操作
  await MyPlatform.showWindow();
} else if (MyPlatform.isMobileOs()) {
  // 移动平台特有操作
  final hasPermission = await MyPlatform.requestPermission(
    Permission.storage,
  );
}

// 文件操作
final appDir = await MyPlatform.getAppDirectory();
final file = await MyPlatform.getFile('example.txt');
final assetFile = await MyPlatform.getFilePastedFromAssets('config.json');

// 延迟显示组件
Widget buildPingDisplay() {
  return MyPlatform.buildDelayDisplay(
    pingTimeFuture: Future.value(BigInt.from(150)),
    fontSize: 14.0,
  );
}
```

### 使用窗口停靠功能

窗口停靠功能允许您将应用窗口快速移动到屏幕的四个角落，并自动避开任务栏：

```dart
// 停靠窗口到左上角
final success = await MyApp.dockToCorner(WindowCorner.topLeft);
if (success) {
  print('窗口已停靠到左上角');
} else {
  print('停靠失败');
}

// 停靠窗口到右上角
await MyApp.dockToCorner(WindowCorner.topRight);

// 停靠窗口到左下角
await MyApp.dockToCorner(WindowCorner.bottomLeft);

// 停靠窗口到右下角
await MyApp.dockToCorner(WindowCorner.bottomRight);
```

窗口停靠功能特性：
- 🎯 **精确停靠**: 窗口会精确停靠到屏幕的四个角落
- 📏 **任务栏感知**: 自动检测任务栏位置，确保窗口不被遮挡
- 🔧 **跨平台兼容**: 支持Windows、macOS、Linux桌面平台
- ⚡ **简单易用**: 一行代码完成停靠操作
- 🛡️ **错误处理**: 内部处理所有异常，返回操作结果

注意：此功能仅在桌面平台（Windows、macOS、Linux）上可用。

### 使用自启动管理
```dart
// 检查是否支持自启动功能
if (MyAutoStart.isSupported()) {
  // 启用开机自启动
  final success = await MyAutoStart.setAutoStart(
    true,
    // 可选：指定桌面平台的包名
    packageName: 'com.myapp.example',
  );

  if (success) {
    print('设置开机自启动成功');
  } else {
    print('设置开机自启动失败');
  }
}

// 禁用开机自启动
await MyAutoStart.setAutoStart(false);
```

注意：
- Web平台不支持此功能
- Android平台会打开系统设置页面
- 桌面平台需要提供正确的包名（可选）

## App重命名功能

本包已集成 rename_app 功能，你可以直接使用以下命令来重命名应用：

### 为所有平台设置相同名称
```bash
dart run rename_app:main all="新应用名称"
```

### 为不同平台设置不同名称
```bash
# 设置 Android 和 iOS 平台名称
dart run rename_app:main android="Android版本" ios="iOS版本"

# 为所有平台分别设置名称
dart run rename_app:main android="Android版本" ios="iOS版本" web="Web版本" windows="Windows版本" linux="Linux版本" mac="Mac版本"
```

注意：重命名操作会修改项目配置文件，建议在进行重命名操作前先提交或备份当前代码。

## 完整示例

对于一个完整的示例，请参考Example页面。该示例展示了如何综合使用 xly 包中的各种功能，包括按钮、菜单、焦点管理和导航等。Example 页面提供了更详细的代码实现和实际运行效果，可以帮助您更好地理解和使用 xly 包的各项功能。

您可以在项目的 `example` 目录下找到完整的示例代码。通过运行示例项目，您可以直观地体验 xly 包提供的各种组件和功能，并了解它们在实际应用中的使用方法。

## splash Json动画资源

- [lottie 动画参考1](https://lottiefiles.com/featured)
- [lottie 动画参考2](https://iconscout.com/lottie-animations/)

## 注意事项

- 确保在使用 XLY 包的功能之前已经正确初始化了应用。
- 某些功能可能需要额外的设置或权限，请参考具体组件的文档。

## 贡献

欢迎提交问题和拉取请求。对于重大更改，请先开启一个问题讨论您想要改的内容。

## 许可证

[MIT](https://choosealicense.com/licenses/mit/)

## 图标生成功能

本项目已集成 [`icons_launcher`](https://pub.dev/packages/icons_launcher) 包，可以方便地生成各种平台的应用图标。用户无需单独导入该包。
