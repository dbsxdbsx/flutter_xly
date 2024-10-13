# XLY包

XLY 是一个Flutter懒人工具包，提供了一些常用的功能和组件。虽然目前仍在开发中，但已经可以在项目中使用许多实用功能。

## 功能

当前，这个包提供了以下功能：

1. 基于GetX的状态管理
2. 基于ScreenUtil的屏幕适配
3. Toast消息显示(基于oktoast)
4. 导航辅助函数
5. 自定义按钮组件
6. 自定义菜单组件
7. 焦点管理

## 安装

要使用 XLY 包，首先在你的 `pubspec.yaml` 文件中添加 `xly` 依赖：


## 使用示例

### 初始化应用

```dart
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';

void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
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
    ],
  );
}

class Routes {
  static const page1 = '/page1';
  static const page2 = '/page2';
}
```

### 显示 Toast 消息
```dart
toast('这是一条测试Toast消息');
```

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


### 完整示例

对于一个完整的示例，请参考 Example 页面。该示例展示了如何综合使用 xly 包中的各种功能，包括按钮、菜单、焦点管理和导航等。Example 页面提供了更详细的代码实现和实际运行效果，可以帮助您更好地理解和使用 xly 包的各项功能。

您可以在项目的 `example` 目录下找到完整的示例代码。通过运行示例项目，您可以直观地体验 xly 包提供的各种组件和功能，并了解它们在实际应用中的使用方法。



## 注意事项

- 确保在使用 XLY 包的功能之前已经正确初始化了应用。
- 某些功能可能需要额外的设置或权限，请参考具体组件的文档。

## 贡献

欢迎提交问题和拉取请求。对于重大更改，请先开启一个问题讨论您想要更改的内容。

## 许可证

[MIT](https://choosealicense.com/licenses/mit/)