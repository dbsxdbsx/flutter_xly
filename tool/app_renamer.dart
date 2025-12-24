// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart' as xml;

/// App重命名工具类
///
/// ⚠️ 警告：此类仅供命令行工具使用，不应在Flutter应用代码中导入！
///
/// 使用方式：
/// ```bash
/// # 为所有平台设置相同名称
/// dart run xly:rename all "好人 平安"
///
/// # 为不同平台设置不同名称
/// dart run xly:rename android "Android版" ios "iOS版"
/// ```
///
/// 如果你在Flutter代码中看到此导入，请立即移除：
/// ```dart
/// // ❌ 错误用法 - 不要这样做！
/// import 'package:xly/src/app_renamer.dart';
/// ```
class AppRenamer {
  // 文件路径常量
  static const String _mainDartFile = 'lib/main.dart';

  /// 命令行入口
  static Future<void> main(List<String> args) async {
    // 解析命令行参数
    final params = _parseArgs(args);

    if (params.containsKey('all')) {
      await renameForAll(params['all']!);
    } else {
      await renameForPlatforms(
        androidName: params['android'],
        iosName: params['ios'],
        webName: params['web'],
        windowsName: params['windows'],
        linuxName: params['linux'],
        macName: params['mac'],
      );
    }
  }

  /// 为所有平台设置相同的应用名称
  static Future<void> renameForAll(String appName) async {
    await renameForPlatforms(
      androidName: appName,
      iosName: appName,
      webName: appName,
      windowsName: appName,
      linuxName: appName,
      macName: appName,
    );

    // 更新 main.dart
    await _updateMainDartInitialize(appName);
  }

  /// 为指定平台设置不同的应用名称
  static Future<void> renameForPlatforms({
    String? androidName,
    String? iosName,
    String? webName,
    String? windowsName,
    String? linuxName,
    String? macName,
  }) async {
    if (androidName != null) await _renameAndroid(androidName);
    if (iosName != null) await _renameIOS(iosName);
    if (webName != null) await _renameWeb(webName);
    if (windowsName != null) await _renameWindows(windowsName);
    if (linuxName != null) await _renameLinux(linuxName);
    if (macName != null) await _renameMacOS(macName);
  }

  /// 解析命令行参数
  ///
  /// 使用 `<field> "<content>"` 风格，例如：
  /// - `dart run xly:rename all "好人 平安"` → appName = "好人 平安"
  /// - `dart run xly:rename android "Android版" ios "iOS版"`
  static Map<String, String> _parseArgs(List<String> args) {
    final params = <String, String>{};
    final validKeys = [
      'all',
      'android',
      'ios',
      'web',
      'windows',
      'linux',
      'mac'
    ];

    int i = 0;
    while (i < args.length) {
      final key = args[i];

      // 如果是有效的 key，下一个参数就是值
      if (validKeys.contains(key) && i + 1 < args.length) {
        final value = args[i + 1].replaceAll('"', '');
        params[key] = value;
        i += 2;
        continue;
      }
      i++;
    }
    return params;
  }

  /// 修改 Android 应用名称
  static Future<void> _renameAndroid(String name) async {
    try {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      if (!manifestFile.existsSync()) {
        _logSkipped('Android', '找不到 AndroidManifest.xml 文件');
        return;
      }

      final document = xml.XmlDocument.parse(await manifestFile.readAsString());
      final application = document.findAllElements('application').first;
      application.setAttribute('android:label', name);
      await manifestFile.writeAsString(document.toString());
      _logSuccess('Android', name);
    } catch (e) {
      _logError('Android', _getFriendlyErrorMessage(e));
    }
  }

  /// 修改 iOS 应用名称
  static Future<void> _renameIOS(String name) async {
    try {
      final plistPaths = [
        'ios/Runner/Info.plist',
        'ios/Runner/Info-Debug.plist',
        'ios/Runner/Info-Release.plist'
      ];

      for (final plistPath in plistPaths) {
        final plistFile = File(plistPath);
        if (!plistFile.existsSync()) continue;

        final document = xml.XmlDocument.parse(await plistFile.readAsString());
        var keys = document
            .findElements('plist')
            .first
            .findElements('dict')
            .first
            .children;

        // 移除由换行符生成的 XmlText 元素
        keys.removeWhere((element) => element is xml.XmlText);

        // 修改 CFBundleName 和 CFBundleDisplayName
        for (int i = 0; i < keys.length; i++) {
          if (keys[i].innerText == 'CFBundleName' ||
              keys[i].innerText == 'CFBundleDisplayName') {
            var value = xml.XmlElement(xml.XmlName('string'));
            value.innerText = name;
            keys.removeAt(i + 1);
            keys.insert(i + 1, value);
          }
        }

        await plistFile.writeAsString(document.toXmlString(pretty: true));
      }
      _logSuccess('iOS', name);
    } catch (e) {
      _logError('iOS', _getFriendlyErrorMessage(e));
    }
  }

