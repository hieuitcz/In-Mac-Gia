// Vẽ mác ra file PDF để in bằng máy in nhiệt.
// In dọc, khổ cuộn: chiều rộng mác đúng bằng cuộn giấy (mặc định
// 80mm, chỉnh được trong Cài đặt), chiều dài (chiều cao trang) tự
// theo nội dung — file PDF dài đúng bằng nội dung của mẫu để máy in
// nhiệt tự cắt đúng chỗ, không ép chiều cao cố định nữa.
// Mã vạch EAN-13 vẽ thật bằng package barcode (đúng số kiểm tra,
// quét được). Font chữ đóng gói trong app (Liberation) để in đúng
// dấu tiếng Séc cả khi máy offline.
//
// Chỉnh cỡ chữ: mỗi mẫu mác có tỉ lệ cỡ chữ riêng (mặc định 100%,
// chỉnh được 70%–130% trong màn hình in). Tỉ lệ chỉ nhân vào cỡ chữ,
// không nhân vào kích thước mã vạch (mã vạch phải giữ đúng kích thước
// để máy quét đọc được).
import 'dart:math' as math;

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../mo_hinh/cai_dat.dart';
import '../mo_hinh/san_pham.dart';
import '../tien_ich/dinh_dang.dart';
import 'chuoi_mac.dart';
import 'mau_mac.dart';
import 'phong_chu.dart';

/// 1 mục in: 1 sản phẩm in bao nhiêu cái.
typedef MucIn = ({SanPham sanPham, int soLuong});

/// Khổ giấy in cuộn: rộng đúng bằng chiều rộng mác đã chỉnh, dài
/// vô hạn — package pdf sẽ tự co chiều cao trang vừa đúng nội dung
/// của mẫu, máy in nhiệt tự cắt đúng chỗ.
PdfPageFormat khoGiayMac(CaiDat caiDat) {
  return PdfPageFormat(caiDat.rongMm * PdfPageFormat.mm, double.infinity);
}

/// Tạo tài liệu PDF gồm tất cả mác cần in (1 mác = 1 trang).
/// Mỗi trang dài đúng bằng nội dung của mác đó.
Future<pw.Document> taoTaiLieuMac({
  required List<MucIn> mucIn,
  required CaiDat caiDat,
}) async {
  await PhongChuMac.tai();
  final taiLieu = pw.Document();
  final khoGiay = khoGiayMac(caiDat);
  for (final muc in mucIn) {
    final mau = mauThucTe(muc.sanPham, caiDat);
    // Vẽ mác ngay tại đây (không để vào hàm build của trang) để tỉ lệ
    // cỡ chữ của từng mẫu được chốt đúng lúc vẽ.
    final mac = _veMac(muc.sanPham, mau, caiDat);
    for (var i = 0; i < muc.soLuong; i++) {
      taiLieu.addPage(
        pw.Page(
          pageFormat: khoGiay,
          // Lề trái/phải: máy in nhiệt in được hẹp hơn khổ giấy nên
          // nội dung thụt vào 2 bên (khổ 80mm chừa 6mm mỗi bên),
          // không vẽ ra hết khổ — chữ ở mép sẽ bị máy cắt mất, khung
          // ở gần mép cũng bị cắt mất theo.
          margin: pw.EdgeInsets.symmetric(
            horizontal: caiDat.leTrangMm * PdfPageFormat.mm,
          ),
          build: (_) => mac,
        ),
      );
    }
  }
  return taiLieu;
}

/// Mẫu thực tế sẽ in, sau khi áp các công tắc:
/// - "In riêng mã vạch" thì luôn in mẫu chỉ mã vạch.
/// - "In mác giá đang giảm giá" + sản phẩm đang giảm giá thì in mẫu giảm giá.
MauMac mauThucTe(SanPham sp, CaiDat cd) {
  if (cd.inRiengMaVach) return MauMac.chiMaVach;
  if (cd.inMacGiamGia && sp.dangGiamGia) return MauMac.giamGia;
  return cd.mauMac;
}

