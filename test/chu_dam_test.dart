// Test công tắc "In chữ đậm": mọi chữ nội dung/phụ đều theo công tắc.
// Ngoại lệ luôn đậm theo thiết kế: số giá + chữ Kč trong khối giá lớn,
// tiêu đề "CENA / PRICE", nhãn "AKCE".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/chuoi_mac.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
import 'package:in_mac_gia/mau_mac/xem_truoc_mac.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';
import 'package:in_mac_gia/tien_ich/dinh_dang.dart';

SanPham _sanPhamMau({bool coMaVach = true, bool giamGia = false}) {
  return SanPham(
    id: 'sp1',
    tenSec: 'Eidam 45% 500 g',
    tenAnh: 'Eidam cheese 45% 500 g',
    maVach: coMaVach ? '5901234123457' : '',
    gia: 99.9,
    giaGiam: giamGia ? 79.9 : null,
    hanGiamGia: giamGia ? DateTime(2026, 11, 30) : null,
    donVi: 'ks',
    khoiLuongGam: 500,
    capNhat: DateTime(2026, 11, 15),
  );
}

/// Cỡ đậm của 1 dòng chữ trong xem trước (null khi không tìm thấy).
FontWeight? _doDamCuaChu(WidgetTester tester, String text) {
  final tim = find.text(text);
  expect(tim, findsOneWidget, reason: 'không tìm thấy chữ "$text"');
  return tester.widget<Text>(tim).style!.fontWeight;
}

