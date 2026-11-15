// Test model sản phẩm và cài đặt: giảm giá, khoảng giá, JSON,
// tỉ lệ cỡ chữ theo mẫu, khổ giấy in cuộn dọc.
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';
import 'package:pdf/pdf.dart';

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

void main() {
  group('Sản phẩm', () {
    test('giá chính là giá thường khi không giảm giá', () {
      expect(_sanPhamMau().giaChinh, 99.9);
      expect(_sanPhamMau().dangGiamGia, isFalse);
    });

    test('đang giảm giá khi có giá giảm và chưa hết hạn', () {
      final sp = _sanPhamMau().copyWith(
        giaGiam: 49.9,
        hanGiamGia: DateTime.now().add(const Duration(days: 5)),
      );
      expect(sp.dangGiamGia, isTrue);
      expect(sp.giaChinh, 49.9);
    });

    test('hết hạn giảm giá thì về giá thường', () {
      final sp = _sanPhamMau().copyWith(
        giaGiam: 49.9,
        hanGiamGia: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sp.dangGiamGia, isFalse);
      expect(sp.giaChinh, 99.9);
    });

    test('giá giảm không cần ngày hết hạn', () {
      final sp = _sanPhamMau().copyWith(giaGiam: 49.9);
      expect(sp.dangGiamGia, isTrue);
    });

    test('bán theo khoảng giá thì giá chính là null', () {
      final sp = SanPham(
        id: 'sp2',
        tenSec: 'Samolepky',
        tenAnh: 'Stickers',
        giaTu: 70,
        giaDen: 100,
        capNhat: DateTime(2026, 11, 15),
      );
      expect(sp.coGiaKhoang, isTrue);
      expect(sp.giaChinh, isNull);
    });

    test('giá không thuế: trừ VAT 12% mặc định', () {
      // 112 Kč gồm thuế 12% thì chưa thuế là 100 Kč.
      expect(_sanPhamMau().giaKhongThue(112), closeTo(100, 0.001));
    });

    test('mã vạch hợp lệ thì vẽ được', () {
      expect(_sanPhamMau().coMaVachHopLe, isTrue);
      expect(_sanPhamMau().copyWith(maVach: '123').coMaVachHopLe, isFalse);
      expect(_sanPhamMau().copyWith(maVach: '').coMaVachHopLe, isFalse);
    });

    test('JSON đi về giữ nguyên dữ liệu', () {
      final sp = _sanPhamMau().copyWith(
        giaGiam: 49.9,
        hanGiamGia: DateTime(2026, 11, 30),
      );
      final docLai = SanPham.fromJson(sp.toJson());
      expect(docLai.id, sp.id);
      expect(docLai.tenSec, sp.tenSec);
      expect(docLai.tenAnh, sp.tenAnh);
      expect(docLai.maVach, sp.maVach);
      expect(docLai.gia, sp.gia);
      expect(docLai.giaGiam, sp.giaGiam);
      expect(docLai.hanGiamGia, DateTime(2026, 11, 30));
      expect(docLai.khoiLuongGam, 500);
      expect(docLai.tyLeThue, 12);
    });
  });

  group('Cài đặt', () {
    test('mặc định: in dọc rộng 80 mm, mẫu thường, tỉ lệ chữ 100%', () {
      const cd = CaiDat();
      expect(cd.rongMm, 80);
      expect(cd.mauMac, MauMac.thuong);
      expect(cd.tiLeChuCua(MauMac.songNguNheNhang), 1.0);
      expect(cd.tiLeChuCua(MauMac.thuong), 1.0);
    });

    test('chỉnh cỡ chữ theo mẫu, kẹp trong 70%–130%', () {
      const cd = CaiDat();
      final nho = cd.voiTiLeChu(MauMac.songNguNheNhang, 0.5);
      expect(nho.tiLeChuCua(MauMac.songNguNheNhang), 0.7);
      final lon = cd.voiTiLeChu(MauMac.songNguNheNhang, 2.0);
      expect(lon.tiLeChuCua(MauMac.songNguNheNhang), 1.3);
      final vua = cd.voiTiLeChu(MauMac.songNguNheNhang, 0.85);
      expect(vua.tiLeChuCua(MauMac.songNguNheNhang), 0.85);
      // Mẫu khác không bị ảnh hưởng.
      expect(vua.tiLeChuCua(MauMac.thuong), 1.0);
    });

    test('JSON đi về giữ nguyên tỉ lệ chữ từng mẫu', () {
      const cd = CaiDat();
      final daChinh = cd.voiTiLeChu(MauMac.songNguNheNhang, 0.85);
      final docLai = CaiDat.fromJson(daChinh.toJson());
      expect(docLai.tiLeChuCua(MauMac.songNguNheNhang), 0.85);
      expect(docLai.rongMm, 80);
      expect(docLai.mauMac, MauMac.thuong);
    });

    test('file cũ còn khóa chiều cao thì vẫn đọc được (bỏ qua khóa đó)', () {
      final docLai = CaiDat.fromJson({'rongMm': 80, 'caoMm': 30});
      expect(docLai.rongMm, 80);
      expect(docLai.tiLeChuCua(MauMac.songNguNheNhang), 1.0);
    });

    test('đủ 8 mẫu mác, gồm 4 mẫu song ngữ', () {
      expect(MauMac.values.length, 8);
      final songNgu = MauMac.values.where((m) => m.laSongNgu).toList();
      expect(songNgu.length, 4);
    });

    test('khổ giấy in cuộn: rộng đúng chiều rộng mác, dài vô hạn', () {
      // Trang dài vô hạn để package pdf tự co chiều cao trang vừa
      // đúng nội dung, máy in nhiệt tự cắt đúng chỗ.
      const cd = CaiDat();
      final kho = khoGiayMac(cd);
      expect(kho.width, 80 * PdfPageFormat.mm);
      expect(kho.height, double.infinity);
      expect(kho.marginLeft, 0);
      expect(kho.marginRight, 0);
      expect(kho.marginTop, 0);
      expect(kho.marginBottom, 0);
      // Đổi cuộn giấy hẹp hơn thì khổ in hẹp theo.
      final hep = khoGiayMac(const CaiDat(rongMm: 57));
      expect(hep.width, 57 * PdfPageFormat.mm);
      expect(hep.height, double.infinity);
    });
  });
}
