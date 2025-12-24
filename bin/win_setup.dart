import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

// 要查找和替换的代码块
const String kOriginalShowBlock = r'''
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });
''';

const String kPatchedShowBlock = r'''
  // XLY: Patched by xly package to support silent startup.
  // The original `this->Show()` call is commented out to allow Dart to control the window's visibility.
  // flutter_controller_->engine()->SetNextFrameCallback([&]() {
  //   this->Show();
  // });
''';

const String kOriginalForceRedrawLine =
    r'  flutter_controller_->ForceRedraw();';

const String kPatchedForceRedrawComment =
    r'  // XLY: The `ForceRedraw` call is also commented out as it is related to the initial auto-show logic.';

// .clangd 配置文件内容，用于抑制 clangd 对 Windows SDK 的误报
const String kClangdConfig = r'''# XLY: 由 xly 包自动生成
# 告诉 clangd 忽略 Flutter Windows runner 的头文件查找问题
# 这些文件在实际编译时由 CMake 正确配置路径
CompileFlags:
  Add:
    - "-Wno-error"
  Remove:
    - "-W*"

Diagnostics:
  Suppress:
    - "pp_file_not_found"
    - "undeclared_var_use"
    - "member_function_call_bad_type"
    - "no_member"
    - "unexpected_typedef"  # LRESULT 等 Windows SDK 类型的误报
  UnusedIncludes: None  # 禁用未使用头文件检查（clangd 无法正确解析 Windows SDK）
''';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'project-dir',
      abbr: 'p',
      help:
          'The root directory of the Flutter project to patch (containing the windows/runner/ directory).',
      valueHelp: 'path',
      defaultsTo: '.',
    )
    ..addFlag(
      'backup',
      abbr: 'b',
      help: 'Create a backup of the original file as flutter_window.cpp.bak.',
      defaultsTo: true,
      negatable: true,
    )
    ..addFlag(
      'dry-run',
      help: 'Perform a dry run: print the changes without writing to the file.',
      defaultsTo: false,
      negatable: false,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Print more detailed logs.',
      defaultsTo: false,
      negatable: false,
    )
    ..addFlag(
      'clangd',
      help:
          'Also generate a .clangd config file to suppress false positive warnings in C++ IDEs. Use --no-clangd to skip without prompting.',
      defaultsTo: null, // null = ask interactively, true = generate, false = skip
      negatable: true,
    );

  late ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    stdout.writeln(parser.usage);
    exit(64); // usage error
  }

  final projectDir = argResults['project-dir'] as String;
  final backup = argResults['backup'] as bool;
  final dryRun = argResults['dry-run'] as bool;
  final verbose = argResults['verbose'] as bool;
  // 检查用户是否显式指定了 --clangd 或 --no-clangd
  final clangdExplicitlySet = argResults.wasParsed('clangd');
  final clangdFlag = argResults['clangd'] as bool?;

  final targetFile =
      File(p.join(projectDir, 'windows', 'runner', 'flutter_window.cpp'));
  if (!await targetFile.exists()) {
    stderr.writeln('Target file not found: ${targetFile.path}');
    stderr.writeln(
        'Please ensure --project-dir points to a valid Flutter project directory.');
    exit(2);
  }

  if (verbose) {
    stdout.writeln('Target file: ${targetFile.path}');
    stdout.writeln('Backup enabled: $backup');
    stdout.writeln('Dry-run: $dryRun');
  }

  var content = await targetFile.readAsString();
  var originalContent = content; // For backup and diff

  // Check if already patched
  if (content.contains('// XLY: Patched by xly package')) {
    stdout.writeln('File already appears to be patched. No changes made.');
    exit(0);
  }

  bool patchApplied = false;

  // Patch 1: The SetNextFrameCallback block
  final showBlockRegex = RegExp(
    r'flutter_controller_->engine\(\)->SetNextFrameCallback\(\[&\]\(\) \{([\s\S]*?)this->Show\(\);([\s\S]*?)\}\);',
    multiLine: true,
  );

  if (content.contains('SetNextFrameCallback')) {
      content = content.replaceFirstMapped(showBlockRegex, (match) {
      patchApplied = true;
      if (verbose) {
        stdout.writeln('Found and patched the SetNextFrameCallback block using regex.');
      }
      return kPatchedShowBlock;
    });
  } else {
      if (verbose) {
      stdout.writeln(
          'SetNextFrameCallback block not found. Skipping this patch.');
      }
  }

  // Patch 2: The ForceRedraw line
  if (content.contains(kOriginalForceRedrawLine)) {
    content = content.replaceFirst(kOriginalForceRedrawLine,
        '$kPatchedForceRedrawComment\n  //${kOriginalForceRedrawLine.trim()}');
    patchApplied = true;
    if (verbose) {
      stdout.writeln('Found and patched the ForceRedraw line.');
    }
  } else {
    if (verbose) {
      stdout.writeln('ForceRedraw line not found. Skipping this patch.');
    }
  }

  if (!patchApplied) {
    stderr.writeln(
        'Could not find any code to patch. The file might be heavily modified or already patched in a different way.');
    exit(1);
  }

  if (dryRun) {
    stdout.writeln('\n--- DRY RUN: PROPOSED CHANGES ---');
    stdout.writeln('--- Original ---');
    stdout.writeln(originalContent);
    stdout.writeln('\n--- Patched ---');
    stdout.writeln(content);

    // 检查 .clangd 文件是否需要创建
    final clangdFile = File(p.join(projectDir, 'windows', '.clangd'));
    if (clangdExplicitlySet && clangdFlag == true) {
      if (!await clangdFile.exists()) {
        stdout.writeln('\n--- .clangd file would be created at: ${clangdFile.path} ---');
      } else {
        stdout.writeln('\n--- .clangd file already exists, would be skipped ---');
      }
    } else if (!clangdExplicitlySet) {
      stdout.writeln('\n--- .clangd: Would prompt user interactively ---');
    }

    stdout.writeln('\n--- END DRY RUN ---');
    exit(0);
  }

  if (backup) {
    final bakFile = File('${targetFile.path}.bak');
    try {
      await bakFile.writeAsString(originalContent);
      if (verbose) {
        stdout.writeln('Backup created at: ${bakFile.path}');
      }
    } catch (e) {
      stderr.writeln('Failed to create backup file: $e');
      // Decide if we should abort. Let's be safe.
      exit(3);
    }
  }

  try {
    await targetFile.writeAsString(content);
    stdout.writeln(
        'Successfully patched `${targetFile.path}` for silent startup.');
  } catch (e) {
    stderr.writeln('Failed to write changes to file: $e');
    exit(4);
  }

  // 处理 .clangd 配置文件生成
  final clangdFile = File(p.join(projectDir, 'windows', '.clangd'));
  bool shouldGenerateClangd = false;

  if (clangdExplicitlySet) {
    // 用户显式指定了 --clangd 或 --no-clangd
    shouldGenerateClangd = clangdFlag == true;
  } else {
    // 未指定，交互式询问用户
    if (!await clangdFile.exists()) {
      stdout.write(
          '\nWould you like to generate a .clangd config file to suppress C++ IDE warnings? (y/N): ');
      final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      shouldGenerateClangd = input == 'y' || input == 'yes';
    }
  }

  if (shouldGenerateClangd) {
    if (!await clangdFile.exists()) {
      try {
        await clangdFile.writeAsString(kClangdConfig);
        stdout.writeln(
            'Created `.clangd` config at `${clangdFile.path}` to suppress clangd false positives.');
      } catch (e) {
        // 非关键错误，仅警告
        stderr.writeln('Warning: Failed to create .clangd file: $e');
      }
    } else {
      if (verbose) {
        stdout.writeln('.clangd file already exists at `${clangdFile.path}`, skipping.');
      }
    }
  }
}
