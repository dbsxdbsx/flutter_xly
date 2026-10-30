part of '../../app.dart';

/// 启动动画上的两个时间点，都是 0~1 的进度。
///
/// - [motionEnd]：从这里起画面上没有大动作了。标了
///   [MyBootstrapTask.afterSplashMotion] 的任务从这里开始跑，主线程被占住也看不出卡。
/// - [hold]：停在这一格当定格画面，播到这里才算播完。
///
/// [MySplashAnimationTiming.fromLottieJson] 从素材里推；推不准时用
/// [MySplash.holdFrame] / [MySplash.motionEndFrame] 按帧号指定。
@immutable
class MySplashAnimationTiming {
  const MySplashAnimationTiming({required this.motionEnd, required this.hold})
      : assert(0 <= motionEnd && motionEnd <= hold && hold <= 1);

  /// 整段播完，播完才放行后面的任务。读不出素材结构时用它。
  static const whole = MySplashAnimationTiming(motionEnd: 1, hold: 1);

  final double motionEnd;
  final double hold;

  static const _contentLayerTypes = {0, 1, 2, 4, 5};
  static const _maxPrecompDepth = 8;

  /// 从 Lottie JSON 推两个时间点。
  ///
  /// [motionEnd]：所有动画属性最晚的关键帧，只算图层在画面上那段时间（出现前
  /// 做完的不算，消失后的截到消失那帧）。预合成按 `st + t × sr` 换回主时间轴；
  /// 带时间重映射的预合成只看重映射本身的关键帧。图层出现、消失这种一帧的变化
  /// 不算动作：主线程晚一点画出来，看不出来。
  ///
  /// [hold]：大动作做完那一刻还在画面上的内容图层（预合成、纯色、图片、形状、
  /// 文字；隐藏层不算，遮罩源要算），就是最后的画面；其中最早消失的那层的前一帧
  /// 就是定格。收尾几帧常是元素被收走、遮罩结束，停在最后一帧会露出半空的画面。
  /// 中途一闪而过的图层不影响定格。预合成按里面的图层往下找。
  ///
  /// 用透明度关键帧做的淡出收尾推不出来（淡出本身就是大动作），这种素材用
  /// [MySplash.holdFrame] 指定。
  factory MySplashAnimationTiming.fromLottieJson(Map<String, Object?> json) {
    final start = _number(json['ip']);
    final end = _number(json['op']);
    final layers = json['layers'];
    if (start == null || end == null || end <= start || layers is! List) {
      return whole;
    }
    final assets = <String, List<Object?>>{};
    final rawAssets = json['assets'];
    if (rawAssets is List) {
      for (final asset in rawAssets.whereType<Map<String, Object?>>()) {
        final id = asset['id'];
        final assetLayers = asset['layers'];
        if (id is String && assetLayers is List) assets[id] = assetLayers;
      }
    }

    double progress(double frame) =>
        ((frame - start) / (end - start)).clamp(0.0, 1.0).toDouble();

    final visible = [
      for (final layer in layers.whereType<Map<String, Object?>>())
        if (layer['hd'] != true) layer,
    ];
    var lastMotion = double.negativeInfinity;
    for (final layer in visible) {
      lastMotion = math.max(lastMotion, _lastMotion(layer, assets, 0));
    }
    final settledAt = lastMotion.isFinite ? math.max(lastMotion, start) : start;
    var lastFull = end;
    for (final layer in visible) {
      final until = _heldUntil(layer, settledAt, assets, 0);
      if (until != null) lastFull = math.min(lastFull, until);
    }
    final hold = progress(lastFull);
    return MySplashAnimationTiming(
      motionEnd: lastMotion.isFinite ? math.min(progress(lastMotion), hold) : 0,
      hold: hold,
    );
  }

  /// 按帧号覆盖推出来的点。帧号和 Lottie 编辑器里看到的一致。
  ///
  /// 只给 [holdFrame] 时 [motionEnd] 不超过新的 [hold]。
  MySplashAnimationTiming withFrames({
    required double startFrame,
    required double endFrame,
    double? holdFrame,
    double? motionEndFrame,
  }) {
    if (holdFrame == null && motionEndFrame == null) return this;
    if (!(endFrame > startFrame)) return this;
    double progress(double frame) =>
        ((frame - startFrame) / (endFrame - startFrame))
            .clamp(0.0, 1.0)
            .toDouble();
    final nextHold = holdFrame == null ? hold : progress(holdFrame);
    final nextMotion =
        motionEndFrame == null ? motionEnd : progress(motionEndFrame);
    return MySplashAnimationTiming(
      motionEnd: math.min(nextMotion, nextHold),
      hold: nextHold,
    );
  }

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : null;

