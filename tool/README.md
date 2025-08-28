# XLY 开发工具

⚠️ **重要提醒**：此目录包含的是开发工具，**不应在 Flutter 应用代码中导入使用**！

## 目录说明

此目录包含 XLY 包的内部开发工具，这些工具仅供命令行使用，不是公共 API 的一部分。

### 包含的工具

- `app_renamer.dart` - 应用重命名工具的核心实现
- `icon_generator.dart` - 应用图标生成工具的核心实现

## 鸣谢

### 应用重命名功能
基于 [rename_app](https://github.com/Syed-Waleed-Shah/rename_app) 项目进行了修改和优化。
感谢原作者 [Syed Waleed Shah](https://github.com/Syed-Waleed-Shah) 的优秀工作！

### 应用图标生成功能
参考了 [icons_launcher](https://pub.dev/packages/icons_launcher) 包的实现思路，并进行了简化。
感谢 [Mrr Hak](https://github.com/mrrhak) 提供的优秀图标生成解决方案！

## 正确使用方式

### ✅ 正确用法（命令行）

#### 应用重命名
```bash
# 为所有平台设置相同名称
dart run xly:rename all="应用名称"

# 为不同平台设置不同名称
dart run xly:rename android="Android版本" ios="iOS版本"
```

#### 应用图标生成
```bash
dart run xly:generate icon="assets/app_icon.png"
dart run xly:generate icon="images/logo.jpeg"
```

**图标生成工具特性：**
- **跨平台智能检测**：自动检测项目中存在的平台目录，无论开发者使用什么操作系统，都会为所有目标平台生成图标
- 支持PNG、JPEG、JPG格式输入
- 为每个平台生成符合规范的图标尺寸
- 自动创建必要的目录结构和配置文件
- **🆕 自动托盘图标支持**：为桌面平台（Windows、macOS、Linux）自动复制图标到Flutter assets，确保MyTray托盘图标与应用图标完全一致
- **🆕 自动更新pubspec.yaml**：自动添加必要的assets路径声明，无需手动配置
- 建议源图标尺寸：1024x1024像素或更大

**托盘图标一致性保证：**
使用图标生成工具后，MyTray会自动使用与应用窗口图标相同的图标，无论是VSCode F5调试还是从应用目录直接运行，都能保持完美一致的视觉效果。

**📁 关于生成的图标文件：**
工具会在 `assets/_auto_tray_icon_gen/` 目录下生成两种格式的图标文件：
- `app_icon.ico`：Windows 平台专用，支持多尺寸，托盘显示更清晰
- `app_icon.png`：macOS/Linux 平台专用，系统推荐格式
- **无冗余**：MyTray 运行时会根据当前平台自动选择正确格式，不会误用另一种
- **体积极小**：两个文件总计通常不超过 50KB，换取跨平台最佳显示效果

**⚠️ Windows 图标缓存注意事项：**
在 Windows 10/11 系统中，更换图标后需要注意：
1. **托盘图标**：重新构建应用后立即生效 ✅
2. **应用图标**（任务栏/文件管理器）：可能因系统图标缓存而显示旧图标
3. **解决方法**：
   - 重启系统以清除图标缓存

**更多自定义需求：**
如需更高级的图标配置（如Android自适应图标、iOS深色/着色变体等），请使用原始的 [icons_launcher](https://pub.dev/packages/icons_launcher) 包。

### ❌ 错误用法（请勿在代码中导入）
```dart
// 不要这样做！
import 'package:xly/tool/app_renamer.dart';   // ❌
import 'package:xly/tool/icon_generator.dart'; // ❌
import '../tool/app_renamer.dart';             // ❌
import '../tool/icon_generator.dart';          // ❌

// 正确的做法是使用 XLY 的公共 API
import 'package:xly/xly.dart';                 // ✅
```

## 开发者注意事项

如果你是 XLY 包的维护者：
- 此目录中的文件可以自由修改，不需要考虑向后兼容性
- 添加新工具时，请更新此 README
- 确保工具不会被意外导出到公共 API 中
