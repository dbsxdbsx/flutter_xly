# XLY包

XLY 是一个Flutter懒人工具包，提供了一些常用的功能和组件。虽然目前仍在开发中，但已经可以在项目中使用许多实用功能。

## 功能（Features）

当前，这个包提供了以下功能：

1. 基于GetX的状态管理(不用再加入"get"包了)
2. 基于ScreenUtil的屏幕适配(不用再加入"flutter_screenutil"包了)
3. 基于window_manager的窗口管理(不用再加入"window_manager"包了)
4. 基于screen_retriever的屏幕信息获取(不用再加入"screen_retriever"包了)
5. 基于GetStorage的本地存储(不用再加入"get_storage"包了)
6. Toast消息显示(内置实现，支持自定义动画和样式)
7. 导航辅助函数
8. 自定义按钮组件
9. 自定义菜单组件
10. 焦点管理(针对只能键盘或遥控操作的App很有用)
11. 自定义文本编辑器(支持下拉建议和样式自定义)
12. 自定义数字输入框(支持步进调节和范围控制)
13. 跨平台工具类(支持文件操作、权限管理、窗口控制等)
14. 开机自启动管理(支持桌面和Android平台)
15. 窗口停靠功能(支持停靠到屏幕四个角落，自动避开任务栏)
16. 边缘停靠功能(类似QQ的窗口边缘隐藏和鼠标悬停显示功能)
17. 智能边缘停靠机制(自动检测窗口拖拽到边缘并触发停靠)
18. 服务管理系统(确保服务在ScreenUtil初始化后注册，避免.sp等扩展方法返回无限值)
19. 全局UI构建器(`appBuilder`)(支持在应用顶层添加自定义组件，如全局浮动按钮)
20. 可拖拽浮动操作栏(`MyFloatBar`)(一个可拖动、可停靠、可展开的浮动操作栏)
21. 自适应侧边栏导航(`MyScaffold`)(根据屏幕尺寸自动切换抽屉/侧边栏/底部导航)

## 内置依赖包

使用本包后，您无需再单独导入以下包：

### 已重导出的包（可直接使用）
- `get: ^4.6.6` - GetX状态管理
- `flutter_screenutil: ^5.9.3` - 屏幕适配
- `window_manager: ^0.4.2` - 窗口管理
- `screen_retriever: ^0.2.0` - 屏幕信息获取
- `get_storage: ^2.1.1` - 本地存储

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

## 待办事项（TODOs）
- floatBar大小不随host app窗口大小随动，stateManagement测试
- right menu 子菜单issue
- 静默启动？
- tray pop msg
- MyToggleBtn?
- permission功能？

## 注意事项（Notes）

### 初始化顺序与配置覆盖
`MyApp.initialize`的配置应用顺序遵循以下核心原则：
1. **`MyApp.initialize`的直接参数**：方法调用时直接传入的配置，如`designSize`、`exitInfoText`等。
2. **`services`列表中的服务**：在`services`列表中注册的`GetxService`。
3. **路由**：通过`routes`参数配置的页面和控制器。

这种顺序意味着**服务（`services`）中加载的设置会覆盖`MyApp.initialize`方法中直接传入的同名参数**。例如，如果一个服务从本地存储中加载了持久化的主题设置，它将覆盖`MyApp.initialize`中设置的默认主题。

这是一个有意为之的设计，目的是为了让用户的个性化、持久化设置拥有更高的优先级，从而提供更符合直觉的用户体验。


## 使用示例（Examples）

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

    // 服务配置 - 确保在ScreenUtil初始化后注册，避免.sp等扩展方法返回无限值
    services: [
      MyService<YourCustomService>(
        service: () => YourCustomService(),
        permanent: true,  // 永久服务
      ),
      MyService<AnotherService>(
        service: () => AnotherService(),
        fenix: true,      // 懒加载服务，支持自动重建
      ),
    ],

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

### 服务管理系统

XLY包提供了服务管理系统，确保GetX服务在ScreenUtil初始化后注册，避免在服务中使用`.sp`、`.w`等扩展方法时返回无限值的问题。

