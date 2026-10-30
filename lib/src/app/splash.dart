part of '../../app.dart';

/// 启动叠层的画面：品牌区（Lottie + 标题，或 [brandBuilder]）加说明区
/// （正在启动 / 启动慢 / 失败页，或 [captionBuilder]）。
///
/// 什么时候揭开由 [MyApp] 的门闩决定：bootstrap 到终态 × 画面播完，然后淡出
/// [fadeOutDuration]。这里不要写 Timer 或改路由。
///
/// 尺寸参数都是**设计尺寸值**，内部按 ScreenUtil 换算一次（见 README「尺寸参数契约」）。
class MySplash extends StatefulWidget {
  /// 已无导航作用，保留只为旧调用方还能编译。
  @Deprecated('Splash 不是路由。无品牌脸请传 splash: null。')
  final String nextRoute;

  /// Lottie 素材（JSON 或 dotLottie）。[MyApp.initialize] 会在 `runApp` 前预载。
  final String? lottieAssetPath;
  final String? appTitle;
  final Color backgroundColor;

  /// 已不再用于揭开。有 Lottie 时播到定格帧；静态脸用 [minVisible]。
  @Deprecated('揭开看 bootstrap × 动画，不再用固定时长。')
  final Duration splashDuration;

  final Color textColor;

  /// 主按钮底色，默认 [textColor]。
  final Color? accentColor;

  /// 标题字号（设计尺寸值，内部自动 .sp），默认 50。标题只排一行，放不下时整行缩小。
  final double? fontSize;
  final FontWeight fontWeight;

  /// Lottie 动画宽度（设计尺寸值，内部自动 .w），默认 200
  final double? lottieWidth;

  /// Lottie 动画高度（设计尺寸值，内部自动 .w）。不传按素材比例；素材没预载到时按正方形。
  final double? lottieHeight;

  /// 动画与标题之间的间距（设计尺寸值，内部自动 .w），默认 20
  final double? spaceBetween;

  /// 品牌区与下方提示之间的间距（设计尺寸值，内部自动 .w），默认 24
  final double? captionGap;

  /// 定格帧帧号，覆盖从素材推出来的定格点（见 [MySplashAnimationTiming]）。
  final double? holdFrame;

  /// 大动作结束的帧号，覆盖从素材推出来的点。
  final double? motionEndFrame;

  /// 无 Lottie 的静态品牌脸最短可见时间，防止闪一帧。有 Lottie 时忽略。
  final Duration minVisible;

  /// 品牌区一直没开始播（素材加载挂住）时，过了这么久按播完处理。开始播后换成 [playLimit]。
  final Duration brandTimeout;

  /// 开播后最多等多久停到定格，到点按播完处理。内置 Lottie 按素材时长另算
  /// （播到定格的时长 + 2 秒），这一项只管 [brandBuilder]。[Duration.zero] 表示不限。
  final Duration playLimit;

  /// `runApp` 前最多等 Lottie 预载多久。等不到就先出第一帧，载好再开播。
  final Duration preloadLimit;

  /// 开播前最多等第一帧真正上屏多久。原生启动画面还盖着时就开始计时，前几帧会被吞掉。
  final Duration firstFrameLimit;

  /// [MyBootstrapTask.afterSplashMotion] 最多等动画的大动作多久。
  ///
  /// 不传时：动画预载到了 → 大动作时长 + [firstFrameLimit] + 1 秒；否则 5 秒。
  /// [Duration.zero] 表示不等。
  final Duration? motionGateLimit;

  /// 揭开时的淡出时长。[Duration.zero] 表示直接拿掉。
  final Duration fadeOutDuration;

  /// 画面播完后还没揭开，再过多久显示「正在启动…」。`null` 不显示。
  final Duration? statusLineAfter;

  final MySplashTexts texts;

  /// 失败页和「启动慢」提示上的「重新启动」。
  ///
  /// 重启方式因平台和应用而异（桌面起新进程、安卓重建 Activity），由应用实现。
  /// 返回 `false` 或抛错时提示用户手动重开；不传就只有「退出」。
  final Future<bool> Function()? onRestart;

