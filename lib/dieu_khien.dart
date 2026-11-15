// Bộ điều khiển dữ liệu của app: giữ danh sách sản phẩm + cài đặt,
// lưu local sau mỗi lần đổi, đẩy lên cloud khi có mạng.
// Màn hình chính và màn hình in đều nghe thay đổi từ đây.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dong_bo/dong_bo_cloud.dart';
import '../luu_tru/kho_du_lieu.dart';
import '../mo_hinh/cai_dat.dart';
import '../mo_hinh/san_pham.dart';

class DieuKhienApp extends ChangeNotifier {
  final KhoDuLieu kho;
  final DongBoCloud dongBo;

  List<SanPham> sanPham = [];
  CaiDat caiDat = const CaiDat();
  bool dangTai = true;

  /// Dòng trạng thái đồng bộ hiện ở màn hình chính và Cài đặt.
  String trangThaiDongBo = 'Đang tải dữ liệu...';

  DieuKhienApp({required this.kho, required this.dongBo});

  /// Mở app: đọc local trước cho nhanh, rồi đồng bộ cloud ở nền.
  Future<void> khoiDong() async {
    sanPham = await kho.docSanPham();
    caiDat = await kho.docCaiDat();
    dangTai = false;
    notifyListeners();
    final ketNoiDuoc = await dongBo.khoiTao();
    if (ketNoiDuoc) {
      sanPham = await dongBo.dongBo(sanPham);
      await kho.luuSanPham(sanPham);
    }
    trangThaiDongBo = dongBo.lyDo;
    notifyListeners();
  }

  /// Đồng bộ ngay khi người dùng bấm nút.
  Future<void> dongBoNgay() async {
    trangThaiDongBo = 'Đang đồng bộ...';
    notifyListeners();
    if (!dongBo.daKetNoi) {
      final ketNoiDuoc = await dongBo.khoiTao();
      if (!ketNoiDuoc) {
        trangThaiDongBo = dongBo.lyDo;
        notifyListeners();
        return;
      }
    }
    sanPham = await dongBo.dongBo(sanPham);
    await kho.luuSanPham(sanPham);
    trangThaiDongBo = dongBo.lyDo;
    notifyListeners();
  }

  /// Tìm nhanh theo tên (Séc/Anh) hoặc mã vạch. Gõ mã vạch rồi quét
  /// là ra ngay sản phẩm để in.
  List<SanPham> timKiem(String tuKhoa) {
    final tu = tuKhoa.trim().toLowerCase();
    if (tu.isEmpty) return sanPham;
    final khongDau = tu.replaceAll(RegExp(r'\s'), '');
    return sanPham.where((sp) {
      if (sp.tenSec.toLowerCase().contains(tu)) return true;
      if (sp.tenAnh.toLowerCase().contains(tu)) return true;
      if (khongDau.isNotEmpty && sp.maVach.contains(khongDau)) return true;
      return false;
    }).toList();
  }

  /// Thêm sản phẩm mới: lưu local rồi đẩy lên cloud (lỗi thì thôi,
  /// lần đồng bộ sau đẩy lại).
  Future<void> themSanPham(SanPham sp) async {
    sanPham = [...sanPham, sp]..sort(_soSanhTen);
    await kho.luuSanPham(sanPham);
    notifyListeners();
    unawaited(dongBo.taiLen(sanPham));
  }

  /// Sửa sản phẩm: đổi mốc sửa cuối để cloud biết bản này mới nhất.
  Future<void> suaSanPham(SanPham sp) async {
    final moi = sp.copyWith(capNhat: DateTime.now());
    sanPham = sanPham.map((cu) => cu.id == sp.id ? moi : cu).toList()
      ..sort(_soSanhTen);
    await kho.luuSanPham(sanPham);
    notifyListeners();
    unawaited(dongBo.taiLen(sanPham));
  }

  /// Xóa sản phẩm khỏi máy (bản cloud sẽ bị ghi đè ở lần đồng bộ sau
  /// vì danh sách local là danh sách chuẩn để đẩy lên).
  Future<void> xoaSanPham(String id) async {
    sanPham = sanPham.where((sp) => sp.id != id).toList();
    await kho.luuSanPham(sanPham);
    notifyListeners();
    unawaited(dongBo.taiLen(sanPham));
  }

  /// Đổi cài đặt (khổ mác, mẫu, công tắc, cỡ chữ): lưu local ngay.
  Future<void> capNhatCaiDat(CaiDat moi) async {
    caiDat = moi;
    await kho.luuCaiDat(moi);
    notifyListeners();
  }

  static int _soSanhTen(SanPham a, SanPham b) =>
      a.tenSec.toLowerCase().compareTo(b.tenSec.toLowerCase());

  /// Mã riêng cho sản phẩm mới.
  static String taoIdMoi() => DateTime.now().microsecondsSinceEpoch.toString();
}
