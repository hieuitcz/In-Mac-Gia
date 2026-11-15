// Danh sách mẫu mác in — đã duyệt thiết kế với anh chủ.
// Tất cả cùng in dọc, rộng bằng chiều rộng mác đã chỉnh trong
// Cài đặt (mặc định 80mm), dài tự theo nội dung, máy in tự cắt,
// in đen trắng trên giấy nhiệt cuộn 80mm.
enum MauMac {
  /// Mẫu thường: tên to bên trái, giá lớn bên phải, mã vạch + số mã
  /// dưới tên, dòng "MN.: 500G" và "100G = 19,98 Kč".
  thuong,

  /// Mẫu giảm giá: nhãn "AKCE" nền đen chữ trắng, tên sản phẩm,
  /// giá cũ gạch ngang, giá mới to, ngày hết hạn giảm giá.
  giamGia,

  /// Mẫu gọn: chỉ tên và giá lớn, không mã vạch.
  gon,

  /// Mẫu chỉ mã vạch: tên nhỏ ở trên, mã vạch to ở giữa, số mã ở dưới.
  chiMaVach,

  /// Song ngữ – Hiện đại: tiêu đề "CENA / PRICE" có gạch dưới,
  /// 2 tên song song có vạch chia giữa, giá chỉ hiện 1 lần to ở dưới.
  songNguHienDai,

  /// Song ngữ – Dải đen: dải đen chữ trắng "CENA / PRICE" ở trên,
  /// 2 tên song song, giá chỉ hiện 1 lần to ở dưới.
  songNguDaiDen,

  /// Song ngữ – Cổ điển: chữ serif, khung đôi, 2 tên song song,
  /// giá chỉ hiện 1 lần to ở dưới.
  songNguCoDien,

  /// Song ngữ – Nhẹ nhàng (mẫu số 6): theo đúng ảnh gốc — tiêu đề
  /// "CENA / PRICE" chữ serif, 2 dòng, mỗi dòng 1 ngôn ngữ kèm luôn
  /// giá của dòng đó (dòng Séc "... Kč / ks", dòng Anh "... Kč / pc").
  /// Khung viền mỏng 1px, nhiều khoảng trắng, không nhấn mạnh giá to.
  songNguNheNhang,
}

extension MauMacMoTa on MauMac {
  /// Tên hiện trong ô chọn mẫu lúc in.
  String get ten {
    switch (this) {
      case MauMac.thuong:
        return 'Thường';
      case MauMac.giamGia:
        return 'Giảm giá';
      case MauMac.gon:
        return 'Gọn';
      case MauMac.chiMaVach:
        return 'Chỉ mã vạch';
      case MauMac.songNguHienDai:
        return 'Song ngữ – Hiện đại';
      case MauMac.songNguDaiDen:
        return 'Song ngữ – Dải đen';
      case MauMac.songNguCoDien:
        return 'Song ngữ – Cổ điển';
      case MauMac.songNguNheNhang:
        return 'Song ngữ – Nhẹ nhàng';
    }
  }

  /// Mô tả ngắn hiện dưới ô chọn mẫu.
  String get moTa {
    switch (this) {
      case MauMac.thuong:
        return 'Tên to, giá lớn, mã vạch, đơn giá 100 g.';
      case MauMac.giamGia:
        return 'Giá cũ gạch ngang, giá mới to, ngày hết hạn.';
      case MauMac.gon:
        return 'Chỉ tên và giá lớn, không mã vạch.';
      case MauMac.chiMaVach:
        return 'Tên nhỏ, mã vạch to, số mã ở dưới.';
      case MauMac.songNguHienDai:
        return '2 tên song song, giá 1 lần to ở dưới.';
      case MauMac.songNguDaiDen:
        return 'Dải đen trên, 2 tên song song, giá 1 lần to.';
      case MauMac.songNguCoDien:
        return 'Chữ serif, khung đôi, giá 1 lần to ở dưới.';
      case MauMac.songNguNheNhang:
        return 'Mỗi dòng 1 ngôn ngữ, kèm luôn giá của dòng đó.';
    }
  }

  /// Có phải mẫu song ngữ CENA / PRICE không.
  bool get laSongNgu {
    return this == MauMac.songNguHienDai ||
        this == MauMac.songNguDaiDen ||
        this == MauMac.songNguCoDien ||
        this == MauMac.songNguNheNhang;
  }
}

/// Tìm mẫu mác theo tên lưu trong JSON. Trả về null khi tên lạ
/// (file cài đặt cũ hoặc gõ sai).
MauMac? mauMacTuTen(String? ten) {
  if (ten == null) return null;
  for (final mau in MauMac.values) {
    if (mau.name == ten) return mau;
  }
  return null;
}
