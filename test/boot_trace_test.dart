import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  setUp(MyBootTrace.debugReset);
  tearDown(MyBootTrace.debugReset);

  test('关着时不打点', () {
    MyBootTrace.mark('app.initialize');
    final lines = <String>[];
    MyBootTrace.attachSink(lines.add);
    MyBootTrace.mark('splash.gone');

    expect(lines, isEmpty);
    expect(MyBootTrace.lastStep, isEmpty);
  });

  test('接上应用日志之前的行按原顺序补写，之后直接写；细节压成一行', () {
    MyBootTrace.enabled = true;
    MyBootTrace.mark('app.initialize');
    MyBootTrace.mark('bootstrap.task', 'load\n  config');
    final lines = <String>[];
    MyBootTrace.attachSink(lines.add);
    MyBootTrace.mark('splash.gone');

    expect(lines, hasLength(3));
    expect(lines[0], matches(RegExp(r'^\+\d+ms app\.initialize$')));
    expect(lines[1], matches(RegExp(r'^\+\d+ms bootstrap\.task load config$')));
    expect(lines[2], matches(RegExp(r'^\+\d+ms splash\.gone$')));
    expect(MyBootTrace.lastStep, 'splash.gone');
  });

  test('缓冲满了丢最早的行，补写时先说明丢了几行', () {
    MyBootTrace.enabled = true;
    for (var i = 0; i < 70; i++) {
      MyBootTrace.mark('step.$i');
    }
    final lines = <String>[];
    MyBootTrace.attachSink(lines.add);

    expect(lines, hasLength(65));
    expect(lines.first, contains('更早的 6 行'));
    expect(lines[1], endsWith(' step.6'));
    expect(lines.last, endsWith(' step.69'));
  });

  test('细节太长时截断；应用日志抛错不影响打点', () {
    MyBootTrace.enabled = true;
    MyBootTrace.attachSink((_) => throw StateError('disk full'));
    MyBootTrace.mark('bootstrap.error', 'x' * 400);

    final lines = <String>[];
    MyBootTrace.attachSink(lines.add);
    MyBootTrace.mark('bootstrap.error', 'y' * 400);

    expect(lines.single, endsWith(' ${'y' * 160}…'));
  });
}