pw.Widget _veMac(SanPham sp, MauMac mau, CaiDat cd) {
  final tiLe = cd.tiLeChuCua(mau);
  // Mẫu 8 in ngang: chữ viết theo chiều dọc (không phải dải tem
  // nằm ngang) — xem _macSongNguNheNhangNgang.
  if (mau == MauMac.songNguNheNhang && cd.inNgangMau8) {
    return _macSongNguNheNhangNgang(sp, cd, tiLe);
  }
  return switch (mau) {
    MauMac.thuong => _macThuong(sp, cd, tiLe),
    MauMac.giamGia => _macGiamGia(sp, cd, tiLe),
    MauMac.gon => _macGon(sp, cd, tiLe),
    MauMac.chiMaVach => _macChiMaVach(sp, cd, tiLe),
    MauMac.songNguHienDai => _macSongNguHienDai(sp, cd, tiLe),
    MauMac.songNguDaiDen => _macSongNguDaiDen(sp, cd, tiLe),
    MauMac.songNguCoDien => _macSongNguCoDien(sp, cd, tiLe),
    MauMac.songNguNheNhang => _macSongNguNheNhang(sp, cd, tiLe),
  };
}

// ---------- Hàm phụ dùng chung ----------

/// Font chữ: font đã chọn trong Cài đặt áp cho chữ chính (serif
/// = false); chữ serif (mẫu Cổ điển, Nhẹ nhàng) luôn giữ serif.
/// Chọn serif khi serif = true hoặc font đã chọn là serif.
pw.Font _phongChu({
  bool serif = false,
  bool dam = false,
  bool nghieng = false,
  FontMac fontMac = FontMac.sans,
}) {
  final dungSerif = serif || fontMac == FontMac.serif;
  if (dungSerif) {
    if (nghieng) return PhongChuMac.serifNghieng!;
    return dam ? PhongChuMac.serifDam! : PhongChuMac.serifThuong!;
  }
  if (nghieng) return PhongChuMac.sansNghieng!;
  return dam ? PhongChuMac.sansDam! : PhongChuMac.sansThuong!;
}

pw.Widget _chu(
  String text, {
  double co = 10,
  bool dam = false,
  bool serif = false,
  bool nghieng = false,
  FontMac fontMac = FontMac.sans,
  pw.TextAlign? can,
  double? khoangChu,
  pw.TextDecoration? gach,
  int? toiDaDong,
  PdfColor? mau,
}) {
  return pw.Text(
    text,
    style: pw.TextStyle(
      font: _phongChu(
        serif: serif,
        dam: dam,
        nghieng: nghieng,
        fontMac: fontMac,
      ),
      fontSize: co,
      color: mau ?? PdfColors.black,
      letterSpacing: khoangChu,
      decoration: gach,
    ),
    textAlign: can,
    maxLines: toiDaDong,
  );
}

/// Tách chuỗi giá "99,90 Kč" thành ("99,90", "Kč") để in số to, đơn vị nhỏ.
(String so, String donVi) _tachGia(String giaText) {
  final viTri = giaText.lastIndexOf(' ');
  if (viTri < 0) return (giaText, '');
  return (giaText.substring(0, viTri), giaText.substring(viTri + 1));
}

/// Giá lớn: số to, chữ "Kč" bằng khoảng 45% cỡ số (ví dụ số 26 thì
/// Kč khoảng 12), vẫn nhỏ hơn số rõ rệt, căn đáy ở góc dưới phải
/// của số. Dùng cho giá lớn ở mẫu thường, giảm giá, gọn và 3 kiểu
/// song ngữ; mẫu Nhẹ nhàng không dùng hàm này (Kč ở đó giữ nhỏ
/// như tên).
pw.Widget _giaLon(
  String giaText, {
  double coSo = 26,
  bool serif = false,
  double tiLe = 1.0,
  FontMac fontMac = FontMac.sans,
}) {
  final (so, donVi) = _tachGia(giaText);
  final co = coSo * tiLe;
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      _chu(so, co: co, dam: true, serif: serif, fontMac: fontMac),
      pw.SizedBox(width: 1 * PdfPageFormat.mm),
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: co * 0.12),
        child: _chu(
          donVi,
          co: co * 0.45,
          dam: true,
          serif: serif,
          fontMac: fontMac,
        ),
      ),
    ],
  );
}

