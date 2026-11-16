// Test tên dài không bao giờ mất chữ hay nhảy lung tung:
// tên dài thì xuống dòng 2 gọn gàng (tối đa 2 dòng, ngắt từ đẹp)
// ở hàng 2 tên song song và các mẫu tên rộng cả dòng; ở các mẫu
// cột tên hẹp (thường, giảm giá, gọn) thì tên xuống bao nhiêu dòng
// tùy ý chứ không cắt chữ — vì 2 dòng không đủ chứa tên rất dài
// trong cột hẹp mà user đã bỏ hướng tự co nhỏ chữ.
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
    tenSec: 'SMALTOVANÉ CEDULKA S DLOUHÝM NÁZVEM',
    tenAnh: 'ENAMEL SIGN WITH A VERY LONG NAME',
    maVach: '5901234123457',
    gia: 100,
    giaTu: 100,
    giaDen: 250,
    giaGiam: 79.9,
    hanGiamGia: DateTime(2026, 11, 30),
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

Future<void> _pumpXemTruoc(
  WidgetTester tester, {
  required MauMac mau,
  CaiDat? caiDat,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            XemTruocMac(
              sanPham: _sanPhamTenDai(),
              mau: mau,
              caiDat: caiDat ?? const CaiDat(),
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
  final sp = _sanPhamTenDai();
  const cd = CaiDat();
  final tenSec = tenSecHienThi(sp, cd);
  final tenAnh = tenAnhHienThi(sp, cd);

  group('PDF: tên dài vẫn in đủ, trang vẫn rộng 80 mm', () {
    test('mọi mẫu đều tạo PDF được, không tràn khỏi khổ 80 mm', () async {
      for (final mau in MauMac.values) {
        final taiLieu = await taoTaiLieuMac(
          mucIn: [(sanPham: sp, soLuong: 1)],
          caiDat: const CaiDat().copyWith(mauMac: mau),
        );
        final khoTrang = _docKhoTrang(await taiLieu.save());
        expect(khoTrang.length, 1, reason: 'mẫu $mau');
        expect(
          khoTrang.first.$1,
          closeTo(80 * 72 / 25.4, 0.5),
          reason: 'mẫu $mau',
        );
      }
      // Bản ngang mẫu 8 cũng vậy.
      final taiLieu = await taoTaiLieuMac(
        mucIn: [(sanPham: sp, soLuong: 1)],
        caiDat: const CaiDat().copyWith(
          mauMac: MauMac.songNguNheNhang,
          inNgangMau8: true,
        ),
      );
      final khoTrang = _docKhoTrang(await taiLieu.save());
      expect(khoTrang.length, 1);
      expect(khoTrang.first.$1, closeTo(80 * 72 / 25.4, 0.5));
    });
  });

  group('xem trước: tên dài hiện đủ, không cắt chữ', () {
    testWidgets('song ngữ Hiện đại: 2 tên xuống dòng 2 gọn gàng', (
      tester,
    ) async {
      await _pumpXemTruoc(tester, mau: MauMac.songNguHienDai);
      // Tên hiện đủ nguyên chữ (không mất chữ ở mép) và tối đa 2 dòng.
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, 2);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, 2);
    });

    testWidgets('song ngữ Cổ điển và Dải đen: 2 tên tối đa 2 dòng', (
      tester,
    ) async {
      await _pumpXemTruoc(tester, mau: MauMac.songNguCoDien);
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, 2);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, 2);

      await _pumpXemTruoc(tester, mau: MauMac.songNguDaiDen);
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, 2);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, 2);
    });

    testWidgets('Nhẹ nhàng dọc: tên tối đa 2 dòng, giá không bị cắt', (
      tester,
    ) async {
      await _pumpXemTruoc(tester, mau: MauMac.songNguNheNhang);
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, 2);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, 2);
      // Giá khoảng vẫn hiện đủ nguyên chuỗi "100 – 250 Kč / ks"
      // (giá là RichText nên phải tìm cả RichText).
      expect(
        find.text('100 – 250 Kč / ks', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('100 – 250 Kč / pc', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Nhẹ nhàng ngang: tên hiện đủ trong cột dọc', (tester) async {
      await _pumpXemTruoc(
        tester,
        mau: MauMac.songNguNheNhang,
        caiDat: const CaiDat().copyWith(inNgangMau8: true),
      );
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(find.text('CENA / PRICE'), findsOneWidget);
    });

    testWidgets('thường, giảm giá, gọn: tên không giới hạn dòng', (
      tester,
    ) async {
      // Cột tên hẹp nên tên rất dài xuống nhiều dòng, không cắt chữ:
      // Text tên không đặt maxLines.
      for (final mau in [MauMac.thuong, MauMac.giamGia, MauMac.gon]) {
        await _pumpXemTruoc(tester, mau: mau);
        expect(find.text(tenSec), findsOneWidget, reason: 'mẫu $mau');
        expect(
          tester.widget<Text>(find.text(tenSec)).maxLines,
          isNull,
          reason: 'mẫu $mau',
        );
      }
    });

    testWidgets('chỉ mã vạch: tên tối đa 2 dòng, hiện đủ', (tester) async {
      await _pumpXemTruoc(tester, mau: MauMac.chiMaVach);
      expect(find.text(tenSec), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, 2);
    });
  });
}
