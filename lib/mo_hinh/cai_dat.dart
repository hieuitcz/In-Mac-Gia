// Cài đặt của app: khổ mác, mẫu đã chọn, các công tắc lúc in.
// Lưu local trên máy, đồng bộ cloud không đụng tới cài đặt này
// (mỗi máy tính tiền có thể để khổ mác và mẫu mặc định khác nhau).
// In dọc: chỉ chỉnh chiều rộng mác (mặc định 80mm, đúng cuộn giấy
// nhiệt). Chiều dài mác tự theo nội dung, máy in tự cắt nên không
// cần nhập chiều cao nữa.
import '../mau_mac/mau_mac.dart';

/// Font chữ trên mác: Sans (không chân) hoặc Serif (có chân).
/// Font đã chọn áp cho chữ chính của các mẫu; mẫu Cổ điển và
/// Nhẹ nhàng thiết kế serif sẵn nên luôn giữ serif.
enum FontMac {
  sans,
  serif;

  String get tenHienThi => switch (this) {
    FontMac.sans => 'Sans (không chân)',
    FontMac.serif => 'Serif (có chân)',
  };

  static FontMac tuTen(String? ten) {
    return FontMac.values.firstWhere(
      (f) => f.name == ten,
      orElse: () => FontMac.sans,
    );
  }
}

class CaiDat {
  /// Chiều rộng mác (mm). Mặc định 80 — cuộn giấy nhiệt 80mm.
  final double rongMm;

  /// Mẫu mác đã chọn lần gần nhất, lần sau mở app vẫn giữ.
  final MauMac mauMac;

  /// In chữ đậm (công tắc "In chữ đậm").
  final bool inChuDam;

  /// In chữ hoa (công tắc "In chữ hoa").
  final bool inChuHoa;

  /// In cả mã vạch trên mác (công tắc "In cả mã vạch").
  final bool inMaVach;

  /// In riêng mã vạch, bỏ qua mẫu đã chọn (công tắc "In riêng mã vạch").
  final bool inRiengMaVach;

  /// Sản phẩm đang giảm giá thì in theo mẫu giảm giá
  /// (công tắc "In mác giá đang giảm giá").
  final bool inMacGiamGia;

  /// In ngày hết hạn giảm giá trên mác giảm giá
  /// (công tắc "In ngày hết hạn giảm giá").
  final bool inNgayHetHan;

  /// In giá bình thường (giá gốc) trên mác giá giảm giá
  /// (công tắc "In giá bình thường trên mác giá giảm giá").
  final bool inGiaThuongTrenMacGiam;

  /// In giá chưa gồm thuế (công tắc "In giá không thuế").
  final bool inGiaKhongThue;

  /// Tỉ lệ cỡ chữ theo từng mẫu mác (1.0 = 100% cỡ mặc định).
  /// Khóa là tên mẫu (ví dụ "songNguNheNhang"), giá trị từ 0.7 đến 1.3.
  /// Tên sản phẩm hoặc giá dài thì thu nhỏ lại cho vừa 1 dòng.
  /// Mẫu nào chưa chỉnh thì dùng 1.0.
  final Map<String, double> tiLeChu;

  /// In ngang mẫu Nhẹ nhàng (mẫu 8): xoay nội dung 90° để tên dài
  /// vừa 1 dòng. Chỉ áp cho mẫu 8, các mẫu khác vẫn in dọc.
  final bool inNgangMau8;

  /// Font chữ trên mác (Sans hoặc Serif). Áp cho chữ chính của
  /// các mẫu; mẫu Cổ điển và Nhẹ nhàng luôn giữ serif.
  final FontMac fontChu;

  /// Máy in mặc định (định danh url của máy in trong gói printing).
  /// Đặt 1 lần trong Cài đặt thì lần sau bấm in là in thẳng bằng máy
  /// này, không hiện hộp thoại chọn máy in mỗi lần. Chưa đặt hoặc
  /// máy in không còn thì app hiện hộp thoại như cũ.
  final String? mayInMacDinh;

  /// Tên hiển thị của máy in mặc định (để hiện trong Cài đặt).
  final String? tenMayInMacDinh;

  const CaiDat({
    this.rongMm = 80,
    this.mauMac = MauMac.thuong,
    this.inChuDam = true,
    this.inChuHoa = true,
    this.inMaVach = true,
    this.inRiengMaVach = false,
    this.inMacGiamGia = false,
    this.inNgayHetHan = false,
    this.inGiaThuongTrenMacGiam = false,
    this.inGiaKhongThue = false,
    this.tiLeChu = const {},
    this.inNgangMau8 = false,
    this.fontChu = FontMac.sans,
    this.mayInMacDinh,
    this.tenMayInMacDinh,
  });

  /// Tỉ lệ cỡ chữ của 1 mẫu (mặc định 1.0 khi chưa chỉnh).
  double tiLeChuCua(MauMac mau) {
    final tiLe = tiLeChu[mau.name];
    if (tiLe == null) return 1.0;
    return tiLe.clamp(0.7, 1.3);
  }

  /// Lề trái/phải mỗi bên khi in (mm): máy in nhiệt in được hẹp hơn
  /// khổ giấy nên nội dung phải thụt vào 2 bên, không vẽ ra hết khổ
  /// (không là chữ ở mép bị máy cắt mất). Khổ 80mm thì chừa 3mm mỗi
  /// bên, nội dung chiếm 74mm ở giữa; lề theo tỉ lệ khổ giấy đã chỉnh.
  double get leTrangMm => rongMm * 3 / 80;

