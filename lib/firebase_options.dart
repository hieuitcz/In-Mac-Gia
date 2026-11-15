// Cấu hình Firebase cho app In Mác Giá — dùng chung project "gio-lam"
// với app chấm công Gio-Lam (anh chủ tạo trên Firebase Console).
// Các giá trị appId, projectId... dưới đây lấy từ file
// firebase_options.dart của repo Gio-Lam-Flutter.
//
// Mã API (apiKey) đã điền đầy đủ nên đồng bộ cloud đang bật.
// (apiKey là key client công khai theo chuẩn Firebase — bảo mật thật
// nằm ở Firestore Rules + Auth.)
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get windows => const FirebaseOptions(
    apiKey: 'AIzaSyCuGZlsiHnnJwaR7t9SaISRnEsMvCcrqKY',
    appId: '1:1039514283001:web:016265e83e30d0940e6b28',
    messagingSenderId: '1039514283001',
    projectId: 'gio-lam',
    authDomain: 'gio-lam.firebaseapp.com',
    storageBucket: 'gio-lam.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform => windows;

  /// Có đủ cấu hình để kết nối Firebase không.
  static bool get coCauHinh => windows.apiKey.isNotEmpty;
}