/// Mã vạch EAN-13 vẽ thật. Chưa có mã hợp lệ thì hiện dòng chữ nhắc
/// (dòng nhắc này cũng theo công tắc in đậm như các chữ phụ khác).
pw.Widget _maVach(
  SanPham sp, {
  required double rong,
  required double cao,
  double tiLe = 1.0,
  bool dam = false,
  FontMac fontMac = FontMac.sans,
}) {
  if (!sp.coMaVachHopLe) {
    return pw.SizedBox(
      width: rong,
      height: cao,
      child: pw.Center(
        child: _chu(
          'Chưa có mã vạch',
          co: 7 * tiLe,
          dam: dam,
          fontMac: fontMac,
        ),
      ),
    );
  }
  return pw.BarcodeWidget(
    barcode: Barcode.ean13(),
    data: sp.maVach,
    width: rong,
    height: cao,
    drawText: false,
    color: PdfColors.black,
    backgroundColor: PdfColors.white,
  );
}

pw.Widget _duongKe({double day = 0.5}) {
  return pw.Container(height: day, color: PdfColors.black);
}

pw.Widget _vachChiaDoc({double cao = 12}) {
  return pw.Container(width: 0.5, height: cao, color: PdfColors.black);
}

/// Giá song ngữ hiện 1 lần, bố cục 2 dòng:
/// - Dòng 1: số giá TO, chữ "Kč" nhỏ đặt ở góc dưới phải của số
///   (kiểu _giaLon: số to, Kč nhỏ căn đáy).
/// - Dòng 2: "/ks · /pc" nhỏ, căn giữa, nằm dưới dòng giá.
/// Giá khoảng dài (hoặc cỡ chữ kéo lên 130%) mà rộng hơn nội dung
/// thì FittedBox tự co nhỏ cả dòng giá lại cho vừa khổ, không bao
/// giờ cắt chữ ở 2 mép.
pw.Widget _giaSongNguMotLan(
  SanPham sp,
  CaiDat cd, {
  bool serif = false,
  double tiLe = 1.0,
}) {
  final gia = giaChinhText(sp, cd);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        child: _giaLon(
          gia,
          coSo: 28,
          serif: serif,
          tiLe: tiLe,
          fontMac: cd.fontChu,
        ),
      ),
      pw.SizedBox(height: 1 * PdfPageFormat.mm),
      _chu(
        '/ks · /pc',
        co: 10 * tiLe,
        dam: cd.inChuDam,
        serif: serif,
        fontMac: cd.fontChu,
        can: pw.TextAlign.center,
      ),
    ],
  );
}

