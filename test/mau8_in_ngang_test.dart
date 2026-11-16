// Test in ngang mẫu 8 (Nhẹ nhàng): VẪN KHỔ DỌC 80mm nhưng chữ
// viết theo chiều dọc — chữ xoay 90° ngược chiều kim đồng hồ, đọc
// từ dưới lên trên, cột "CENA / PRICE" ở bên phải, 2 dòng sản phẩm
// (tiếng Anh rồi tiếng Séc) là các cột đứng bên trái nó, có vạch
// chia dọc giữa các cột, khung viền mỏng bao ngoài. Xoay tem 90°
// ngược chiều kim đồng hồ để đọc thì thành: tiêu đề "CENA / PRICE"
// ở trên cùng, dưới nó là 1 đường gạch ngang (chính là vạch chia
// dọc bên cạnh cột tiêu đề), rồi đến các dòng sản phẩm.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/chuoi_mac.dart';
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
    // giờ là chiều rộng của dải tem đứng (chữ viết dọc theo cuộn).
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

  testWidgets('xem trước mẫu 8 ngang: 3 cột dọc, CENA / PRICE bên phải', (
    tester,
  ) async {
    final sp = _sanPhamTenDai();
    const cd = CaiDat();
    final tenSec = tenSecHienThi(sp, cd);
    final tenAnh = tenAnhHienThi(sp, cd);

    Future<void> pump({required bool inNgang}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                XemTruocMac(
                  sanPham: sp,
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

    // Bản dọc: không có chữ xoay, không có bảng.
    await pump(inNgang: false);
    expect(find.byType(RotatedBox), findsNothing);
    expect(find.byType(Table), findsNothing);

    // Bản ngang: 1 bảng 3 cột, mỗi cột xoay -90° (quarterTurns 3 =
    // 90° ngược chiều kim đồng hồ, đọc từ dưới lên trên).
    await pump(inNgang: true);
    expect(find.byType(Table), findsOneWidget);
    expect(find.byType(RotatedBox), findsNWidgets(3));
    for (final xoay in tester.widgetList<RotatedBox>(find.byType(RotatedBox))) {
      expect(xoay.quarterTurns, 3);
    }
    // Thứ tự cột trái sang phải: tiếng Anh, tiếng Séc, CENA / PRICE.
    // (Cột tiêu đề ở bên phải nhất; xoay lại để đọc thì thành tiêu đề
    // trên cùng, dưới nó là vạch chia dọc = đường gạch ngang.)
    Rect rectCua(Finder tim) {
      return tester.getRect(
        find.ancestor(of: tim, matching: find.byType(RotatedBox)),
      );
    }

    final xAnh = rectCua(find.text(tenAnh)).center.dx;
    final xSec = rectCua(find.text(tenSec)).center.dx;
    final xTieuDe = rectCua(find.text('CENA / PRICE')).center.dx;
    expect(xAnh, lessThan(xSec));
    expect(xSec, lessThan(xTieuDe));
  });

  testWidgets('xem trước mẫu 8 ngang dài hơn bản dọc', (tester) async {
    Future<double> caoXemTruoc({required bool inNgang}) async {
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
      return tester.getSize(find.byType(XemTruocMac)).height;
    }

    final caoDoc = await caoXemTruoc(inNgang: false);
    final caoNgang = await caoXemTruoc(inNgang: true);
    expect(caoNgang, greaterThan(caoDoc));
  });
}
