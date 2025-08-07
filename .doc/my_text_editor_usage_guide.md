# MyTextEditor 使用指南

## 概述

MyTextEditor 是 xly_flutter_package 中的高级文本编辑器组件，提供丰富的功能和高度的自定义性。它不仅支持基础的文本输入，还具备智能下拉建议、键盘导航、自定义样式等高级特性。

## 主要特性

### 🎯 核心功能
- **基础文本编辑**：支持单行和多行文本输入
- **智能下拉建议**：异步获取建议选项，支持自定义过滤
- **清除功能**：可选的清除按钮，支持自定义清除回调
- **输入限制**：支持键盘类型、输入格式化器等限制

### 🎨 样式自定义
- **边框样式**：可自定义边框颜色、宽度、圆角
- **字体样式**：支持标签、文本、提示文字的字体大小和颜色
- **背景颜色**：可设置输入框背景色
- **布局控制**：支持高度、内边距等布局属性

### ⌨️ 交互体验
- **键盘导航**：上下箭头键导航，Enter选择，Escape关闭
- **鼠标键盘协同**：鼠标悬停与键盘导航智能同步
- **自动滚动**：选中项自动滚动到可视区域
- **防抖动机制**：选择后智能防止下拉列表闪烁
- **手动关闭记忆**：记住用户主动关闭行为

## 快速开始

### 基础用法

```dart
class BasicExample extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MyTextEditor(
      textController: controller,
      label: '用户名',
      hint: '请输入用户名',
      clearable: true,
    );
  }
}
```

### 带下拉建议的输入框

```dart
class DropdownExample extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MyTextEditor(
      textController: controller,
      label: '城市选择',
      hint: '请选择或输入城市',
      getDropDownOptions: _getCities,
      onOptionSelected: (city) {
        controller.text = city;
        debugPrint('选择了城市: $city');
      },
      maxShowDropDownItems: 8,
    );
  }

  Future<List<String>> _getCities() async {
    // 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      '北京', '上海', '广州', '深圳', '杭州',
      '南京', '武汉', '成都', '西安', '重庆'
    ];
  }
}
```

## 高级用法

### 自定义选项显示

```dart
MyTextEditor(
  textController: controller,
  label: '国家选择',
  hint: '请选择国家',
  getDropDownOptions: _getCountries,
  onOptionSelected: (country) => controller.text = country,
  // 自定义选项前缀图标
  leadingBuilder: (option) => Flag.fromCode(
    _getCountryCode(option),
    width: 24.w,
    height: 24.w,
    borderRadius: 4,
  ),
  // 自定义显示文本
  displayStringForOption: (option) => '🌍 $option',
  // 自定义过滤逻辑
  filterOption: (option, input) {
    return option.toLowerCase().contains(input.toLowerCase()) ||
           _getCountryCode(option).toLowerCase().contains(input.toLowerCase());
  },
)
```

### 显示选项数量

在标签中显示可用选项数量，提升用户体验：

```dart
class CountryController extends GetxController {
  final countryController = TextEditingController();
  final countryCount = 195; // 总国家数量

  @override
  Widget build(BuildContext context) {
    return MyTextEditor(
      textController: countryController,
      label: '国家选择 ($countryCount)', // 在标签中显示数量
      hint: '选择或输入国家',
      getDropDownOptions: getCountries,
      onOptionSelected: onCountrySelected,
      leadingBuilder: (option) => Flag.fromCode(
        getCountryCode(option),
        width: 24.w,
        height: 24.w,
        borderRadius: 4,
      ),
    );
  }
}
```

### 完全自定义样式

```dart
MyTextEditor(
  textController: controller,
  label: '自定义样式',
  hint: '展示自定义样式',
  clearable: true,

  // 尺寸设置
  height: 60.h,
  borderRadius: 12.r,
  borderWidth: 2,
  contentPadding: 16.w,

  // 字体设置
  labelFontSize: 16.sp,
  textFontSize: 14.sp,
  hintFontSize: 12.sp,
  labelFontWeight: FontWeight.w600,
  textFontWeight: FontWeight.w400,

  // 颜色设置
  backgroundColor: Colors.grey[50],
  normalBorderColor: Colors.grey[300]!,
  enabledBorderColor: Colors.blue[200]!,
  focusedBorderColor: Colors.blue[500]!,
  labelColor: Colors.blue[700],
  textColor: Colors.grey[800],
  hintColor: Colors.grey[500],

  // 下拉列表样式
  dropdownMaxHeight: 200.h,
  dropdownHighlightColor: Colors.blue[50],
  dropDownItemPadding: EdgeInsets.symmetric(
    horizontal: 16.w,
    vertical: 12.h,
  ),

  // 布局属性
  isDense: false, // 是否使用紧凑布局
  showScrollbar: true, // 多行时是否显示滚动条
  floatingLabelBehavior: FloatingLabelBehavior.always, // 标签浮动行为
)
```

## 控制器管理最佳实践

### 使用GetX控制器

