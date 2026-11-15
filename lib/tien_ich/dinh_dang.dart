// Các hàm định dạng thuần (không phụ thuộc Flutter) — dùng chung cho
// cả bản in PDF và xem trước trên màn hình, có test riêng.
// Mọi chuỗi giá, ngày tháng trên mác in đều viết theo kiểu Séc:
// dấu phẩy thập phân, ngày dạng "30. 11. 2026".

/// Định dạng số tiền kiểu Séc: dấu phẩy thập phân, 2 chữ số.
/// 99.9 -> "99,90 Kč"; 120 -> "120 Kč"; 1250 -> "1 250 Kč".
String dinhDangGia(double gia) {
  final lamTron = (gia * 100).round() / 100;
  final phanNguyen = lamTron.truncate();
  final phanThapPhan = ((lamTron - phanNguyen) * 100).round();
  final nguyen = _nhomHangNghin(phanNguyen);
  if (phanThapPhan == 0) return '$nguyen Kč';
  return '$nguyen,${phanThapPhan.toString().padLeft(2, '0')} Kč';
}

/// Nhóm hàng nghìn bằng dấu cách, kiểu Séc: 1250 -> "1 250".
String _nhomHangNghin(int so) {
  final chuoi = so.toString();
  final boDem = StringBuffer();
  for (var i = 0; i < chuoi.length; i++) {
    if (i > 0 && (chuoi.length - i) % 3 == 0) boDem.write(' ');
    boDem.write(chuoi[i]);
  }
  return boDem.toString();
}

/// Định dạng giá khoảng (giá từ–đến) hoặc giá 1 mức.
/// Kiểu Séc: "od 70 do 100 Kč"; kiểu Anh: "from 70 to 100 Kč".
/// Giá 1 mức thì "120 Kč" (cả 2 ngôn ngữ giống nhau).
String dinhDangGiaKhoang({
  double? gia,
  double? giaTu,
  double? giaDen,
  bool tiengAnh = false,
}) {
  if (giaTu != null && giaDen != null) {
    final tu = _boDonViTien(dinhDangGia(giaTu));
    final den = dinhDangGia(giaDen);
    return tiengAnh ? 'from $tu to $den' : 'od $tu do $den';
  }
  if (gia != null) return dinhDangGia(gia);
  return '';
}

/// Bỏ hậu tố " Kč" ở cuối chuỗi giá, để ghép lại câu khoảng giá
/// cho đúng ngữ pháp Séc/Anh ("od 70 do 100 Kč", không lặp "Kč").
String _boDonViTien(String gia) {
  return gia.replaceAll(' Kč', '');
}

/// Định dạng ngày kiểu Séc: "30. 11. 2026".
String dinhDangNgaySec(DateTime ngay) {
  return '${ngay.day}. ${ngay.month}. ${ngay.year}';
}

/// Tính số kiểm tra EAN-13 từ 12 chữ số đầu.
/// Quy tắc: vị trí lẻ (đếm từ trái, bắt đầu từ 1) nhân 1,
/// vị trí chẵn nhân 3, cộng lại, lấy 10 trừ đi phần dư cho 10.
int tinhSoKiemTraEan13(String muoiHaiSo) {
  if (muoiHaiSo.length != 12 || int.tryParse(muoiHaiSo) == null) {
    throw ArgumentError('Cần đúng 12 chữ số để tính số kiểm tra EAN-13.');
  }
  var tong = 0;
  for (var i = 0; i < 12; i++) {
    final so = int.parse(muoiHaiSo[i]);
    tong += (i % 2 == 0) ? so : so * 3;
  }
  return (10 - (tong % 10)) % 10;
}

/// Kiểm tra mã EAN-13 đầy đủ 13 chữ số có đúng số kiểm tra không.
bool kiemTraEan13(String ma) {
  if (ma.length != 13 || int.tryParse(ma) == null) return false;
  return tinhSoKiemTraEan13(ma.substring(0, 12)) == int.parse(ma[12]);
}

/// Chuẩn hoá mã vạch người dùng nhập: bỏ khoảng trắng, nếu nhập
/// 12 số thì tự thêm số kiểm tra thành 13 số. Trả về null khi sai.
/// Chuỗi trống thì trả về trống (sản phẩm không bắt buộc có mã vạch).
String? chuanHoaMaVach(String nhap) {
  final sach = nhap.replaceAll(RegExp(r'\s'), '');
  if (sach.isEmpty) return '';
  if (int.tryParse(sach) == null) return null;
  if (sach.length == 12) {
    return sach + tinhSoKiemTraEan13(sach).toString();
  }
  if (sach.length == 13 && kiemTraEan13(sach)) return sach;
  return null;
}

/// Hiện số mã vạch kiểu in trên mác: "5 901234 123457".
String dinhDangSoMaVach(String ma) {
  if (ma.length != 13) return ma;
  return '${ma[0]} ${ma.substring(1, 7)} ${ma.substring(7)}';
}

/// Chuỗi khối lượng/dung tích, ví dụ "500G", "1KG", "250ML", "1L".
/// Trả về null khi không nhập khối lượng lẫn dung tích.
String? chuoiKhoiLuong({double? gam, double? ml}) {
  if (gam != null && gam > 0) {
    if (gam < 1000) return '${gam.toInt()}G';
    final kg = gam / 1000;
    return '${_boSoKhong(kg)}KG';
  }
  if (ml != null && ml > 0) {
    if (ml < 1000) return '${ml.toInt()}ML';
    final lit = ml / 1000;
    return '${_boSoKhong(lit)}L';
  }
  return null;
}

/// Bỏ phần thập phân ".0" cho gọn: 1.0 -> "1", 1.5 -> "1,5".
String _boSoKhong(double so) {
  if (so == so.truncateToDouble()) return so.toInt().toString();
  return so.toString().replaceAll('.', ',');
}

/// Dòng đơn giá, ví dụ "100G = 19,98 Kč" hoặc "1KG = 199,80 Kč".
/// - Dưới 1000 g/ml thì tính theo 100 g/ml, từ 1000 trở lên tính theo 1 kg/l.
/// - Trả về null khi không nhập khối lượng lẫn dung tích.
String? chuoiDonGia({required double gia, double? gam, double? ml}) {
  if (gam != null && gam > 0) {
    if (gam < 1000) {
      return '100G = ${dinhDangGia(gia * 100 / gam)}';
    }
    return '1KG = ${dinhDangGia(gia * 1000 / gam)}';
  }
  if (ml != null && ml > 0) {
    if (ml < 1000) {
      return '100ML = ${dinhDangGia(gia * 100 / ml)}';
    }
    return '1L = ${dinhDangGia(gia * 1000 / ml)}';
  }
  return null;
}
