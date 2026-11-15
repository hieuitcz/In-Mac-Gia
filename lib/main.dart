// Điểm vào của app In Mác Giá.
// Mở app: đọc dữ liệu local trước cho nhanh, rồi đồng bộ cloud ở nền.
import 'dart:async';

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
  final dieuKhien = DieuKhienApp(kho: KhoDuLieu(), dongBo: DongBoCloud());
  unawaited(dieuKhien.khoiDong());
  runApp(UngDung(dieuKhien: dieuKhien));
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
