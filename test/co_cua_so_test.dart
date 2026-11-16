// Test tính cỡ cửa sổ vừa màn hình (giống app chấm công bản
// windows-53): rộng = min(800, rộng màn − 16), cao = min(1024,
// cao màn − 16), kẹp trong 520×480 đến 900×1150.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/tien_ich/co_cua_so.dart';

void main() {
  test('màn hình lớn: 800×1024', () {
    expect(tinhCoCuaSo(1920, 1080), const Size(800, 1024));
    expect(tinhCoCuaSo(2560, 1440), const Size(800, 1024));
  });

  test('màn hình laptop thường: co cao theo màn hình', () {
    expect(tinhCoCuaSo(1366, 768), const Size(800, 752));
    expect(tinhCoCuaSo(1024, 768), const Size(800, 752));
  });

  test('màn hình nhỏ: co cả rộng lẫn cao', () {
    expect(tinhCoCuaSo(800, 600), const Size(784, 584));
    expect(tinhCoCuaSo(600, 500), const Size(584, 484));
  });

  test('màn hình rất nhỏ: kẹp ở cỡ tối thiểu 520×480', () {
    expect(tinhCoCuaSo(500, 400), const Size(520, 480));
    expect(tinhCoCuaSo(300, 300), const Size(520, 480));
  });

  test('cỡ tính ra luôn trong giới hạn cho phép', () {
    for (final (rong, cao) in [
      (1920, 1080),
      (1366, 768),
      (800, 600),
      (500, 400),
      (1024, 600),
    ]) {
      final co = tinhCoCuaSo(rong.toDouble(), cao.toDouble());
      expect(co.width, inInclusiveRange(520, 900));
      expect(co.height, inInclusiveRange(480, 1150));
    }
  });
}
