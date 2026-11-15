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
    final mauThuc = mauThucTe(sanPham, caiDat);
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

  Text _chu(
    String text, {
    double co = 12,
    bool dam = false,
    bool serif = false,
    bool nghieng = false,
    TextAlign? can,
    double? khoangChu,
    TextDecoration? gach,
    Color? mau,
    int? toiDaDong,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: serif ? 'LiberationSerif' : 'LiberationSans',
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

  Widget _giaLon(
    String giaText, {
    double coSo = 30,
    bool serif = false,
    double tiLe = 1.0,
  }) {
    final (so, donVi) = _tachGia(giaText);
    final co = coSo * tiLe;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _chu(so, co: co, dam: true, serif: serif),
        const SizedBox(width: 3),
        Padding(
          padding: EdgeInsets.only(bottom: co * 0.12),
          child: _chu(donVi, co: co * 0.45, dam: true, serif: serif),
        ),
      ],
    );
  }

  Widget _maVach(
    SanPham sp, {
    required double rong,
    required double cao,
    double tiLe = 1.0,
  }) {
    if (!sp.coMaVachHopLe) {
      return SizedBox(
        width: rong,
        height: cao,
        child: Center(child: _chu('Chưa có mã vạch', co: 9 * tiLe)),
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
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text: gia,
            style: TextStyle(
              fontFamily: serif ? 'LiberationSerif' : 'LiberationSans',
              fontSize: 22 * tiLe,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: ' /ks · /pc',
            style: TextStyle(
              fontFamily: serif ? 'LiberationSerif' : 'LiberationSans',
              fontSize: 11 * tiLe,
            ),
          ),
        ],
      ),
    );
  }

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
            can: TextAlign.right,
            toiDaDong: 1,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 16, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: _chu(
            tenAnhHienThi(sp, cd),
            co: 13 * tiLe,
            serif: serif,
            nghieng: true,
            can: TextAlign.left,
            toiDaDong: 1,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chu(
                  tenSecHienThi(sp, cd),
                  co: 15 * tiLe,
                  dam: cd.inChuDam,
                  toiDaDong: 2,
                ),
                const SizedBox(height: 8),
                if (cd.inMaVach)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _maVach(sp, rong: 128, cao: 36, tiLe: tiLe),
                      if (sp.coMaVachHopLe)
                        _chu(dinhDangSoMaVach(sp.maVach), co: 9 * tiLe),
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
              _giaLon(giaChinhText(sp, cd), coSo: 30, tiLe: tiLe),
              if (khoiLuong != null) _chu(khoiLuong, co: 10 * tiLe),
              if (donGia != null) _chu(donGia, co: 10 * tiLe),
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
                  mau: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chu(
                  tenSecHienThi(sp, cd),
                  co: 15 * tiLe,
                  dam: cd.inChuDam,
                  toiDaDong: 1,
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
                      gach: TextDecoration.lineThrough,
                    ),
                  if (han != null) _chu(han, co: 10 * tiLe),
                ],
              ),
              _giaLon(giaGiamText(sp, cd), coSo: 30, tiLe: tiLe),
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
            child: _chu(
              tenSecHienThi(sp, cd),
              co: 16 * tiLe,
              dam: cd.inChuDam,
              toiDaDong: 2,
            ),
          ),
          const SizedBox(width: 8),
          _giaLon(giaChinhText(sp, cd), coSo: 30, tiLe: tiLe),
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
            toiDaDong: 1,
          ),
          const SizedBox(height: 4),
          _maVach(sp, rong: 240, cao: 52, tiLe: tiLe),
          if (sp.coMaVachHopLe)
            _chu(dinhDangSoMaVach(sp.maVach), co: 11 * tiLe),
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
            child: _chu('CENA / PRICE', co: 11 * tiLe, dam: true, khoangChu: 2),
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
    return Container(
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
          _chu(
            '${tenSecHienThi(sp, cd)} $giaSec / ks',
            co: 13 * tiLe,
            serif: true,
            toiDaDong: 2,
          ),
          const SizedBox(height: 8),
          _chu(
            '${tenAnhHienThi(sp, cd)} $giaAnh / pc',
            co: 13 * tiLe,
            serif: true,
            toiDaDong: 2,
          ),
        ],
      ),
    );
  }
}
