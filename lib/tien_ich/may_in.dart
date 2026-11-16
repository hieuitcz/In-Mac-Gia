// Tìm máy in mặc định đã lưu trong Cài đặt.
// Định danh máy in là `url` (ổn định hơn tên hiển thị, tên có thể
// đổi khi cài lại driver). Cỡ giấy/mác mặc định thì lấy luôn chiều
// rộng mác (rongMm) đã lưu trong Cài đặt.
import 'package:printing/printing.dart';

/// Tìm máy in trong danh sách theo url đã lưu. Không có thì null.
/// Hàm thuần để test được mà không cần máy in thật.
Printer? timMayInTrongDanhSach(List<Printer> danhSach, String? url) {
  if (url == null || url.isEmpty) return null;
  for (final mayIn in danhSach) {
    if (mayIn.url == url) return mayIn;
  }
  return null;
}

/// Lấy danh sách máy in của máy tính rồi tìm máy in mặc định đã lưu.
/// Lỗi (không lấy được danh sách) thì trả về null để màn hình in
/// hiện hộp thoại chọn máy in như cũ.
Future<Printer?> timMayInMacDinh(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final danhSach = await Printing.listPrinters();
    return timMayInTrongDanhSach(danhSach, url);
  } catch (_) {
    return null;
  }
}
