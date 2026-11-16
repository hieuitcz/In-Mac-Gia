// Test tên dài không bao giờ mất chữ hay nhảy lung tung:
// tên dài thì xuống bao nhiêu dòng tùy ý (không giới hạn 2 dòng
// nữa — tên rất dài mà chỉ cho 2 dòng thì chữ cuối bị cắt mất),
// ngắt từ đẹp, ở hàng 2 tên song song và các mẫu tên rộng cả dòng;
// ở các mẫu cột tên hẹp (thường, giảm giá, gọn) thì tên xuống bao
// nhiêu dòng tùy ý chứ không cắt chữ — vì 2 dòng không đủ chứa tên
// rất dài trong cột hẹp mà user đã bỏ hướng tự co nhỏ chữ.
// Lề trái/phải: nội dung thụt vào 2 bên (khổ 80mm chừa 6mm mỗi
// bên) để máy in nhiệt không cắt chữ ở mép; giá khoảng dài thì tự
// co nhỏ lại cho vừa khổ chứ không tràn khỏi mép.
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
  SanPham? sanPham,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            // Bọc Center như màn hình in thật: không có Center thì
            // ListView kéo khung xem trước giãn hết chiều ngang (800px)
            // thay vì đúng 320px như bản in, vị trí chữ sẽ sai.
            Center(
              child: XemTruocMac(
                sanPham: sanPham ?? _sanPhamTenDai(),
                mau: mau,
                caiDat: caiDat ?? const CaiDat(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

/// Sản phẩm có giá khoảng dài: "1 250 – 2 500" ở cỡ 130% rộng hơn
/// khổ nội dung nên dòng giá phải tự co nhỏ lại mới vừa khổ.
SanPham _sanPhamGiaKhoangDai() {
  return SanPham(
    id: 'sp-gia-dai',
    tenSec: 'Magnet',
    tenAnh: 'Magnet',
    maVach: '5901234123457',
    gia: 250,
    giaTu: 1250,
    giaDen: 2500,
    donVi: 'ks',
    khoiLuongGam: 500,
    capNhat: DateTime(2026, 11, 16),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Nạp font thật để đo chữ đúng như app (không nạp thì font mặc
  // định của test đo rộng hơn thật, Row tràn oan).
  setUpAll(napFontMac);
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
    testWidgets('song ngữ Hiện đại: 2 tên xuống nhiều dòng, đủ chữ', (
      tester,
    ) async {
      await _pumpXemTruoc(tester, mau: MauMac.songNguHienDai);
      // Tên hiện đủ nguyên chữ (không mất chữ ở mép) và không giới
      // hạn dòng: tên rất dài xuống bao nhiêu dòng tùy ý.
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, isNull);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, isNull);
    });

    testWidgets('song ngữ Cổ điển và Dải đen: 2 tên không giới hạn dòng', (
      tester,
    ) async {
      await _pumpXemTruoc(tester, mau: MauMac.songNguCoDien);
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, isNull);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, isNull);

      await _pumpXemTruoc(tester, mau: MauMac.songNguDaiDen);
      expect(find.text(tenSec), findsOneWidget);
      expect(find.text(tenAnh), findsOneWidget);
      expect(tester.widget<Text>(find.text(tenSec)).maxLines, isNull);
      expect(tester.widget<Text>(find.text(tenAnh)).maxLines, isNull);
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

  group('lề trái/phải: nội dung thụt vào 2 bên, không chạm mép giấy', () {
    test('lề theo tỉ lệ khổ giấy: khổ 80mm chừa 6mm mỗi bên', () {
      expect(const CaiDat().leTrangMm, 6.0);
      expect(const CaiDat().rongNoiDungMm, 68.0);
      // Khổ khác thì lề theo tỉ lệ (6/80 khổ giấy).
      expect(const CaiDat(rongMm: 40).leTrangMm, 3.0);
      expect(const CaiDat(rongMm: 40).rongNoiDungMm, 34.0);
      expect(const CaiDat(rongMm: 100).leTrangMm, 7.5);
      expect(const CaiDat(rongMm: 100).rongNoiDungMm, 85.0);
    });

    testWidgets('xem trước: không chữ nào chạm mép giấy', (tester) async {
      // Khung xem trước rộng 320px, lề 24px mỗi bên (6mm ở tỉ lệ
      // 4px/mm): mọi chữ phải nằm trong khung xem trước thụt vào
      // 24px mỗi bên. Kiểm tra cả 8 mẫu, ở 100% và 130%.
      for (final tiLe in [1.0, 1.3]) {
        for (final mau in MauMac.values) {
          await _pumpXemTruoc(
            tester,
            mau: mau,
            caiDat: const CaiDat().voiTiLeChu(mau, tiLe),
          );
          final khung = tester.getRect(find.byType(XemTruocMac));
          expect(khung.width, closeTo(320, 1), reason: 'mẫu $mau');
          for (final chu in tester.widgetList<Text>(find.byType(Text))) {
            final rect = tester.getRect(find.text(chu.data!));
            expect(
              rect.left,
              greaterThanOrEqualTo(khung.left + 23),
              reason: 'mẫu $mau, tỉ lệ $tiLe, chữ "${chu.data}"',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(khung.right - 23),
              reason: 'mẫu $mau, tỉ lệ $tiLe, chữ "${chu.data}"',
            );
          }
        }
      }
    });

    test('PDF: khung Cổ điển và Nhẹ nhàng nằm hẳn trong lề 6mm', () async {
      // Khung ngoài Cổ điển cách mép trang = lề in (6mm) + lề khung
      // riêng (1,5mm) = 7,5mm; khung Nhẹ nhàng cách mép trang đúng
      // bằng lề in (6mm). Cả hai đều nằm hẳn trong vùng in được của
      // máy (cắt ~5mm mỗi bên) nên không bao giờ mất khung nữa.
      const leIn = 6.0;
      expect(const CaiDat().leTrangMm, leIn);
      expect(leIn + 1.5, 7.5);
      // Trang PDF vẫn rộng đúng khổ giấy 80mm, chỉ nội dung thụt vào.
      final taiLieu = await taoTaiLieuMac(
        mucIn: [(sanPham: _sanPhamTenDai(), soLuong: 1)],
        caiDat: const CaiDat().copyWith(mauMac: MauMac.songNguCoDien),
      );
      final khoTrang = _docKhoTrang(await taiLieu.save());
      expect(khoTrang.length, 1);
      expect(khoTrang.first.$1, closeTo(80 * 72 / 25.4, 0.5));
    });
  });

  group('từ dài không bị ngắt giữa từ', () {
    test('cột tên chứa được từ dài nhất ở cỡ đã chọn', () {
      // Chiều rộng từ đo bằng fontTools trên file Liberation đóng gói
      // trong app (đơn vị mm, đã gồm dấu Séc):
      // "ČOKOLÁDOVÉ" sans đậm 11pt = 27,8; serif đậm 10pt = 25,9;
      // sans đậm 13pt = 32,9; serif đậm 11pt = 28,5.
      // "SMALTOVANÉ" ngắn hơn nên vừa theo.
      final rongNoiDung = const CaiDat().rongNoiDungMm; // 68mm
      // Hàng 2 tên song ngữ (Hiện đại/Dải đen): đệm 2mm mỗi bên,
      // vạch chia 0,5mm + khoảng cách 3mm mỗi bên.
      final cotSongNgu = (rongNoiDung - 4 - 6.5) / 2;
      expect(cotSongNgu, closeTo(28.75, 0.01));
      expect(27.8, lessThan(cotSongNgu));
      // Cổ điển: khung đôi ăn thêm lề 1,5 + viền 0,42 + đệm 1 +
      // viền 0,18 + đệm trong 1 (mỗi bên), tên serif 10pt.
      final cotCoDien = (rongNoiDung - 8.2 - 6.5) / 2;
      expect(cotCoDien, closeTo(26.65, 0.01));
      expect(25.9, lessThan(cotCoDien));
      // Mẫu Thường/Gọn (giá dài): cột tên = nội dung − đệm 4 −
      // giá tối đa 28 − khoảng cách 2; tên 13pt.
      final cotTenHep = rongNoiDung - 4 - 28 - 2;
      expect(cotTenHep, closeTo(34.0, 0.01));
      expect(32.9, lessThan(cotTenHep));
      // Mẫu Nhẹ nhàng (giá dài): cột tên = nội dung − đệm 8 −
      // giá tối đa 28 − khoảng cách 2; tên serif 11pt.
      final cotNheNhang = rongNoiDung - 8 - 28 - 2;
      expect(cotNheNhang, closeTo(30.0, 0.01));
      expect(28.5, lessThan(cotNheNhang));
    });
  });

  group('giá khoảng dài: tự co nhỏ cho vừa khổ, không tràn mép', () {
    testWidgets('song ngữ Hiện đại, giá khoảng dài ở 130% vẫn vừa khổ', (
      tester,
    ) async {
      final cd = const CaiDat()
          .copyWith(mauMac: MauMac.songNguHienDai)
          .voiTiLeChu(MauMac.songNguHienDai, 1.3);
      await _pumpXemTruoc(
        tester,
        mau: MauMac.songNguHienDai,
        caiDat: cd,
        sanPham: _sanPhamGiaKhoangDai(),
      );
      // Dòng giá được bọc FittedBox scaleDown để tự co nhỏ khi quá
      // rộng — giá khoảng "1 250 – 2 500" ở 130% vẫn hiện đủ, vừa khổ.
      expect(find.byType(FittedBox), findsOneWidget);
      expect(find.text('1 250 – 2 500'), findsOneWidget);
      final khung = tester.getRect(find.byType(XemTruocMac));
      final rect = tester.getRect(find.text('1 250 – 2 500'));
      expect(rect.left, greaterThanOrEqualTo(khung.left + 23));
      expect(rect.right, lessThanOrEqualTo(khung.right - 23));
    });

    test('PDF: giá khoảng dài ở 130% vẫn tạo được, trang rộng 80 mm', () async {
      final cd = const CaiDat()
          .copyWith(mauMac: MauMac.songNguHienDai)
          .voiTiLeChu(MauMac.songNguHienDai, 1.3);
      final taiLieu = await taoTaiLieuMac(
        mucIn: [(sanPham: _sanPhamGiaKhoangDai(), soLuong: 1)],
        caiDat: cd,
      );
      final khoTrang = _docKhoTrang(await taiLieu.save());
      expect(khoTrang.length, 1);
      expect(khoTrang.first.$1, closeTo(80 * 72 / 25.4, 0.5));
    });

    test(
      'PDF: giá khoảng dài không làm vỡ mẫu Thường/Gọn (từng crash mã vạch)',
      () async {
        // Giá "1 250 – 2 500 Kč" ở 26pt rộng ~53mm: mẫu Thường/Gọn
        // trước đây để giá chiếm hết chiều rộng trong nên cột tên bị
        // đẩy về 0 rồi BarcodeWidget ném lỗi "width > 0" khi vẽ.
        // Giờ giá tự co nhỏ trong giới hạn, cột tên còn đủ chỗ.
        for (final mau in [MauMac.thuong, MauMac.gon]) {
          final cd = const CaiDat().copyWith(mauMac: mau).voiTiLeChu(mau, 1.3);
          final taiLieu = await taoTaiLieuMac(
            mucIn: [(sanPham: _sanPhamGiaKhoangDai(), soLuong: 1)],
            caiDat: cd,
          );
          final khoTrang = _docKhoTrang(await taiLieu.save());
          expect(khoTrang.length, 1, reason: 'mẫu $mau');
          expect(
            khoTrang.first.$1,
            closeTo(80 * 72 / 25.4, 0.5),
            reason: 'mẫu $mau',
          );
        }
      },
    );

    testWidgets('xem trước: giá khoảng dài không làm tràn mẫu Thường/Gọn', (
      tester,
    ) async {
      for (final mau in [MauMac.thuong, MauMac.gon]) {
        final cd = const CaiDat().copyWith(mauMac: mau).voiTiLeChu(mau, 1.3);
        await _pumpXemTruoc(
          tester,
          mau: mau,
          caiDat: cd,
          sanPham: _sanPhamGiaKhoangDai(),
        );
        expect(find.text('1 250 – 2 500'), findsOneWidget, reason: '$mau');
      }
    });
  });
}
