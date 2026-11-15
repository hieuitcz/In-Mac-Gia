// Cài đặt của app: khổ mác, mẫu đã chọn, các công tắc lúc in.
// Lưu local trên máy, đồng bộ cloud không đụng tới cài đặt này
// (mỗi máy tính tiền có thể để khổ mác và mẫu mặc định khác nhau).
import '../mau_mac/mau_mac.dart';

class CaiDat {
  /// Chiều rộng mác (mm). Mặc định 80 — cuộn giấy nhiệt 80mm.
  final double rongMm;

  /// Chiều cao mác (mm). Mặc định 30 — vừa thanh nẹp giá.
  final double caoMm;

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

  const CaiDat({
    this.rongMm = 80,
    this.caoMm = 30,
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
  });

  /// Tỉ lệ cỡ chữ của 1 mẫu (mặc định 1.0 khi chưa chỉnh).
  double tiLeChuCua(MauMac mau) {
    final tiLe = tiLeChu[mau.name];
    if (tiLe == null) return 1.0;
    return tiLe.clamp(0.7, 1.3);
  }

  /// Trả về bản cài đặt mới với tỉ lệ cỡ chữ của 1 mẫu đã đổi.
  /// Tỉ lệ tự kẹp trong khoảng 0.7–1.3.
  CaiDat voiTiLeChu(MauMac mau, double tiLe) {
    final moi = Map<String, double>.of(tiLeChu);
    moi[mau.name] = tiLe.clamp(0.7, 1.3);
    return copyWith(tiLeChu: moi);
  }

  CaiDat copyWith({
    double? rongMm,
    double? caoMm,
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
  }) {
    return CaiDat(
      rongMm: rongMm ?? this.rongMm,
      caoMm: caoMm ?? this.caoMm,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'rongMm': rongMm,
    'caoMm': caoMm,
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
  };

  factory CaiDat.fromJson(Map<String, dynamic> json) {
    return CaiDat(
      rongMm: (json['rongMm'] as num?)?.toDouble() ?? 80,
      caoMm: (json['caoMm'] as num?)?.toDouble() ?? 30,
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