  /// 失败页显示「退出」（调 [MyApp.exit]）。`null`：iOS 不显示（系统不允许应用
  /// 自己退出），其余平台显示。
  final bool? showExitButton;

  /// 自定义品牌区，替换内置的 Lottie + 标题。
  ///
  /// 有动画时把 [brandAnimates] 设为 `true`，并用 [MySplashHandle] 上报开播、
  /// 大动作做完、停到定格；否则按 [minVisible] 算播完。
  final Widget Function(BuildContext context, MySplashHandle handle)?
      brandBuilder;

  /// [brandBuilder] 自己上报播完。
  final bool brandAnimates;

  /// 自定义说明区，替换内置的提示与按钮。
  final Widget Function(BuildContext context, MySplashStatus status)?
      captionBuilder;

  static const overlayKey = Key('xly-splash-overlay');

  /// 内置品牌区里给动画留的那块位置。
  static const animationKey = Key('xly-splash-animation');

  /// 测试用：替换「等第一帧真正上屏」。widget 测试里第一帧永远不会光栅化。
  @visibleForTesting
  static Future<void> Function()? debugFirstFrameShown;

  const MySplash({
    super.key,
    @Deprecated('Splash 不是路由。无品牌脸请传 splash: null。') this.nextRoute = '',
    this.lottieAssetPath,
    this.appTitle,
    this.backgroundColor = Colors.white,
    @Deprecated('揭开看 bootstrap × 动画，不再用固定时长。')
    this.splashDuration = const Duration(milliseconds: 2500),
    this.textColor = Colors.black,
    this.accentColor,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.lottieWidth,
    this.lottieHeight,
    this.spaceBetween,
    this.captionGap,
    this.holdFrame,
    this.motionEndFrame,
    this.minVisible = const Duration(milliseconds: 300),
    this.brandTimeout = const Duration(seconds: 8),
    this.playLimit = const Duration(seconds: 10),
    this.preloadLimit = const Duration(milliseconds: 500),
    this.firstFrameLimit = const Duration(seconds: 1),
    this.motionGateLimit,
    this.fadeOutDuration = const Duration(milliseconds: 200),
    this.statusLineAfter = const Duration(milliseconds: 1500),
    this.texts = const MySplashTexts(),
    this.onRestart,
    this.showExitButton,
    this.brandBuilder,
    this.brandAnimates = false,
    this.captionBuilder,
  }) : assert(
          brandBuilder != null || !brandAnimates,
          'brandAnimates 只对 brandBuilder 有效；内置 Lottie 自己上报',
        );

  static const _fallbackMotionGate = Duration(seconds: 5);
  static const _motionGateMargin = Duration(seconds: 1);

  bool get _usesBuiltInLottie =>
      brandBuilder == null && lottieAssetPath != null;

  /// 品牌区自己上报播完；否则门闩按 [minVisible] 算。
  bool get _reportsPresentation =>
      brandBuilder != null ? brandAnimates : lottieAssetPath != null;

  bool get _showsExit =>
      showExitButton ?? defaultTargetPlatform != TargetPlatform.iOS;

  MySplashAnimationTiming _timingFor(MySplashClip clip) =>
      clip.timingWith(holdFrame: holdFrame, motionEndFrame: motionEndFrame);

  Duration _motionGateLimitFor(MySplashClip? clip) {
    final explicit = motionGateLimit;
    if (explicit != null) return explicit;
    if (clip == null || !_usesBuiltInLottie) return _fallbackMotionGate;
    return clip.duration * _timingFor(clip).motionEnd +
        firstFrameLimit +
        _motionGateMargin;
  }

  @override
  State<MySplash> createState() => _MySplashState();
}

/// 内置说明区的文案。
@immutable
class MySplashTexts {
  const MySplashTexts({
    this.starting = '正在启动…',
    this.slow = '启动比平时慢，请再等等',
    this.slowWithRestart = '启动比平时慢，可以再等等，或者重新启动',
    this.failed = '启动没有完成，请退出后重新打开',
    this.failedWithRestart = '启动没有完成，请重新启动',
    this.restart = '重新启动',
    this.restarting = '正在重启…',
    this.restartFailed = '没能自动重启，请手动关掉再打开',
    this.exit = '退出',
  });

