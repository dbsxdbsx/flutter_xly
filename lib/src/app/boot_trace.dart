part of '../../app.dart';

/// 冷启动阶梯：每一步打一行，排查「卡在哪一步」用。默认关闭。
///
/// - 行格式 `+<毫秒> <步骤> <细节>`，毫秒从第一次打点算起（通常是
///   [MyApp.initialize] 开头）。
/// - 先走 `debugPrint`（安卓即 logcat）：文件日志还没建好、界面还没出来时也看得到。
/// - [attachSink] 接上应用自己的日志后，之前缓冲的行（最多 64 行）按原顺序补写，
///   行里的毫秒仍是当时的。
/// - 打开时门闩还会挂一根卡顿探针：主线程一次被占住 120ms 以上记一行
///   `boot.lag`，带上当时停在哪一步。后台层跑完 3 秒后探针自己停。
///
/// 打开：`MyApp.initialize(enableBootTrace: true)`，或在调用前设 [enabled]。
abstract final class MyBootTrace {
  static bool enabled = false;

  /// `debugPrint` 前缀，便于在 logcat 里过滤。
  static String tag = 'XlyBoot';

  static const _pendingLimit = 64;
  static const _detailLimit = 160;
  static final _pending = <String>[];
  static var _dropped = 0;
  static void Function(String line)? _sink;
  static Stopwatch? _clock;
  static var _lastStep = '';

  /// 最近一次打点的步骤名。
  static String get lastStep => _lastStep;

  static void mark(String step, [String? detail]) {
    if (!enabled) return;
    _lastStep = step;
    _write(step, detail);
  }

  /// 接上应用日志。之前缓冲的行按原顺序补写。
  static void attachSink(void Function(String line) sink) {
    _sink = sink;
    final replay = List<String>.of(_pending);
    _pending.clear();
    if (_dropped > 0) {
      _deliver(sink, '（缓冲已满，更早的 $_dropped 行只在 debugPrint 里）');
      _dropped = 0;
    }
    for (final line in replay) {
      _deliver(sink, line);
    }
  }

  static void detachSink() => _sink = null;

  static void _markLag(Duration late) {
    if (!enabled) return;
    _write('boot.lag', '${late.inMilliseconds}ms after $_lastStep');
  }

  static void _write(String step, String? detail) {
    final clock = _clock ??= Stopwatch()..start();
    var line = '+${clock.elapsedMilliseconds}ms $step';
    if (detail != null && detail.isNotEmpty) {
      final flat = detail.replaceAll(RegExp(r'\s+'), ' ');
      line += flat.length > _detailLimit
          ? ' ${flat.substring(0, _detailLimit)}…'
          : ' $flat';
    }
    debugPrint('[$tag] $line');
    final sink = _sink;
    if (sink != null) {
      _deliver(sink, line);
      return;
    }
    if (_pending.length >= _pendingLimit) {
      _pending.removeAt(0);
      _dropped++;
    }
    _pending.add(line);
  }

  static void _deliver(void Function(String line) sink, String line) {
    try {
      sink(line);
    } catch (e) {
      debugPrint('[$tag] 写入应用日志失败: $e');
    }
  }

  @visibleForTesting
  static void debugReset() {
    enabled = false;
    tag = 'XlyBoot';
    _pending.clear();
    _dropped = 0;
    _sink = null;
    _clock = null;
    _lastStep = '';
  }
}

/// 主线程卡顿探针：100ms 一跳，迟到 120ms 以上记一行。
/// 后台层一直没跑完时也最多跑 [_maxRun]，不会在应用里常驻。
class _StartupLagProbe {
  static const _tick = Duration(milliseconds: 100);
  static const _reportOver = Duration(milliseconds: 120);
  static const _maxRun = Duration(seconds: 60);

  Timer? _timer;
  final _watch = Stopwatch();
  final _total = Stopwatch();

  void start() {
    if (_timer != null) return;
    _watch
      ..reset()
      ..start();
    _total
      ..reset()
      ..start();
    _timer = Timer.periodic(_tick, (_) {
      final late = _watch.elapsed - _tick;
      _watch
        ..reset()
        ..start();
      if (late >= _reportOver) MyBootTrace._markLag(late);
      if (_total.elapsed >= _maxRun) stop();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _watch.stop();
    _total.stop();
  }
}