#### 基本用法

```dart
void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),

    // 在services参数中注册服务
    services: [
      // 永久服务 - 应用启动时立即创建并保持到应用结束
      MyService<YourService>(
        service: () => YourService(),
        permanent: true,
      ),

      // 懒加载服务 - 首次使用时创建
      MyService<DataService>(
        service: () => DataService(),
        fenix: false,  // 默认值，服务被删除后不会自动重建
      ),

      // 凤凰服务 - 支持自动重建
      MyService<NetworkService>(
        service: () => NetworkService(),
        fenix: true,   // 服务被删除后会在下次使用时自动重建
      ),

      // 带标签的服务 - 支持同一类型的多个实例
      MyService<CacheService>(
        service: () => CacheService('user_cache'),
        tag: 'user',
        permanent: true,
      ),
      MyService<CacheService>(
        service: () => CacheService('app_cache'),
        tag: 'app',
        permanent: true,
      ),
    ],

    routes: [...],
  );
}
```

#### 自定义服务示例

```dart
class MyCustomService extends GetxService {
  static MyCustomService get to => Get.find();

  final counter = 0.obs;
  late GetStorage _storage;

  @override
  Future<void> onInit() async {
    super.onInit();
    // 在这里可以安全使用ScreenUtil扩展方法
    final fontSize = 16.sp;  // 不会返回无限值

    // 初始化GetStorage（MyApp.initialize已经调用了GetStorage.init()）
    _storage = GetStorage();
    counter.value = _storage.read('counter') ?? 0;
  }

  void increment() async {
    counter.value++;
    await _storage.write('counter', counter.value);
  }
}
```

#### 服务配置选项

- `permanent: true` - 永久服务，应用启动时立即创建并保持到应用结束
- `fenix: true` - 凤凰服务，支持自动重建（当服务被删除后，下次使用时会自动重新创建）
- `tag: 'custom_tag'` - 服务标签，支持同一类型的多个实例

#### 重要说明

1. **初始化时机**: 服务会在ScreenUtil初始化**之后**、runApp**之前**注册
2. **避免无限值**: 在服务的`onInit()`方法中可以安全使用`.sp`、`.w`等扩展方法
3. **向后兼容**: `services`参数是可选的，现有代码无需修改
4. **GetX兼容**: 完全兼容GetX的所有服务管理功能

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

### 使用边缘停靠功能（类似QQ）

边缘停靠功能允许您将窗口停靠到屏幕边缘，大部分隐藏，只留一小部分可见，类似腾讯QQ的停靠行为：

```dart
// 启用左边缘停靠，可见宽度为8像素
final success = await MyApp.enableSimpleEdgeDocking(
  edge: WindowEdge.left,
  visibleWidth: 8.0,
);

if (success) {
  print('边缘停靠已启用');
}

// 启用其他边缘停靠
await MyApp.enableSimpleEdgeDocking(edge: WindowEdge.right);
await MyApp.enableSimpleEdgeDocking(edge: WindowEdge.top);
await MyApp.enableSimpleEdgeDocking(edge: WindowEdge.bottom);

// 手动切换停靠窗口的展开/收缩状态
await MyApp.toggleDockedWindow();

// 手动展开停靠的窗口
await MyApp.expandDockedWindow();

// 手动收缩窗口到停靠位置
await MyApp.collapseDockedWindow();

// 禁用边缘停靠功能
MyApp.disableEdgeDocking();
```

边缘停靠功能特性：
- 🎯 **智能停靠**: 窗口停靠到屏幕边缘，只留小部分可见
- 🖱️ **交互友好**: 点击可见部分可展开/收缩窗口
- 📏 **可调节**: 支持自定义可见宽度
- 🔧 **跨平台**: 支持Windows、macOS、Linux桌面平台
- ⚡ **简单控制**: 提供手动控制方法
- 🛡️ **安全可靠**: 内部异常处理，操作安全

### 使用智能停靠机制

