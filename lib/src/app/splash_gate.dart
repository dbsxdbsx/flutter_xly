part of '../../app.dart';

/// 启动叠层门闩：首帧提交后跑 [MyBootstrapTask]，按公式揭开 [MySplash]。
///
/// 揭开 = blocking bootstrap 到终态（ready / degraded）× 画面播完（内置 Lottie
/// 停到定格帧、自定义品牌区上报、静态脸过了 [minVisible]）。画面挂着时先淡出
/// [fadeOutDuration]，淡完才算 [MySplashPhase.finished]；揭开后再跑后台层。
///
/// 一般由 [MyApp.initialize] 创建。测试可直接构造。
class MySplashGate {
  MySplashGate({
    required this.hasOverlay,
    required this.hasBrandLottie,
    required this.hasStaticBrandFace,
    this.minVisible = const Duration(milliseconds: 300),
    this.brandTimeout = const Duration(seconds: 8),
    this.playLimit = const Duration(seconds: 10),
    this.frameWaitLimit = const Duration(seconds: 3),
    this.bootstrapTimeout = const Duration(seconds: 20),
    this.bootstrapSlowAfter = const Duration(seconds: 8),
    this.motionGateLimit = const Duration(seconds: 5),
    this.fadeOutDuration = const Duration(milliseconds: 200),
    this.backgroundWaitLimit = const Duration(seconds: 10),
    List<MyBootstrapTask>? tasks,
    List<MyBootstrapTask>? backgroundTasks,
    this.onVisible,
    this.showWindowAfterFirstFrame = false,
    this.focusWindowAfterFirstFrame = false,
    this.skipTaskbarWhenVisible = false,
    this.onError,
  })  : tasks = List<MyBootstrapTask>.unmodifiable(tasks ?? const []),
        backgroundTasks =
            List<MyBootstrapTask>.unmodifiable(backgroundTasks ?? const []);

  final bool hasOverlay;

  /// 品牌区自己上报播完：内置 Lottie，或 [MySplash.brandAnimates] 的自定义品牌区。
  final bool hasBrandLottie;

  /// 品牌区不上报，过了 [minVisible] 就算播完。
  final bool hasStaticBrandFace;
  final Duration minVisible;

  /// 品牌区一直没开始播（素材加载挂住）时，过了这么久按播完处理。
  /// 开始播之后换成 [playLimit] 计时，长动画不会被它截断。
  final Duration brandTimeout;

  /// 品牌区开播后最多等多久停到定格，到点按播完处理（自定义品牌区忘了上报、
  /// 动画被系统暂停）。内置 Lottie 开播时按素材时长另给。[Duration.zero] 表示不限。
  final Duration playLimit;

  /// 首帧后等两帧提交最多等多久。息屏、首帧被推迟时一直没有帧，到点也开始 bootstrap。
  /// [Duration.zero] 表示不限。
  final Duration frameWaitLimit;
  final Duration bootstrapTimeout;

  /// blocking bootstrap 过了这么久还没到终态，[MyApp.isBootstrapSlow] 变 true。
  /// [Duration.zero] 表示不提示。
  final Duration bootstrapSlowAfter;

  /// [MyBootstrapTask.afterSplashMotion] 最多等动画的大动作多久。
  /// [Duration.zero] 表示不等。
  final Duration motionGateLimit;

  /// 画面淡出时长。没有画面挂着或为零时立刻揭开。
  final Duration fadeOutDuration;

  /// 后台层最多等叠层揭开多久。[Duration.zero] 表示 blocking 一到终态就开始。
  final Duration backgroundWaitLimit;
  final List<MyBootstrapTask> tasks;

  /// 揭开之后才跑的任务，失败只记日志。
  final List<MyBootstrapTask> backgroundTasks;
  final VoidCallback? onVisible;
  final bool showWindowAfterFirstFrame;
  final bool focusWindowAfterFirstFrame;

