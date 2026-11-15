// Kiểu giao diện kiểu iOS, giống app chấm công Gio-Lam:
// nền xám nhạt, thẻ trắng bo tròn, nút xanh iOS.
import 'package:flutter/material.dart';

/// Màu nền trang kiểu iOS.
const mauNenTrang = Color(0xFFF2F2F7);

/// Màu chính (xanh iOS) cho nút và điểm nhấn.
const mauChinh = Color(0xFF007AFF);

/// Màu đỏ cho nút xóa.
const mauNguyHiem = Color(0xFFFF3B30);

/// Màu chữ phụ.
const mauChuPhu = Color(0xFF8E8E93);

/// Thẻ trắng bo tròn 20, dùng cho danh sách và khối cài đặt.
class TheIOS extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? dem;
  final VoidCallback? onTap;

  const TheIOS({super.key, required this.child, this.dem, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: dem ?? const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

/// Tiêu đề mục nhỏ, chữ hoa, màu xám, kiểu iOS.
class TieuDeMuc extends StatelessWidget {
  final String tieuDe;

  const TieuDeMuc(this.tieuDe, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        tieuDe.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: mauChuPhu,
        ),
      ),
    );
  }
}

/// Nút chính màu xanh iOS, bo tròn.
class NutChinh extends StatelessWidget {
  final String nhan;
  final VoidCallback? onTap;
  final bool nguyHiem;

  const NutChinh(this.nhan, {super.key, this.onTap, this.nguyHiem = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: nguyHiem ? mauNguyHiem : mauChinh,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(nhan, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

/// 1 hàng công tắc: tiêu đề + mô tả + công tắc bật/tắt.
class HangCongTac extends StatelessWidget {
  final String tieuDe;
  final String? moTa;
  final bool giaTri;
  final ValueChanged<bool> onChanged;

  const HangCongTac({
    super.key,
    required this.tieuDe,
    this.moTa,
    required this.giaTri,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(tieuDe, style: const TextStyle(fontSize: 16)),
      subtitle: moTa == null
          ? null
          : Text(moTa!, style: const TextStyle(fontSize: 13)),
      value: giaTri,
      activeThumbColor: mauChinh,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }
}

/// Ô nhập chữ kiểu iOS: nhãn trên, ô nhập dưới, bo tròn.
class TruongNhap extends StatelessWidget {
  final String nhan;
  final TextEditingController dieuKhien;
  final String? goiY;
  final TextInputType? kieuBanPhim;
  final int? toiDaDong;

  const TruongNhap({
    super.key,
    required this.nhan,
    required this.dieuKhien,
    this.goiY,
    this.kieuBanPhim,
    this.toiDaDong = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nhan,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: dieuKhien,
          keyboardType: kieuBanPhim,
          maxLines: toiDaDong,
          decoration: InputDecoration(
            hintText: goiY,
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