智能停靠是一个更高级的功能，它会自动检测用户拖拽窗口的行为，当窗口的某部分被拖拽超出屏幕边界时，自动触发停靠。系统会智能判断是进行边缘停靠还是角落停靠：

```dart
// 启用智能停靠机制
await MyApp.setSmartEdgeDocking(
  enabled: true,
  visibleWidth: 8.0,      // 停靠时可见宽度
);

// 检查智能停靠状态
bool isEnabled = MyApp.isSmartDockingEnabled();

// 禁用智能停靠
await MyApp.setSmartEdgeDocking(enabled: false);
```

智能停靠特性：
- 🧠 **智能检测**: 自动检测窗口拖拽行为和位置
- 🎯 **边界触发**: 窗口部分超出屏幕边界时自动停靠
- 📐 **智能选择**: 自动判断边缘停靠或角落停靠
  - 窗口同时超出两个相邻边界时，触发**角落停靠**（如左上角）
  - 窗口只超出一个边界时，触发**边缘停靠**（如左边缘）
- 👁️ **可见区域优化**: 角落停靠时露出更大的可见区域，便于鼠标悬停
- ⏱️ **延迟触发**: 窗口停止移动后延迟触发，避免误操作
- 🔄 **动态切换**: 可以在不同边缘/角落间自由切换停靠
- 🛡️ **状态管理**: 自动管理停靠状态，避免冲突
- 🎭 **两步式行为**: 先对齐到目标位置，再根据鼠标位置智能隐藏/显示

### 功能对比：`dockToCorner` vs 智能停靠

| 功能 | `dockToCorner` | 智能停靠 (`setSmartEdgeDocking`) |
|------|----------------|----------------------------------|
| **触发方式** | 手动调用API | 自动检测拖拽行为 |
| **行为模式** | 仅对齐到角落，不隐藏 | 先对齐，后根据鼠标智能隐藏 |
| **适用场景** | 简单的窗口定位 | 类似QQ的智能停靠体验 |
| **鼠标交互** | 无 | 鼠标悬停显示，离开隐藏 |
| **使用复杂度** | 简单 | 自动化，无需手动管理 |

```dart
// 简单对齐到角落（不隐藏）
await MyApp.dockToCorner(WindowCorner.topLeft);

// vs

// 智能停靠（自动检测 + 智能隐藏）
await MyApp.setSmartEdgeDocking(enabled: true);
```

**重要更新**：智能角落停靠行为已优化！现在当拖拽到屏幕角落时，窗口会：
1. 🎯 **先对齐到角落** - 与边缘停靠行为保持一致
2. 👁️ **再智能隐藏** - 鼠标离开时才隐藏到角落
3. 🔄 **鼠标交互** - 悬停显示完整窗口，离开后隐藏

这确保了角落停靠与边缘停靠具有一致的用户体验。

注意：此功能仅在桌面平台（Windows、macOS、Linux）上可用。

 ### 使用 appBuilder 添加全局浮动栏

 `MyApp.initialize` 提供了一个 `appBuilder` 参数，允许您在应用的顶层UI上包裹自定义组件。这对于实现全局浮动导航栏、消息通知等功能非常有用。

 `MyFloatBar` 是一个可拖动、可停靠、可展开的浮动操作栏，可以与 `appBuilder` 结合使用。

 ```dart
 // main.dart
 void main() async {
   await MyApp.initialize(
     // ... 其他配置
     services: [
       // 为FloatBar注册控制器
       MyService<FloatBarNavController>(
         service: () => FloatBarNavController(),
         permanent: true,
       ),
     ],
     appBuilder: (context, child) {
       // 使用Stack将FloatBar覆盖在应用内容之上
       return Stack(
         children: [
           child!, // child是原始的应用页面
           getFloatBar(), // 自定义的FloatBar
         ],
       );
     },
   );
 }

 // float_bar_navigation.dart

 /// 获取FloatBar组件
 Widget getFloatBar() {
   final ctrl = Get.find<FloatBarNavController>();
   return Obx(
     () => MyFloatBar(
       barWidthInput: 60,
       backgroundColor: const Color(0xFF222222),
       buttons: ctrl.buttons.toList(),
       onPressed: (index) {
         // 处理按钮点击事件
         if (index == 0) {
           // 打开导航菜单
         } else if (index == 1) {
           // 最小化窗口
           windowManager.minimize();
         } else if (index == 2) {
           // 退出应用
           showExitConfirmDialog();
         }
       },
     ),
   );
 }

 /// FloatBar导航控制器
 class FloatBarNavController extends GetxController {
   final buttons = <MyFloatBarButton>[
     MyFloatBarButton(icon: Icons.menu),          // 导航菜单按钮
     MyFloatBarButton(icon: CupertinoIcons.minus), // 最小化窗口按钮
     MyFloatBarButton(icon: CupertinoIcons.xmark_circle), // 退出应用按钮
   ].obs;
 }
 ```

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

