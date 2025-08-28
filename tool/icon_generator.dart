// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart' as xml;

/// 图标生成工具类
///
/// ⚠️ 警告：此类仅供命令行工具使用，不应在Flutter应用代码中导入！
///
/// 使用方式：
/// ```bash
/// dart run tool/icon_generator.dart --source="assets/my_icon.png"
/// ```
class IconGenerator {
  /// 命令行入口
  static Future<void> main(List<String> args) async {
    print('🎨 开始生成应用图标...\n');

    final parser = ArgParser();
    parser.addOption('source', abbr: 's', help: '源图标文件路径 (PNG/JPEG/JPG)');
    parser.addFlag('help', abbr: 'h', help: '显示帮助信息', negatable: false);

    try {
      final results = parser.parse(args);

      if (results['help'] == true) {
        _showHelp(parser);
        return;
      }

      final sourcePath = results['source'] as String?;
      if (sourcePath == null || sourcePath.isEmpty) {
        print('❌ 错误：请指定源图标文件路径');
        print('使用 --help 查看帮助信息');
        exit(1);
      }

      final generator = IconGenerator();
      await generator.generateIcons(sourcePath);

      print('\n🎉 图标生成完成！');
    } catch (e) {
      print('❌ 参数解析错误: $e');
      _showHelp(parser);
      exit(1);
    }
  }

  /// 显示帮助信息
  static void _showHelp(ArgParser parser) {
    print('图标生成工具 - 为Flutter应用生成所有平台的图标');
    print('\n用法:');
    print('  dart run tool/icon_generator.dart --source="path/to/icon.png"');
    print('\n选项:');
    print(parser.usage);
    print('\n支持的图像格式: PNG, JPEG, JPG');
    print('建议源图标尺寸: 1024x1024 像素或更大');
  }

  /// 生成所有平台图标
  Future<void> generateIcons(String sourcePath) async {
    // 验证源文件
    if (!await _validateSourceFile(sourcePath)) {
      return;
    }

    // 加载源图像
    final sourceImage = await _loadImage(sourcePath);
    if (sourceImage == null) {
      print('❌ 无法加载图像文件: $sourcePath');
      return;
    }

    print('✅ 成功加载源图像: ${sourceImage.width}x${sourceImage.height}');

    // 检测项目中存在的平台
    final platforms = await _detectPlatforms();
    if (platforms.isEmpty) {
      print('❌ 未检测到任何支持的平台目录');
      return;
    }

    print('📱 检测到平台: ${platforms.join(', ')}');

    // 为每个平台生成图标
    for (final platform in platforms) {
      await _generatePlatformIcons(platform, sourceImage);
    }

    // 更新配置文件
    if (platforms.contains('android')) {
      await _updateAndroidManifest();
    }
  }

  /// 验证源文件
  Future<bool> _validateSourceFile(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      print('❌ 文件不存在: $sourcePath');
      return false;
    }

    final extension = path.extension(sourcePath).toLowerCase();
    if (!['.png', '.jpg', '.jpeg'].contains(extension)) {
      print('❌ 不支持的文件格式: $extension');
      print('支持的格式: PNG, JPEG, JPG');
      return false;
    }