```dart
class MyFormController extends GetxController {
  // 文本控制器
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();

  // 响应式状态
  final isLoading = false.obs;
  final cities = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadCities();
  }

  @override
  void onClose() {
    // 重要：释放控制器资源
    nameController.dispose();
    emailController.dispose();
    cityController.dispose();
    super.onClose();
  }

  // 异步获取城市列表
  Future<List<String>> getCities() async {
    if (cities.isEmpty) {
      await _loadCities();
    }
    return cities.toList();
  }

  Future<void> _loadCities() async {
    isLoading.value = true;
    try {
      // 模拟API调用
      await Future.delayed(const Duration(milliseconds: 500));
      cities.value = [
        '北京', '上海', '广州', '深圳', '杭州',
        '南京', '武汉', '成都', '西安', '重庆'
      ];
    } finally {
      isLoading.value = false;
    }
  }

  // 选择回调
  void onCitySelected(String city) {
    cityController.text = city;
    debugPrint('选择了城市: $city');
  }

  // 表单提交
  void submitForm() {
    if (_validateForm()) {
      // 处理表单提交
      MyToast.showSuccess('表单提交成功');
    }
  }

  bool _validateForm() {
    if (nameController.text.isEmpty) {
      MyToast.showError('请输入姓名');
      return false;
    }
    if (emailController.text.isEmpty) {
      MyToast.showError('请输入邮箱');
      return false;
    }
    return true;
  }
}
```

### 在页面中使用

```dart
class MyFormView extends GetView<MyFormController> {
  const MyFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表单示例')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            MyTextEditor(
              textController: controller.nameController,
              label: '姓名',
              hint: '请输入您的姓名',
              clearable: true,
            ),
            SizedBox(height: 16.h),
            MyTextEditor(
              textController: controller.emailController,
              label: '邮箱',
              hint: '请输入邮箱地址',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),
            MyTextEditor(
              textController: controller.cityController,
              label: '城市',
              hint: '请选择您的城市',
              getDropDownOptions: controller.getCities,
              onOptionSelected: controller.onCitySelected,
            ),
            SizedBox(height: 32.h),
            MyButton(
              text: '提交',
              onPressed: controller.submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
```

## 性能优化建议

### 1. 大量选项处理

```dart
MyTextEditor(
  // 限制显示的选项数量
  maxShowDropDownItems: 10,

  // 自定义过滤逻辑，提前过滤数据
  filterOption: (option, input) {
    if (input.length < 2) return false; // 至少输入2个字符才开始过滤
    return option.toLowerCase().contains(input.toLowerCase());
  },

  // 异步获取时添加防抖
  getDropDownOptions: () => _debouncedGetOptions(),
)
```

### 2. 内存管理

```dart
class MyController extends GetxController {
  final controllers = <TextEditingController>[];

  TextEditingController createController() {
    final controller = TextEditingController();
    controllers.add(controller);
    return controller;
  }

  @override
  void onClose() {
    // 批量释放控制器
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    super.onClose();
  }
}
```

## 常见问题解答

### Q: 下拉列表不显示怎么办？
A: 检查以下几点：
1. `getDropDownOptions` 是否返回非空列表
2. 是否有异步错误导致数据获取失败
3. `maxShowDropDownItems` 是否设置过小

### Q: 键盘导航不工作？
A: 确保：
1. 输入框已获得焦点
2. 下拉列表已显示
3. 没有其他组件拦截键盘事件

### Q: 如何实现搜索功能？
A: 使用自定义过滤：
```dart
filterOption: (option, input) {
  return option.toLowerCase().contains(input.toLowerCase());
}
```

### Q: 如何处理网络请求失败？
A: 在 `getDropDownOptions` 中添加错误处理：
```dart
getDropDownOptions: () async {
  try {
    return await apiService.getCities();
  } catch (e) {
    debugPrint('获取城市列表失败: $e');
    return ['默认选项'];
  }
}
```

## 参数速查表

### 核心参数
| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `textController` | `TextEditingController` | ✅ | - | 文本控制器 |
| `label` | `String` | ✅ | - | 输入框标签 |
| `hint` | `String?` | ❌ | `null` | 提示文字 |
| `enabled` | `bool` | ❌ | `true` | 是否启用 |
| `readOnly` | `bool` | ❌ | `false` | 是否只读 |
| `clearable` | `bool` | ❌ | `false` | 是否显示清除按钮 |

### 输入控制
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `keyboardType` | `TextInputType?` | `null` | 键盘类型 |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | 输入格式化器 |
| `maxLines` | `int?` | `1` | 最大行数 |
| `textAlign` | `TextAlign` | `TextAlign.start` | 文本对齐方式 |

### 下拉功能
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `getDropDownOptions` | `Future<List<String>> Function()?` | `null` | 获取下拉选项 |
| `onOptionSelected` | `ValueChanged<String>?` | `null` | 选项选择回调 |
| `leadingBuilder` | `Widget Function(String)?` | `null` | 选项前缀构建器 |
| `maxShowDropDownItems` | `int` | `5` | 最大显示选项数 |
| `dropdownMaxHeight` | `double?` | `200` | 下拉列表最大高度 |

### 样式定制
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `height` | `double?` | `null` | 输入框高度 |
| `borderRadius` | `double?` | `4.0` | 边框圆角 |
| `borderWidth` | `double?` | `1.0` | 边框宽度 |
| `backgroundColor` | `Color?` | `null` | 背景颜色 |
| `focusedBorderColor` | `Color` | `Color(0xFF64B5F6)` | 聚焦边框颜色 |
| `labelFontSize` | `double?` | `15.0` | 标签字体大小 |
| `textFontSize` | `double?` | `12.0` | 文本字体大小 |

## 更多示例

完整的使用示例请参考项目中的 `example/lib/pages/page6.dart` 文件，其中包含了各种使用场景的详细实现。

---

*最后更新：2025-08-07*