/// Hàng 2 tên song song, có vạch chia ở giữa (3 kiểu song ngữ giá 1 lần).
/// Tên dài thì xuống bao nhiêu dòng tùy ý (không giới hạn 2 dòng
/// nữa): tên rất dài mà chỉ cho 2 dòng thì chữ cuối bị cắt mất, còn
/// mác chỉ dài thêm chứ không mất chữ. Tên Séc theo công tắc in đậm.
/// Tên Anh in nghiêng khi tắt đậm; khi bật đậm thì in đậm thẳng
/// (không nghiêng) vì font Liberation đóng gói không có file
/// đậm-nghiêng nên PDF không vẽ được chữ vừa đậm vừa nghiêng.
pw.Widget _haiTenSongSong(
  SanPham sp,
  CaiDat cd, {
  bool serif = false,
  double tiLe = 1.0,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      pw.Expanded(
        child: _chu(
          tenSecHienThi(sp, cd),
          // Cỡ 11pt cho sans, 10pt cho serif: chữ serif đậm rộng hơn
          // sans nên "ČOKOLÁDOVÉ" serif 11pt (28,5mm) không vừa cột
          // Cổ điển (~26,7mm) mà bị ngắt giữa từ thành "ČOKOLÁDOV /
          // É ..."; serif 10pt (25,9mm) thì vừa. Sans 11pt vừa cột
          // Hiện đại/Dải đen (28,8mm).
          co: (serif ? 10 : 11) * tiLe,
          dam: cd.inChuDam,
          serif: serif,
          fontMac: cd.fontChu,
          can: pw.TextAlign.right,
        ),
      ),
      pw.SizedBox(width: 3 * PdfPageFormat.mm),
      _vachChiaDoc(),
      pw.SizedBox(width: 3 * PdfPageFormat.mm),
      pw.Expanded(
        child: _chu(
          tenAnhHienThi(sp, cd),
          co: 10 * tiLe,
          dam: cd.inChuDam,
          serif: serif,
          fontMac: cd.fontChu,
          nghieng: !cd.inChuDam,
          can: pw.TextAlign.left,
        ),
      ),
    ],
  );
}

// ---------- Từng mẫu ----------

/// Giá lớn nhưng không bao giờ chiếm quá [rongToiDaMm] (mm): giá dài
/// (khoảng giá "1 250 – 2 500 Kč" hoặc cỡ chữ kéo lên 130%) thì tự
/// co nhỏ lại cho vừa, không đẩy cột tên về 0 rồi làm mã vạch lỗi
/// (cột tên hẹp quá thì BarcodeWidget nhận chiều rộng ≤ 0 và ném
/// lỗi khi vẽ — đã gặp ở mẫu Thường với giá khoảng dài sau khi lề
/// tăng lên 6mm). Dùng cho giá lớn ở mẫu thường, giảm giá, gọn.
pw.Widget _giaLonVuaKho(
  String giaText,
  double rongToiDaMm, {
  double coSo = 26,
  bool serif = false,
  double tiLe = 1.0,
  FontMac fontMac = FontMac.sans,
}) {
  return pw.ConstrainedBox(
    constraints: pw.BoxConstraints(maxWidth: rongToiDaMm * PdfPageFormat.mm),
    child: pw.FittedBox(
      fit: pw.BoxFit.scaleDown,
      child: _giaLon(
        giaText,
        coSo: coSo,
        serif: serif,
        tiLe: tiLe,
        fontMac: fontMac,
      ),
    ),
  );
}

/// Mẫu thường: tên to bên trái, giá lớn bên phải, mã vạch + số mã
/// dưới tên, dòng "MN.: 500G" và "100G = 19,98 Kč".
pw.Widget _macThuong(SanPham sp, CaiDat cd, double tiLe) {
  final khoiLuong = khoiLuongText(sp);
  final donGia = donGiaText(sp, cd);
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    child: pw.Row(
      // Hai cột căn giữa dọc với nhau. Căn giữa ở đây an toàn vì
      // chiều cao hàng đã là số hữu hạn (cao nhất trong 2 cột),
      // khác với canh giữa dọc trong 1 cột dài vô hạn.
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Tên dài thì xuống bao nhiêu dòng tùy ý, không bao
              // giờ cắt chữ: cột tên ở đây hẹp (giá lớn chiếm chỗ),
              // tên rất dài mà giới hạn 2 dòng thì mất chữ.
              _chu(
                tenSecHienThi(sp, cd),
                co: 13 * tiLe,
                dam: cd.inChuDam,
                fontMac: cd.fontChu,
              ),
              pw.SizedBox(height: 2 * PdfPageFormat.mm),
              if (cd.inMaVach)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _maVach(
                      sp,
                      rong: 32 * PdfPageFormat.mm,
                      cao: 9 * PdfPageFormat.mm,
                      tiLe: tiLe,
                      dam: cd.inChuDam,
                      fontMac: cd.fontChu,
                    ),
                    if (sp.coMaVachHopLe)
                      _chu(
                        dinhDangSoMaVach(sp.maVach),
                        co: 7 * tiLe,
                        dam: cd.inChuDam,
                        fontMac: cd.fontChu,
                      ),
                  ],
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 2 * PdfPageFormat.mm),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Giá không chiếm quá phần còn lại sau khi trừ cột tên
            // (34mm — đủ cho từ dài "ČOKOLÁDOVÉ" 13pt ≈ 33mm và mã
            // vạch 32mm) và khoảng cách (2mm) khỏi chiều rộng trong
            // (nội dung trừ đệm 2mm mỗi bên): tên dài không bị ngắt
            // giữa từ, mã vạch không bao giờ bị đẩy về 0.
            _giaLonVuaKho(
              giaChinhText(sp, cd),
              cd.rongNoiDungMm - 4 - 34 - 2,
              tiLe: tiLe,
              fontMac: cd.fontChu,
            ),
            if (khoiLuong != null)
              _chu(
                khoiLuong,
                co: 8 * tiLe,
                dam: cd.inChuDam,
                fontMac: cd.fontChu,
              ),
            if (donGia != null)
              _chu(donGia, co: 8 * tiLe, dam: cd.inChuDam, fontMac: cd.fontChu),
          ],
        ),
      ],
    ),
  );
}