    return true;
  }

  /// 加载图像
  Future<img.Image?> _loadImage(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      print('❌ 加载图像失败: $e');
      return null;
    }
  }

  /// 检测项目中存在的平台
  Future<List<String>> _detectPlatforms() async {
    final platforms = <String>[];

    final platformDirs = {
      'android': 'android',
      'ios': 'ios',
      'windows': 'windows',
      'macos': 'macos',
      'linux': 'linux',
      'web': 'web',
    };

    for (final entry in platformDirs.entries) {
      if (await Directory(entry.value).exists()) {
        platforms.add(entry.key);
      }
    }

    return platforms;
  }

  /// 为指定平台生成图标
  Future<void> _generatePlatformIcons(
      String platform, img.Image sourceImage) async {
    print('\n🔧 正在为 $platform 平台生成图标...');

    switch (platform) {
      case 'android':
        await _generateAndroidIcons(sourceImage);
        break;
      case 'ios':
        await _generateIosIcons(sourceImage);
        break;
      case 'windows':
        await _generateWindowsIcons(sourceImage);
        await _copyTrayIconToAssets(platform, sourceImage);
        break;
      case 'macos':
        await _generateMacosIcons(sourceImage);
        await _copyTrayIconToAssets(platform, sourceImage);
        break;
      case 'linux':
        await _generateLinuxIcons(sourceImage);
        await _copyTrayIconToAssets(platform, sourceImage);
        break;
      case 'web':
        await _generateWebIcons(sourceImage);
        break;
      default:
        print('⚠️ 不支持的平台: $platform');
    }
  }

  /// 生成Android图标
  Future<void> _generateAndroidIcons(img.Image sourceImage) async {
    // Android标准图标尺寸
    final iconSizes = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final entry in iconSizes.entries) {
      final dir = 'android/app/src/main/res/${entry.key}';
      await _createDirectoryIfNotExists(dir);
      await _saveResizedImage(sourceImage, entry.value, '$dir/ic_launcher.png');
    }

    print('✅ Android 图标生成完成');
  }

  /// 生成iOS图标
  Future<void> _generateIosIcons(img.Image sourceImage) async {
    // iOS图标尺寸 (基础尺寸 * 倍数)
    final iconSpecs = [
      {
        'size': 20,
        'scales': [2, 3]
      },
      {
        'size': 29,
        'scales': [2, 3]
      },
      {
        'size': 40,
        'scales': [2, 3]
      },
      {
        'size': 60,
        'scales': [2, 3]
      },
      {
        'size': 76,
        'scales': [2]
      },
      {
        'size': 83.5,
        'scales': [2]
      },
      {
        'size': 1024,
        'scales': [1]
      },
    ];

    final dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    await _createDirectoryIfNotExists(dir);

    // 移除alpha通道（iOS要求）
    final processedImage = _removeAlphaChannel(sourceImage);

    for (final spec in iconSpecs) {
      final baseSize = spec['size'] as num;
      final scales = spec['scales'] as List<int>;

      for (final scale in scales) {
        final actualSize = (baseSize * scale).round();
        final filename = baseSize == 83.5
            ? 'Icon-App-83.5x83.5@${scale}x.png'
            : 'Icon-App-${baseSize.round()}x${baseSize.round()}@${scale}x.png';

        await _saveResizedImage(processedImage, actualSize, '$dir/$filename');
      }
    }

    // 生成Contents.json文件
    await _generateIosContentsJson(dir);

    print('✅ iOS 图标生成完成');
  }

  /// 移除alpha通道
  img.Image _removeAlphaChannel(img.Image image) {
    if (!image.hasAlpha) return image;

    final result = img.Image(width: image.width, height: image.height);
    img.fill(result, color: img.ColorRgb8(255, 255, 255));

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.a / 255.0;
        final r = ((pixel.r * alpha) + (255 * (1 - alpha))).round();
        final g = ((pixel.g * alpha) + (255 * (1 - alpha))).round();
        final b = ((pixel.b * alpha) + (255 * (1 - alpha))).round();
        result.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return result;
  }

  /// 生成Windows图标
  Future<void> _generateWindowsIcons(img.Image sourceImage) async {
    final sizes = [16, 24, 32, 48, 64, 96, 128, 256];
    final dir = 'windows/runner/resources';
    await _createDirectoryIfNotExists(dir);

    // 生成各种尺寸的PNG图像
    final images = <img.Image>[];
    for (final size in sizes) {
      images.add(img.copyResize(sourceImage, width: size, height: size));
    }

    // 保存为ICO文件
    await _saveIcoFile(images, '$dir/app_icon.ico');

    print('✅ Windows 图标生成完成');
  }

  /// 创建目录（如果不存在）
  Future<void> _createDirectoryIfNotExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 保存调整尺寸后的图像
  Future<void> _saveResizedImage(
      img.Image sourceImage, int size, String filePath) async {
    final resized = img.copyResize(sourceImage, width: size, height: size);
    final bytes = img.encodePng(resized);
    await File(filePath).writeAsBytes(bytes);
  }

  /// 保存ICO文件
  Future<void> _saveIcoFile(List<img.Image> images, String filePath) async {
    // 创建一个包含多个尺寸的图像
    final icoImage = img.Image(width: 256, height: 256);
    icoImage.frames = images;
    icoImage.frameType = img.FrameType.sequence;

    final bytes = img.encodeIco(icoImage);
    await File(filePath).writeAsBytes(bytes);
  }

  /// 生成macOS图标
  Future<void> _generateMacosIcons(img.Image sourceImage) async {
    // macOS图标规格
    final specs = [
      {
        'size': 16,
        'scales': [1, 2]
      },
      {
        'size': 32,
        'scales': [1, 2]
      },
      {
        'size': 128,
        'scales': [1, 2]
      },
      {
        'size': 256,
        'scales': [1, 2]
      },
      {
        'size': 512,
        'scales': [1, 2]
      },
    ];

    final dir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    await _createDirectoryIfNotExists(dir);

    for (final spec in specs) {
      final baseSize = spec['size'] as int;
      final scales = spec['scales'] as List<int>;

      for (final scale in scales) {
        final actualSize = baseSize * scale;
        final filename =
            'app_icon_${baseSize}x$baseSize${scale > 1 ? '@${scale}x' : ''}.png';
        await _saveResizedImage(sourceImage, actualSize, '$dir/$filename');
      }
    }

    // 生成Contents.json文件
    await _generateMacosContentsJson(dir);

    print('✅ macOS 图标生成完成');
  }

  /// 生成Linux图标
  Future<void> _generateLinuxIcons(img.Image sourceImage) async {
    final dir = 'snap/gui';
    await _createDirectoryIfNotExists(dir);
    await _saveResizedImage(sourceImage, 256, '$dir/app_icon.png');
    print('✅ Linux 图标生成完成');
  }

  /// 生成Web图标
  Future<void> _generateWebIcons(img.Image sourceImage) async {
    final iconDir = 'web/icons';
    await _createDirectoryIfNotExists(iconDir);

    // Web图标
    await _saveResizedImage(sourceImage, 192, '$iconDir/Icon-192.png');
    await _saveResizedImage(sourceImage, 512, '$iconDir/Icon-512.png');
    await _saveResizedImage(sourceImage, 192, '$iconDir/Icon-maskable-192.png');
    await _saveResizedImage(sourceImage, 512, '$iconDir/Icon-maskable-512.png');

    // Favicon
    await _saveResizedImage(sourceImage, 32, 'web/favicon.png');

    print('✅ Web 图标生成完成');
  }

  /// 生成iOS Contents.json文件
  Future<void> _generateIosContentsJson(String dir) async {
    final contentsJson = '''
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}''';

    await File('$dir/Contents.json').writeAsString(contentsJson);
  }

  /// 更新Android Manifest文件
  Future<void> _updateAndroidManifest() async {
    final manifestPath = 'android/app/src/main/AndroidManifest.xml';
    final manifestFile = File(manifestPath);

    if (!await manifestFile.exists()) {
      print('⚠️ Android Manifest文件不存在，跳过更新');
      return;
    }

    try {
      final content = await manifestFile.readAsString();
      final document = xml.XmlDocument.parse(content);

      // 查找application元素
      final application = document.findAllElements('application').first;

      // 确保图标属性正确设置
      application.setAttribute('android:icon', '@mipmap/ic_launcher');

      await manifestFile.writeAsString(document.toString());
      print('✅ 已更新 Android Manifest');
    } catch (e) {
      print('⚠️ 更新 Android Manifest 失败: $e');
    }
  }

  /// 生成macOS Contents.json文件
  Future<void> _generateMacosContentsJson(String dir) async {
    final contentsJson = '''
{
  "images" : [
    {
      "filename" : "app_icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "app_icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "app_icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "app_icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "app_icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "app_icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "app_icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "app_icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "app_icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "app_icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}''';

    await File('$dir/Contents.json').writeAsString(contentsJson);
  }

  /// 复制托盘图标到Flutter assets目录（用于MyTray运行时访问）
  Future<void> _copyTrayIconToAssets(
      String platform, img.Image sourceImage) async {
    print('🔄 正在复制托盘图标到Flutter assets...');

    String assetPath;
    String sourceFilePath;

    // 使用统一的 _auto_tray_icon_gen 文件夹，简化资产管理
    String fileName;
    switch (platform) {
      case 'windows':
        fileName = 'app_icon.ico';
        sourceFilePath = 'windows/runner/resources/app_icon.ico';
        break;
      case 'macos':
        fileName = 'app_icon.png'; // macOS 使用 PNG 格式
        sourceFilePath =
            'macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-512@2x.png';
        break;
      case 'linux':
        fileName = 'app_icon.png';
        sourceFilePath = 'snap/gui/app_icon.png';
        break;
      default:
        return; // 不支持的平台，跳过
    }

    assetPath = 'assets/_auto_tray_icon_gen/$fileName';

    // 创建assets目录
    final assetDir = path.dirname(assetPath);
    await _createDirectoryIfNotExists(assetDir);

    // 复制文件
    final sourceFile = File(sourceFilePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(assetPath);
      print('✅ 托盘图标已复制到: $assetPath');

      // 更新pubspec.yaml
      await _updatePubspecAssets(assetDir);
    } else {
      print('⚠️ 源文件不存在，跳过复制: $sourceFilePath');
    }
  }

  /// 更新pubspec.yaml的assets配置
  Future<void> _updatePubspecAssets(String assetDir) async {
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      print('⚠️ pubspec.yaml 文件不存在，跳过更新');
      return;
    }

    try {
      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');

      // 标准化资产路径（确保以/结尾）
      final normalizedAssetDir =
          assetDir.endsWith('/') ? assetDir : '$assetDir/';

      // 查找flutter和assets部分
      int flutterIndex = -1;
      int assetsIndex = -1;
      int assetsIndent = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim() == 'flutter:') {
          flutterIndex = i;
        } else if (flutterIndex != -1 && line.trim() == 'assets:') {
          assetsIndex = i;
          assetsIndent = line.length - line.trimLeft().length;
          break;
        }
      }

      // 检查是否已存在该资产路径
      bool assetExists = false;
      if (assetsIndex != -1) {
        for (int i = assetsIndex + 1; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isEmpty) continue;

          // 如果缩进不对，说明已经离开assets部分
          final currentIndent = line.length - line.trimLeft().length;
          if (currentIndent <= assetsIndent) break;

          if (line.trim() == '- $normalizedAssetDir') {
            assetExists = true;
            break;
          }
        }
      }

      if (!assetExists) {
        if (assetsIndex == -1) {
          // 没有assets部分，需要添加
          if (flutterIndex == -1) {
            // 没有flutter部分，添加完整的flutter配置
            lines.add('');
            lines.add('flutter:');
            lines.add('  uses-material-design: true');
            lines.add('  assets:');
            lines.add('    - $normalizedAssetDir');
          } else {
            // 有flutter部分，添加assets
            lines.insert(flutterIndex + 1, '  assets:');
            lines.insert(flutterIndex + 2, '    - $normalizedAssetDir');
          }
        } else {
          // 有assets部分，添加新的资产路径
          final assetIndentStr = ' ' * (assetsIndent + 2);
          lines.insert(assetsIndex + 1, '$assetIndentStr- $normalizedAssetDir');
        }

        await pubspecFile.writeAsString(lines.join('\n'));
        print('✅ 已更新 pubspec.yaml，添加资产路径: $normalizedAssetDir');
      } else {
        print('ℹ️ pubspec.yaml 中已存在资产路径: $normalizedAssetDir');
      }
    } catch (e) {
      print('⚠️ 更新 pubspec.yaml 失败: $e');
    }
  }
}

/// 程序入口点
void main(List<String> args) async {
  await IconGenerator.main(args);
}