  /// 修改 Web 应用名称
  static Future<void> _renameWeb(String name) async {
    try {
      // 修改 index.html
      final htmlFile = File('web/index.html');
      if (htmlFile.existsSync()) {
        String content = await htmlFile.readAsString();

        // 使用正则表达式替换 title 标签内容
        final titleRegex = RegExp(r'<title>.*?</title>');
        content = content.replaceAll(titleRegex, '<title>$name</title>');

        await htmlFile.writeAsString(content);
      }

      // 修改 manifest.json
      final manifestFile = File('web/manifest.json');
      if (manifestFile.existsSync()) {
        final content = await manifestFile.readAsString();
        final Map<String, dynamic> manifest = jsonDecode(content);

        if (manifest.containsKey('name')) {
          manifest['name'] = name;
        }
        if (manifest.containsKey('short_name')) {
          manifest['short_name'] = name;
        }

        final encoder = const JsonEncoder.withIndent('  ');
        await manifestFile.writeAsString(encoder.convert(manifest));
      }
      _logSuccess('Web', name);
    } catch (e) {
      _logError('Web', _getFriendlyErrorMessage(e));
    }
  }

  /// 修改 Windows 应用名称
  static Future<void> _renameWindows(String name) async {
    try {
      // 修改 main.cpp
      final cppFile = File('windows/runner/main.cpp');
      if (cppFile.existsSync()) {
        String content = await cppFile.readAsString();

        // 使用更精确的正则表达式，并确保正确处理 Unicode 字符串
        final appNameLine = RegExp(r'if \(!window\.Create\(L"[^"]*"')
            .firstMatch(content)
            ?.group(0);
        if (appNameLine != null) {
          // 对于非 ASCII 字符，我们使用 UTF-16 编码的十六进制表示
          final encodedName = _encodeWindowsString(name);
          content = content.replaceAll(
              appNameLine, 'if (!window.Create(L"$encodedName"');
          await cppFile.writeAsString(content);
        }
      }

      // 修改 Runner.rc
      final rcFile = File('windows/runner/Runner.rc');
      if (rcFile.existsSync()) {
        String content = await rcFile.readAsString();

        final replacements = {
          r'VALUE "FileDescription", "[^"]*"':
              'VALUE "FileDescription", "$name\\0"',
          r'VALUE "InternalName", "[^"]*"': 'VALUE "InternalName", "$name\\0"',
          r'VALUE "OriginalFilename", "[^"]*"':
              'VALUE "OriginalFilename", "$name.exe\\0"',
          r'VALUE "ProductName", "[^"]*"': 'VALUE "ProductName", "$name\\0"',
        };

        for (final entry in replacements.entries) {
          final regex = RegExp(entry.key);
          content = content.replaceAll(regex, entry.value);
        }

        await rcFile.writeAsString(content);
      }
      _logSuccess('Windows', name);
    } catch (e) {
      _logError('Windows', _getFriendlyErrorMessage(e));
    }
  }

