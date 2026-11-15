// Vẽ mác ra file PDF đúng khổ đã chỉnh, để in bằng máy in nhiệt.
// Mỗi mẫu mác là 1 trang PDF đúng bằng khổ mác (mặc định 80×30mm).
// Mã vạch EAN-13 vẽ thật bằng package barcode (đúng số kiểm tra,
// quét được). Font chữ đóng gói trong app (Liberation) để in đúng
// dấu tiếng Séc cả khi máy offline.
//
// Chỉnh cỡ chữ: mỗi mẫu mác có tỉ lệ cỡ chữ riêng (mặc định 100%,
// chỉnh được 70%–130% trong màn hình in). Tỉ lệ chỉ nhân vào cỡ chữ,
// không nhân vào kích thước mã vạch (mã vạch phải giữ đúng kích thước
// để máy quét đọc được).
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

/// Tạo tài liệu PDF gồm tất cả mác cần in (1 mác = 1 trang).
Future<pw.Document> taoTaiLieuMac({
  required List<MucIn> mucIn,
  required CaiDat caiDat,
}) async {
  await PhongChuMac.tai();
  final taiLieu = pw.Document();
  final khoGiay = PdfPageFormat(
    caiDat.rongMm * PdfPageFormat.mm,
    caiDat.caoMm * PdfPageFormat.mm,
  );
  for (final muc in mucIn) {
    final mau = mauThucTe(muc.sanPham, caiDat);
    // Vẽ mác ngay tại đây (không để vào hàm build của trang) để tỉ lệ
    // cỡ chữ của từng mẫu được chốt đúng lúc vẽ.
    final mac = _veMac(muc.sanPham, mau, caiDat);
    for (var i = 0; i < muc.soLuong; i++) {
      taiLieu.addPage(
        pw.Page(
          pageFormat: khoGiay,
          margin: pw.EdgeInsets.zero,
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
  switch (mau) {
    case MauMac.thuong:
      return _macThuong(sp, cd, tiLe);
    case MauMac.giamGia:
      return _macGiamGia(sp, cd, tiLe);
    case MauMac.gon:
      return _macGon(sp, cd, tiLe);
    case MauMac.chiMaVach:
      return _macChiMaVach(sp, cd, tiLe);
    case MauMac.songNguHienDai:
      return _macSongNguHienDai(sp, cd, tiLe);
    case MauMac.songNguDaiDen:
      return _macSongNguDaiDen(sp, cd, tiLe);
    case MauMac.songNguCoDien:
      return _macSongNguCoDien(sp, cd, tiLe);
    case MauMac.songNguNheNhang:
      return _macSongNguNheNhang(sp, cd, tiLe);
  }
}

// ---------- Hàm phụ dùng chung ----------

pw.Font _phongChu({
  bool serif = false,
  bool dam = false,
  bool nghieng = false,
}) {
  if (serif) {
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
  pw.TextAlign? can,
  double? khoangChu,
  pw.TextDecoration? gach,
  int? toiDaDong,
  PdfColor? mau,
}) {
  return pw.Text(
    text,
    style: pw.TextStyle(
      font: _phongChu(serif: serif, dam: dam, nghieng: nghieng),
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

/// Giá lớn: số to, đơn vị "Kč" nhỏ hơn, căn cuối dòng.
pw.Widget _giaLon(
  String giaText, {
  double coSo = 26,
  bool serif = false,
  double tiLe = 1.0,
}) {
  final (so, donVi) = _tachGia(giaText);
  final co = coSo * tiLe;
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      _chu(so, co: co, dam: true, serif: serif),
      pw.SizedBox(width: 1 * PdfPageFormat.mm),
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: co * 0.12),
        child: _chu(donVi, co: co * 0.45, dam: true, serif: serif),
      ),
    ],
  );
}

/// Mã vạch EAN-13 vẽ thật. Chưa có mã hợp lệ thì hiện dòng chữ nhắc.
pw.Widget _maVach(
  SanPham sp, {
  required double rong,
  required double cao,
  double tiLe = 1.0,
}) {
  if (!sp.coMaVachHopLe) {
    return pw.SizedBox(
      width: rong,
      height: cao,
      child: pw.Center(child: _chu('Chưa có mã vạch', co: 7 * tiLe)),
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

/// Giá song ngữ hiện 1 lần: "od 70 do 100 Kč" + " /ks · /pc" nhỏ hơn.
pw.Widget _giaSongNguMotLan(
  SanPham sp,
  CaiDat cd, {
  bool serif = false,
  double tiLe = 1.0,
}) {
  final gia = giaChinhText(sp, cd);
  return pw.RichText(
    textAlign: pw.TextAlign.center,
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: gia,
          style: pw.TextStyle(
            font: _phongChu(serif: serif, dam: true),
            fontSize: 19 * tiLe,
            color: PdfColors.black,
          ),
        ),
        pw.TextSpan(
          text: ' /ks · /pc',
          style: pw.TextStyle(
            font: _phongChu(serif: serif, dam: false),
            fontSize: 10 * tiLe,
            color: PdfColors.black,
          ),
        ),
      ],
    ),
  );
}

/// Hàng 2 tên song song, có vạch chia ở giữa (3 kiểu song ngữ giá 1 lần).
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
          co: 12 * tiLe,
          dam: cd.inChuDam,
          serif: serif,
          can: pw.TextAlign.right,
          toiDaDong: 1,
        ),
      ),
      pw.SizedBox(width: 3 * PdfPageFormat.mm),
      _vachChiaDoc(),
      pw.SizedBox(width: 3 * PdfPageFormat.mm),
      pw.Expanded(
        child: _chu(
          tenAnhHienThi(sp, cd),
          co: 11 * tiLe,
          serif: serif,
          nghieng: true,
          can: pw.TextAlign.left,
          toiDaDong: 1,
        ),
      ),
    ],
  );
}

