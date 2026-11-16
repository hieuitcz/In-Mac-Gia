// Lưu dữ liệu local trên máy (offline-first): danh sách sản phẩm và
// cài đặt lưu thành file JSON trong thư mục AppData của app.
// Mất mạng vẫn dùng bình thường; có mạng thì đồng bộ lên cloud.
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../mo_hinh/cai_dat.dart';
import '../mo_hinh/san_pham.dart';

class KhoDuLieu {
  /// Thư mục ghi đè khi test (không dùng AppData thật).
  final Directory? thuMucGhiDe;

  KhoDuLieu({this.thuMucGhiDe});

  Future<Directory> get _thuMuc async {
    if (thuMucGhiDe != null) return thuMucGhiDe!;
    return getApplicationSupportDirectory();
  }

  Future<File> get _tepSanPham async =>
      File('${(await _thuMuc).path}/san-pham.json');

  Future<File> get _tepCaiDat async =>
      File('${(await _thuMuc).path}/cai-dat.json');

  /// Đọc danh sách sản phẩm đã lưu. File chưa có hoặc hỏng thì trả về rỗng.
  Future<List<SanPham>> docSanPham() async {
    try {
      final tep = await _tepSanPham;
      if (!await tep.exists()) return [];
      final noiDung = await tep.readAsString();
      final danhSach = jsonDecode(noiDung) as List;
      return danhSach
          .map((e) => SanPham.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ghi đè toàn bộ danh sách sản phẩm xuống file local.
  Future<void> luuSanPham(List<SanPham> danhSach) async {
    final tep = await _tepSanPham;
    await tep.create(recursive: true);
    final json = danhSach.map((sp) => sp.toJson()).toList();
    await tep.writeAsString(jsonEncode(json));
  }

  /// Đọc cài đặt đã lưu. Chưa có thì dùng mặc định.
  Future<CaiDat> docCaiDat() async {
    try {
      final tep = await _tepCaiDat;
      if (!await tep.exists()) return const CaiDat();
      final noiDung = await tep.readAsString();
      return CaiDat.fromJson(jsonDecode(noiDung) as Map<String, dynamic>);
    } catch (_) {
      return const CaiDat();
    }
  }

  /// Ghi cài đặt xuống file local.
  Future<void> luuCaiDat(CaiDat caiDat) async {
    final tep = await _tepCaiDat;
    await tep.create(recursive: true);
    await tep.writeAsString(jsonEncode(caiDat.toJson()));
  }

  /// File nhật ký khởi động (ghi lỗi mở app để lần sau có bằng chứng).
  Future<File> get tepNhatKy async =>
      File('${(await _thuMuc).path}/nhat-ky-khoi-dong.log');

  /// Đường dẫn file nhật ký để hiện trong Cài đặt.
  Future<String> get duongDanNhatKy async => (await tepNhatKy).path;

  /// Ghi 1 dòng vào nhật ký khởi động (kèm giờ). Lỗi ghi log thì thôi,
  /// không bao giờ ném lỗi ra ngoài để khỏi làm app tắt theo.
  Future<void> ghiNhatKy(String dong) async {
    try {
      final tep = await tepNhatKy;
      await tep.create(recursive: true);
      final gio = DateTime.now().toIso8601String();
      await tep.writeAsString('[$gio] $dong\n', mode: FileMode.append);
    } catch (_) {
      // Ghi log lỗi thì thôi.
    }
  }
}
