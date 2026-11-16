// Test hồi quy mẫu thường + tỉ lệ chữ "Kč" ở giá lớn.
// Lỗi user báo (bản windows-4): mẫu thường không xem trước, không in
// được — nguyên nhân là _macThuong dùng CrossAxisAlignment.stretch
// trong ListView cao vô hạn nên layout vỡ (BoxConstraints forces an
// infinite height). Test này khóa lại: xem trước trong ListView phải
// chạy được, PDF tạo được, và chữ "Kč" ở giá lớn bằng khoảng 45%
// cỡ số (mẫu thường, giảm giá, gọn, song ngữ). Riêng mẫu Nhẹ nhàng
// giữ Kč nhỏ như tên nên không nằm trong test này.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
import 'package:in_mac_gia/mau_mac/xem_truoc_mac.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';

SanPham sanPhamMau({double? giaGiam}) {
  return SanPham(
    id: 'sp1',
    tenSec: 'Eidam 45% 500 g',
    tenAnh: 'Eidam cheese 45% 500 g',
    maVach: '5901234123457',
    gia: 99.9,
    giaGiam: giaGiam,
    donVi: 'ks',
    khoiLuongGam: 500,
    capNhat: DateTime(2026, 11, 15),
  );
}

/// Cỡ chữ của số giá lớn và của chữ "Kč" khi xem trước 1 mẫu.
Future<(double, double)> _coGiaVaKc(
  WidgetTester tester,
  MauMac mau, {
  required String soGia,
  SanPham? sanPham,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            XemTruocMac(
              sanPham: sanPham ?? sanPhamMau(),
              mau: mau,
              caiDat: const CaiDat(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
  final so = tester.widget<Text>(find.text(soGia));
  final kc = tester.widget<Text>(find.text('Kč'));
  return (so.style!.fontSize!, kc.style!.fontSize!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tạo PDF mẫu thường', () async {
    final taiLieu = await taoTaiLieuMac(
      mucIn: [(sanPham: sanPhamMau(), soLuong: 1)],
      caiDat: const CaiDat().copyWith(mauMac: MauMac.thuong),
    );
    final bytes = await taiLieu.save();
    expect(bytes.length, greaterThan(0));
  });

  testWidgets('xem trước mẫu thường trong ListView (cao vô hạn)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              XemTruocMac(
                sanPham: sanPhamMau(),
                mau: MauMac.thuong,
                caiDat: const CaiDat(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('99,90'), findsOneWidget);
  });

  group('chữ "Kč" ở giá lớn bằng khoảng 45% cỡ số', () {
    testWidgets('mẫu thường: số 30 thì Kč khoảng 13,5', (tester) async {
      final (coSo, coKc) = await _coGiaVaKc(
        tester,
        MauMac.thuong,
        soGia: '99,90',
      );
      expect(coSo, 30);
      expect(coKc / coSo, closeTo(0.45, 0.01));
    });

    testWidgets('mẫu giảm giá: số 30 thì Kč khoảng 13,5', (tester) async {
      final (coSo, coKc) = await _coGiaVaKc(
        tester,
        MauMac.giamGia,
        soGia: '79,90',
        sanPham: sanPhamMau(giaGiam: 79.9),
      );
      expect(coSo, 30);
      expect(coKc / coSo, closeTo(0.45, 0.01));
    });

    testWidgets('mẫu gọn: số 30 thì Kč khoảng 13,5', (tester) async {
      final (coSo, coKc) = await _coGiaVaKc(tester, MauMac.gon, soGia: '99,90');
      expect(coSo, 30);
      expect(coKc / coSo, closeTo(0.45, 0.01));
    });

    testWidgets('mẫu song ngữ hiện đại: số 30 thì Kč khoảng 13,5', (
      tester,
    ) async {
      final (coSo, coKc) = await _coGiaVaKc(
        tester,
        MauMac.songNguHienDai,
        soGia: '99,90',
      );
      expect(coSo, 30);
      expect(coKc / coSo, closeTo(0.45, 0.01));
    });
  });
}
