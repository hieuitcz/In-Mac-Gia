// Xem trước mác trên màn hình — cùng bố cục và chuỗi hiển thị với
// bản in PDF, chỉ khác là vẽ bằng widget Flutter để xem nhanh.
// Khung xem trước rộng 320 (tương đương 80mm), cao tự theo nội dung
// như bản in dọc — không ép tỉ lệ 80×30 nữa.
// Tỉ lệ cỡ chữ của mẫu đang chọn (70%–130%) cũng áp vào đây để
// xem trước đổi ngay theo thanh trượt.
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../mo_hinh/cai_dat.dart';
import '../mo_hinh/san_pham.dart';
import '../tien_ich/dinh_dang.dart';
import 'chuoi_mac.dart';
import 'mau_mac.dart';
import 've_mac_pdf.dart';

class XemTruocMac extends StatelessWidget {
  final SanPham sanPham;
  final MauMac mau;
  final CaiDat caiDat;

  const XemTruocMac({
    super.key,
    required this.sanPham,
    required this.mau,
    required this.caiDat,
  });

  @override
  Widget build(BuildContext context) {
    // Tôn trọng mẫu được truyền vào (mau), chỉ áp thêm các công tắc
    // ghi đè (in riêng mã vạch / in mác giảm giá) như bản in PDF.
    // Trước đây build dùng thẳng caiDat.mauMac nên tham số mau bị
    // bỏ qua — màn hình in truyền trùng nhau nên app vẫn đúng,
    // nhưng gọi riêng với mẫu khác sẽ xem trước sai mẫu.
    final mauThuc = mauThucTe(sanPham, caiDat.copyWith(mauMac: mau));
    final tiLe = caiDat.tiLeChuCua(mauThuc);
    return SizedBox(
      width: 320,
      child: Container(
        color: Colors.white,
        child: _veMac(sanPham, mauThuc, caiDat, tiLe),
      ),
    );
  }

  Widget _veMac(SanPham sp, MauMac mau, CaiDat cd, double tiLe) {
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

  Text _chu(
    String text, {
    double co = 12,
    bool dam = false,
    bool serif = false,
    bool nghieng = false,
    FontMac fontMac = FontMac.sans,
    TextAlign? can,
    double? khoangChu,
    TextDecoration? gach,
    Color? mau,
    int? toiDaDong,
  }) {
    // Font đã chọn áp cho chữ chính; chữ serif (mẫu Cổ điển,
    // Nhẹ nhàng) luôn giữ serif.
    final dungSerif = serif || fontMac == FontMac.serif;
    return Text(
      text,
      style: TextStyle(
        fontFamily: dungSerif ? 'LiberationSerif' : 'LiberationSans',
        fontSize: co,
        fontWeight: dam ? FontWeight.bold : FontWeight.normal,
        fontStyle: nghieng ? FontStyle.italic : FontStyle.normal,
        color: mau ?? Colors.black,
        letterSpacing: khoangChu,
        decoration: gach,
        height: 1.15,
      ),
      textAlign: can,
      maxLines: toiDaDong,
      overflow: TextOverflow.ellipsis,
    );
  }

  (String, String) _tachGia(String giaText) {
    final viTri = giaText.lastIndexOf(' ');
    if (viTri < 0) return (giaText, '');
    return (giaText.substring(0, viTri), giaText.substring(viTri + 1));
  }

  /// Giá lớn: số to, chữ "Kč" bằng khoảng 45% cỡ số (ví dụ số 30 thì
  /// Kč khoảng 13,5), vẫn nhỏ hơn số rõ rệt, căn đáy ở góc dưới phải
  /// của số. Dùng cho giá lớn ở mẫu thường, giảm giá, gọn và 3 kiểu
  /// song ngữ; mẫu Nhẹ nhàng không dùng hàm này (Kč ở đó giữ nhỏ
  /// như tên).
  Widget _giaLon(
    String giaText, {
    double coSo = 30,
    bool serif = false,
    double tiLe = 1.0,
    FontMac fontMac = FontMac.sans,
  }) {
    final (so, donVi) = _tachGia(giaText);
    final co = coSo * tiLe;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _chu(so, co: co, dam: true, serif: serif, fontMac: fontMac),
        const SizedBox(width: 3),
        Padding(
          padding: EdgeInsets.only(bottom: co * 0.12),
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

  Widget _maVach(
    SanPham sp, {
    required double rong,
    required double cao,
    double tiLe = 1.0,
    bool dam = false,
    FontMac fontMac = FontMac.sans,
  }) {
    if (!sp.coMaVachHopLe) {
      return SizedBox(
        width: rong,
        height: cao,
        child: Center(
          child: _chu(
            'Chưa có mã vạch',
            co: 9 * tiLe,
            dam: dam,
            fontMac: fontMac,
          ),
        ),
      );
    }
    return BarcodeWidget(
      barcode: Barcode.ean13(),
      data: sp.maVach,
      width: rong,
      height: cao,
      drawText: false,
      color: Colors.black,
      backgroundColor: Colors.white,
    );
  }

  Widget _giaSongNguMotLan(
    SanPham sp,
    CaiDat cd, {
    bool serif = false,
    double tiLe = 1.0,
  }) {
    final gia = giaChinhText(sp, cd);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _giaLon(gia, coSo: 30, serif: serif, tiLe: tiLe, fontMac: cd.fontChu),
        const SizedBox(height: 2),
        _chu(
          '/ks · /pc',
          co: 11 * tiLe,
          dam: cd.inChuDam,
          serif: serif,
          fontMac: cd.fontChu,
          can: TextAlign.center,
        ),
      ],
    );
  }

  /// Tên Anh in nghiêng khi tắt đậm; khi bật đậm thì in đậm thẳng
  /// (không nghiêng) để giống hệt bản in PDF — font Liberation đóng
  /// gói không có file đậm-nghiêng nên PDF không vẽ được chữ vừa
  /// đậm vừa nghiêng.
  Widget _haiTenSongSong(
    SanPham sp,
    CaiDat cd, {
    bool serif = false,
    double tiLe = 1.0,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _chu(
            tenSecHienThi(sp, cd),
            co: 14 * tiLe,
            dam: cd.inChuDam,
            serif: serif,
            fontMac: cd.fontChu,
            can: TextAlign.right,
            toiDaDong: 2,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 16, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: _chu(
            tenAnhHienThi(sp, cd),
            co: 13 * tiLe,
            dam: cd.inChuDam,
            serif: serif,
            fontMac: cd.fontChu,
            nghieng: !cd.inChuDam,
            can: TextAlign.left,
            toiDaDong: 2,
          ),
        ),
      ],
    );
  }