本包集成了应用重命名功能，支持一键重命名所有平台的应用名称：

```bash
# 为所有平台设置相同名称
dart run xly:rename all="新应用名称"

# 为不同平台设置不同名称
dart run xly:rename android="Android版本" ios="iOS版本" windows="Windows版本"
```

### 使用自适应侧边栏导航

`MyScaffold` 提供了根据屏幕尺寸自动切换的导航体验：

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xly/xly.dart';

class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  void switchToPage(int index) {
    currentIndex.value = index;
  }
}

class MyHomePage extends StatelessWidget {
  final controller = Get.put(NavigationController());

  final List<Widget> pages = [
    Center(child: Text('首页内容')),
    Center(child: Text('设置内容')),
    Center(child: Text('关于内容')),
  ];

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBar(title: Text('我的应用')),
      drawer: [
        AdaptiveNavigationItem(
          icon: Icon(Icons.home),
          label: '首页',
          onTap: () => controller.switchToPage(0),
        ),
        AdaptiveNavigationItem(
          icon: Icon(Icons.settings),
          label: '设置',
          onTap: () => controller.switchToPage(1),
          badgeCount: 2, // 可选的徽章数量
        ),
        AdaptiveNavigationItem(
          icon: Icon(Icons.info),
          label: '关于',
          onTap: () => controller.switchToPage(2),
        ),
      ],
      body: Obx(() => pages[controller.currentIndex.value]),

      // 可选配置
      useBottomNavigationOnSmall: false, // 小屏幕使用抽屉而非底部导航
      smallBreakpoint: 600.0,           // 小屏幕断点
      largeBreakpoint: 840.0,           // 大屏幕断点
      drawerWidthRatio: 0.88,           // 抽屉宽度比例
    );
  }
}
```

**特性说明：**
- **小屏幕**：显示抽屉式导航或底部导航栏
- **中等屏幕**：显示收缩的图标式侧边栏
- **大屏幕**：显示完整的展开式侧边栏（图标+文字）
- **自动适配**：根据屏幕宽度自动切换显示模式
- **灵活配置**：支持自定义断点、抽屉宽度等参数

### 应用图标生成

本包还提供了简化版的图标生成工具，支持一键为所有平台生成应用图标：

```bash
# 从单个源图标生成所有平台的图标
dart run xly:generate icon="path/to/your/icon.png"
```

**支持的平台：**
- Android (多种密度的mipmap图标)
- iOS (包含所有尺寸规格，自动移除alpha通道)
- Windows (ICO格式，包含多种尺寸)
- macOS (包含Contents.json配置)
- Linux (256x256 PNG)
- Web (包含favicon和PWA图标)

**特性：**
- 自动检测项目中存在的平台
- 支持PNG、JPEG、JPG格式输入
- 自动创建必要的目录结构
- 生成平台特定的配置文件
- 建议源图标尺寸：1024x1024像素或更大

**更多自定义需求：**
如需更高级的图标配置（如Android自适应图标、iOS深色/着色变体等），请使用原始的 [icons_launcher](https://pub.dev/packages/icons_launcher) 包。

详细使用说明和注意事项请参考：[tool/README.md](tool/README.md)

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