/// Mẫu giảm giá: nhãn "AKCE", tên, giá cũ gạch ngang, giá mới to,
/// ngày hết hạn giảm giá (theo công tắc).
pw.Widget _macGiamGia(SanPham sp, CaiDat cd, double tiLe) {
  final giaCu = cd.inGiaThuongTrenMacGiam ? giaGocText(sp, cd) : '';
  final han = cd.inNgayHetHan ? hanGiamGiaText(sp) : null;
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              color: PdfColors.black,
              padding: pw.EdgeInsets.symmetric(
                horizontal: 3 * PdfPageFormat.mm,
                vertical: 1 * PdfPageFormat.mm,
              ),
              child: _chu(
                'AKCE',
                co: 9 * tiLe,
                dam: true,
                khoangChu: 2,
                fontMac: cd.fontChu,
                mau: PdfColors.white,
              ),
            ),
            pw.SizedBox(width: 2 * PdfPageFormat.mm),
            pw.Expanded(
              // Tên dài thì xuống bao nhiêu dòng tùy ý, không bao
              // giờ cắt chữ (cột tên hẹp, xem mẫu thường).
              child: _chu(
                tenSecHienThi(sp, cd),
                co: 13 * tiLe,
                dam: cd.inChuDam,
                fontMac: cd.fontChu,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3 * PdfPageFormat.mm),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (giaCu.isNotEmpty)
                  _chu(
                    giaCu,
                    co: 11 * tiLe,
                    dam: cd.inChuDam,
                    fontMac: cd.fontChu,
                    gach: pw.TextDecoration.lineThrough,
                  ),
                if (han != null)
                  _chu(
                    han,
                    co: 8 * tiLe,
                    dam: cd.inChuDam,
                    fontMac: cd.fontChu,
                  ),
              ],
            ),
            _giaLonVuaKho(
              giaGiamText(sp, cd),
              // Giá giảm không chiếm quá 30mm: dòng ngày hết hạn bên
              // trái rộng ~33mm, cộng lại vẫn vừa chiều rộng trong.
              (cd.rongNoiDungMm - 4) / 2 - 2,
              tiLe: tiLe,
              fontMac: cd.fontChu,
            ),
          ],
        ),
      ],
    ),
  );
}

