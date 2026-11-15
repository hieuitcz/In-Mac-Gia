// Cấu hình Firebase cho app In Mác Giá — dùng chung project "gio-lam"
// với app chấm công Gio-Lam (anh chủ tạo trên Firebase Console).
// Các giá trị appId, projectId... dưới đây lấy từ file
// firebase_options.dart của repo Gio-Lam-Flutter.
//
// QUAN TRỌNG — mã API (apiKey) đang để trống:
// Lúc copy file từ repo Gio-Lam, hệ thống đã che mất giá trị apiKey
// nên không lấy được. Muốn bật đồng bộ cloud thì dán mã apiKey vào
// chỗ trống dưới đây. Lấy mã ở Firebase Console > Cài đặt project
// (Project settings) > mục "Your apps" > app web "gio-lam-windows"
// > trường apiKey. (apiKey là key client công khai theo chuẩn
// Firebase — bảo mật thật nằm ở Firestore Rules + Auth.)
// Chưa có apiKey thì app vẫn chạy bình thường, chỉ lưu trên máy.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get windows => const FirebaseOptions(
    // Dán mã apiKey vào đây để bật đồng bộ cloud.
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
