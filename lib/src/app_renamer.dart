import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart' as xml;

/// App重命名工具类
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
  static Map<String, String> _parseArgs(List<String> args) {
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

  /// 修改 Android 应用名称
  static Future<void> _renameAndroid(String name) async {
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
  }

  /// 修改 iOS 应用名称
  static Future<void> _renameIOS(String name) async {
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
      _logError('Web', e.toString());
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
      _logError('Windows', e.toString());
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
    final ccFile = File('linux/my_application.cc');
    if (!ccFile.existsSync()) return;

    String content = await ccFile.readAsString();
    final regex = RegExp(r'gtk_window_set_title\(window, ".*"\);');
    content =
        content.replaceAll(regex, 'gtk_window_set_title(window, "$name");');
    await ccFile.writeAsString(content);
  }

  /// 修改 macOS 应用名称
  static Future<void> _renameMacOS(String name) async {
    final plistFile = File('macos/Runner/Info.plist');
    if (!plistFile.existsSync()) return;

    String content = await plistFile.readAsString();
    content = _replacePlistValue(content, 'CFBundleName', name);
    await plistFile.writeAsString(content);
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

  /// 打印跳过消息
  static void _logSkipped(String platform, String reason) {
    print('⏭️ 跳过 [$platform] 平台的重命名: $reason');
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

      // 查找 MyApp.initialize 调用
      final initializeRegex = RegExp(r'MyApp\.initialize\(([\s\S]*?)\);');
      final match = initializeRegex.firstMatch(content);

      if (match == null) {
        _logSkipped(_mainDartFile, '找不到 MyApp.initialize 调用');
        return;
      }

      final initializeContent = match.group(1)!;

      // 检查是否已经有 appName 参数，使用原始字符串避免转义问题
      final appNameRegex = RegExp(r'''appName:\s*(['"]).*?\1''');
      if (appNameRegex.hasMatch(initializeContent)) {
        // 替换现有的 appName 值
        content = content.replaceAll(
          appNameRegex,
          '''appName: "$name"'''
        );
      } else {
        // 在第一个参数后添加 appName
        content = content.replaceAll(
          'MyApp.initialize(',
          'MyApp.initialize(\n      appName: "$name",',
        );
      }

      await mainFile.writeAsString(content);
      print('✅ 已成功修改、格式化[$_mainDartFile] appName字段部分');

      // 运行 dart format 命令格式化文件
      try {
        await Process.run('dart', ['format', mainFile.path]);
      } catch (e) {
        print('⚠️ 运行格式化命令失败: $e');
      }
    } catch (e) {
      _logError(_mainDartFile, e.toString());
    }
  }
}