  final String starting;
  final String slow;
  final String slowWithRestart;
  final String failed;
  final String failedWithRestart;
  final String restart;
  final String restarting;
  final String restartFailed;
  final String exit;
}

/// 交给 [MySplash.captionBuilder] 的当前状态。
@immutable
class MySplashStatus {
  const MySplashStatus({
    required this.phase,
    required this.isSlow,
    required this.isWaiting,
    required this.fatalMessage,
    required this.fatalDetail,
    required this.canRestart,
    required this.isRestarting,
    required this.restartFailed,
    required this.canExit,
    required this.restart,
    required this.exit,
  });

  final MySplashPhase phase;

  /// bootstrap 超过 `bootstrapSlowAfter` 还没到终态。
  final bool isSlow;

  /// 画面播完后迟迟没揭开（[MySplash.statusLineAfter]）。
  final bool isWaiting;
  final String? fatalMessage;

  /// 出错任务的 debugLabel + 错误第一行。
  final String? fatalDetail;

  /// 传了 [MySplash.onRestart]。
  final bool canRestart;
  final bool isRestarting;

  /// [MySplash.onRestart] 返回了 false 或抛错。
  final bool restartFailed;
  final bool canExit;

  /// 调 [MySplash.onRestart]；没传时什么也不做。
  final Future<void> Function() restart;

  /// 调 [MyApp.exit]。
  final Future<void> Function() exit;

  bool get isFatal => phase == MySplashPhase.fatal;
}