  /// 将 Unicode 字符串编为 Windows 可用的格式
  static String _encodeWindowsString(String input) {
    if (input.codeUnits.every((unit) => unit < 128)) {
      return input; // ASCII 字符直接返回
    }

    // 将非 ASCII 字符转换为 UTF-16 编码的形式
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      if (codeUnit < 128) {
        buffer.write(String.fromCharCode(codeUnit));
      } else {
        // 使用 \u 转义序列
        buffer.write('\\u${codeUnit.toRadixString(16).padLeft(4, '0')}');
      }
    }
    return buffer.toString();
  }

  /// 修改 Linux 应用名称
  static Future<void> _renameLinux(String name) async {
    try {
      final ccFile = File('linux/my_application.cc');
      if (!ccFile.existsSync()) {
        _logSkipped('Linux', '找不到 my_application.cc 文件');
        return;
      }

      String content = await ccFile.readAsString();
      final regex = RegExp(r'gtk_window_set_title\(window, ".*"\);');
      content =
          content.replaceAll(regex, 'gtk_window_set_title(window, "$name");');
      await ccFile.writeAsString(content);
      _logSuccess('Linux', name);
    } catch (e) {
      _logError('Linux', _getFriendlyErrorMessage(e));
    }
  }

  /// 修改 macOS 应用名称
  static Future<void> _renameMacOS(String name) async {
    try {
      final plistFile = File('macos/Runner/Info.plist');
      if (!plistFile.existsSync()) {
        _logSkipped('macOS', '找不到 Info.plist 文件');
        return;
      }

      String content = await plistFile.readAsString();
      content = _replacePlistValue(content, 'CFBundleName', name);
      await plistFile.writeAsString(content);
      _logSuccess('macOS', name);
    } catch (e) {
      _logError('macOS', _getFriendlyErrorMessage(e));
    }
  }

  /// 替换 plist 文件中的值
  static String _replacePlistValue(String content, String key, String value) {
    final keyRegex = RegExp('<key>$key</key>\\s*<string>.*?</string>');
    return content.replaceAll(
        keyRegex, '<key>$key</key>\n\t<string>$value</string>');
  }

  /// 打印成功消息
  static void _logSuccess(String platform, String name) {
    print('✅ 成功重命名 [$platform] 平台的应用为: "$name"');
  }

  /// 打印错误消息
  static void _logError(String platform, String error) {
    print('❌ 重命名 [$platform] 平台应用时出错: $error');
  }

  /// 检测是否为文件锁定错误，并返回友好的错误信息
  static String _getFriendlyErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    // 检测常见的文件锁定/访问拒绝错误
    if (errorStr.contains('access') ||
        errorStr.contains('denied') ||
        errorStr.contains('locked') ||
        errorStr.contains('being used') ||
        errorStr.contains('permission') ||
        errorStr.contains('cannot open') ||
        errorStr.contains('sharing violation')) {
      return '文件被占用，可能是应用正在运行中。请先关闭 Flutter 应用后再试。';
    }
    return error.toString();
  }

  /// 打印跳过消息
  static void _logSkipped(String platform, String reason) {
    print('🚫 跳过 [$platform]: $reason');
  }

  /// 修改 main.dart 中的 MyApp.initialize 配置
  static Future<void> _updateMainDartInitialize(String name) async {
    final mainFile = File(_mainDartFile);
    if (!mainFile.existsSync()) {
      _logSkipped(_mainDartFile, '找不到 $_mainDartFile 文件');
      return;
    }

    try {
      String content = await mainFile.readAsString();

      // 首先检查是否整个 MyApp.initialize 调用被注释
      final commentedInitRegex =
          RegExp(r'^\s*\/\/.*MyApp\.initialize\(', multiLine: true);
      if (commentedInitRegex.hasMatch(content)) {
        _logSkipped(_mainDartFile, '找到的 MyApp.initialize 调用已被注释');
        return;
      }

      // 查找未注释的 MyApp.initialize 调用
      final initializeRegex =
          RegExp(r'(?<!\/\/\s*)MyApp\.initialize\(([\s\S]*?)\);');
      final match = initializeRegex.firstMatch(content);

      if (match == null) {
        _logSkipped(_mainDartFile, '找不到未注释的 MyApp.initialize 调用');
        return;
      }

      // 查找并移除所有的 appName 参数（包括注释的和未注释的）
      final allAppNameRegex = RegExp(
          r'''^\s*(\/\/\s*)?appName:\s*(['"]).*?\2.*?(?=\s*[,，].*?\w+:|$)''',
          multiLine: true);
      content = content.replaceAll(allAppNameRegex, '');

      // 在 initialize 的开始位置添加新的 appName 参数
      content = content.replaceFirst(
        'MyApp.initialize(',
        'MyApp.initialize(\n      appName: "$name",',
      );

      // 清理可能产生的多余空行和逗号（包括全角逗号）
      content = content
          .replaceAll(RegExp(r'[,，](\s*[,，])+'), ',') // 移除多余的逗号（包括全角逗号）
          .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n'); // 移除多余的空行

      await mainFile.writeAsString(content);
      print('✅ 已成功修改、格式化[$_mainDartFile] appName字段部分');

      // 运行 dart format 命令格式化文件
      try {
        await Process.run('dart', ['format', mainFile.path]);
      } catch (e) {
        print('⚠️ 运行格式化命令失败: $e');
      }
    } catch (e) {
      _logError(_mainDartFile, _getFriendlyErrorMessage(e));
    }
  }
}
