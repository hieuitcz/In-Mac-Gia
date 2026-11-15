// Test kho lưu trữ local: ghi/đọc sản phẩm và cài đặt qua file JSON.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_mac_gia/luu_tru/kho_du_lieu.dart';
import 'package:in_mac_gia/mau_mac/mau_mac.dart';
import 'package:in_mac_gia/mo_hinh/cai_dat.dart';
import 'package:in_mac_gia/mo_hinh/san_pham.dart';

void main() {
  late Directory thuMucTam;

  setUp(() async {
    thuMucTam = await Directory.systemTemp.createTemp('in-mac-gia-test');
  });

  tearDown(() async {
    if (await thuMucTam.exists()) await thuMucTam.delete(recursive: true);
  });

  test('chưa có file thì đọc ra rỗng / mặc định', () async {
    final kho = KhoDuLieu(thuMucGhiDe: thuMucTam);
    expect(await kho.docSanPham(), isEmpty);
    final cd = await kho.docCaiDat();
    expect(cd.rongMm, 80);
  });

  test('ghi rồi đọc lại giữ nguyên sản phẩm', () async {
    final kho = KhoDuLieu(thuMucGhiDe: thuMucTam);
    final danhSach = [
      SanPham(
        id: '1',
        tenSec: 'Eidam 45% 500 g',
        tenAnh: 'Eidam cheese',
        maVach: '5901234123457',
        gia: 99.9,
        khoiLuongGam: 500,
        capNhat: DateTime(2026, 11, 15),
      ),
      SanPham(
        id: '2',
        tenSec: 'Samolepky',
        tenAnh: 'Stickers',
        giaTu: 70,
        giaDen: 100,
        capNhat: DateTime(2026, 11, 15),
      ),
    ];
    await kho.luuSanPham(danhSach);
    final docLai = await kho.docSanPham();
    expect(docLai.length, 2);
    expect(docLai[0].tenSec, 'Eidam 45% 500 g');
    expect(docLai[0].maVach, '5901234123457');
    expect(docLai[1].coGiaKhoang, isTrue);
  });

  test('ghi rồi đọc lại giữ nguyên cài đặt và tỉ lệ chữ', () async {
    final kho = KhoDuLieu(thuMucGhiDe: thuMucTam);
    const cd = CaiDat();
    final daChinh = cd
        .copyWith(rongMm: 80)
        .voiTiLeChu(MauMac.songNguNheNhang, 0.85);
    await kho.luuCaiDat(daChinh);
    final docLai = await kho.docCaiDat();
    expect(docLai.rongMm, 80);
    expect(docLai.tiLeChuCua(MauMac.songNguNheNhang), 0.85);
  });
}
