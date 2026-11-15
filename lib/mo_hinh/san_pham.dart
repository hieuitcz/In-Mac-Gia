// Model sản phẩm — 1 sản phẩm là 1 mặt hàng trong cửa hàng potraviny.
// Giá và tên lưu bằng tiếng Séc (in lên mác), tên tiếng Anh để in mác
// song ngữ. Dữ liệu dùng chung 2 cửa hàng qua đồng bộ cloud.
import '../tien_ich/dinh_dang.dart';

class SanPham {
  /// Mã riêng của sản phẩm (tự sinh, không đổi suốt đời sản phẩm).
  final String id;

  /// Tên tiếng Séc, bắt buộc (in lên mọi mẫu mác).
  final String tenSec;

  /// Tên tiếng Anh, có thể trống (dùng cho mác song ngữ).
  final String tenAnh;

  /// Mã vạch EAN-13 (13 chữ số), có thể trống.
  final String maVach;

  /// Giá 1 mức (Kč, đã gồm thuế). Trống khi bán theo khoảng giá.
  final double? gia;

  /// Giá từ (Kč) khi bán theo khoảng giá, ví dụ từ 70 đến 100 Kč.
  final double? giaTu;

  /// Giá đến (Kč) khi bán theo khoảng giá.
  final double? giaDen;

  /// Giá giảm (Kč) khi đang giảm giá, trống khi không giảm giá.
  final double? giaGiam;

  /// Ngày hết hạn giảm giá (ngày cuối cùng còn giảm giá), có thể trống.
  final DateTime? hanGiamGia;

  /// Đơn vị bán: ks, kg, g, l, ml, pc, balení...
  final String donVi;

  /// Khối lượng tịnh (gam) để tính đơn giá 100 g / 1 kg, có thể trống.
  final double? khoiLuongGam;

  /// Dung tích (ml) để tính đơn giá 100 ml / 1 l, có thể trống.
  final double? dungTichMl;

  /// Thuế VAT % của mặt hàng (mặc định 12 — thuế thực phẩm ở Séc).
  /// Dùng để tính "giá không thuế" khi in mác.
  final double tyLeThue;

  /// Lần sửa cuối — đồng bộ cloud lấy bản mới nhất theo mốc này.
  final DateTime capNhat;

  const SanPham({
    required this.id,
    required this.tenSec,
    this.tenAnh = '',
    this.maVach = '',
    this.gia,
    this.giaTu,
    this.giaDen,
    this.giaGiam,
    this.hanGiamGia,
    this.donVi = 'ks',
    this.khoiLuongGam,
    this.dungTichMl,
    this.tyLeThue = 12,
    required this.capNhat,
  });

  /// Sản phẩm có bán theo khoảng giá không (có cả giá từ và giá đến).
  bool get coGiaKhoang => giaTu != null && giaDen != null;

  /// Sản phẩm có đang giảm giá không (có giá giảm và chưa hết hạn).
  bool get dangGiamGia {
    if (giaGiam == null) return false;
    if (hanGiamGia == null) return true;
    final homNay = DateTime.now();
    final han = DateTime(hanGiamGia!.year, hanGiamGia!.month, hanGiamGia!.day);
    final nay = DateTime(homNay.year, homNay.month, homNay.day);
    return !nay.isAfter(han);
  }

  /// Giá chính để in: giá giảm nếu đang giảm giá, ngược lại giá thường.
  /// Trả về null khi sản phẩm bán theo khoảng giá.
  double? get giaChinh {
    if (coGiaKhoang) return null;
    if (dangGiamGia) return giaGiam;
    return gia;
  }

  /// Giá chưa gồm thuế, tính từ giá đã gồm thuế.
  double giaKhongThue(double giaCoThue) => giaCoThue / (1 + tyLeThue / 100);

  /// Mã vạch có hợp lệ để vẽ không (đúng 13 số, đúng số kiểm tra).
  bool get coMaVachHopLe => maVach.isNotEmpty && kiemTraEan13(maVach);

  SanPham copyWith({
    String? tenSec,
    String? tenAnh,
    String? maVach,
    double? gia,
    double? giaTu,
    double? giaDen,
    double? giaGiam,
    DateTime? hanGiamGia,
    String? donVi,
    double? khoiLuongGam,
    double? dungTichMl,
    double? tyLeThue,
    DateTime? capNhat,
    bool xoaGiaGiam = false,
    bool xoaHanGiamGia = false,
  }) {
    return SanPham(
      id: id,
      tenSec: tenSec ?? this.tenSec,
      tenAnh: tenAnh ?? this.tenAnh,
      maVach: maVach ?? this.maVach,
      gia: gia ?? this.gia,
      giaTu: giaTu ?? this.giaTu,
      giaDen: giaDen ?? this.giaDen,
      giaGiam: xoaGiaGiam ? null : (giaGiam ?? this.giaGiam),
      hanGiamGia: xoaHanGiamGia ? null : (hanGiamGia ?? this.hanGiamGia),
      donVi: donVi ?? this.donVi,
      khoiLuongGam: khoiLuongGam ?? this.khoiLuongGam,
      dungTichMl: dungTichMl ?? this.dungTichMl,
      tyLeThue: tyLeThue ?? this.tyLeThue,
      capNhat: capNhat ?? this.capNhat,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenSec': tenSec,
    'tenAnh': tenAnh,
    'maVach': maVach,
    'gia': gia,
    'giaTu': giaTu,
    'giaDen': giaDen,
    'giaGiam': giaGiam,
    'hanGiamGia': hanGiamGia?.toIso8601String(),
    'donVi': donVi,
    'khoiLuongGam': khoiLuongGam,
    'dungTichMl': dungTichMl,
    'tyLeThue': tyLeThue,
    'capNhat': capNhat.toIso8601String(),
  };

  factory SanPham.fromJson(Map<String, dynamic> json) {
    return SanPham(
      id: json['id'] as String? ?? '',
      tenSec: json['tenSec'] as String? ?? '',
      tenAnh: json['tenAnh'] as String? ?? '',
      maVach: json['maVach'] as String? ?? '',
      gia: (json['gia'] as num?)?.toDouble(),
      giaTu: (json['giaTu'] as num?)?.toDouble(),
      giaDen: (json['giaDen'] as num?)?.toDouble(),
      giaGiam: (json['giaGiam'] as num?)?.toDouble(),
      hanGiamGia: json['hanGiamGia'] == null
          ? null
          : DateTime.tryParse(json['hanGiamGia'] as String),
      donVi: json['donVi'] as String? ?? 'ks',
      khoiLuongGam: (json['khoiLuongGam'] as num?)?.toDouble(),
      dungTichMl: (json['dungTichMl'] as num?)?.toDouble(),
      tyLeThue: (json['tyLeThue'] as num?)?.toDouble() ?? 12,
      capNhat: json['capNhat'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(json['capNhat'] as String) ??
                DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
