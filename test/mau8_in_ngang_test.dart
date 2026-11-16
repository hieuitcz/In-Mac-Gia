// Test in ngang mẫu 8 (Nhẹ nhàng): xoay 90° để tên dài vừa 1 dòng.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
import 'package:in_mac_gia/mau_mac/xem_truoc_mac.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';

SanPham _sanPhamTenDai() {
  return SanPham(
    id: 'sp-dai',
    tenSec: 'Sýr Eidam 45% uzený krájený na plátky 500 g',
    tenAnh: 'Smoked Eidam cheese 45% sliced into thin slices 500 g',
    maVach: '5901234123457',
    gia: 129.9,
    donVi: 'ks',
    khoiLuongGam: 500,
    capNhat: DateTime(2026, 11, 16),
  );
}

/// Đọc tất cả MediaBox (rộng, cao) theo đơn vị point trong file PDF.
List<(double, double)> _docKhoTrang(List<int> pdf) {
  final text = String.fromCharCodes(pdf);
  final mau = RegExp(r'MediaBox\[([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)\]');
  return mau
      .allMatches(text)
      .map((m) => (double.parse(m.group(3)!), double.parse(m.group(4)!)))
      .toList();
}

Future<(double, double)> _khoTrangMau8({required bool inNgang}) async {
  final cd = const CaiDat().copyWith(
    mauMac: MauMac.songNguNheNhang,
    inNgangMau8: inNgang,
  );
  final taiLieu = await taoTaiLieuMac(
    mucIn: [(sanPham: _sanPhamTenDai(), soLuong: 1)],
    caiDat: cd,
  );
  final khoTrang = _docKhoTrang(await taiLieu.save());
  expect(khoTrang.length, 1);
  return khoTrang.first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mẫu 8 dọc: trang rộng 80 mm, cao vừa nội dung', () async {
    final (rong, cao) = await _khoTrangMau8(inNgang: false);
    expect(rong, closeTo(80 * 72 / 25.4, 0.5));
    expect(cao.isFinite && cao > 0, isTrue);
  });

  test('mẫu 8 ngang: trang vẫn rộng 80 mm, dài hơn hẳn bản dọc', () async {
    final (_, caoDoc) = await _khoTrangMau8(inNgang: false);
    final (rong, caoNgang) = await _khoTrangMau8(inNgang: true);
    // 80 mm = 226,77 point: chiều rộng trang vẫn là cuộn giấy 80 mm,
    // giờ là chiều cao của dải tem ngang.
    expect(rong, closeTo(80 * 72 / 25.4, 0.5));
    // Tên dài chạy dọc theo cuộn nên dải tem dài hơn hẳn bản dọc
    // (bản dọc tên dài phải ngắt xuống 2 dòng).
    expect(caoNgang, greaterThan(caoDoc * 1.5));
  });

  test('mẫu 8 ngang không áp cho mẫu khác', () async {
    // Cùng bật công tắc nhưng in mẫu thường: trang vẫn là bản dọc
    // (cao vừa nội dung, không dài bất thường).
    final cd = const CaiDat().copyWith(
      mauMac: MauMac.thuong,
      inNgangMau8: true,
    );
    final taiLieu = await taoTaiLieuMac(
      mucIn: [(sanPham: _sanPhamTenDai(), soLuong: 1)],
      caiDat: cd,
    );
    final khoTrang = _docKhoTrang(await taiLieu.save());
    expect(khoTrang.length, 1);
    final (rong, cao) = khoTrang.first;
    expect(rong, closeTo(80 * 72 / 25.4, 0.5));
    expect(cao, lessThan(150));
  });

  test('cài đặt in ngang mẫu 8 lưu/tải lại được', () {
    const macDinh = CaiDat();
    expect(macDinh.inNgangMau8, isFalse);
    final bat = macDinh.copyWith(inNgangMau8: true);
    expect(bat.inNgangMau8, isTrue);
    final taiLai = CaiDat.fromJson(bat.toJson());
    expect(taiLai.inNgangMau8, isTrue);
    // File cài đặt cũ chưa có khóa này thì mặc định là dọc.
    expect(CaiDat.fromJson({}).inNgangMau8, isFalse);
  });

  testWidgets('xem trước mẫu 8 ngang có RotatedBox, dọc thì không', (
    tester,
  ) async {
    Future<void> pump({required bool inNgang}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                XemTruocMac(
                  sanPham: _sanPhamTenDai(),
                  mau: MauMac.songNguNheNhang,
                  caiDat: const CaiDat().copyWith(inNgangMau8: inNgang),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await pump(inNgang: false);
    expect(find.byType(RotatedBox), findsNothing);

    await pump(inNgang: true);
    final xoay = tester.widget<RotatedBox>(find.byType(RotatedBox));
    expect(xoay.quarterTurns, 1);
  });
}
