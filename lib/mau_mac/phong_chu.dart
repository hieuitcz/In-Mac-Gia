// Tải font chữ đóng gói trong app để vẽ file PDF.
// Dùng font Liberation (Sans cho mẫu thường, Serif cho mẫu cổ điển
// và mẫu nhẹ nhàng) để in đúng dấu tiếng Séc (č, ř, ž, š, ě...).
// Tải 1 lần rồi giữ lại, các lần in sau dùng luôn.
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PhongChuMac {
  static pw.Font? sansThuong;
  static pw.Font? sansDam;
  static pw.Font? sansNghieng;
  static pw.Font? serifThuong;
  static pw.Font? serifDam;
  static pw.Font? serifNghieng;

  static bool get daTai => sansThuong != null;

  static Future<void> tai() async {
    if (daTai) return;
    sansThuong = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'),
    );
    sansDam = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'),
    );
    sansNghieng = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Italic.ttf'),
    );
    serifThuong = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSerif-Regular.ttf'),
    );
    serifDam = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSerif-Bold.ttf'),
    );
    serifNghieng = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSerif-Italic.ttf'),
    );
  }
}
