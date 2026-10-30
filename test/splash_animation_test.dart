import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

Map<String, Object?> _shape({
  required num ip,
  required num op,
  List<num> keyframes = const [],
  bool hidden = false,
  int type = 4,
}) {
  return {
    'ty': type,
    'ip': ip,
    'op': op,
    if (hidden) 'hd': true,
    'ks': {
      'p': keyframes.isEmpty
          ? {
              'a': 0,
              'k': [0, 0, 0],
            }
          : {
              'a': 1,
              'k': [
                for (final t in keyframes)
                  {
                    't': t,
                    's': [0, 0, 0],
                  },
              ],
            },
    },
  };
}

void main() {
  test('示例动画：遮罩源先走，定格停在第 93 帧，大动作到 63.44 帧', () {
    final json = jsonDecode(
      File('example/assets/animation/splash_loading.json').readAsStringSync(),
    ) as Map<String, Object?>;

    final timing = MySplashAnimationTiming.fromLottieJson(json);

    expect(timing.hold, 93 / 96);
    expect(timing.motionEnd, closeTo(63.437578125 / 96, 1e-9));
  });

  test('所有内容层都到结尾时停在最后一帧之前一帧', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 60,
      'layers': [
        _shape(ip: 0, op: 60, keyframes: [0, 30]),
      ],
    });

    expect(timing.hold, 59 / 60);
    expect(timing.motionEnd, 0.5);
  });

  test('中途一闪而过的图层不截断后面的动作', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 120,
      'layers': [
        _shape(ip: 0, op: 120, keyframes: [0, 90]),
        _shape(ip: 50, op: 62),
      ],
    });

    expect(timing.hold, 119 / 120);
    expect(timing.motionEnd, 0.75);
  });

  test('只算图层在画面上那段时间的动作', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 100,
      'layers': [
        _shape(ip: 0, op: 100, keyframes: [0, 30]),
        // 出现之前就做完了。
        _shape(ip: 60, op: 100, keyframes: [0, 50]),
        // 第 40 帧就消失了，后面的关键帧看不见。
        _shape(ip: 0, op: 40, keyframes: [0, 80]),
      ],
    });

    expect(timing.motionEnd, 0.4);
    expect(timing.hold, 99 / 100);
  });

  test('空层带着子层动，不按自己的出入点截', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 100,
      'layers': [
        _shape(ip: 0, op: 100),
        _shape(ip: 0, op: 10, type: 3, keyframes: [0, 70]),
      ],
    });

    expect(timing.motionEnd, 0.7);
    expect(timing.hold, 99 / 100);
  });

  test('隐藏层、空层和动作做完时不在画面上的图层不决定定格帧', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 100,
      'layers': [
        _shape(ip: 0, op: 100, keyframes: [0, 40]),
        _shape(ip: 0, op: 60, hidden: true, keyframes: [0, 90]),
        _shape(ip: 0, op: 55, type: 3),
        _shape(ip: 0, op: 30),
        _shape(ip: 70, op: 100),
      ],
    });

    expect(timing.hold, 99 / 100);
    expect(timing.motionEnd, 0.4);
  });

  test('预合成按里面的图层算，时间按 st + t × sr 换回主时间轴', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 100,
      'assets': [
        {
          'id': 'comp_0',
          'layers': [
            _shape(ip: 0, op: 40, keyframes: [0, 20]),
          ],
        },
      ],
      'layers': [
        {
          'ty': 0,
          'refId': 'comp_0',
          'ip': 0,
          'op': 100,
          'st': 10,
          'sr': 2,
        },
      ],
    });

    // 里面那层到局部第 40 帧消失：主时间轴 10 + 39 × 2 = 88。
    expect(timing.hold, 88 / 100);
    // 里面最后一个关键帧在局部第 20 帧：10 + 20 × 2 = 50。
    expect(timing.motionEnd, 0.5);
  });

  test('带时间重映射的预合成只看重映射本身的关键帧', () {
    final timing = MySplashAnimationTiming.fromLottieJson({
      'ip': 0,
      'op': 100,
      'assets': [
        {
          'id': 'comp_0',
          'layers': [
            _shape(ip: 0, op: 100, keyframes: [0, 90]),
          ],
        },
      ],
      'layers': [
        {
          'ty': 0,
          'refId': 'comp_0',
          'ip': 0,
          'op': 100,
          'tm': {
            'a': 1,
            'k': [
              {
                't': 0,
                's': [0],
              },
              {
                't': 25,
                's': [1],
              },
            ],
          },
        },
      ],
    });

    expect(timing.motionEnd, 0.25);
  });

  test('读不出结构时整段播完', () {
    expect(
      MySplashAnimationTiming.fromLottieJson({'layers': []}),
      MySplashAnimationTiming.whole,
    );
    expect(
      MySplashAnimationTiming.fromLottieJson({'ip': 10, 'op': 10}),
      MySplashAnimationTiming.whole,
    );
  });

  test('按帧号覆盖推出来的点，大动作不晚于定格', () {
    const detected = MySplashAnimationTiming(motionEnd: 0.6, hold: 0.9);

    final both = detected.withFrames(
      startFrame: 0,
      endFrame: 100,
      holdFrame: 80,
      motionEndFrame: 20,
    );
    expect(both, const MySplashAnimationTiming(motionEnd: 0.2, hold: 0.8));

    final holdOnly =
        detected.withFrames(startFrame: 0, endFrame: 100, holdFrame: 50);
    expect(holdOnly, const MySplashAnimationTiming(motionEnd: 0.5, hold: 0.5));

    expect(detected.withFrames(startFrame: 0, endFrame: 100), detected);
  });
}