/// Mẫu gọn: chỉ tên và giá lớn, không mã vạch.
pw.Widget _macGon(SanPham sp, CaiDat cd, double tiLe) {
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          // Tên dài thì xuống bao nhiêu dòng tùy ý, không bao
          // giờ cắt chữ (cột tên hẹp, xem mẫu thường). Cỡ 13pt
          // (thay vì 14pt): từ dài "ČOKOLÁDOVÉ" 14pt (≈35mm) không
          // vừa cột tên 34mm mà bị ngắt giữa từ; 13pt (≈33mm) thì vừa.
          child: _chu(
            tenSecHienThi(sp, cd),
            co: 13 * tiLe,
            dam: cd.inChuDam,
            fontMac: cd.fontChu,
          ),
        ),
        pw.SizedBox(width: 2 * PdfPageFormat.mm),
        // Giá không chiếm quá phần còn lại sau khi trừ cột tên
        // (34mm — đủ cho từ dài "ČOKOLÁDOVÉ" 13pt ≈ 33mm) và khoảng
        // cách (2mm): tên dài không bị ngắt giữa từ.
        _giaLonVuaKho(
          giaChinhText(sp, cd),
          cd.rongNoiDungMm - 4 - 34 - 2,
          tiLe: tiLe,
          fontMac: cd.fontChu,
        ),
      ],
    ),
  );
}

/// Mẫu chỉ mã vạch: tên nhỏ ở trên, mã vạch to ở giữa, số mã ở dưới.
pw.Widget _macChiMaVach(SanPham sp, CaiDat cd, double tiLe) {
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    // Canh đầu (không canh giữa) vì chiều cao cột đúng bằng nội
    // dung nên canh giữa cũng không đổi vị trí, mà trang in dài
    // vô hạn sẽ tính ra vị trí NaN.
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        _chu(
          tenSecHienThi(sp, cd),
          co: 9 * tiLe,
          dam: cd.inChuDam,
          fontMac: cd.fontChu,
          toiDaDong: 2,
        ),
        pw.SizedBox(height: 1 * PdfPageFormat.mm),
        _maVach(
          sp,
          rong: 60 * PdfPageFormat.mm,
          cao: 13 * PdfPageFormat.mm,
          tiLe: tiLe,
          dam: cd.inChuDam,
          fontMac: cd.fontChu,
        ),
        if (sp.coMaVachHopLe)
          _chu(
            dinhDangSoMaVach(sp.maVach),
            co: 9 * tiLe,
            dam: cd.inChuDam,
            fontMac: cd.fontChu,
          ),
      ],
    ),
  );
}

/// Song ngữ – Hiện đại: tiêu đề có gạch dưới, 2 tên song song,
/// giá 1 lần to ở dưới.
pw.Widget _macSongNguHienDai(SanPham sp, CaiDat cd, double tiLe) {
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    child: pw.Column(
      children: [
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: _chu(
            'CENA / PRICE',
            co: 9 * tiLe,
            dam: true,
            khoangChu: 2,
            fontMac: cd.fontChu,
          ),
        ),
        pw.SizedBox(height: 1 * PdfPageFormat.mm),
        _duongKe(),
        pw.SizedBox(height: 3 * PdfPageFormat.mm),
        _haiTenSongSong(sp, cd, tiLe: tiLe),
        pw.SizedBox(height: 3 * PdfPageFormat.mm),
        _giaSongNguMotLan(sp, cd, tiLe: tiLe),
      ],
    ),
  );
}

/// Song ngữ – Dải đen: dải đen chữ trắng ở trên, 2 tên song song,
/// giá 1 lần to ở dưới.
pw.Widget _macSongNguDaiDen(SanPham sp, CaiDat cd, double tiLe) {
  return pw.Column(
    children: [
      pw.Container(
        width: double.infinity,
        color: PdfColors.black,
        padding: pw.EdgeInsets.symmetric(vertical: 1.5 * PdfPageFormat.mm),
        child: pw.Center(
          child: _chu(
            'CENA / PRICE',
            co: 9 * tiLe,
            dam: true,
            khoangChu: 3,
            fontMac: cd.fontChu,
            mau: PdfColors.white,
          ),
        ),
      ),
      pw.SizedBox(height: 3 * PdfPageFormat.mm),
      pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 2 * PdfPageFormat.mm),
        child: _haiTenSongSong(sp, cd, tiLe: tiLe),
      ),
      pw.SizedBox(height: 3 * PdfPageFormat.mm),
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 2 * PdfPageFormat.mm),
        child: _giaSongNguMotLan(sp, cd, tiLe: tiLe),
      ),
    ],
  );
}

