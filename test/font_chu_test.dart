// Test chọn font chữ trong Cài đặt: font đã chọn áp cho chữ chính
// của các mẫu; mẫu Cổ điển và Nhẹ nhàng thiết kế serif sẵn nên
// luôn giữ serif dù chọn Sans.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/chuoi_mac.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
import 'package:in_mac_gia/mau_mac/xem_truoc_mac.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';

SanPham _sanPhamMau() {
  return SanPham(
    id: 'sp1',
    tenSec: 'Eidam 45% 500 g',
    tenAnh: 'Eidam cheese 45% 500 g',
    maVach: '5901234123457',
    gia: 99.9,
    donVi: 'ks',
    khoiLuongGam: 500,
    capNhat: DateTime(2026, 11, 15),
  );
}

Future<String> _taoPdfChu({
  required MauMac mau,
  required FontMac fontChu,
}) async {
  final cd = const CaiDat().copyWith(mauMac: mau, fontChu: fontChu);
  final taiLieu = await taoTaiLieuMac(
    mucIn: [(sanPham: _sanPhamMau(), soLuong: 1)],
    caiDat: cd,
  );
  return String.fromCharCodes(await taiLieu.save());
}

Future<void> _pumpXemTruoc(
  WidgetTester tester, {
  required MauMac mau,
  required FontMac fontChu,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            XemTruocMac(
              sanPham: _sanPhamMau(),
              mau: mau,
              caiDat: const CaiDat().copyWith(fontChu: fontChu),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaiDat: lưu/tải lựa chọn font', () {
    test('mặc định là Sans', () {
      expect(const CaiDat().fontChu, FontMac.sans);
    });

    test('chọn Serif rồi lưu/tải lại được', () {
      final chon = const CaiDat().copyWith(fontChu: FontMac.serif);
      expect(chon.fontChu, FontMac.serif);
      expect(CaiDat.fromJson(chon.toJson()).fontChu, FontMac.serif);
    });

    test('file cài đặt cũ chưa có khóa này thì mặc định là Sans', () {
      expect(CaiDat.fromJson({}).fontChu, FontMac.sans);
      expect(CaiDat.fromJson({'fontChu': 'khong-co'}).fontChu, FontMac.sans);
    });

    test('tên hiển thị của 2 font', () {
      expect(FontMac.sans.tenHienThi, 'Sans (không chân)');
      expect(FontMac.serif.tenHienThi, 'Serif (có chân)');
    });
  });

  group('PDF: font đã chọn áp cho chữ chính', () {
    test('mẫu thường chọn Serif thì chỉ dùng font Serif', () async {
      final pdf = await _taoPdfChu(mau: MauMac.thuong, fontChu: FontMac.serif);
      expect(pdf, contains('LiberationSerif'));
      expect(pdf, isNot(contains('LiberationSans')));
    });

    test('mẫu thường chọn Sans thì chỉ dùng font Sans', () async {
      final pdf = await _taoPdfChu(mau: MauMac.thuong, fontChu: FontMac.sans);
      expect(pdf, contains('LiberationSans'));
      expect(pdf, isNot(contains('LiberationSerif')));
    });

    test('mẫu Cổ điển luôn giữ Serif dù chọn Sans', () async {
      final pdf = await _taoPdfChu(
        mau: MauMac.songNguCoDien,
        fontChu: FontMac.sans,
      );
      expect(pdf, contains('LiberationSerif'));
      expect(pdf, isNot(contains('LiberationSans')));
    });

    test('mẫu Nhẹ nhàng luôn giữ Serif dù chọn Sans', () async {
      final pdf = await _taoPdfChu(
        mau: MauMac.songNguNheNhang,
        fontChu: FontMac.sans,
      );
      expect(pdf, contains('LiberationSerif'));
      expect(pdf, isNot(contains('LiberationSans')));
    });
  });

  group('xem trước: font đã chọn áp cho chữ chính', () {
    testWidgets('mẫu thường: Serif thì tên dùng LiberationSerif', (
      tester,
    ) async {
      final ten = tenSecHienThi(_sanPhamMau(), const CaiDat());
      await _pumpXemTruoc(tester, mau: MauMac.thuong, fontChu: FontMac.serif);
      expect(
        tester.widget<Text>(find.text(ten)).style!.fontFamily,
        'LiberationSerif',
      );

      await _pumpXemTruoc(tester, mau: MauMac.thuong, fontChu: FontMac.sans);
      expect(
        tester.widget<Text>(find.text(ten)).style!.fontFamily,
        'LiberationSans',
      );
    });

    testWidgets('mẫu Cổ điển luôn giữ Serif dù chọn Sans', (tester) async {
      final ten = tenSecHienThi(_sanPhamMau(), const CaiDat());
      await _pumpXemTruoc(
        tester,
        mau: MauMac.songNguCoDien,
        fontChu: FontMac.sans,
      );
      expect(
        tester.widget<Text>(find.text(ten)).style!.fontFamily,
        'LiberationSerif',
      );
    });
  });
}