  /// 首帧出示窗口时的任务栏策略。有托盘时跟 [MyTray.hideTaskBarIcon]。
  final bool skipTaskbarWhenVisible;
  final void Function(Object error, StackTrace stack)? onError;

  static const _fadeGrace = Duration(seconds: 1);
  static const _playGrace = Duration(seconds: 2);
  static const _probeTail = Duration(seconds: 3);

  final Completer<void> _ready = Completer<void>();
  final Completer<void> _motion = Completer<void>();
  final Completer<void> _gone = Completer<void>();
  final Completer<void> _uiSettled = Completer<void>();
  final Completer<void> _background = Completer<void>();

  var _animationDone = false;
  var _presentationStarted = false;
  var _minVisibleElapsed = false;
  var _bootstrapTerminal = false;
  var _finished = false;
  var _dismissing = false;
  var _visibleNotified = false;
  var _started = false;
  var _backgroundStarted = false;
  var _backgroundDone = false;
  var _skipped = false;
  var _slow = false;
  var _disposed = false;
  var _faces = 0;
  String? _currentStep;

  MySplashPhase _phase = MySplashPhase.running;
  String? _fatalMessage;
  String? _fatalDetail;
  Timer? _brandTimer;
  Timer? _playTimer;
  Timer? _minVisibleTimer;
  Timer? _slowTimer;
  Timer? _fadeTimer;
  Timer? _probeStopTimer;
  _StartupLagProbe? _lagProbe;

  /// blocking bootstrap 到 ready / degraded。fatal 时以错误完成。
  Future<void> get ready => _ready.future;

  /// 叠层第一次离场：淡出走完、被跳过，或本来就没有叠层。之后不会再变回未离场；
  /// fatal 时失败页另外盖上（看 [phase]）。
  Future<void> get finished => _gone.future;

  /// 后台层全部跑完。blocking fatal 时以错误完成。
  Future<void> get backgroundReady => _background.future;

  MySplashPhase get phase => _phase;

  bool get isFinished => _finished;

  /// 已满足揭开条件，正在淡出。
  bool get isDismissing => _dismissing;

  bool get isSlow => _slow;

  String? get fatalMessage => _fatalMessage;

  /// 出错任务的 debugLabel + 错误第一行。
  String? get fatalDetail => _fatalDetail;

  /// 品牌区上报用的句柄，和 [MySplash.brandBuilder] 拿到的是同一种。
  MySplashHandle get handle => MySplashHandle._(this);

  bool get canDismiss {
    if (_phase == MySplashPhase.fatal) return false;
    if (!_bootstrapTerminal) return false;
    if (hasBrandLottie && !_animationDone) return false;
    if (hasStaticBrandFace && !_minVisibleElapsed) return false;
    return true;
  }

  /// 绑定为当前 [MyApp] 门闩，并按有无叠层重置静态量。
  ///
  /// [MyApp.skipSplashThisLaunch] 已经调过时，叠层从一开始就不出现。
  void attachToApp() {
    MyApp._splashGate?.dispose();
    MyApp._splashGate = this;
    _animationDone = !hasBrandLottie;
    _minVisibleElapsed = !hasStaticBrandFace;
    if (!hasBrandLottie) _completeMotion();
    if (!hasOverlay) {
      _finished = true;
      _phase = MySplashPhase.finished;
      _gone.complete();
    } else {
      _finished = false;
      _phase = MySplashPhase.running;
    }
    _syncToApp();
    if (hasOverlay && MyApp._skipSplashThisLaunch) _skip();
  }

  /// `runApp` 之后调用，不要 `await` 它，以免挡住 `initialize` 返回。
  Future<void> startAfterFirstFrame() async {
    if (_started) return;
    _started = true;
    _startLagProbe();
    try {
      await _waitFirstFrames();
      if (_disposed) return;
      await _onFirstFrameSubmitted();
    } catch (e, st) {
      XlyLogger.error('MySplashGate: 首帧后启动失败', e, st);
      onError?.call(e, st);
      _enterFatal(e.toString());
    }
  }