  /// Chiều rộng nội dung sau khi trừ lề 2 bên (mm).
  double get rongNoiDungMm => rongMm - 2 * leTrangMm;

  /// Trả về bản cài đặt mới với tỉ lệ cỡ chữ của 1 mẫu đã đổi.
  /// Tỉ lệ tự kẹp trong khoảng 0.7–1.3.
  CaiDat voiTiLeChu(MauMac mau, double tiLe) {
    final moi = Map<String, double>.of(tiLeChu);
    moi[mau.name] = tiLe.clamp(0.7, 1.3);
    return copyWith(tiLeChu: moi);
  }

  CaiDat copyWith({
    double? rongMm,
    MauMac? mauMac,
    bool? inChuDam,
    bool? inChuHoa,
    bool? inMaVach,
    bool? inRiengMaVach,
    bool? inMacGiamGia,
    bool? inNgayHetHan,
    bool? inGiaThuongTrenMacGiam,
    bool? inGiaKhongThue,
    Map<String, double>? tiLeChu,
    bool? inNgangMau8,
    FontMac? fontChu,
    String? mayInMacDinh,
    String? tenMayInMacDinh,
    // Đặt true để xóa máy in mặc định (vì truyền null vào
    // mayInMacDinh thì copyWith hiểu là "giữ nguyên").
    bool xoaMayInMacDinh = false,
  }) {
    return CaiDat(
      rongMm: rongMm ?? this.rongMm,
      mauMac: mauMac ?? this.mauMac,
      inChuDam: inChuDam ?? this.inChuDam,
      inChuHoa: inChuHoa ?? this.inChuHoa,
      inMaVach: inMaVach ?? this.inMaVach,
      inRiengMaVach: inRiengMaVach ?? this.inRiengMaVach,
      inMacGiamGia: inMacGiamGia ?? this.inMacGiamGia,
      inNgayHetHan: inNgayHetHan ?? this.inNgayHetHan,
      inGiaThuongTrenMacGiam:
          inGiaThuongTrenMacGiam ?? this.inGiaThuongTrenMacGiam,
      inGiaKhongThue: inGiaKhongThue ?? this.inGiaKhongThue,
      tiLeChu: tiLeChu ?? this.tiLeChu,
      inNgangMau8: inNgangMau8 ?? this.inNgangMau8,
      fontChu: fontChu ?? this.fontChu,
      mayInMacDinh: xoaMayInMacDinh
          ? null
          : (mayInMacDinh ?? this.mayInMacDinh),
      tenMayInMacDinh: xoaMayInMacDinh
          ? null
          : (tenMayInMacDinh ?? this.tenMayInMacDinh),
    );
  }

  Map<String, dynamic> toJson() => {
    'rongMm': rongMm,
    'mauMac': mauMac.name,
    'inChuDam': inChuDam,
    'inChuHoa': inChuHoa,
    'inMaVach': inMaVach,
    'inRiengMaVach': inRiengMaVach,
    'inMacGiamGia': inMacGiamGia,
    'inNgayHetHan': inNgayHetHan,
    'inGiaThuongTrenMacGiam': inGiaThuongTrenMacGiam,
    'inGiaKhongThue': inGiaKhongThue,
    'tiLeChu': tiLeChu,
    'inNgangMau8': inNgangMau8,
    'fontChu': fontChu.name,
    'mayInMacDinh': mayInMacDinh,
    'tenMayInMacDinh': tenMayInMacDinh,
  };

  factory CaiDat.fromJson(Map<String, dynamic> json) {
    return CaiDat(
      // File cài đặt cũ có khóa 'caoMm' thì cứ bỏ qua (không đọc nữa)
      // vì giờ in dọc, chiều dài mác tự theo nội dung.
      rongMm: (json['rongMm'] as num?)?.toDouble() ?? 80,
      mauMac: mauMacTuTen(json['mauMac'] as String?) ?? MauMac.thuong,
      inChuDam: json['inChuDam'] as bool? ?? true,
      inChuHoa: json['inChuHoa'] as bool? ?? true,
      inMaVach: json['inMaVach'] as bool? ?? true,
      inRiengMaVach: json['inRiengMaVach'] as bool? ?? false,
      inMacGiamGia: json['inMacGiamGia'] as bool? ?? false,
      inNgayHetHan: json['inNgayHetHan'] as bool? ?? false,
      inGiaThuongTrenMacGiam: json['inGiaThuongTrenMacGiam'] as bool? ?? false,
      inGiaKhongThue: json['inGiaKhongThue'] as bool? ?? false,
      tiLeChu: _docTiLeChu(json['tiLeChu']),
      inNgangMau8: json['inNgangMau8'] as bool? ?? false,
      // File cài đặt cũ chưa có khóa này thì mặc định Sans.
      fontChu: FontMac.tuTen(json['fontChu'] as String?),
      mayInMacDinh: json['mayInMacDinh'] as String?,
      tenMayInMacDinh: json['tenMayInMacDinh'] as String?,
    );
  }

  /// Đọc map tỉ lệ cỡ chữ từ JSON (file cũ chưa có thì dùng rỗng).
  static Map<String, double> _docTiLeChu(dynamic json) {
    if (json is! Map) return {};
    final ketQua = <String, double>{};
    for (final muc in json.entries) {
      final giaTri = (muc.value as num?)?.toDouble();
      if (giaTri != null) ketQua[muc.key.toString()] = giaTri;
    }
    return ketQua;
  }
}
