// Test máy in mặc định: lưu/tải cài đặt, tìm máy in theo url.
import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/tien_ich/may_in.dart';
import 'package:printing/printing.dart';

void main() {
  group('Cài đặt máy in mặc định', () {
    test('mặc định chưa đặt máy in', () {
      const cd = CaiDat();
      expect(cd.mayInMacDinh, isNull);
      expect(cd.tenMayInMacDinh, isNull);
    });

    test('lưu/tải lại máy in mặc định', () {
      const cd = CaiDat();
      final dat = cd.copyWith(
        mayInMacDinh: 'ipp://may-in-nhan',
        tenMayInMacDinh: 'Máy in nhãn',
      );
      expect(dat.mayInMacDinh, 'ipp://may-in-nhan');
      expect(dat.tenMayInMacDinh, 'Máy in nhãn');
      final taiLai = CaiDat.fromJson(dat.toJson());
      expect(taiLai.mayInMacDinh, 'ipp://may-in-nhan');
      expect(taiLai.tenMayInMacDinh, 'Máy in nhãn');
      // File cài đặt cũ chưa có 2 khóa này thì là chưa đặt.
      expect(CaiDat.fromJson({}).mayInMacDinh, isNull);
    });

    test('xóa máy in mặc định', () {
      final dat = const CaiDat().copyWith(
        mayInMacDinh: 'ipp://may-in-nhan',
        tenMayInMacDinh: 'Máy in nhãn',
      );
      final xoa = dat.copyWith(xoaMayInMacDinh: true);
      expect(xoa.mayInMacDinh, isNull);
      expect(xoa.tenMayInMacDinh, isNull);
    });
  });

  group('tìm máy in trong danh sách theo url', () {
    const danhSach = [
      Printer(url: 'ipp://may-in-nhan', name: 'Máy in nhãn'),
      Printer(url: 'ipp://may-in-van-phong', name: 'Máy in văn phòng'),
    ];

    test('tìm thấy máy in đã lưu', () {
      final tim = timMayInTrongDanhSach(danhSach, 'ipp://may-in-nhan');
      expect(tim?.name, 'Máy in nhãn');
    });

    test('máy in không còn thì trả về null (để hiện hộp thoại)', () {
      expect(timMayInTrongDanhSach(danhSach, 'ipp://may-in-cu'), isNull);
      expect(timMayInTrongDanhSach(danhSach, null), isNull);
      expect(timMayInTrongDanhSach(danhSach, ''), isNull);
      expect(timMayInTrongDanhSach([], 'ipp://may-in-nhan'), isNull);
    });
  });
}