  /// 画面播完（停在定格帧）。等同 [MySplashHandle.reportPresentationDone]。
  void reportAnimationDone() {
    if (_disposed || _animationDone) return;
    _animationDone = true;
    _presentationStarted = true;
    _brandTimer?.cancel();
    _playTimer?.cancel();
    _completeMotion();
    MyBootTrace.mark('splash.presented');
    _tryDismiss();
  }

  @visibleForTesting
  Future<void> debugOnFirstFrameSubmitted() => _onFirstFrameSubmitted();

  Future<void> _waitFirstFrames() async {
    MyBootTrace.mark('splash.frame-wait');
    final frames = _waitSubmittedFrames(2);
    if (frameWaitLimit <= Duration.zero) return frames;
    try {
      await frames.timeout(frameWaitLimit);
    } on TimeoutException {
      MyBootTrace.mark('splash.frame-timeout');
      XlyLogger.warning('MySplashGate: 首帧迟迟没有提交（息屏或首帧被推迟），先开始 bootstrap');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _brandTimer?.cancel();
    _playTimer?.cancel();
    _minVisibleTimer?.cancel();
    _slowTimer?.cancel();
    _fadeTimer?.cancel();
    _probeStopTimer?.cancel();
    _lagProbe?.stop();
    if (!_ready.isCompleted) _ready.complete();
    _completeMotion();
    if (!_uiSettled.isCompleted) _uiSettled.complete();
    if (!_background.isCompleted) _background.complete();
    if (!_gone.isCompleted) _gone.complete();
  }

  // ── 画面（MySplash / MySplashHandle）上报 ───────────────────────

  /// [expected]：开播到停在定格要多久。内置 Lottie 按素材时长给，
  /// 看门狗按它加一点余量；不给时用 [playLimit]。
  void _onPresentationStarted({Duration? expected}) {
    if (_disposed || _presentationStarted) return;
    _presentationStarted = true;
    _brandTimer?.cancel();
    MyBootTrace.mark('splash.animation-start');
    final limit = expected != null ? expected + _playGrace : playLimit;
    if (_animationDone || limit <= Duration.zero) return;
    _playTimer = Timer(limit, () {
      MyBootTrace.mark('splash.play-timeout');
      XlyLogger.warning('MySplashGate: 品牌区开播后迟迟没停到定格，按播完处理');
      reportAnimationDone();
    });
  }

  void _onMotionDone() {
    if (_disposed || _motion.isCompleted) return;
    // 大动作做完就一定开播过：没报开播的自定义品牌区也要换成播放看门狗。
    _onPresentationStarted();
    MyBootTrace.mark('splash.motion-done');
    _completeMotion();
  }

  void _attachFace() {
    if (!_disposed) _faces++;
  }

  void _detachFace() {
    if (_faces > 0) _faces--;
    // 画面在拆树时调这里，父级 Obx 正在拆：不能当场写 Rx。
    if (_faces == 0 && _dismissing) scheduleMicrotask(_completeDismiss);
  }

  void _onFadedOut() {
    if (_dismissing) _completeDismiss();
  }

  /// 外部意图（通知、深链、投屏）直接进页面时调用，见 [MyApp.skipSplashThisLaunch]。
  void _skip() {
    if (_skipped || _disposed || !hasOverlay) return;
    _skipped = true;
    MyBootTrace.mark('splash.skip');
    _brandTimer?.cancel();
    _playTimer?.cancel();
    _minVisibleTimer?.cancel();
    _animationDone = true;
    _presentationStarted = true;
    _minVisibleElapsed = true;
    _completeMotion();
    if (_phase == MySplashPhase.fatal || _finished) {
      _syncToApp();
      return;
    }
    _completeDismiss();
  }

  bool get _presentationSettled => _disposed || _animationDone;

  // ── 内部流程 ───────────────────────────────────────────────────

  void _syncToApp() {
    if (!identical(MyApp._splashGate, this)) return;
    MyApp.splashFatalMessage = _fatalMessage;
    MyApp.splashFatalDetail = _fatalDetail;
    MyApp.isSplashFinished.value = _finished;
    MyApp.isBootstrapReady.value =
        _bootstrapTerminal && _phase != MySplashPhase.fatal;
    MyApp.isBootstrapSlow.value = _slow;
    MyApp.isBackgroundReady.value = _backgroundDone;
    MyApp._splashPresented.value = _animationDone && _minVisibleElapsed;
    MyApp._splashDismissing.value = _dismissing;
    MyApp.splashPhase.value = _phase;
  }

  Future<void> _onFirstFrameSubmitted() async {
    MyBootTrace.mark('splash.first-frames');
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

    if (hasBrandLottie &&
        !_animationDone &&
        !_presentationStarted &&
        brandTimeout > Duration.zero) {
      _brandTimer = Timer(brandTimeout, () {
        MyBootTrace.mark('splash.brand-timeout');
        reportAnimationDone();
      });
    }
    if (hasStaticBrandFace && !_minVisibleElapsed) {
      if (minVisible <= Duration.zero) {
        _minVisibleElapsed = true;
        _syncToApp();
      } else {
        _minVisibleTimer = Timer(minVisible, () {
          _minVisibleElapsed = true;
          _tryDismiss();
        });
      }
    }
    if (_finished) _settleAfterFrame();

    // 第一次 yield，避免 bootstrap 开头的同步重活卡住刚提交的帧。
    // 用已完成 Future 而不是 Delayed，以免 widget 测试未 pump 时挂住。
    await Future<void>.value();
    await _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    var sawFatal = false;
    var sawDegraded = false;
    var completed = 0;
    var waitedMotion = false;
    // 超时按 degraded 揭开后，还在跑的任务照常往下跑，但结局已定：失败只记日志。
    var settled = false;
    MyBootTrace.mark('bootstrap.start', '${tasks.length} tasks');
    _armSlowTimer();

    Future<void> runAll() async {
      for (var i = 0; i < tasks.length; i++) {
        if (_disposed) return;
        final task = tasks[i];
        if (task.afterSplashMotion && !waitedMotion) {
          waitedMotion = true;
          await _waitMotion();
          if (_disposed) return;
        }
        final label = task.debugLabel ?? '#${i + 1}';
        _currentStep = label;
        MyBootTrace.mark('bootstrap.task', label);
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
          MyBootTrace.mark('bootstrap.error', '$label: ${_firstLine(e)}');
          if (settled) continue;
          if (e is MyBootstrapContractError) {
            sawFatal = true;
            _fatalMessage = e.message;
            _fatalDetail = _describeFailure(task.debugLabel, e);
            return;
          }
          switch (task.severity) {
            case MyBootstrapSeverity.fatal:
              sawFatal = true;
              _fatalDetail = _describeFailure(task.debugLabel, e);
              return;
            case MyBootstrapSeverity.degraded:
              sawDegraded = true;
              completed++;
            case MyBootstrapSeverity.optional:
              completed++;
          }
        }
      }
      _currentStep = null;
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
        final stuck = _currentStep;
        _enterFatal(
          '启动初始化超时',
          detail: stuck == null ? null : '停在 $stuck',
        );
        return;
      }
      sawDegraded = true;
      XlyLogger.warning('MySplashGate: bootstrap 超时，按 degraded 揭开');
    } finally {
      settled = true;
    }
    if (_disposed) return;

