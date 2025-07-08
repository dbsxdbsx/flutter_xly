import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  test('GetStorage should be exported from xly package', () {
    // 测试GetStorage类是否可以从xly包中访问
    expect(GetStorage, isNotNull);
  });
}
