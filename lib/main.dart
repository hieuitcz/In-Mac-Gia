// Điểm vào của app In Mác Giá.
// Mở app: đọc dữ liệu local trước cho nhanh, rồi đồng bộ cloud ở nền.
// Lỗi khởi động không làm app tắt: khoiDong tự bắt lỗi từng bước,
// lỗi chưa bắt được ghi vào nhật ký khởi động để lần sau có bằng chứng.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'dieu_khien.dart';
import 'dong_bo/dong_bo_cloud.dart';
import 'giao_dien/chu_de.dart';
import 'luu_tru/kho_du_lieu.dart';
import 'man_hinh/man_hinh_chinh.dart';

/// Số phiên bản hiện trong Cài đặt. CI truyền số bản qua
/// --dart-define=APP_BUILD_NUMBER khi build (giống app chấm công).
const String _soBan = String.fromEnvironment(
  'APP_BUILD_NUMBER',
  defaultValue: '1',
);

/// Phiên bản app, ví dụ "1.0.12".
String get phienBanApp => '1.0.$_soBan';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final kho = KhoDuLieu();
  // Lỗi chưa bắt thì ghi nhật ký rồi cho app chạy tiếp, không tắt app.
  FlutterError.onError = (chiTiet) {
    unawaited(kho.ghiNhatKy('Lỗi giao diện: ${chiTiet.exception}'));
    FlutterError.presentError(chiTiet);
  };
  PlatformDispatcher.instance.onError = (e, s) {
    unawaited(kho.ghiNhatKy('Lỗi chưa bắt: $e'));
    return true;
  };
  runZonedGuarded(
    () {
      final dieuKhien = DieuKhienApp(kho: kho, dongBo: DongBoCloud());
      unawaited(dieuKhien.khoiDong());
      runApp(UngDung(dieuKhien: dieuKhien));
    },
    (e, s) {
      unawaited(kho.ghiNhatKy('Lỗi vùng chính: $e'));
    },
  );
}

class UngDung extends StatelessWidget {
  final DieuKhienApp dieuKhien;

  const UngDung({super.key, required this.dieuKhien});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In Mác Giá',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: mauNenTrang,
        useMaterial3: true,
      ),
      home: ManHinhChinh(dieuKhien: dieuKhien),
    );
  }
}