// ---------- Từng mẫu ----------

/// Mẫu thường: tên to bên trái, giá lớn bên phải, mã vạch + số mã
/// dưới tên, dòng "MN.: 500G" và "100G = 19,98 Kč".
pw.Widget _macThuong(SanPham sp, CaiDat cd, double tiLe) {
  final khoiLuong = khoiLuongText(sp);
  final donGia = donGiaText(sp, cd);
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _chu(
                tenSecHienThi(sp, cd),
                co: 13 * tiLe,
                dam: cd.inChuDam,
                toiDaDong: 2,
              ),
              if (cd.inMaVach)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _maVach(
                      sp,
                      rong: 32 * PdfPageFormat.mm,
                      cao: 9 * PdfPageFormat.mm,
                      tiLe: tiLe,
                    ),
                    if (sp.coMaVachHopLe)
                      _chu(dinhDangSoMaVach(sp.maVach), co: 7 * tiLe),
                  ],
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 2 * PdfPageFormat.mm),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _giaLon(giaChinhText(sp, cd), coSo: 26, tiLe: tiLe),
            if (khoiLuong != null) _chu(khoiLuong, co: 8 * tiLe),
            if (donGia != null) _chu(donGia, co: 8 * tiLe),
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
                mau: PdfColors.white,
              ),
            ),
            pw.SizedBox(width: 2 * PdfPageFormat.mm),
            pw.Expanded(
              child: _chu(
                tenSecHienThi(sp, cd),
                co: 13 * tiLe,
                dam: cd.inChuDam,
                toiDaDong: 1,
              ),
            ),
          ],
        ),
        pw.Spacer(),
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
                    gach: pw.TextDecoration.lineThrough,
                  ),
                if (han != null) _chu(han, co: 8 * tiLe),
              ],
            ),
            _giaLon(giaGiamText(sp, cd), coSo: 26, tiLe: tiLe),
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
          child: _chu(
            tenSecHienThi(sp, cd),
            co: 14 * tiLe,
            dam: cd.inChuDam,
            toiDaDong: 2,
          ),
        ),
        pw.SizedBox(width: 2 * PdfPageFormat.mm),
        _giaLon(giaChinhText(sp, cd), coSo: 26, tiLe: tiLe),
      ],
    ),
  );
}

/// Mẫu chỉ mã vạch: tên nhỏ ở trên, mã vạch to ở giữa, số mã ở dưới.
pw.Widget _macChiMaVach(SanPham sp, CaiDat cd, double tiLe) {
  return pw.Container(
    padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _chu(
          tenSecHienThi(sp, cd),
          co: 9 * tiLe,
          dam: cd.inChuDam,
          toiDaDong: 1,
        ),
        pw.SizedBox(height: 1 * PdfPageFormat.mm),
        _maVach(
          sp,
          rong: 60 * PdfPageFormat.mm,
          cao: 13 * PdfPageFormat.mm,
          tiLe: tiLe,
        ),
        if (sp.coMaVachHopLe) _chu(dinhDangSoMaVach(sp.maVach), co: 9 * tiLe),
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
          child: _chu('CENA / PRICE', co: 9 * tiLe, dam: true, khoangChu: 2),
        ),
        pw.SizedBox(height: 1 * PdfPageFormat.mm),
        _duongKe(),
        pw.Expanded(
          child: pw.Center(child: _haiTenSongSong(sp, cd, tiLe: tiLe)),
        ),
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
            mau: PdfColors.white,
          ),
        ),
      ),
      pw.Expanded(
        child: pw.Container(
          padding: pw.EdgeInsets.symmetric(horizontal: 2 * PdfPageFormat.mm),
          child: pw.Center(child: _haiTenSongSong(sp, cd, tiLe: tiLe)),
        ),
      ),
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
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.2),
    ),
    padding: pw.EdgeInsets.all(1 * PdfPageFormat.mm),
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      padding: pw.EdgeInsets.all(2 * PdfPageFormat.mm),
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
          pw.Expanded(
            child: pw.Center(
              child: _haiTenSongSong(sp, cd, serif: true, tiLe: tiLe),
            ),
          ),
          _giaSongNguMotLan(sp, cd, serif: true, tiLe: tiLe),
        ],
      ),
    ),
  );
}

/// Song ngữ – Nhẹ nhàng (mẫu số 6): theo đúng ảnh gốc — tiêu đề
/// "CENA / PRICE" chữ serif, 2 dòng, mỗi dòng 1 ngôn ngữ kèm luôn
/// giá của dòng đó. Khung viền mỏng, nhiều khoảng trắng, giá không to.
/// Mẫu này chỉnh được cỡ chữ (70%–130%) để tên/giá dài vẫn vừa 1 dòng.
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
        pw.Spacer(),
        _chu(
          '${tenSecHienThi(sp, cd)} $giaSec / ks',
          co: 11 * tiLe,
          serif: true,
          toiDaDong: 2,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        _chu(
          '${tenAnhHienThi(sp, cd)} $giaAnh / pc',
          co: 11 * tiLe,
          serif: true,
          toiDaDong: 2,
        ),
        pw.Spacer(),
      ],
    ),
  );
}