class _MySplashState extends State<MySplash>
    with SingleTickerProviderStateMixin {
  MySplashGate? _gate;
  late final MySplashHandle _handle;
  final _workers = <Worker>[];
  AnimationController? _controller;
  MySplashClip? _clip;
  var _timing = MySplashAnimationTiming.whole;
  var _motionReported = false;
  var _fadeRequested = false;
  var _fading = false;
  var _waiting = false;
  var _restarting = false;
  var _restartFailed = false;
  Timer? _statusTimer;
  Timer? _firstFrameTimer;
  Completer<void>? _firstFrame;

  @override
  void initState() {
    super.initState();
    _gate = MyApp._splashGate;
    _gate?._attachFace();
    _handle = MySplashHandle._(_gate);
    _workers
      ..add(ever<bool>(MyApp._splashDismissing, (dismissing) {
        if (dismissing) _startFade();
      }))
      ..add(ever<bool>(MyApp._splashPresented, (presented) {
        if (presented) _armStatusLine();
      }));
    if (MyApp._splashDismissing.value) _startFade();
    if (MyApp._splashPresented.value) _armStatusLine();
    if (widget._usesBuiltInLottie) _prepareClip(widget.lottieAssetPath!);
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _statusTimer?.cancel();
    _firstFrameTimer?.cancel();
    final firstFrame = _firstFrame;
    if (firstFrame != null && !firstFrame.isCompleted) firstFrame.complete();
    _controller?.dispose();
    _gate?._detachFace();
    super.dispose();
  }

  bool get _settled => _gate?._presentationSettled ?? false;

  void _prepareClip(String path) {
    _controller = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    final ready = MySplashClip.peek(path);
    if (ready != null) {
      _useClip(ready);
      unawaited(_play());
    } else {
      unawaited(_loadThenPlay(path));
    }
  }

  void _useClip(MySplashClip clip) {
    _clip = clip;
    _timing = widget._timingFor(clip);
  }

  Future<void> _loadThenPlay(String path) async {
    final clip = await MySplashClip.load(path);
    if (!mounted) return;
    if (clip == null) {
      _handle.reportPresentationDone();
      return;
    }
    setState(() => _useClip(clip));
    // 先按第 0 帧画出来再起表：开播那一帧要是卡了，动画开头不会被跳过。
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _play();
  }

  Future<void> _play() async {
    final controller = _controller;
    final clip = _clip;
    if (controller == null || clip == null) return;
    controller.duration = clip.duration;
    if (!_settled) await _firstFrameOnScreen();
    if (!mounted) return;
    // 跳过、加载超时或失败页重新盖上时，直接停在定格帧。
    if (_settled) {
      controller.value = _timing.hold;
      return;
    }
    _gate?._onPresentationStarted(expected: clip.duration * _timing.hold);
    MyBootTrace.mark(
        'splash.animation', 'to ${_timing.hold.toStringAsFixed(3)}');
    controller.animateTo(_timing.hold);
  }

  /// 原生启动画面还盖着时动画就开始走，前几帧用户看不到。等第一帧真正上屏再起表。
  Future<void> _firstFrameOnScreen() {
    final seam = MySplash.debugFirstFrameShown;
    if (seam != null) return seam();
    final binding = WidgetsBinding.instance;
    if (binding.firstFrameRasterized) return Future<void>.value();
    final done = _firstFrame = Completer<void>();
    void finish() {
      _firstFrameTimer?.cancel();
      if (!done.isCompleted) done.complete();
    }

    _firstFrameTimer = Timer(widget.firstFrameLimit, () {
      MyBootTrace.mark('splash.first-frame-timeout');
      finish();
    });
    unawaited(binding.waitUntilFirstFrameRasterized.then((_) => finish()));
    return done.future;
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || _motionReported) return;
    if (controller.value >= _timing.motionEnd) {
      _motionReported = true;
      _handle.reportMotionDone();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    MyBootTrace.mark('splash.animation', 'hold');
    _handle.reportPresentationDone();
  }

  void _armStatusLine() {
    final after = widget.statusLineAfter;
    if (after == null || _waiting || _statusTimer != null || _fadeRequested) {
      return;
    }
    _statusTimer = Timer(after, () {
      if (!mounted || _fadeRequested) return;
      setState(() => _waiting = true);
    });
  }

  Future<void> _startFade() async {
    if (_fadeRequested) return;
    _fadeRequested = true;
    _statusTimer?.cancel();
    // 先让首页按就绪后的状态画完一帧，淡出时露出来的是新画面。
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _fading = true);
  }

  void _onFadeEnd() {
    if (_fading) _gate?._onFadedOut();
  }

  Future<void> _restart() async {
    final onRestart = widget.onRestart;
    if (onRestart == null || _restarting) return;
    setState(() {
      _restarting = true;
      _restartFailed = false;
    });
    var ok = false;
    try {
      ok = await onRestart();
    } catch (e, st) {
      XlyLogger.error('MySplash: 重启失败', e, st);
    }
    if (!mounted || ok) return;
    setState(() {
      _restarting = false;
      _restartFailed = true;
    });
  }

  Future<void> _exit() => MyApp.exit();

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.maybePaddingOf(context) ?? EdgeInsets.zero;
    final margin = 24.w;
    return AnimatedOpacity(
      opacity: _fading ? 0 : 1,
      duration: widget.fadeOutDuration,
      curve: Curves.easeOut,
      onEnd: _onFadeEnd,
      child: Material(
        key: MySplash.overlayKey,
        color: widget.backgroundColor,
        child: CustomMultiChildLayout(
          delegate: _SplashLayout(
            gap: (widget.captionGap ?? 24).w,
            padding: safe + EdgeInsets.all(margin),
            captionMaxWidth: 480.w,
          ),
          children: [
            LayoutId(id: _SplashSlot.brand, child: _buildBrand(context)),
            LayoutId(
              id: _SplashSlot.caption,
              child: Obx(() => _buildCaption(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    final custom = widget.brandBuilder;
    if (custom != null) return custom(context, _handle);
    final hasLottie = widget.lottieAssetPath != null;
    final title = widget.appTitle;
    if (!hasLottie && title == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLottie) _buildLottieBox(),
        if (hasLottie && title != null)
          SizedBox(height: (widget.spaceBetween ?? 20).w),
        if (title != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.textColor,
                fontSize: (widget.fontSize ?? 50).sp,
                fontWeight: widget.fontWeight,
              ),
            ),
          ),
      ],
    );
  }

  /// 动画没载好之前也按最终尺寸留位置，标题不会在动画出现时被挤走。
  Widget _buildLottieBox() {
    final width = (widget.lottieWidth ?? 200).w;
    final clip = _clip;
    final designHeight = widget.lottieHeight;
    final height = designHeight != null
        ? designHeight.w
        : width / (clip?.aspectRatio ?? 1);
    return SizedBox(
      key: MySplash.animationKey,
      width: width,
      height: height,
      child: clip == null
          ? null
          : Lottie(
              composition: clip.composition,
              controller: _controller,
              width: width,
              height: height,
              fit: BoxFit.contain,
            ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    // 先读 Rx：Obx 里一个 Rx 都不读会被 GetX 判为误用。
    final phase = MyApp.splashPhase.value;
    final slow = MyApp.isBootstrapSlow.value;
    final status = MySplashStatus(
      phase: phase,
      isSlow: slow,
      isWaiting: _waiting,
      fatalMessage: MyApp.splashFatalMessage,
      fatalDetail: MyApp.splashFatalDetail,
      canRestart: widget.onRestart != null,
      isRestarting: _restarting,
      restartFailed: _restartFailed,
      canExit: widget._showsExit,
      restart: _restart,
      exit: _exit,
    );
    final custom = widget.captionBuilder;
    if (custom != null) return custom(context, status);
    return _SplashCaption(splash: widget, status: status);
  }
}

class _SplashCaption extends StatelessWidget {
  const _SplashCaption({required this.splash, required this.status});

  final MySplash splash;
  final MySplashStatus status;

  @override
  Widget build(BuildContext context) {
    final texts = splash.texts;
    final strong = splash.textColor;
    final muted = strong.withValues(alpha: 0.62);
    final faint = strong.withValues(alpha: 0.48);
    final lineStyle = TextStyle(color: muted, fontSize: 15.sp, height: 1.4);

    if (status.isFatal) {
      final detail = status.fatalDetail ?? status.fatalMessage;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.canRestart ? texts.failedWithRestart : texts.failed,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: strong,
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (detail != null && detail.isNotEmpty) ...[
            SizedBox(height: 6.w),
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: faint, fontSize: 12.sp, height: 1.4),
            ),
          ],
          ..._actions(includeExit: status.canExit),
        ],
      );
    }
    if (status.isSlow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.canRestart ? texts.slowWithRestart : texts.slow,
            textAlign: TextAlign.center,
            style: lineStyle,
          ),
          ..._actions(includeExit: false),
        ],
      );
    }
    if (status.isWaiting) {
      return Text(texts.starting,
          textAlign: TextAlign.center, style: lineStyle);
    }
    return const SizedBox.shrink();
  }

  List<Widget> _actions({required bool includeExit}) {
    final texts = splash.texts;
    final strong = splash.textColor;
    final buttons = <Widget>[
      if (status.canRestart)
        _SplashButton(
          label: status.isRestarting ? texts.restarting : texts.restart,
          onPressed: status.restart,
          primary: true,
          autofocus: true,
          splash: splash,
        ),
      if (includeExit)
        _SplashButton(
          label: texts.exit,
          onPressed: status.exit,
          autofocus: !status.canRestart,
          splash: splash,
        ),
    ];
    return [
      if (buttons.isNotEmpty) ...[
        SizedBox(height: 16.w),
        FocusScope(
          child: FocusTraversalGroup(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.w,
              runSpacing: 10.w,
              children: buttons,
            ),
          ),
        ),
      ],
      if (status.restartFailed) ...[
        SizedBox(height: 10.w),
        Text(
          texts.restartFailed,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: strong.withValues(alpha: 0.62),
            fontSize: 13.sp,
            height: 1.4,
          ),
        ),
      ],
    ];
  }
}