  /// 这一层在父时间轴上最后一次有动作的帧；没有动画属性时是负无穷。
  static double _lastMotion(
    Map<String, Object?> layer,
    Map<String, List<Object?>> assets,
    int depth,
  ) {
    var last = _lastKeyframe(layer);
    final st = _number(layer['st']) ?? 0;
    final sr = _number(layer['sr']) ?? 1;
    final inner = assets[layer['refId']];
    // 倒放（sr ≤ 0）、时间重映射和过深的嵌套不往里找，只看这一层自己的关键帧。
    if (layer['ty'] == 0 &&
        layer['tm'] == null &&
        depth < _maxPrecompDepth &&
        inner != null &&
        sr > 0) {
      for (final child in inner.whereType<Map<String, Object?>>()) {
        if (child['hd'] == true) continue;
        final childLast = _lastMotion(child, assets, depth + 1);
        if (childLast.isFinite) last = math.max(last, st + childLast * sr);
      }
    }
    return _whileOnScreen(layer, last);
  }

  /// 只留图层在画面上那段时间里的动作。空层、相机这类不画东西的图层管的是
  /// 别的图层（父级变换），不按自己的出入点截。
  static double _whileOnScreen(Map<String, Object?> layer, double frame) {
    if (!frame.isFinite || !_contentLayerTypes.contains(layer['ty'])) {
      return frame;
    }
    final ip = _number(layer['ip']);
    final op = _number(layer['op']);
    if (ip != null && frame < ip) return double.negativeInfinity;
    if (op != null && frame > op) return op;
    return frame;
  }

  /// [at] 那一刻在画面上的内容图层能完整留在画面上的最后一帧；不在画面上时返回 null。
  static double? _heldUntil(
    Map<String, Object?> layer,
    double at,
    Map<String, List<Object?>> assets,
    int depth,
  ) {
    if (layer['hd'] == true) return null;
    if (!_contentLayerTypes.contains(layer['ty'])) return null;
    final ip = _number(layer['ip']);
    final op = _number(layer['op']);
    if (ip == null || op == null || !(ip <= at && at < op)) {
      return null;
    }
    var until = op - 1;
    if (layer['ty'] != 0 || layer['tm'] != null || depth >= _maxPrecompDepth) {
      return until;
    }
    final inner = assets[layer['refId']];
    final st = _number(layer['st']) ?? 0;
    final sr = _number(layer['sr']) ?? 1;
    if (inner == null || sr <= 0) return until;
    final localAt = (at - st) / sr;
    for (final child in inner.whereType<Map<String, Object?>>()) {
      final childUntil = _heldUntil(child, localAt, assets, depth + 1);
      if (childUntil != null) until = math.min(until, st + childUntil * sr);
    }
    return until;
  }

  static double _lastKeyframe(Object? node) {
    var last = double.negativeInfinity;
    if (node is Map) {
      final keyframes = node['k'];
      if (node['a'] == 1 && keyframes is List) {
        for (final keyframe in keyframes) {
          if (keyframe is Map) {
            final time = _number(keyframe['t']);
            if (time != null) last = math.max(last, time);
          }
        }
      }
      for (final value in node.values) {
        last = math.max(last, _lastKeyframe(value));
      }
    } else if (node is List) {
      for (final value in node) {
        last = math.max(last, _lastKeyframe(value));
      }
    }
    return last;
  }

  @override
  bool operator ==(Object other) =>
      other is MySplashAnimationTiming &&
      other.motionEnd == motionEnd &&
      other.hold == hold;

  @override
  int get hashCode => Object.hash(motionEnd, hold);

  @override
  String toString() =>
      'MySplashAnimationTiming(motionEnd: ${motionEnd.toStringAsFixed(3)}, '
      'hold: ${hold.toStringAsFixed(3)})';
}

