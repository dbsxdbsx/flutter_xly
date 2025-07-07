# XLY 开发工具

⚠️ **重要提醒**：此目录包含的是开发工具，**不应在 Flutter 应用代码中导入使用**！

## 目录说明

此目录包含 XLY 包的内部开发工具，这些工具仅供命令行使用，不是公共 API 的一部分。

### 包含的工具

- `app_renamer.dart` - 应用重命名工具的核心实现

## 鸣谢

应用重命名功能基于 [rename_app](https://github.com/Syed-Waleed-Shah/rename_app) 项目进行了修改和优化。

感谢原作者 [Syed Waleed Shah](https://github.com/Syed-Waleed-Shah) 的优秀工作！

## 正确使用方式

### ✅ 正确用法（命令行）
```bash
# 为所有平台设置相同名称
dart run xly:rename all="应用名称"

# 为不同平台设置不同名称
dart run xly:rename android="Android版本" ios="iOS版本"
```

### ❌ 错误用法（请勿在代码中导入）
```dart
// 不要这样做！
import 'package:xly/tool/app_renamer.dart';  // ❌
import '../tool/app_renamer.dart';            // ❌

// 正确的做法是使用 XLY 的公共 API
import 'package:xly/xly.dart';                // ✅
```

## 开发者注意事项

如果你是 XLY 包的维护者：
- 此目录中的文件可以自由修改，不需要考虑向后兼容性
- 添加新工具时，请更新此 README
- 确保工具不会被意外导出到公共 API 中