/// Song ngữ – Cổ điển: chữ serif, khung đôi, 2 tên song song,
/// giá 1 lần to ở dưới.
pw.Widget _macSongNguCoDien(SanPham sp, CaiDat cd, double tiLe) {
  // Khung đôi thụt vào 1,5mm quanh khung ngoài: máy in nhiệt không
  // in sát mép được nên khung dính mép trang sẽ mất 1 đoạn kẻ phải.
  return pw.Container(
    margin: pw.EdgeInsets.all(1.5 * PdfPageFormat.mm),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.2),
    ),
    padding: pw.EdgeInsets.all(1 * PdfPageFormat.mm),
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      // Đệm trong chỉ 1mm (thay vì 2mm): khung đôi ăn nhiều chiều
      // ngang nên cột tên chỉ còn ~26,7mm — đệm 2mm thì từ dài
      // "ČOKOLÁDOVÉ" serif 10pt (25,9mm) vẫn chật, đệm 1mm mới vừa.
      padding: pw.EdgeInsets.all(1 * PdfPageFormat.mm),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: _duongKe()),
              pw.SizedBox(width: 2 * PdfPageFormat.mm),
              _chu(
                'CENA / PRICE',
                co: 9 * tiLe,
                dam: true,
                serif: true,
                khoangChu: 2,
              ),
              pw.SizedBox(width: 2 * PdfPageFormat.mm),
              pw.Expanded(child: _duongKe()),
            ],
          ),
          pw.SizedBox(height: 3 * PdfPageFormat.mm),
          _haiTenSongSong(sp, cd, serif: true, tiLe: tiLe),
          pw.SizedBox(height: 3 * PdfPageFormat.mm),
          _giaSongNguMotLan(sp, cd, serif: true, tiLe: tiLe),
        ],
      ),
    ),
  );
}

/// Song ngữ – Nhẹ nhàng (mẫu số 6): theo đúng ảnh gốc — tiêu đề
/// "CENA / PRICE" chữ serif, 2 dòng, mỗi dòng 1 ngôn ngữ kèm luôn
/// giá của dòng đó. Khung viền mỏng, nhiều khoảng trắng.
/// Số tiền TO hơn tên (tên 11pt, số tiền 16pt đậm), đơn vị "/ ks"
/// và "/ pc" giữ nhỏ như tên. Tên, chữ "Kč" và đơn vị theo công tắc
/// in đậm; số tiền luôn đậm vì đó là giá.
pw.Widget _macSongNguNheNhang(SanPham sp, CaiDat cd, double tiLe) {
  final giaSec = giaChinhText(sp, cd);
  final giaAnh = giaChinhText(sp, cd, tiengAnh: true);
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 0.5),
    ),
    padding: pw.EdgeInsets.symmetric(
      horizontal: 4 * PdfPageFormat.mm,
      vertical: 3 * PdfPageFormat.mm,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _chu(
          'CENA / PRICE',
          co: 10 * tiLe,
          dam: true,
          serif: true,
          khoangChu: 1,
        ),
        pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
        _duongKe(day: 0.5),
        pw.SizedBox(height: 3 * PdfPageFormat.mm),
        _dongNheNhang(
          tenSecHienThi(sp, cd),
          giaSec,
          '/ ks',
          tiLe,
          rongNoiDungMm: cd.rongNoiDungMm,
          dam: cd.inChuDam,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        _dongNheNhang(
          tenAnhHienThi(sp, cd),
          giaAnh,
          '/ pc',
          tiLe,
          rongNoiDungMm: cd.rongNoiDungMm,
          dam: cd.inChuDam,
        ),
      ],
    ),
  );
}

