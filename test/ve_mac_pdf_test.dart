// Test in dọc khổ cuộn: trang PDF dài đúng bằng nội dung của mẫu,
// không ép chiều cao 30 mm như trước nữa.
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mau_mac/ve_mac_pdf.dart';
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

/// Đọc tất cả MediaBox (rộng, cao) theo đơn vị point trong file PDF.
List<(double, double)> _docKhoTrang(List<int> pdf) {
  final text = String.fromCharCodes(pdf);
  final mau = RegExp(r'MediaBox\[([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)\]');
  return mau
      .allMatches(text)
      .map((m) => (double.parse(m.group(3)!), double.parse(m.group(4)!)))
      .toList();
}

void main() {
  // Cần binding thì rootBundle mới tải được font Liberation đóng gói
  // trong app để vẽ file PDF.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trang PDF rộng 80 mm, cao vừa nội dung', () async {
    const cd = CaiDat();
    final taiLieu = await taoTaiLieuMac(
      mucIn: [(sanPham: _sanPhamMau(), soLuong: 1)],
      caiDat: cd,
    );
    final khoTrang = _docKhoTrang(await taiLieu.save());
    expect(khoTrang.length, 1);
    final (rong, cao) = khoTrang.first;
    // 80 mm = 226,77 point.
    expect(rong, closeTo(80 * 72 / 25.4, 0.5));
    // Chiều cao hữu hạn, lớn hơn 0 và không còn bị ép 30 mm
    // (30 mm = 85,04 point).
    expect(cao.isFinite, isTrue);
    expect(cao, greaterThan(0));
    expect(cao, isNot(closeTo(30 * 72 / 25.4, 0.5)));
  });

  test('mẫu dài nội dung hơn thì trang dài hơn', () async {
    const cd = CaiDat();
    final sp = _sanPhamMau();
    final gon = await taoTaiLieuMac(
      mucIn: [(sanPham: sp, soLuong: 1)],
      caiDat: cd.copyWith(mauMac: MauMac.gon),
    );
    final maVach = await taoTaiLieuMac(
      mucIn: [(sanPham: sp, soLuong: 1)],
      caiDat: cd.copyWith(mauMac: MauMac.chiMaVach),
    );
    final caoGon = _docKhoTrang(await gon.save()).first.$2;
    final caoMaVach = _docKhoTrang(await maVach.save()).first.$2;
    // Mẫu chỉ mã vạch có mã vạch to nên trang dài hơn mẫu gọn.
    expect(caoMaVach, greaterThan(caoGon));
  });

  test('in 3 cái thì có đúng 3 trang', () async {
    const cd = CaiDat();
    final taiLieu = await taoTaiLieuMac(
      mucIn: [(sanPham: _sanPhamMau(), soLuong: 3)],
      caiDat: cd,
    );
    expect(_docKhoTrang(await taiLieu.save()).length, 3);
  });
}
