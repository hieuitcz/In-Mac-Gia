// Test in ngang mẫu 8 (Nhẹ nhàng): VẪN KHỔ DỌC 80mm nhưng chữ
// viết theo chiều dọc — bản ngang là bản chuyển vị đúng của bản dọc:
// xoay nguyên mẫu dọc 90° theo chiều kim đồng hồ, chữ đọc từ trên
// xuống dưới (như ảnh gốc), cột "CENA / PRICE" ở bên phải, 2 dòng
// sản phẩm (tiếng Anh rồi tiếng Séc) là các cột đứng bên trái nó,
// có vạch chia dọc giữa cột tiêu đề và các cột sản phẩm (chính là
// gạch ngang dưới tiêu đề bản dọc). Xoay tem 90° ngược chiều kim
// đồng hồ để đọc thì thành: tiêu đề "CENA / PRICE" ở trên cùng,
// dưới nó là 1 đường gạch ngang, rồi đến các dòng sản phẩm.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/chuoi_mac.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
import 'package:in_mac_gia/mau_mac/xem_truoc_mac.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';

import 'nap_font_mac.dart';

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
  // Nạp font thật để đo chữ đúng như app.
  setUpAll(napFontMac);

  test('mẫu 8 dọc: trang rộng 80 mm, cao vừa nội dung', () async {
    final (rong, cao) = await _khoTrangMau8(inNgang: false);
    expect(rong, closeTo(80 * 72 / 25.4, 0.5));
    expect(cao.isFinite && cao > 0, isTrue);
  });

  test(
    'mẫu 8 ngang: trang vẫn rộng 80 mm, dài bằng đúng chiều rộng nội dung bản dọc',
    () async {
      final (_, caoDoc) = await _khoTrangMau8(inNgang: false);
      final (rong, caoNgang) = await _khoTrangMau8(inNgang: true);
      // 80 mm = 226,77 point: chiều rộng trang vẫn là cuộn giấy 80 mm.
      expect(rong, closeTo(80 * 72 / 25.4, 0.5));
      // Bản chuyển vị: chiều dài dải tem bằng đúng chiều rộng nội
      // dung bản dọc (khổ giấy trừ lề 2 bên, mặc định 74 mm).
      expect(caoNgang, closeTo(const CaiDat().rongNoiDungMm * 72 / 25.4, 1.0));
      expect(caoNgang, greaterThan(caoDoc));
    },
  );

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

  testWidgets(
    'xem trước mẫu 8 ngang: xoay nguyên mẫu dọc, CENA / PRICE bên phải',
    (tester) async {
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

      // Bản ngang: đúng 1 RotatedBox xoay nguyên mẫu dọc 90° theo
      // chiều kim đồng hồ (quarterTurns 1), không dựng bảng riêng,
      // không thêm vạch chia.
      await pump(inNgang: true);
      expect(find.byType(Table), findsNothing);
      expect(find.byType(RotatedBox), findsOneWidget);
      expect(
        tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
        1,
      );
      // Nội dung trong khung xoay vẫn là đủ thành phần bản dọc:
      // tiêu đề, 2 tên, 2 dòng giá.
      expect(find.text('CENA / PRICE'), findsOneWidget);
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      // Thứ tự cột trái sang phải: tiếng Anh, tiếng Séc, CENA / PRICE.
      // (Cột tiêu đề ở bên phải nhất; xoay lại để đọc thì thành tiêu đề
      // trên cùng, dưới nó là gạch ngang dưới tiêu đề bản dọc.)
      final xAnh = tester.getRect(find.text(tenAnh)).center.dx;
      final xSec = tester.getRect(find.text(tenSec)).center.dx;
      final xTieuDe = tester.getRect(find.text('CENA / PRICE')).center.dx;
      expect(xAnh, lessThan(xSec));
      expect(xSec, lessThan(xTieuDe));
    },
  );

  testWidgets('xem trước mẫu 8 ngang dài bằng chiều rộng nội dung bản dọc', (
    tester,
  ) async {
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
    // Bản chuyển vị: chiều dài dải tem bằng chiều rộng nội dung
    // xem trước (320px trừ lề 2 bên 24px = 272px).
    expect(caoNgang, closeTo(272, 2));
    expect(caoNgang, greaterThan(caoDoc));
  });
}