/// 1 dòng mẫu Nhẹ nhàng: tên nhỏ (11pt), chỉ PHẦN SỐ to đậm (16pt),
/// chữ "Kč" giữ nhỏ như tên (11pt, căn đáy như giá lớn ở các mẫu
/// khác), đơn vị nhỏ như tên (11pt). Giá khoảng hiện dạng "100 – 250 Kč".
/// Tên, chữ "Kč" và đơn vị theo công tắc in đậm; PHẦN SỐ luôn đậm
/// vì đó là giá (cùng nguyên tắc như _giaLon ở các mẫu khác).
/// Tên dài thì xuống dòng 2 gọn gàng (tối đa 2 dòng, ngắt từ đẹp):
/// tên nằm trong Flexible nên chỉ chiếm chiều rộng còn lại, phần giá
/// luôn nằm gọn bên phải, không bao giờ bị cắt mất.
pw.Widget _dongNheNhang(
  String ten,
  String gia,
  String donVi,
  double tiLe, {
  required double rongNoiDungMm,
  bool dam = false,
}) {
  final (so, donViTien) = _tachGia(gia);
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Flexible(
        child: _chu(ten, co: 11 * tiLe, dam: dam, serif: true, toiDaDong: 2),
      ),
      pw.SizedBox(width: 2 * PdfPageFormat.mm),
      // Giá không chiếm quá phần còn lại sau khi trừ cột tên (30mm —
      // đủ cho từ dài "ČOKOLÁDOVÉ" serif 11pt ≈ 28,5mm) và khoảng
      // cách (2mm): tên dài không bị ngắt giữa từ thành "ČOKOL /
      // ÁDOVÉ" khi giá khoảng dài chiếm hết chiều rộng.
      pw.ConstrainedBox(
        constraints: pw.BoxConstraints(
          maxWidth: (rongNoiDungMm - 8 - 30 - 2) * PdfPageFormat.mm,
        ),
        child: pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _chu(so, co: 16 * tiLe, dam: true, serif: true),
              if (donViTien.isNotEmpty) ...[
                pw.SizedBox(width: 1),
                _chu(donViTien, co: 11 * tiLe, dam: dam, serif: true),
              ],
              pw.SizedBox(width: 1),
              _chu(donVi, co: 11 * tiLe, dam: dam, serif: true),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Song ngữ – Nhẹ nhàng, in ngang (mẫu 8): VẪN KHỔ DỌC 80mm
/// (dải tem đứng), nhưng CHỮ VIẾT THEO CHIỀU DỌC — bản chuyển vị
/// đúng của mẫu dọc: xoay nguyên mẫu dọc -90° (chữ đọc từ trên
/// xuống dưới, như ảnh gốc). Cột "CENA / PRICE" ở bên phải, 2 dòng
/// sản phẩm (tiếng Anh rồi tiếng Séc) là các cột đứng bên trái nó,
/// khung viền mỏng bao ngoài, không thêm vạch chia giữa 2 dòng sản
/// phẩm. Xoay tem 90° ngược chiều kim đồng hồ để đọc thì thành:
/// tiêu đề "CENA / PRICE" ở trên cùng, dưới nó là 1 đường gạch ngang
/// (chính là gạch ngang dưới tiêu đề bản dọc), rồi đến các dòng sản
/// phẩm. Giá vẫn dạng gạch ngang "100 – 250 Kč", số to + Kč nhỏ
/// như đã chốt. Chiều dài dải tem bằng chiều rộng nội dung bản dọc
/// (khổ giấy trừ lề 2 bên), chiều rộng dải bằng chiều cao bản dọc.
pw.Widget _macSongNguNheNhangNgang(SanPham sp, CaiDat cd, double tiLe) {
  return pw.Transform.rotateBox(
    angle: -math.pi / 2,
    child: pw.SizedBox(
      width: cd.rongNoiDungMm * PdfPageFormat.mm,
      child: _macSongNguNheNhang(sp, cd, tiLe),
    ),
  );
}
