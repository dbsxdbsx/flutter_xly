part of '../../app.dart';

/// 启动叠层门闩：首帧提交后跑 [MyBootstrapTask]，按公式揭开 [MySplash]。
///
/// 一般由 [MyApp.initialize] 创建。测试可直接构造。
class MySplashGate {
  MySplashGate({
    required this.hasOverlay,
    required this.hasBrandLottie,
    required this.hasStaticBrandFace,
    this.minVisible = const Duration(milliseconds: 300),
    this.brandTimeout = const Duration(seconds: 8),
    this.bootstrapTimeout = const Duration(seconds: 20),
    List<MyBootstrapTask>? tasks,
    this.onVisible,
    this.showWindowAfterFirstFrame = false,
    this.focusWindowAfterFirstFrame = false,
    this.skipTaskbarWhenVisible = false,
    this.onError,
  }) : tasks = List<MyBootstrapTask>.unmodifiable(tasks ?? const []);

  final bool hasOverlay;
  final bool hasBrandLottie;
  final bool hasStaticBrandFace;
  final Duration minVisible;
  final Duration brandTimeout;
  final Duration bootstrapTimeout;
  final List<MyBootstrapTask> tasks;
  final VoidCallback? onVisible;
  final bool showWindowAfterFirstFrame;
  final bool focusWindowAfterFirstFrame;

  /// 首帧出示窗口时的任务栏策略。有托盘时跟 [MyTray.hideTaskBarIcon]。
  final bool skipTaskbarWhenVisible;
  final void Function(Object error, StackTrace stack)? onError;

  final Completer<void> _ready = Completer<void>();

  var _animationDone = false;
  var _minVisibleElapsed = false;
  var _bootstrapTerminal = false;
  var _finished = false;
  var _visibleNotified = false;
  var _started = false;

  MySplashPhase _phase = MySplashPhase.running;
  String? _fatalMessage;
  Timer? _brandTimer;
  Timer? _minVisibleTimer;

  Future<void> get ready => _ready.future;

  MySplashPhase get phase => _phase;

  bool get isFinished => _finished;

  String? get fatalMessage => _fatalMessage;

  bool get canDismiss {
    if (_phase == MySplashPhase.fatal) return false;
    if (!_bootstrapTerminal) return false;
    if (hasBrandLottie && !_animationDone) return false;
    if (hasStaticBrandFace && !_minVisibleElapsed) return false;
    return true;
  }

  /// 绑定为当前 [MyApp] 门闩，并按有无叠层重置静态量。
  void attachToApp() {
    MyApp._splashGate?.dispose();
    MyApp._splashGate = this;
    _animationDone = !hasBrandLottie;
    _minVisibleElapsed = !hasStaticBrandFace;
    if (!hasOverlay) {
      _finished = true;
      _phase = MySplashPhase.finished;
    } else {
      _finished = false;
      _phase = MySplashPhase.running;
    }
    MyApp.isSplashFinished.value = _finished;
    MyApp.isBootstrapReady.value = false;
    MyApp.splashPhase.value = _phase;
    MyApp.splashFatalMessage = null;
  }

  /// `runApp` 之后调用，不要 `await` 它，以免挡住 `initialize` 返回。
  Future<void> startAfterFirstFrame() async {
    if (_started) return;
    _started = true;
    try {
      await _waitTwoSubmittedFrames();
      await _onFirstFrameSubmitted();
    } catch (e, st) {
      XlyLogger.error('MySplashGate: 首帧后启动失败', e, st);
      onError?.call(e, st);
      _enterFatal(e.toString());
    }
  }

  void reportAnimationDone() {
    if (_animationDone) return;
    _animationDone = true;
    _brandTimer?.cancel();
    _tryDismiss();
  }

  @visibleForTesting
  Future<void> debugOnFirstFrameSubmitted() => _onFirstFrameSubmitted();

