// Tự nhận màn hình rồi đặt cỡ cửa sổ vừa màn hình ngay từ đầu
// (giống app chấm công bản windows-53): cửa sổ mở lên đã vừa,
// không mở to rồi mới co lại. Nội dung các màn hình cuộn được
// nên màn nhỏ không che mất Cài đặt.
// Dùng window_manager + screen_retriever. Lỗi (không đọc được
// màn hình...) thì dùng cỡ mặc định 800×1024, không bao giờ ném
// lỗi ra ngoài để app vẫn mở được.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// Cỡ cửa sổ mặc định khi không đọc được màn hình.
const Size coCuaSoMacDinh = Size(800, 1024);

/// Cỡ cửa sổ nhỏ nhất / lớn nhất cho phép.
const Size coCuaSoNhoNhat = Size(520, 480);
const Size coCuaSoLonNhat = Size(900, 1150);

/// Tính cỡ cửa sổ vừa màn hình: rộng = min(800, rộng màn − 16),
/// cao = min(1024, cao màn − 16), kẹp trong 520×480 đến 900×1150.
Size tinhCoCuaSo(double rongMan, double caoMan) {
  final rong = math.min(800.0, rongMan - 16.0).clamp(520.0, 900.0);
  final cao = math.min(1024.0, caoMan - 16.0).clamp(480.0, 1150.0);
  return Size(rong.toDouble(), cao.toDouble());
}

/// Đọc màn hình chính rồi trả về cỡ cửa sổ vừa màn hình.
/// Không đọc được thì trả về cỡ mặc định, không ném lỗi.
Future<Size> docCoCuaSoVuaManHinh() async {
  try {
    await windowManager.ensureInitialized();
    final manHinh = await screenRetriever.getPrimaryDisplay();
    final coMan = manHinh.visibleSize ?? manHinh.size;
    return tinhCoCuaSo(coMan.width, coMan.height);
  } catch (_) {
    return coCuaSoMacDinh;
  }
}

/// Hiện cửa sổ ở cỡ đã tính ngay khi sẵn sàng (không mở to rồi
/// mới co lại). Lỗi thì cố hiện cửa sổ ở cỡ mặc định để app không
/// bao giờ mở lên mà không thấy cửa sổ.
Future<void> hienCuaSoVuaManHinh(Size coCuaSo) async {
  try {
    windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: coCuaSo,
        center: true,
        minimumSize: coCuaSoNhoNhat,
        maximumSize: coCuaSoLonNhat,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  } catch (_) {
    try {
      await windowManager.show();
    } catch (_) {}
  }
}