    if (sawFatal) {
      _enterFatal(_fatalMessage ?? '启动初始化失败', detail: _fatalDetail);
      return;
    }

    _slowTimer?.cancel();
    _slow = false;
    _bootstrapTerminal = true;
    _phase = sawDegraded ? MySplashPhase.degraded : MySplashPhase.ready;
    MyBootTrace.mark('bootstrap.${_phase.name}');
    if (!_ready.isCompleted) {
      _ready.complete();
    }
    _syncToApp();
    _tryDismiss();
    unawaited(_runBackground());
  }

  Future<void> _waitMotion() async {
    if (_motion.isCompleted || motionGateLimit <= Duration.zero) return;
    MyBootTrace.mark('bootstrap.wait-motion');
    try {
      await _motion.future.timeout(motionGateLimit);
    } on TimeoutException {
      MyBootTrace.mark('bootstrap.motion-timeout');
      XlyLogger.warning('MySplashGate: 启动动画的大动作迟迟没做完，后面的任务先跑');
    }
  }

  void _armSlowTimer() {
    if (bootstrapSlowAfter <= Duration.zero) return;
    _slowTimer?.cancel();
    _slowTimer = Timer(bootstrapSlowAfter, () {
      if (_disposed || _bootstrapTerminal || _phase == MySplashPhase.fatal) {
        return;
      }
      _slow = true;
      MyBootTrace.mark('bootstrap.slow', _currentStep);
      _syncToApp();
    });
  }

  void _tryDismiss() {
    if (_disposed) return;
    if (!canDismiss) {
      _syncToApp();
      return;
    }
    if (_finished) {
      _phase = MySplashPhase.finished;
      _syncToApp();
      return;
    }
    if (_dismissing) return;
    _dismissing = true;
    MyBootTrace.mark('splash.dismiss');
    if (_faces == 0 || fadeOutDuration <= Duration.zero) {
      _completeDismiss();
      return;
    }
    // 画面没回报淡完（被换掉、动画被系统关掉）时的兜底。
    _fadeTimer = Timer(fadeOutDuration + _fadeGrace, () {
      MyBootTrace.mark('splash.fade-timeout');
      _completeDismiss();
    });
    _syncToApp();
  }

  void _completeDismiss() {
    if (_finished || _disposed) return;
    _fadeTimer?.cancel();
    _dismissing = false;
    _finished = true;
    if (_phase != MySplashPhase.fatal) _phase = MySplashPhase.finished;
    if (!_gone.isCompleted) _gone.complete();
    MyBootTrace.mark('splash.gone');
    _syncToApp();
    _settleAfterFrame();
  }

  /// 首页在叠层拿掉后画完一帧，后台层才开始。
  void _settleAfterFrame() {
    if (_uiSettled.isCompleted) return;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (_uiSettled.isCompleted) return;
      MyBootTrace.mark('splash.ui-settled');
      _uiSettled.complete();
    });
    binding.ensureVisualUpdate();
  }

  Future<void> _runBackground() async {
    if (_backgroundStarted || _disposed) return;
    _backgroundStarted = true;
    if (backgroundTasks.isNotEmpty) {
      if (!_uiSettled.isCompleted && backgroundWaitLimit > Duration.zero) {
        try {
          await _uiSettled.future.timeout(backgroundWaitLimit);
        } on TimeoutException {
          MyBootTrace.mark('background.wait-timeout');
          XlyLogger.warning('MySplashGate: 叠层迟迟没揭开，后台层先开始');
        }
      }
      for (var i = 0; i < backgroundTasks.length; i++) {
        if (_disposed) return;
        await _yieldFrame();
        if (_disposed) return;
        final task = backgroundTasks[i];
        final label = task.debugLabel ?? '#${i + 1}';
        MyBootTrace.mark('background.task', label);
        try {
          await task.execute();
        } catch (e, st) {
          XlyLogger.error('MySplashGate: 后台初始化失败 ($label)', e, st);
          onError?.call(e, st);
          MyBootTrace.mark('background.error', '$label: ${_firstLine(e)}');
        }
      }
    }
    if (_disposed) return;
    _backgroundDone = true;
    if (!_background.isCompleted) _background.complete();
    MyBootTrace.mark('background.done');
    _syncToApp();
    _stopLagProbeLater();
  }

  void _enterFatal(String message, {String? detail}) {
    if (_disposed || _phase == MySplashPhase.fatal) return;
    // 终态不回头：首页已经能用之后的错误（例如应用挂在 Rx 上的回调抛了）只记日志。
    if (_bootstrapTerminal) {
      XlyLogger.warning('MySplashGate: 启动已完成，之后的错误不再盖失败页: $message');
      return;
    }
    _fatalMessage = message;
    _fatalDetail = detail;
    _phase = MySplashPhase.fatal;
    _bootstrapTerminal = false;
    _slowTimer?.cancel();
    _slow = false;
    if (_dismissing) {
      _dismissing = false;
      _fadeTimer?.cancel();
    }
    // 已经跳过叠层时 _finished 保持 true：MyApp 看 phase 把失败页盖上。
    MyBootTrace.mark('bootstrap.fatal', detail ?? message);
    final error = StateError(message);
    if (!_ready.isCompleted) {
      _ready.completeError(error, StackTrace.current);
    }
    if (!_background.isCompleted) {
      _background.completeError(error, StackTrace.current);
    }
    // 没人 await 时不要把 completeError 当成未捕获异常。
    unawaited(_ready.future.then((_) {}, onError: (_) {}));
    unawaited(_background.future.then((_) {}, onError: (_) {}));
    _syncToApp();
    _stopLagProbeLater();
  }

  void _completeMotion() {
    if (!_motion.isCompleted) _motion.complete();
  }

  void _startLagProbe() {
    if (!MyBootTrace.enabled) return;
    (_lagProbe ??= _StartupLagProbe()).start();
  }

  void _stopLagProbeLater() {
    if (_lagProbe == null) return;
    _probeStopTimer?.cancel();
    _probeStopTimer = Timer(_probeTail, () => _lagProbe?.stop());
  }

  static String _firstLine(Object error) {
    final text =
        error is MyBootstrapContractError ? error.message : error.toString();
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      return trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
    }
    return '';
  }

  static String _describeFailure(String? label, Object error) {
    final line = _firstLine(error);
    if (label == null) return line;
    return line.isEmpty ? label : '$label：$line';
  }
}

