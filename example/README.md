# XLY Example

## 应用重命名功能测试

在 example 项目目录下，你可以使用以下命令来测试重命名功能：

### 为所有平台设置相同名称
```bash
dart run xly:rename all="新应用名称"
```

### 为不同平台设置不同名称
```bash
# 设置 Android 和 iOS 平台名称
dart run xly:rename android="Android版本" ios="iOS版本"

# 为所有平台分别设置名称
dart run xly:rename android="Android版本" ios="iOS版本" web="Web版本" windows="Windows版本" linux="Linux版本" mac="Mac版本"
```

注意：重命名操作会修改项目配置文件，建议在进行重命名操作前先提交或备份当前代码。
