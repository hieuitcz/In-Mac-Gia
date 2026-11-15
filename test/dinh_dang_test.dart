// Test các hàm định dạng: giá kiểu Séc, đơn giá, mã vạch EAN-13,
// giá từ–đến, ngày kiểu Séc.
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/tien_ich/dinh_dang.dart';

void main() {
  group('Định dạng giá kiểu Séc', () {
    test('số lẻ hiện 2 chữ số thập phân, dấu phẩy', () {
      expect(dinhDangGia(99.9), '99,90 Kč');
      expect(dinhDangGia(19.98), '19,98 Kč');
      expect(dinhDangGia(0.5), '0,50 Kč');
    });

    test('số tròn thì không hiện phần thập phân', () {
      expect(dinhDangGia(120), '120 Kč');
      expect(dinhDangGia(70), '70 Kč');
    });

    test('hàng nghìn tách bằng dấu cách', () {
      expect(dinhDangGia(1250), '1 250 Kč');
      expect(dinhDangGia(1999.9), '1 999,90 Kč');
    });
  });

  group('Định dạng giá từ–đến', () {
    test('kiểu Séc dùng "od ... do ..." ', () {
      expect(dinhDangGiaKhoang(giaTu: 70, giaDen: 100), 'od 70 do 100 Kč');
    });

    test('kiểu Anh dùng "from ... to ..." ', () {
      expect(
        dinhDangGiaKhoang(giaTu: 70, giaDen: 100, tiengAnh: true),
        'from 70 to 100 Kč',
      );
    });

    test('giá 1 mức thì hiện như giá thường', () {
      expect(dinhDangGiaKhoang(gia: 120), '120 Kč');
      expect(dinhDangGiaKhoang(gia: 99.9), '99,90 Kč');
    });

    test('không có giá thì trả về trống', () {
      expect(dinhDangGiaKhoang(), '');
    });
  });

  group('Định dạng ngày kiểu Séc', () {
    test('ngày 30 tháng 11 năm 2026', () {
      expect(dinhDangNgaySec(DateTime(2026, 11, 30)), '30. 11. 2026');
    });
  });

  group('Mã vạch EAN-13', () {
    test('tính số kiểm tra theo ví dụ chuẩn', () {
      // Ví dụ chuẩn: 590123412345 -> số kiểm tra 7.
      expect(tinhSoKiemTraEan13('590123412345'), 7);
      // Tự tính tay: vị trí lẻ (8+9) = 17, vị trí chẵn (5+1) × 3 = 18,
      // tổng 35 -> số kiểm tra 5.
      expect(tinhSoKiemTraEan13('859000000001'), 5);
      expect(kiemTraEan13('8590000000015'), isTrue);
    });

    test('kiểm tra mã 13 số đúng và sai', () {
      expect(kiemTraEan13('5901234123457'), isTrue);
      expect(kiemTraEan13('5901234123458'), isFalse);
      expect(kiemTraEan13('123'), isFalse);
      expect(kiemTraEan13('590123412345a'), isFalse);
    });

    test('chuẩn hoá: 12 số thì tự thêm số kiểm tra', () {
      expect(chuanHoaMaVach('590123412345'), '5901234123457');
      expect(chuanHoaMaVach('5901234123457'), '5901234123457');
      expect(chuanHoaMaVach(' 5901234123457 '), '5901234123457');
    });

    test('chuẩn hoá: nhập sai thì trả về null, trống thì trả về trống', () {
      expect(chuanHoaMaVach('123'), isNull);
      expect(chuanHoaMaVach('5901234123458'), isNull);
      expect(chuanHoaMaVach('abc'), isNull);
      expect(chuanHoaMaVach(''), '');
    });

    test('hiện số mã vạch kiểu in trên mác', () {
      expect(dinhDangSoMaVach('5901234123457'), '5 901234 123457');
    });
  });

  group('Khối lượng và đơn giá', () {
    test('chuỗi khối lượng', () {
      expect(chuoiKhoiLuong(gam: 500), '500G');
      expect(chuoiKhoiLuong(gam: 1500), '1,5KG');
      expect(chuoiKhoiLuong(gam: 1000), '1KG');
      expect(chuoiKhoiLuong(ml: 250), '250ML');
      expect(chuoiKhoiLuong(ml: 1500), '1,5L');
      expect(chuoiKhoiLuong(), isNull);
    });

    test('đơn giá theo 100 g', () {
      // 500 g giá 99,90 thì 100 g = 19,98.
      expect(chuoiDonGia(gia: 99.9, gam: 500), '100G = 19,98 Kč');
    });

    test('đơn giá theo 1 kg khi từ 1000 g trở lên', () {
      expect(chuoiDonGia(gia: 199.8, gam: 1000), '1KG = 199,80 Kč');
    });

    test('đơn giá theo thể tích', () {
      expect(chuoiDonGia(gia: 24.95, ml: 250), '100ML = 9,98 Kč');
      expect(chuoiDonGia(gia: 99.8, ml: 1000), '1L = 99,80 Kč');
    });

    test('không có khối lượng thì không có đơn giá', () {
      expect(chuoiDonGia(gia: 99.9), isNull);
    });
  });
}