enum _SplashSlot { brand, caption }

/// 品牌区整组放正中；提示和按钮放在下面，出现时不把上面那组顶走。
/// 下面放不下（横屏手机出了按钮）时整组往上挪，但不越过安全区顶边。
class _SplashLayout extends MultiChildLayoutDelegate {
  _SplashLayout({
    required this.gap,
    required this.padding,
    required this.captionMaxWidth,
  });

  final double gap;
  final EdgeInsets padding;
  final double captionMaxWidth;

  @override
  void performLayout(Size size) {
    final maxWidth = math.max(0.0, size.width - padding.horizontal);
    final maxHeight = math.max(0.0, size.height - padding.vertical);
    final brand = layoutChild(
      _SplashSlot.brand,
      BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
    );
    final caption = layoutChild(
      _SplashSlot.caption,
      BoxConstraints(maxWidth: math.min(captionMaxWidth, maxWidth)),
    );
    final captionGap = caption.height > 0 ? gap : 0.0;
    var top = (size.height - brand.height) / 2;
    final overflow = top +
        brand.height +
        captionGap +
        caption.height -
        (size.height - padding.bottom);
    if (overflow > 0) {
      top -= math.min(overflow, math.max(0.0, top - padding.top));
    }
    positionChild(
      _SplashSlot.brand,
      Offset((size.width - brand.width) / 2, top),
    );
    positionChild(
      _SplashSlot.caption,
      Offset((size.width - caption.width) / 2, top + brand.height + captionGap),
    );
  }