  // ---------- Từng mẫu ----------

  Widget _macThuong(SanPham sp, CaiDat cd, double tiLe) {
    final khoiLuong = khoiLuongText(sp);
    final donGia = donGiaText(sp, cd);
    return Padding(
      padding: const EdgeInsets.all(8),
      // Căn giữa dọc (không dùng stretch): khung xem trước nằm trong
      // ListView ở màn hình in nên chiều cao không giới hạn — Row mà
      // stretch con theo chiều cao vô hạn sẽ ném lỗi
      // "BoxConstraints forces an infinite height" và cả khung xem
      // trước mẫu thường vỡ theo (đây chính là lỗi user báo).
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên dài thì xuống bao nhiêu dòng tùy ý, không bao
                // giờ cắt chữ: cột tên ở đây hẹp (giá lớn chiếm chỗ),
                // tên rất dài mà giới hạn 2 dòng thì mất chữ.
                _chu(
                  tenSecHienThi(sp, cd),
                  co: 15 * tiLe,
                  dam: cd.inChuDam,
                  fontMac: cd.fontChu,
                ),
                const SizedBox(height: 8),
                if (cd.inMaVach)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _maVach(
                        sp,
                        rong: 128,
                        cao: 36,
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _giaLon(
                giaChinhText(sp, cd),
                coSo: 30,
                tiLe: tiLe,
                fontMac: cd.fontChu,
              ),
              if (khoiLuong != null)
                _chu(
                  khoiLuong,
                  co: 10 * tiLe,
                  dam: cd.inChuDam,
                  fontMac: cd.fontChu,
                ),
              if (donGia != null)
                _chu(
                  donGia,
                  co: 10 * tiLe,
                  dam: cd.inChuDam,
                  fontMac: cd.fontChu,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macGiamGia(SanPham sp, CaiDat cd, double tiLe) {
    final giaCu = cd.inGiaThuongTrenMacGiam ? giaGocText(sp, cd) : '';
    final han = cd.inNgayHetHan ? hanGiamGiaText(sp) : null;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: _chu(
                  'AKCE',
                  co: 11 * tiLe,
                  dam: true,
                  khoangChu: 2,
                  fontMac: cd.fontChu,
                  mau: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                // Tên dài thì xuống bao nhiêu dòng tùy ý, không bao
                // giờ cắt chữ (cột tên hẹp, xem mẫu thường).
                child: _chu(
                  tenSecHienThi(sp, cd),
                  co: 15 * tiLe,
                  dam: cd.inChuDam,
                  fontMac: cd.fontChu,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (giaCu.isNotEmpty)
                    _chu(
                      giaCu,
                      co: 13 * tiLe,
                      dam: cd.inChuDam,
                      fontMac: cd.fontChu,
                      gach: TextDecoration.lineThrough,
                    ),
                  if (han != null)
                    _chu(
                      han,
                      co: 10 * tiLe,
                      dam: cd.inChuDam,
                      fontMac: cd.fontChu,
                    ),
                ],
              ),
              _giaLon(
                giaGiamText(sp, cd),
                coSo: 30,
                tiLe: tiLe,
                fontMac: cd.fontChu,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macGon(SanPham sp, CaiDat cd, double tiLe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            // Tên dài thì xuống bao nhiêu dòng tùy ý, không bao
            // giờ cắt chữ (cột tên hẹp, xem mẫu thường).
            child: _chu(
              tenSecHienThi(sp, cd),
              co: 16 * tiLe,
              dam: cd.inChuDam,
              fontMac: cd.fontChu,
            ),
          ),
          const SizedBox(width: 8),
          _giaLon(
            giaChinhText(sp, cd),
            coSo: 30,
            tiLe: tiLe,
            fontMac: cd.fontChu,
          ),
        ],
      ),
    );
  }

  Widget _macChiMaVach(SanPham sp, CaiDat cd, double tiLe) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _chu(
            tenSecHienThi(sp, cd),
            co: 11 * tiLe,
            dam: cd.inChuDam,
            fontMac: cd.fontChu,
            toiDaDong: 2,
          ),
          const SizedBox(height: 4),
          _maVach(
            sp,
            rong: 240,
            cao: 52,
            tiLe: tiLe,
            dam: cd.inChuDam,
            fontMac: cd.fontChu,
          ),
          if (sp.coMaVachHopLe)
            _chu(
              dinhDangSoMaVach(sp.maVach),
              co: 11 * tiLe,
              dam: cd.inChuDam,
              fontMac: cd.fontChu,
            ),
        ],
      ),
    );
  }

  Widget _macSongNguHienDai(SanPham sp, CaiDat cd, double tiLe) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _chu(
              'CENA / PRICE',
              co: 11 * tiLe,
              dam: true,
              khoangChu: 2,
              fontMac: cd.fontChu,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: Colors.black),
          const SizedBox(height: 12),
          _haiTenSongSong(sp, cd, tiLe: tiLe),
          const SizedBox(height: 12),
          _giaSongNguMotLan(sp, cd, tiLe: tiLe),
        ],
      ),
    );
  }

  Widget _macSongNguDaiDen(SanPham sp, CaiDat cd, double tiLe) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: _chu(
              'CENA / PRICE',
              co: 11 * tiLe,
              dam: true,
              khoangChu: 3,
              fontMac: cd.fontChu,
              mau: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _haiTenSongSong(sp, cd, tiLe: tiLe),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _giaSongNguMotLan(sp, cd, tiLe: tiLe),
        ),
      ],
    );
  }

  Widget _macSongNguCoDien(SanPham sp, CaiDat cd, double tiLe) {
    // Khung đôi thụt vào 6px (~1,5mm) quanh khung ngoài: khung dính
    // mép khung xem trước sẽ mất 1 đoạn kẻ phải.
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(border: Border.all(width: 1.5)),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 0.5)),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.black, height: 1)),
                const SizedBox(width: 8),
                _chu(
                  'CENA / PRICE',
                  co: 11 * tiLe,
                  dam: true,
                  serif: true,
                  khoangChu: 2,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Divider(color: Colors.black, height: 1)),
              ],
            ),
            const SizedBox(height: 12),
            _haiTenSongSong(sp, cd, serif: true, tiLe: tiLe),
            const SizedBox(height: 12),
            _giaSongNguMotLan(sp, cd, serif: true, tiLe: tiLe),
          ],
        ),
      ),
    );
  }

  Widget _macSongNguNheNhang(SanPham sp, CaiDat cd, double tiLe) {
    final giaSec = giaChinhText(sp, cd);
    final giaAnh = giaChinhText(sp, cd, tiengAnh: true);
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chu(
            'CENA / PRICE',
            co: 12 * tiLe,
            dam: true,
            serif: true,
            khoangChu: 1,
          ),
          const SizedBox(height: 6),
          Container(height: 0.5, color: Colors.black),
          const SizedBox(height: 12),
          _dongNheNhang(
            tenSecHienThi(sp, cd),
            giaSec,
            '/ ks',
            tiLe,
            dam: cd.inChuDam,
          ),
          const SizedBox(height: 8),
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

  /// 1 dòng mẫu Nhẹ nhàng: tên nhỏ (13), chỉ PHẦN SỐ to đậm (19),
  /// chữ "Kč" giữ nhỏ như tên (13), đơn vị nhỏ như tên (13).
  /// Tên, chữ "Kč" và đơn vị theo công tắc in đậm; PHẦN SỐ luôn đậm
  /// vì đó là giá (cùng nguyên tắc như _giaLon ở các mẫu khác).
  /// Tên dài thì xuống dòng 2 gọn gàng (tối đa 2 dòng, ngắt từ đẹp):
  /// tên nằm trong Flexible nên chỉ chiếm chiều rộng còn lại, phần giá
  /// luôn nằm gọn bên phải, không bao giờ bị cắt mất.
  Widget _dongNheNhang(
    String ten,
    String gia,
    String donVi,
    double tiLe, {
    bool dam = false,
  }) {
    final (so, donViTien) = _tachGia(gia);
    TextSpan spanTen(String text, {required double co, bool damChu = false}) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'LiberationSerif',
          fontSize: co,
          fontWeight: damChu ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            ten,
            style: TextStyle(
              fontFamily: 'LiberationSerif',
              fontSize: 13 * tiLe,
              fontWeight: dam ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black),
            children: [
              spanTen(so, co: 19 * tiLe, damChu: true),
              if (donViTien.isNotEmpty)
                spanTen(' $donViTien', co: 13 * tiLe, damChu: dam),
              spanTen(' $donVi', co: 13 * tiLe, damChu: dam),
            ],
          ),
        ),
      ],
    );
  }

  /// Song ngữ – Nhẹ nhàng, in ngang (mẫu 8): VẪN KHỔ DỌC 80mm
  /// (dải tem đứng), nhưng CHỮ VIẾT THEO CHIỀU DỌC — chữ xoay 90°
  /// ngược chiều kim đồng hồ, đọc từ dưới lên trên. Cột "CENA / PRICE"
  /// ở bên phải, 2 dòng sản phẩm (tiếng Anh rồi tiếng Séc) là các cột
  /// đứng bên trái nó, có vạch chia dọc giữa các cột, khung viền mỏng
  /// bao ngoài. Xoay tem 90° theo chiều kim đồng hồ để đọc thì thành:
  /// tiêu đề "CENA / PRICE" ở trên cùng, dưới nó là 1 đường gạch ngang
  /// (chính là vạch chia dọc bên cạnh cột tiêu đề), rồi đến các dòng
  /// sản phẩm. Giá vẫn dạng gạch ngang "100 – 250 Kč", số to + Kč nhỏ
  /// như đã chốt. Dùng Table 1 hàng × 3 cột, mỗi ô xoay nội dung
  /// của mình (RotatedBox quarterTurns 3 = 90° ngược chiều kim đồng
  /// hồ); vạch chia dọc là border verticalInside của bảng.
  Widget _macSongNguNheNhangNgang(SanPham sp, CaiDat cd, double tiLe) {
    final giaSec = giaChinhText(sp, cd);
    final giaAnh = giaChinhText(sp, cd, tiengAnh: true);

    // 1 cột dọc: xoay nội dung -90° (đọc từ dưới lên trên), căn giữa
    // trong cột. Ô bảng được layout với chiều rộng cố định bằng chiều
    // rộng cột nên Center căn ngang được; căn dọc giữa hàng do
    // defaultVerticalAlignment của bảng.
    Widget cotDoc(Widget dong) {
      // Đệm dọc 12px (~3mm) mỗi đầu: dòng dài nhất chạm sát khung
      // trên/dưới nếu không có đệm này.
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: RotatedBox(quarterTurns: 3, child: dong),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.25),
        },
        border: TableBorder(
          top: const BorderSide(width: 0.5),
          left: const BorderSide(width: 0.5),
          right: const BorderSide(width: 0.5),
          bottom: const BorderSide(width: 0.5),
          verticalInside: const BorderSide(width: 0.5),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              cotDoc(
                _dongNheNhang(
                  tenAnhHienThi(sp, cd),
                  giaAnh,
                  '/ pc',
                  tiLe,
                  dam: cd.inChuDam,
                ),
              ),
              cotDoc(
                _dongNheNhang(
                  tenSecHienThi(sp, cd),
                  giaSec,
                  '/ ks',
                  tiLe,
                  dam: cd.inChuDam,
                ),
              ),
              cotDoc(
                _chu(
                  'CENA / PRICE',
                  co: 12 * tiLe,
                  dam: true,
                  serif: true,
                  khoangChu: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
