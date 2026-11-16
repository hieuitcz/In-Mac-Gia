// Nạp font Liberation đóng gói trong app cho test widget, để đo chữ
// đúng như app thật. Không nạp thì Flutter dùng font mặc định của
// test, mỗi ký tự rộng 1em nên chữ đo ra rộng hơn thật rất nhiều
// (giá "100 – 250 Kč / ks" đo ra 279px thay vì ~167px) và Row bị
// tràn oan. Gọi 1 lần trong setUpAll của file test cần đo chữ.
import 'package:flutter/services.dart';

Future<void> napFontMac() async {
  Future<void> nap(String family, List<String> duongDan) async {
    final loader = FontLoader(family);
    for (final duong in duongDan) {
      loader.addFont(rootBundle.load(duong));
    }
    await loader.load();
  }

  await nap('LiberationSans', [
    'assets/fonts/LiberationSans-Regular.ttf',
    'assets/fonts/LiberationSans-Bold.ttf',
    'assets/fonts/LiberationSans-Italic.ttf',
  ]);
  await nap('LiberationSerif', [
    'assets/fonts/LiberationSerif-Regular.ttf',
    'assets/fonts/LiberationSerif-Bold.ttf',
    'assets/fonts/LiberationSerif-Italic.ttf',
  ]);
}