  @override
  bool shouldRelayout(_SplashLayout oldDelegate) =>
      oldDelegate.gap != gap ||
      oldDelegate.padding != padding ||
      oldDelegate.captionMaxWidth != captionMaxWidth;
}

/// 失败页按钮。确定键、左右键自己接：电视遥控的确定键不一定在应用快捷键里。
class _SplashButton extends StatefulWidget {
  const _SplashButton({
    required this.label,
    required this.onPressed,
    required this.splash,
    this.primary = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onPressed;
  final MySplash splash;
  final bool primary;
  final bool autofocus;

  @override
  State<_SplashButton> createState() => _SplashButtonState();
}

class _SplashButtonState extends State<_SplashButton> {
  final _node = FocusNode(debugLabel: 'MySplash button');
  var _focused = false;
  var _hovered = false;

  /// 抢焦点之前的焦点（盖在下面的首页）。按钮撤掉时还给它，遥控不会落空。
  FocusNode? _previous;

  static final _activateKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  };

  @override
  void initState() {
    super.initState();
    if (!widget.autofocus) return;
    // 不能用 Focus.autofocus：根焦点域里已经有首页路由的焦点，
    // autofocus 只在域里没有焦点时才生效。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = FocusManager.instance.primaryFocus;
      if (current != _node) _previous = current;
      _node.requestFocus();
    });
  }

  @override
  void dispose() {
    final previous = _previous;
    final hadFocus = _node.hasPrimaryFocus;
    _node.dispose();
    super.dispose();
    if (!hadFocus || previous == null) return;
    // 拆树时不当场改焦点，等这一帧拆完。
    scheduleMicrotask(() {
      if (previous.context != null && previous.canRequestFocus) {
        previous.requestFocus();
      }
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final activates = _activateKeys.contains(key);
    final horizontal = key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
    // 上下键吞掉：交给应用的方向导航会把焦点送到盖在下面的首页。
    final vertical = key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;
    if (!activates && !horizontal && !vertical) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (activates) {
        widget.onPressed();
      } else if (horizontal) {
        node.focusInDirection(key == LogicalKeyboardKey.arrowLeft
            ? TraversalDirection.left
            : TraversalDirection.right);
      }
    }
    return event is KeyUpEvent
        ? KeyEventResult.ignored
        : KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final splash = widget.splash;
    final ink = splash.textColor;
    final fill = widget.primary ? (splash.accentColor ?? ink) : null;
    final foreground = widget.primary ? splash.backgroundColor : ink;
    final radius = BorderRadius.circular(8.r);
    final ring = _focused || _hovered;
    return Focus(
      focusNode: _node,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: _onKeyEvent,
      child: Semantics(
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.w),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: radius,
                border: widget.primary
                    ? null
                    : Border.all(color: ink.withValues(alpha: 0.35)),
                // 外圈用文字色、内圈用底色：主按钮底色和文字色相同时焦点仍看得出。
                boxShadow: ring
                    ? [
                        BoxShadow(color: ink, spreadRadius: 4.w),
                        BoxShadow(
                          color: splash.backgroundColor,
                          spreadRadius: 2.w,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
