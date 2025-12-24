// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'generate.dart' as generate;
import 'rename.dart' as rename;
import 'win_setup.dart' as win_setup;

/// 检测是否在 Git Bash 或其他 UTF-8 终端中运行
bool _isUtf8Terminal() {
  // Git Bash 设置 MSYSTEM 环境变量
  // 或者 TERM 环境变量通常表示 Unix-like 终端
  final msystem = Platform.environment['MSYSTEM'];
  final term = Platform.environment['TERM'];
  final lang = Platform.environment['LANG'] ?? '';

  return msystem != null ||
      term != null ||
      lang.toLowerCase().contains('utf-8') ||
      lang.toLowerCase().contains('utf8');
}

/// 读取一行输入，自动处理编码
String? _readLine() {
  if (_isUtf8Terminal()) {
    return stdin.readLineSync(encoding: utf8);
  }
  return stdin.readLineSync();
}

/// XLY 工具包主入口
///
/// 使用方式：
/// ```bash
/// dart run xly           # 显示交互式菜单
/// dart run xly help      # 显示帮助信息
/// dart run xly <command> # 直接执行子命令
/// ```
void main(List<String> args) async {
  // 如果有参数，尝试直接执行子命令
  if (args.isNotEmpty) {
    final command = args[0].toLowerCase();
    final subArgs = args.length > 1 ? args.sublist(1) : <String>[];

    switch (command) {
      case 'generate':
        generate.main(subArgs);
        return;
      case 'rename':
        rename.main(subArgs);
        return;
      case 'win_setup':
      case 'win-setup':
      case 'winsetup':
        win_setup.main(subArgs);
        return;
      case 'help':
      case '-h':
      case '--help':
        _showHelp();
        return;
      default:
        print('❌ 未知命令: $command\n');
        _showHelp();
        exit(1);
    }
  }

  // 无参数时显示交互式菜单
  await _showInteractiveMenu();
}

/// 显示交互式菜单
Future<void> _showInteractiveMenu() async {
  print('');
  print('╔════════════════════════════════════════════════════════╗');
  print('║             🎯 XLY Flutter 工具包                      ║');
  print('╠════════════════════════════════════════════════════════╣');
  print('║                                                        ║');
  print('║  [1] generate   - 生成应用图标                         ║');
  print('║  [2] rename     - 重命名应用（修改显示名称）           ║');
  print('║  [3] win_setup  - Windows 静默启动补丁                 ║');
  print('║                                                        ║');
  print('║  [h] help       - 显示帮助信息                         ║');
  print('║  [q] quit       - 退出                                 ║');
  print('║                                                        ║');
  print('╚════════════════════════════════════════════════════════╝');
  print('');
  stdout.write('请选择命令 (1-3/h/q): ');

  // 自动检测终端编码
  final input = _readLine()?.trim().toLowerCase() ?? '';

  switch (input) {
    case '1':
    case 'generate':
      print('\n📦 已选择: generate (生成应用图标)\n');
      print(
          '⚠️  如路径含非 ASCII 字符（如中文、日文等），请直接运行: dart run xly:generate icon "路径"\n');
      stdout.write('请输入图标路径: ');
      final iconPath = _readLine()?.trim() ?? '';
      if (iconPath.isEmpty) {
        print('❌ 未输入图标路径，已取消');
        exit(1);
      }
      // 使用 Process.start + inheritStdio 实时显示输出
      final genProcess = await Process.start(
        'dart',
        ['run', 'xly:generate', 'icon', iconPath],
        runInShell: true,
        mode: ProcessStartMode.inheritStdio,
      );
      await genProcess.exitCode;
      break;

    case '2':
    case 'rename':
      print('\n📦 已选择: rename (重命名应用)\n');
      print(
          '⚠️  如名称含非 ASCII 字符（如中文、日文等），请直接运行: dart run xly:rename all "名称"\n');
      stdout.write('请输入新的应用名称: ');
      final appName = _readLine()?.trim() ?? '';
      if (appName.isEmpty) {
        print('❌ 未输入应用名称，已取消');
        exit(1);
      }
      // 使用 Process.start + inheritStdio 实时显示输出
      final renameProcess = await Process.start(
        'dart',
        ['run', 'xly:rename', 'all', appName],
        runInShell: true,
        mode: ProcessStartMode.inheritStdio,
      );
      await renameProcess.exitCode;
      break;

    case '3':
    case 'win_setup':
    case 'win-setup':
    case 'winsetup':
      print('\n📦 已选择: win_setup (Windows 静默启动补丁)\n');
      stdout.write('项目目录 (默认为当前目录 ".", 直接回车使用默认): ');
      final projectDir = _readLine()?.trim() ?? '';
      final winCmdArgs = ['run', 'xly:win_setup'];
      if (projectDir.isNotEmpty) {
        winCmdArgs.addAll(['--project-dir', projectDir]);
      }
      // 使用 Process.start 以支持交互式输入（如询问是否生成 .clangd）
      final process = await Process.start(
        'dart',
        winCmdArgs,
        runInShell: true,
        mode: ProcessStartMode.inheritStdio,
      );
      await process.exitCode;
      break;

    case 'h':
    case 'help':
      _showHelp();
      break;

    case 'q':
    case 'quit':
    case 'exit':
    case '':
      print('👋 再见！');
      exit(0);

    default:
      print('❌ 无效选择: $input');
      exit(1);
  }
}

/// 显示帮助信息
void _showHelp() {
  print('''
╔════════════════════════════════════════════════════════════════════╗
║                    🎯 XLY Flutter 工具包                           ║
╚════════════════════════════════════════════════════════════════════╝

用法:
  dart run xly                    显示交互式菜单
  dart run xly <command> [args]   直接执行子命令
  dart run xly help               显示此帮助信息

可用命令:
  generate    生成应用图标
              示例: dart run xly generate icon "assets/app_icon.png"
              或者: dart run xly:generate icon "assets/app_icon.png"

  rename      重命名应用（修改所有平台的显示名称）
              示例: dart run xly rename all "My App"
              或者: dart run xly:rename all "我的应用"

  win_setup   为 Windows 应用打补丁以支持静默启动
              示例: dart run xly win_setup --project-dir .
              或者: dart run xly:win_setup

提示:
  - 直接运行 `dart run xly` 可通过菜单交互式选择命令
  - 每个命令也可以单独运行，如 `dart run xly:generate`
''');
}
