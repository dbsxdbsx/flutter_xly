// ignore_for_file: avoid_print

import 'dart:io';
import '../tool/icon_generator.dart';

/// 生成工具命令行入口
///
/// 使用方式：
/// ```bash
/// dart run xly:generate icon="path/to/icon.png"
/// ```
void main(List<String> args) async {
  if (args.isEmpty) {
    _showHelp();
    return;
  }

  // 解析参数
  final params = _parseArgs(args);

  if (params.containsKey('icon')) {
    final iconPath = params['icon']!;
    print('🎨 开始生成应用图标...\n');

    final generator = IconGenerator();
    await generator.generateIcons(iconPath);

    print('\n🎉 图标生成完成！');
  } else {
    print('❌ 未识别的命令参数');
    _showHelp();
    exit(1);
  }
}

/// 解析命令行参数
Map<String, String> _parseArgs(List<String> args) {
  final params = <String, String>{};
  for (final arg in args) {
    if (arg.contains('=')) {
      final parts = arg.split('=');
      if (parts.length == 2) {
        params[parts[0]] = parts[1].replaceAll('"', '');
      }
    }
  }
  return params;
}

/// 显示帮助信息
void _showHelp() {
  print('XLY 生成工具 - 为Flutter应用生成资源文件');
  print('\n用法:');
  print('  dart run xly:generate icon="path/to/icon.png"');
  print('\n参数说明:');
  print('  icon="图标路径"    从指定图标生成所有平台的应用图标');
  print('\n支持的图像格式: PNG, JPEG, JPG');
  print('建议源图标尺寸: 1024x1024 像素或更大');
  print('\n示例:');
  print('  dart run xly:generate icon="assets/app_icon.png"');
  print('  dart run xly:generate icon="images/logo.jpg"');
}