  void dispose() {
    _brandTimer?.cancel();
    _minVisibleTimer?.cancel();
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  void _syncToApp() {
    if (!identical(MyApp._splashGate, this)) return;
    MyApp.isSplashFinished.value = _finished;
    MyApp.isBootstrapReady.value =
        _bootstrapTerminal && _phase != MySplashPhase.fatal;
    MyApp.splashPhase.value = _phase;
    MyApp.splashFatalMessage = _fatalMessage;
  }

  Future<void> _waitTwoSubmittedFrames() async {
    final binding = WidgetsBinding.instance;
    Future<void> one() async {
      final done = Completer<void>();
      binding.addPostFrameCallback((_) {
        if (!done.isCompleted) done.complete();
      });
      await done.future;
      await binding.endOfFrame;
    }

    await one();
    await one();
  }

  Future<void> _onFirstFrameSubmitted() async {
    if (!_visibleNotified) {
      _visibleNotified = true;
      try {
        onVisible?.call();
      } catch (e, st) {
        XlyLogger.error('MyApp.onSplashVisible 回调异常（不影响离场）', e, st);
      }
    }

    if (showWindowAfterFirstFrame && MyPlatform.isDesktop) {
      try {
        await windowManager.setSkipTaskbar(skipTaskbarWhenVisible);
        await windowManager.show();
        if (focusWindowAfterFirstFrame) {
          await windowManager.focus();
        }
      } catch (e, st) {
        XlyLogger.error('MySplashGate: 首帧后出示窗口失败', e, st);
        onError?.call(e, st);
        _enterFatal('窗口出示失败: $e');
        return;
      }
    }

    if (hasBrandLottie && !_animationDone && brandTimeout > Duration.zero) {
      _brandTimer = Timer(brandTimeout, reportAnimationDone);
    }
    if (hasStaticBrandFace && !_minVisibleElapsed) {
      if (minVisible <= Duration.zero) {
        _minVisibleElapsed = true;
      } else {
        _minVisibleTimer = Timer(minVisible, () {
          _minVisibleElapsed = true;
          _tryDismiss();
        });
      }
    }

    // 第一次 yield，避免 bootstrap 开头的同步重活卡住刚提交的帧。
    // 用已完成 Future 而不是 Delayed，以免 widget 测试未 pump 时挂住。
    await Future<void>.value();
    await _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    var sawFatal = false;
    var sawDegraded = false;
    var completed = 0;

    Future<void> runAll() async {
      for (final task in tasks) {
        try {
          await task.execute();
          completed++;
        } catch (e, st) {
          XlyLogger.error(
            'MySplashGate: bootstrap 失败'
            '${task.debugLabel == null ? '' : ' (${task.debugLabel})'}',
            e,
            st,
          );
          onError?.call(e, st);
          if (e is MyBootstrapContractError) {
            sawFatal = true;
            _fatalMessage = e.message;
            return;
          }
          switch (task.severity) {
            case MyBootstrapSeverity.fatal:
              sawFatal = true;
              return;
            case MyBootstrapSeverity.degraded:
              sawDegraded = true;
              completed++;
            case MyBootstrapSeverity.optional:
              completed++;
          }
        }
      }
    }

    try {
      if (bootstrapTimeout <= Duration.zero) {
        await runAll();
      } else {
        await runAll().timeout(bootstrapTimeout);
      }
    } on TimeoutException {
      final pendingFatal = tasks
          .skip(completed)
          .any((t) => t.severity == MyBootstrapSeverity.fatal);
      if (sawFatal || pendingFatal) {
        _enterFatal('启动初始化超时');
        return;
      }
      sawDegraded = true;
      XlyLogger.warning('MySplashGate: bootstrap 超时，按 degraded 揭开');
    }

    if (sawFatal) {
      _enterFatal(_fatalMessage ?? '启动初始化失败');
      return;
    }

    _bootstrapTerminal = true;
    _phase = sawDegraded ? MySplashPhase.degraded : MySplashPhase.ready;
    if (!_ready.isCompleted) {
      _ready.complete();
    }
    _syncToApp();
    _tryDismiss();
  }

  void _tryDismiss() {
    if (!canDismiss) {
      _syncToApp();
      return;
    }
    _finished = true;
    _phase = MySplashPhase.finished;
    _syncToApp();
  }

  void _enterFatal(String message) {
    _fatalMessage = message;
    _phase = MySplashPhase.fatal;
    _bootstrapTerminal = false;
    if (!_ready.isCompleted) {
      _ready.completeError(StateError(message), StackTrace.current);
    }
    // 没人 await 时不要把 completeError 当成未捕获异常。
    unawaited(_ready.future.then((_) {}, onError: (_) {}));
    _syncToApp();
  }
}
