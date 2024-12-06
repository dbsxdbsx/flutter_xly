import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart' as xml;

/// App重命名工具类
class AppRenamer {
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
    if (!manifestFile.existsSync()) return;

    final document = xml.XmlDocument.parse(await manifestFile.readAsString());
    final application = document.findAllElements('application').first;
    application.setAttribute('android:label', name);
    await manifestFile.writeAsString(document.toString());
  }

  /// 修改 iOS 应用名称
  static Future<void> _renameIOS(String name) async {
    final plistFile = File('ios/Runner/Info.plist');
    if (!plistFile.existsSync()) return;

    String content = await plistFile.readAsString();
    content = _replacePlistValue(content, 'CFBundleName', name);
    await plistFile.writeAsString(content);
  }

  /// 修改 Web 应用名称
  static Future<void> _renameWeb(String name) async {
    final htmlFile = File('web/index.html');
    if (!htmlFile.existsSync()) return;

    final document = xml.XmlDocument.parse(await htmlFile.readAsString());
    final title = document.findAllElements('title').first;
    title.children.clear();
    title.children.add(xml.XmlText(name));
    await htmlFile.writeAsString(document.toString());
  }

  /// 修改 Windows 应用名称
  static Future<void> _renameWindows(String name) async {
    // 修改 main.cpp 中的窗口标题
    final cppFile = File('windows/runner/main.cpp');
    if (cppFile.existsSync()) {
      String content = await cppFile.readAsString();
      final regex = RegExp(r'window.SetTitle\(".*"\);');
      content = content.replaceAll(regex, 'window.SetTitle("$name");');
      await cppFile.writeAsString(content);
    }

    // 修改 Runner.rc 中的应用信息
    final rcFile = File('windows/runner/Runner.rc');
    if (rcFile.existsSync()) {
      String content = await rcFile.readAsString();

      // 定义需要替换的值
      final replacements = {
        r'VALUE "FileDescription", ".*?"': 'VALUE "FileDescription", "$name"',
        r'VALUE "InternalName", ".*?"': 'VALUE "InternalName", "$name"',
        r'VALUE "OriginalFilename", ".*?"': 'VALUE "OriginalFilename", "$name.exe"',
        r'VALUE "ProductName", ".*?"': 'VALUE "ProductName", "$name"',
        // 可选：如果需要也修改公司名称
        // r'VALUE "CompanyName", ".*?"': 'VALUE "CompanyName", "你的公司名"',
      };

      // 执行所有替换
      for (final entry in replacements.entries) {
        final regex = RegExp(entry.key);
        content = content.replaceAll(regex, '${entry.value} "\\0"');
      }

      await rcFile.writeAsString(content);
    }
  }

  /// 修改 Linux 应用名称
  static Future<void> _renameLinux(String name) async {
    final ccFile = File('linux/my_application.cc');
    if (!ccFile.existsSync()) return;

    String content = await ccFile.readAsString();
    final regex = RegExp(r'gtk_window_set_title\(window, ".*"\);');
    content = content.replaceAll(regex, 'gtk_window_set_title(window, "$name");');
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
    return content.replaceAll(keyRegex, '<key>$key</key>\n\t<string>$value</string>');
  }
}