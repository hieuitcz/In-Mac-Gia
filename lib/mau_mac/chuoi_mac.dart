// Tính các chuỗi hiển thị trên mác từ sản phẩm + cài đặt.
// Dùng chung cho cả bản in PDF và xem trước trên màn hình, để 2 bên
// không lệch nhau. Mọi chữ trên mác đều là tiếng Séc (hoặc Anh).
import '../mo_hinh/cai_dat.dart';
import '../mo_hinh/san_pham.dart';
import '../tien_ich/dinh_dang.dart';

/// Tên tiếng Séc để in (in hoa nếu bật công tắc "In chữ hoa").
String tenSecHienThi(SanPham sp, CaiDat cd) {
  return cd.inChuHoa ? sp.tenSec.toUpperCase() : sp.tenSec;
}

/// Tên tiếng Anh để in (in hoa nếu bật công tắc "In chữ hoa").
String tenAnhHienThi(SanPham sp, CaiDat cd) {
  final ten = sp.tenAnh.isEmpty ? sp.tenSec : sp.tenAnh;
  return cd.inChuHoa ? ten.toUpperCase() : ten;
}

/// Giá đã áp công tắc "In giá không thuế" (chia cho 1 + VAT).
double _giaSauThue(SanPham sp, double gia, CaiDat cd) {
  return cd.inGiaKhongThue ? sp.giaKhongThue(gia) : gia;
}

/// Chuỗi giá chính để in: giá 1 mức ("120 Kč") hoặc giá khoảng
/// ("70 – 100 Kč", dấu gạch ngang). Đã tính giá giảm
/// (nếu đang giảm giá) và công tắc giá không thuế.
String giaChinhText(SanPham sp, CaiDat cd, {bool tiengAnh = false}) {
  if (sp.coGiaKhoang) {
    final tu = _giaSauThue(sp, sp.giaTu!, cd);
    final den = _giaSauThue(sp, sp.giaDen!, cd);
    return dinhDangGiaKhoang(giaTu: tu, giaDen: den, tiengAnh: tiengAnh);
  }
  final gia = sp.giaChinh;
  if (gia == null) return '';
  return dinhDangGia(_giaSauThue(sp, gia, cd));
}

/// Chuỗi giá gốc (chưa giảm) để gạch ngang trên mác giảm giá.
/// Trả về rỗng khi sản phẩm không giảm giá.
String giaGocText(SanPham sp, CaiDat cd) {
  if (!sp.dangGiamGia || sp.gia == null) return '';
  return dinhDangGia(_giaSauThue(sp, sp.gia!, cd));
}

/// Chuỗi giá giảm để in to trên mác giảm giá.
String giaGiamText(SanPham sp, CaiDat cd) {
  if (sp.giaGiam == null) return '';
  return dinhDangGia(_giaSauThue(sp, sp.giaGiam!, cd));
}

/// Dòng khối lượng trên mẫu thường, ví dụ "MN.: 500G".
String? khoiLuongText(SanPham sp) {
  final khoiLuong = chuoiKhoiLuong(gam: sp.khoiLuongGam, ml: sp.dungTichMl);
  if (khoiLuong == null) return null;
  return 'MN.: $khoiLuong';
}

/// Dòng đơn giá trên mẫu thường, ví dụ "100G = 19,98 Kč".
/// Tính theo giá chính (đã tính giảm giá / không thuế theo công tắc).
String? donGiaText(SanPham sp, CaiDat cd) {
  final gia = sp.giaChinh;
  if (gia == null) return null;
  final giaTinh = _giaSauThue(sp, gia, cd);
  return chuoiDonGia(gia: giaTinh, gam: sp.khoiLuongGam, ml: sp.dungTichMl);
}

/// Dòng ngày hết hạn giảm giá, ví dụ "Platí do 30. 11. 2026".
String? hanGiamGiaText(SanPham sp) {
  if (sp.hanGiamGia == null) return null;
  return 'Platí do ${dinhDangNgaySec(sp.hanGiamGia!)}';
}