/// 品牌区和门闩说话的句柄。
///
/// 内置 Lottie 品牌区用它上报；[MySplash.brandBuilder] 拿到的也是它（配合
/// [MySplash.brandAnimates] = true）。三个上报都幂等，只报
/// [reportPresentationDone] 时前两个一并算作已发生。门闩换掉（测试里重新
/// attach）后，旧句柄的上报自动作废。
class MySplashHandle {
  const MySplashHandle._(this._gate);

  final MySplashGate? _gate;

  /// 素材加载好、开始播了。此后不再受 [MySplash.brandTimeout] 约束。
  void reportStarted() => _gate?._onPresentationStarted();

  /// 大动作做完：标了 [MyBootstrapTask.afterSplashMotion] 的任务从这里开始跑。
  void reportMotionDone() => _gate?._onMotionDone();

  /// 停在定格画面：bootstrap 也到终态时开始淡出揭开。
  void reportPresentationDone() => _gate?.reportAnimationDone();
}

/// 等 [count] 帧提交。每一帧都主动请求：`addPostFrameCallback` 不会排帧，
/// 画面上没有动画在跑时不请求就等不到下一帧，bootstrap 永远不开始。
Future<void> _waitSubmittedFrames(int count) async {
  final binding = WidgetsBinding.instance;
  for (var n = 1; n <= count; n++) {
    final done = Completer<void>();
    binding.addPostFrameCallback((_) {
      if (!done.isCompleted) done.complete();
    });
    binding.ensureVisualUpdate();
    await done.future;
    await binding.endOfFrame;
  }
}

/// 后台层两步之间让一帧：有帧排着就等它画完，否则只让出事件循环。
/// 息屏时排着的帧可能一直不来，所以等帧有上限。
Future<void> _yieldFrame() {
  final binding = WidgetsBinding.instance;
  if (!binding.hasScheduledFrame) return Future<void>.delayed(Duration.zero);
  return binding.endOfFrame.timeout(
    const Duration(milliseconds: 100),
    onTimeout: () {},
  );
}