/// Xem trước 1 mẫu với công tắc đậm bật/tắt.
Future<void> _pumpXemTruoc(
  WidgetTester tester, {
  required MauMac mau,
  required bool inChuDam,
  SanPham? sanPham,
  CaiDat? caiDatThem,
}) async {
  final cd = (caiDatThem ?? const CaiDat()).copyWith(inChuDam: inChuDam);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            XemTruocMac(
              sanPham: sanPham ?? _sanPhamMau(),
              mau: mau,
              caiDat: cd,
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

  group('xem trước: chữ phụ theo công tắc in đậm', () {
    testWidgets('mẫu thường: số mã vạch, khối lượng, đơn giá', (tester) async {
      final sp = _sanPhamMau();
      const cd = CaiDat();
      final soMa = dinhDangSoMaVach(sp.maVach);
      final khoiLuong = khoiLuongText(sp)!;
      final donGia = donGiaText(sp, cd)!;

      await _pumpXemTruoc(tester, mau: MauMac.thuong, inChuDam: true);
      expect(_doDamCuaChu(tester, soMa), FontWeight.bold);
      expect(_doDamCuaChu(tester, khoiLuong), FontWeight.bold);
      expect(_doDamCuaChu(tester, donGia), FontWeight.bold);

      await _pumpXemTruoc(tester, mau: MauMac.thuong, inChuDam: false);
      expect(_doDamCuaChu(tester, soMa), FontWeight.normal);
      expect(_doDamCuaChu(tester, khoiLuong), FontWeight.normal);
      expect(_doDamCuaChu(tester, donGia), FontWeight.normal);
    });

    testWidgets('mẫu giảm giá: giá cũ gạch ngang, ngày hết hạn', (
      tester,
    ) async {
      final sp = _sanPhamMau(giamGia: true);
      const cd = CaiDat();
      final giaCu = giaGocText(sp, cd);
      final han = hanGiamGiaText(sp)!;
      final cdGiam = const CaiDat().copyWith(
        inGiaThuongTrenMacGiam: true,
        inNgayHetHan: true,
      );

      await _pumpXemTruoc(
        tester,
        mau: MauMac.giamGia,
        inChuDam: true,
        sanPham: sp,
        caiDatThem: cdGiam,
      );
      expect(_doDamCuaChu(tester, giaCu), FontWeight.bold);
      expect(_doDamCuaChu(tester, han), FontWeight.bold);

      await _pumpXemTruoc(
        tester,
        mau: MauMac.giamGia,
        inChuDam: false,
        sanPham: sp,
        caiDatThem: cdGiam,
      );
      expect(_doDamCuaChu(tester, giaCu), FontWeight.normal);
      expect(_doDamCuaChu(tester, han), FontWeight.normal);
    });

    testWidgets('mẫu chỉ mã vạch: số mã vạch', (tester) async {
      final sp = _sanPhamMau();
      final soMa = dinhDangSoMaVach(sp.maVach);

      await _pumpXemTruoc(tester, mau: MauMac.chiMaVach, inChuDam: true);
      expect(_doDamCuaChu(tester, soMa), FontWeight.bold);

      await _pumpXemTruoc(tester, mau: MauMac.chiMaVach, inChuDam: false);
      expect(_doDamCuaChu(tester, soMa), FontWeight.normal);
    });

    testWidgets('mẫu song ngữ: tên Anh, dòng /ks · /pc', (tester) async {
      final sp = _sanPhamMau();
      const cd = CaiDat();
      final tenAnh = tenAnhHienThi(sp, cd);

      await _pumpXemTruoc(tester, mau: MauMac.songNguHienDai, inChuDam: true);
      expect(_doDamCuaChu(tester, tenAnh), FontWeight.bold);
      expect(_doDamCuaChu(tester, '/ks · /pc'), FontWeight.bold);
      // Bật đậm thì tên Anh in đậm thẳng (không nghiêng) vì font
      // đóng gói không có file đậm-nghiêng.
      expect(
        tester.widget<Text>(find.text(tenAnh)).style!.fontStyle,
        FontStyle.normal,
      );

      await _pumpXemTruoc(tester, mau: MauMac.songNguHienDai, inChuDam: false);
      expect(_doDamCuaChu(tester, tenAnh), FontWeight.normal);
      expect(_doDamCuaChu(tester, '/ks · /pc'), FontWeight.normal);
      // Tắt đậm thì tên Anh in nghiêng thường như cũ.
      expect(
        tester.widget<Text>(find.text(tenAnh)).style!.fontStyle,
        FontStyle.italic,
      );
    });

    testWidgets('mẫu Nhẹ nhàng: tên, Kč, đơn vị theo công tắc; số luôn đậm', (
      tester,
    ) async {
      // Mỗi dòng Nhẹ nhàng là 1 Row: tên là Text riêng (Flexible),
      // giá là RichText 3 đoạn: số, Kč, đơn vị. Tên dài thì xuống
      // dòng 2 gọn gàng, phần giá luôn nằm gọn bên phải.
      final sp = _sanPhamMau();
      const cd = CaiDat();
      final tenSec = tenSecHienThi(sp, cd);
      final tenAnh = tenAnhHienThi(sp, cd);

      // Lấy các đoạn giá (RichText có đúng 3 đoạn: số, Kč, đơn vị).
      List<List<TextSpan>> layCacDoanGia(WidgetTester t) {
        return t
            .widgetList<RichText>(find.byType(RichText))
            .map((r) => r.text as TextSpan)
            .where(
              (doan) => doan.children != null && doan.children!.length == 3,
            )
            .map((doan) => doan.children!.cast<TextSpan>())
            .toList();
      }

      await _pumpXemTruoc(tester, mau: MauMac.songNguNheNhang, inChuDam: true);
      expect(_doDamCuaChu(tester, tenSec), FontWeight.bold); // tên Séc
      expect(_doDamCuaChu(tester, tenAnh), FontWeight.bold); // tên Anh
      final khiDam = layCacDoanGia(tester);
      expect(khiDam.length, 2);
      for (final doan in khiDam) {
        expect(doan[0].style!.fontWeight, FontWeight.bold); // số luôn đậm
        expect(doan[1].style!.fontWeight, FontWeight.bold); // Kč
        expect(doan[2].style!.fontWeight, FontWeight.bold); // đơn vị
      }

      await _pumpXemTruoc(tester, mau: MauMac.songNguNheNhang, inChuDam: false);
      expect(_doDamCuaChu(tester, tenSec), FontWeight.normal); // tên Séc
      expect(_doDamCuaChu(tester, tenAnh), FontWeight.normal); // tên Anh
      final khiThuong = layCacDoanGia(tester);
      expect(khiThuong.length, 2);
      for (final doan in khiThuong) {
        expect(doan[0].style!.fontWeight, FontWeight.bold); // số luôn đậm
        expect(doan[1].style!.fontWeight, FontWeight.normal); // Kč
        expect(doan[2].style!.fontWeight, FontWeight.normal); // đơn vị
      }
    });

    testWidgets('chưa có mã vạch: dòng nhắc cũng theo công tắc', (
      tester,
    ) async {
      await _pumpXemTruoc(
        tester,
        mau: MauMac.thuong,
        inChuDam: true,
        sanPham: _sanPhamMau(coMaVach: false),
      );
      expect(_doDamCuaChu(tester, 'Chưa có mã vạch'), FontWeight.bold);

      await _pumpXemTruoc(
        tester,
        mau: MauMac.thuong,
        inChuDam: false,
        sanPham: _sanPhamMau(coMaVach: false),
      );
      expect(_doDamCuaChu(tester, 'Chưa có mã vạch'), FontWeight.normal);
    });
  });

  group('xem trước: ngoại lệ luôn đậm dù tắt công tắc', () {
    testWidgets('giá lớn, CENA / PRICE, AKCE', (tester) async {
      await _pumpXemTruoc(tester, mau: MauMac.thuong, inChuDam: false);
      expect(_doDamCuaChu(tester, '99,90'), FontWeight.bold);
      expect(_doDamCuaChu(tester, 'Kč'), FontWeight.bold);

      await _pumpXemTruoc(tester, mau: MauMac.songNguHienDai, inChuDam: false);
      expect(_doDamCuaChu(tester, 'CENA / PRICE'), FontWeight.bold);

      await _pumpXemTruoc(
        tester,
        mau: MauMac.giamGia,
        inChuDam: false,
        sanPham: _sanPhamMau(giamGia: true),
      );
      expect(_doDamCuaChu(tester, 'AKCE'), FontWeight.bold);
    });
  });

  group('PDF: font đậm dùng theo công tắc', () {
    Future<String> taoPdfChu({
      required MauMac mau,
      required bool inChuDam,
    }) async {
      final cd = const CaiDat().copyWith(mauMac: mau, inChuDam: inChuDam);
      final taiLieu = await taoTaiLieuMac(
        mucIn: [(sanPham: _sanPhamMau(), soLuong: 1)],
        caiDat: cd,
      );
      return String.fromCharCodes(await taiLieu.save());
    }

    test('mẫu chỉ mã vạch: bật đậm thì có font đậm, tắt thì không', () async {
      final khiDam = await taoPdfChu(mau: MauMac.chiMaVach, inChuDam: true);
      expect(khiDam, contains('LiberationSans-Bold'));
      final khiThuong = await taoPdfChu(mau: MauMac.chiMaVach, inChuDam: false);
      expect(khiThuong, isNot(contains('LiberationSans-Bold')));
    });

    test('mẫu thường tắt đậm vẫn có font đậm (giá lớn luôn đậm)', () async {
      final pdf = await taoPdfChu(mau: MauMac.thuong, inChuDam: false);
      expect(pdf, contains('LiberationSans-Bold'));
    });
  });
}
