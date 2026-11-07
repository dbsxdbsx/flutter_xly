import 'dart:io';

int _tmpCounter = 0;

const List<Duration> _renameRetryDelays = [
  Duration(milliseconds: 20),
  Duration(milliseconds: 60),
  Duration(milliseconds: 180),
];

/// 写临时文件并刷盘，再改名覆盖 [target]。断电后目标要么是旧内容，要么是新内容。
///
/// 不刷盘就改名，文件系统可能只落了长度没落数据，重启后读到整片零。
/// 改名被杀毒 / 同步盘短暂占用时重试；仍失败则保留旧文件并抛出。
/// 禁止先删目标再改名：第二次改名再失败，新旧内容就都没了。
///
/// 临时文件名带 pid + 时间戳 + 进程内序号：并发写同一目标时各写各的，
/// 不会互相把对方的 `.tmp` 改走（移动端表现为 ENOENT）。
Future<void> durableReplaceString(File target, String content) async {
  final unique =
      '$pid.${DateTime.now().microsecondsSinceEpoch}.${_tmpCounter++}';
  final tmp = File('${target.path}.$unique.tmp');
  try {
    await tmp.writeAsString(content, flush: true);
    await _renameWithRetry(tmp, target.path);
  } finally {
    try {
      if (await tmp.exists()) await tmp.delete();
    } catch (_) {}
  }
}

Future<void> _renameWithRetry(File source, String targetPath) async {
  for (var attempt = 0;; attempt++) {
    try {
      await source.rename(targetPath);
      return;
    } on FileSystemException {
      if (attempt >= _renameRetryDelays.length) rethrow;
      await Future<void>.delayed(_renameRetryDelays[attempt]);
    }
  }
}