/// 载好的启动动画：Lottie 素材加上从素材推出的时间点。
///
/// [MyApp.initialize] 在 `runApp` 前按 [MySplash.lottieAssetPath] 预载（最多等
/// [MySplash.preloadLimit]），叠层第一帧就能按动画真实比例留位置、直接开播。
/// 自定义品牌区（[MySplash.brandBuilder]）也可以用 [load] 拿同一份。
class MySplashClip {
  MySplashClip(this.composition, {this.timing = MySplashAnimationTiming.whole});

  final LottieComposition composition;

  /// 从素材推出来的时间点，没有套 [MySplash.holdFrame] 这类覆盖。
  final MySplashAnimationTiming timing;

  Duration get duration => composition.duration;

  /// 宽 / 高。素材没写尺寸时按正方形。
  double get aspectRatio {
    final bounds = composition.bounds;
    if (bounds.width <= 0 || bounds.height <= 0) return 1;
    return bounds.width / bounds.height;
  }

  /// 套上帧号覆盖后的时间点。
  MySplashAnimationTiming timingWith({
    double? holdFrame,
    double? motionEndFrame,
  }) {
    return timing.withFrames(
      startFrame: composition.startFrame,
      endFrame: composition.endFrame,
      holdFrame: holdFrame,
      motionEndFrame: motionEndFrame,
    );
  }

  static final _loading = <String, Future<MySplashClip?>>{};
  static final _loaded = <String, MySplashClip>{};

  /// 开始（或复用）加载。失败返回 null，不抛。
  ///
  /// 支持 JSON 和 dotLottie（zip）；zip 读不出结构，时间点按 [MySplashAnimationTiming.whole]。
  static Future<MySplashClip?> load(String assetPath) {
    return _loading[assetPath] ??= _load(assetPath);
  }

  /// 已经载好的那份；还在加载或失败时返回 null。
  static MySplashClip? peek(String assetPath) => _loaded[assetPath];

  /// 测试用：直接放进缓存，[peek] / [load] 都会拿到它。
  @visibleForTesting
  static void debugSeed(String assetPath, MySplashClip clip) {
    _loaded[assetPath] = clip;
    _loading[assetPath] = Future<MySplashClip?>.value(clip);
  }

  @visibleForTesting
  static void debugClear() {
    _loaded.clear();
    _loading.clear();
  }

  static Future<MySplashClip?> _load(String assetPath) async {
    try {
      // 两份解析都放后台 isolate：素材大时主线程不被占住，preloadLimit 才真能限住等待。
      final timingLoad = _readTiming(assetPath);
      final composition =
          await AssetLottie(assetPath, backgroundLoading: true).load();
      final timing = await timingLoad;
      final clip = MySplashClip(composition, timing: timing);
      _loaded[assetPath] = clip;
      MyBootTrace.mark(
        'splash.clip',
        '${composition.duration.inMilliseconds}ms '
            'motionEnd=${timing.motionEnd.toStringAsFixed(3)} '
            'hold=${timing.hold.toStringAsFixed(3)}',
      );
      return clip;
    } catch (e, st) {
      XlyLogger.error('MySplashClip: 启动动画加载失败 ($assetPath)', e, st);
      MyBootTrace.mark('splash.clip-failed', '$e');
      return null;
    }
  }

  static Future<MySplashAnimationTiming> _readTiming(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (!_looksLikeJson(bytes)) return MySplashAnimationTiming.whole;
      return await compute(
        _timingFromBytes,
        bytes,
        debugLabel: 'xly splash timing',
      );
    } catch (e) {
      XlyLogger.warning('MySplashClip: 读不出动画时间点，整段播完 ($assetPath): $e');
    }
    return MySplashAnimationTiming.whole;
  }

  static MySplashAnimationTiming _timingFromBytes(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes, allowMalformed: true));
    if (json is Map<String, Object?>) {
      return MySplashAnimationTiming.fromLottieJson(json);
    }
    return MySplashAnimationTiming.whole;
  }

  static bool _looksLikeJson(List<int> bytes) {
    var i = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      i = 3;
    }
    for (; i < bytes.length; i++) {
      final b = bytes[i];
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) continue;
      return b == 0x7B;
    }
    return false;
  }
}
