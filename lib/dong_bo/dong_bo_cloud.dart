// Đồng bộ cloud qua Firebase project gio-lam (dùng chung với app
// chấm công). Đăng nhập ẩn danh vì giá sản phẩm vốn là thông tin
// công khai trên mác, không phải dữ liệu nhạy cảm.
// Collection riêng: cenovky_products (1 doc = 1 sản phẩm).
//
// CẦN LÀM TRÊN FIREBASE CONSOLE (1 lần duy nhất):
// 1. Authentication > Sign-in method > bật "Anonymous".
// 2. Firestore Database > Rules > thêm rule cho collection mới
//    (xem file firestore.rules ở gốc repo rồi dán vào Console).
// 3. Dán mã apiKey vào lib/firebase_options.dart (xem ghi chú trong file).
// Chưa làm 3 bước trên thì hàm khoiTao() trả về false và app chỉ
// lưu trên máy — không báo lỗi, không treo app.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../mo_hinh/san_pham.dart';

class DongBoCloud {
  static const String tenCollection = 'cenovky_products';

  /// Đã kết nối được Firebase chưa.
  bool daKetNoi = false;

  /// Lý do chưa đồng bộ được (hiện trong Cài đặt để anh chủ biết).
  String lyDo = 'Chưa thử kết nối.';

  /// Khởi tạo Firebase + đăng nhập ẩn danh. Lỗi thì bỏ qua, app vẫn
  /// chạy offline. Hết 10 giây không xong thì coi như mất mạng.
  Future<bool> khoiTao() async {
    if (!DefaultFirebaseOptions.coCauHinh) {
      lyDo =
          'Chưa có mã API Firebase — dán apiKey vào '
          'lib/firebase_options.dart rồi build lại.';
      return false;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      await FirebaseAuth.instance.signInAnonymously().timeout(
        const Duration(seconds: 10),
      );
      daKetNoi = true;
      lyDo = 'Đã đồng bộ cloud.';
      return true;
    } catch (e) {
      daKetNoi = false;
      lyDo = 'Không kết nối được cloud — chỉ lưu trên máy.';
      return false;
    }
  }

  /// Đẩy toàn bộ danh sách local lên cloud (ghi đè theo mã sản phẩm).
  Future<void> taiLen(List<SanPham> danhSach) async {
    if (!daKetNoi) return;
    try {
      final ref = FirebaseFirestore.instance.collection(tenCollection);
      final lo = FirebaseFirestore.instance.batch();
      for (final sp in danhSach) {
        lo.set(ref.doc(sp.id), sp.toJson());
      }
      await lo.commit().timeout(const Duration(seconds: 15));
    } catch (_) {
      // Đẩy lỗi thì thôi, lần đồng bộ sau đẩy lại.
    }
  }

  /// Tải toàn bộ sản phẩm trên cloud về. Lỗi thì trả về rỗng.
  Future<List<SanPham>> taiXuong() async {
    if (!daKetNoi) return [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection(tenCollection)
          .get()
          .timeout(const Duration(seconds: 15));
      return snap.docs.map((d) => SanPham.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  /// Đồng bộ 2 chiều: đẩy local lên, tải cloud về, gộp theo mốc
  /// sửa cuối (bản nào mới hơn thì giữ). Trả về danh sách đã gộp.
  Future<List<SanPham>> dongBo(List<SanPham> local) async {
    if (!daKetNoi) return local;
    await taiLen(local);
    final trenCloud = await taiXuong();
    final theoId = <String, SanPham>{};
    for (final sp in local) {
      theoId[sp.id] = sp;
    }
    for (final sp in trenCloud) {
      final cu = theoId[sp.id];
      if (cu == null || sp.capNhat.isAfter(cu.capNhat)) {
        theoId[sp.id] = sp;
      }
    }
    final gop = theoId.values.toList()
      ..sort((a, b) => a.tenSec.compareTo(b.tenSec));
    return gop;
  }
}
