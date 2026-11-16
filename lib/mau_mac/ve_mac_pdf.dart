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
  final mac = switch (mau) {
    MauMac.thuong => _macThuong(sp, cd, tiLe),
    MauMac.giamGia => _macGiamGia(sp, cd, tiLe),
    MauMac.gon => _macGon(sp, cd, tiLe),
    MauMac.chiMaVach => _macChiMaVach(sp, cd, tiLe),
    MauMac.songNguHienDai => _macSongNguHienDai(sp, cd, tiLe),
    MauMac.songNguDaiDen => _macSongNguDaiDen(sp, cd, tiLe),
    MauMac.songNguCoDien => _macSongNguCoDien(sp, cd, tiLe),
    MauMac.songNguNheNhang => _macSongNguNheNhang(sp, cd, tiLe),
  };
  // Mẫu 8 in ngang: xoay nội dung 90° để tên dài vừa 1 dòng.
  // Khổ trang vẫn là cuộn rộng 80mm (chiều cao của dải tem ngang),
  // chiều dài dải tem tự theo nội dung, máy in tự cắt.
  // rotateBox với unconstrained: true layout nội dung với chiều rộng
  // vô hạn (mỗi dòng tên + giá nằm gọn 1 dòng) rồi mới xoay khung;
  // đường kẻ dưới tiêu đề không căng được theo chiều rộng vô hạn
  // nên ở bản in ngang nó không hiện (chỉ mất đường kẻ, nội dung
  // vẫn đủ). Chỉ áp cho mẫu 8, các mẫu khác vẫn in dọc.
  if (mau == MauMac.songNguNheNhang && cd.inNgangMau8) {
    return pw.Transform.rotateBox(
      angle: math.pi / 2,
      unconstrained: true,
      child: mac,
    );
  }
  return mac;
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

/// Mã vạch EAN-13 vẽ thật. Chưa có mã hợp lệ thì hiện dòng chữ nhắc
/// (dòng nhắc này cũng theo công tắc in đậm như các chữ phụ khác).
pw.Widget _maVach(
  SanPham sp, {
  required double rong,
  required double cao,
  double tiLe = 1.0,
  bool dam = false,
}) {
  if (!sp.coMaVachHopLe) {
    return pw.SizedBox(
      width: rong,
      height: cao,
      child: pw.Center(
        child: _chu('Chưa có mã vạch', co: 7 * tiLe, dam: dam),
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
      _giaLon(gia, coSo: 28, serif: serif, tiLe: tiLe),
      pw.SizedBox(height: 1 * PdfPageFormat.mm),
      _chu(
        '/ks · /pc',
        co: 10 * tiLe,
        dam: cd.inChuDam,
        serif: serif,
        can: pw.TextAlign.center,
      ),
    ],
  );
}

/// Hàng 2 tên song song, có vạch chia ở giữa (3 kiểu song ngữ giá 1 lần).
/// Tên Séc theo công tắc in đậm. Tên Anh in nghiêng khi tắt đậm;
/// khi bật đậm thì in đậm thẳng (không nghiêng) vì font Liberation
/// đóng gói không có file đậm-nghiêng nên PDF không vẽ được chữ
/// vừa đậm vừa nghiêng.
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
          dam: cd.inChuDam,
          serif: serif,
          nghieng: !cd.inChuDam,
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
      // Hai cột căn giữa dọc với nhau. Căn giữa ở đây an toàn vì
      // chiều cao hàng đã là số hữu hạn (cao nhất trong 2 cột),
      // khác với canh giữa dọc trong 1 cột dài vô hạn.
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _chu(
                tenSecHienThi(sp, cd),
                co: 13 * tiLe,
                dam: cd.inChuDam,
                toiDaDong: 2,
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
                    ),
                    if (sp.coMaVachHopLe)
                      _chu(
                        dinhDangSoMaVach(sp.maVach),
                        co: 7 * tiLe,
                        dam: cd.inChuDam,
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
            _giaLon(giaChinhText(sp, cd), coSo: 26, tiLe: tiLe),
            if (khoiLuong != null)
              _chu(khoiLuong, co: 8 * tiLe, dam: cd.inChuDam),
            if (donGia != null) _chu(donGia, co: 8 * tiLe, dam: cd.inChuDam),
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
                    gach: pw.TextDecoration.lineThrough,
                  ),
                if (han != null) _chu(han, co: 8 * tiLe, dam: cd.inChuDam),
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
          toiDaDong: 1,
        ),
        pw.SizedBox(height: 1 * PdfPageFormat.mm),
        _maVach(
          sp,
          rong: 60 * PdfPageFormat.mm,
          cao: 13 * PdfPageFormat.mm,
          tiLe: tiLe,
          dam: cd.inChuDam,
        ),
        if (sp.coMaVachHopLe)
          _chu(dinhDangSoMaVach(sp.maVach), co: 9 * tiLe, dam: cd.inChuDam),
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
          dam: cd.inChuDam,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        _dongNheNhang(
          tenAnhHienThi(sp, cd),
          giaAnh,
          '/ pc',
          tiLe,
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
pw.Widget _dongNheNhang(
  String ten,
  String gia,
  String donVi,
  double tiLe, {
  bool dam = false,
}) {
  final (so, donViTien) = _tachGia(gia);
  return pw.RichText(
    maxLines: 2,
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$ten ',
          style: pw.TextStyle(
            font: _phongChu(serif: true, dam: dam),
            fontSize: 11 * tiLe,
            color: PdfColors.black,
          ),
        ),
        pw.TextSpan(
          text: so,
          style: pw.TextStyle(
            font: _phongChu(serif: true, dam: true),
            fontSize: 16 * tiLe,
            color: PdfColors.black,
          ),
        ),
        if (donViTien.isNotEmpty)
          pw.TextSpan(
            text: ' $donViTien',
            style: pw.TextStyle(
              font: _phongChu(serif: true, dam: dam),
              fontSize: 11 * tiLe,
              color: PdfColors.black,
            ),
          ),
        pw.TextSpan(
          text: ' $donVi',
          style: pw.TextStyle(
            font: _phongChu(serif: true, dam: dam),
            fontSize: 11 * tiLe,
            color: PdfColors.black,
          ),
        ),
      ],
    ),
  );
}
