// Màn hình Cài đặt: khổ mác, trạng thái đồng bộ cloud, giới thiệu app.
import 'package:flutter/material.dart';

import '../dieu_khien.dart';
import '../firebase_options.dart';
import '../giao_dien/chu_de.dart';
import '../main.dart';

class ManHinhCaiDat extends StatefulWidget {
  final DieuKhienApp dieuKhien;

  const ManHinhCaiDat({super.key, required this.dieuKhien});

  @override
  State<ManHinhCaiDat> createState() => _ManHinhCaiDatState();
}

class _ManHinhCaiDatState extends State<ManHinhCaiDat> {
  late final TextEditingController _rong;
  String? _loi;

  @override
  void initState() {
    super.initState();
    final cd = widget.dieuKhien.caiDat;
    _rong = TextEditingController(text: _soThanhChu(cd.rongMm));
  }

  static String _soThanhChu(double so) {
    if (so == so.truncateToDouble()) return so.toInt().toString();
    return so.toString().replaceAll('.', ',');
  }

  static double? _docSo(String chuoi) {
    final sach = chuoi.trim().replaceAll(',', '.');
    return double.tryParse(sach);
  }

  @override
  void dispose() {
    _rong.dispose();
    super.dispose();
  }

  Future<void> _luuKhoMac() async {
    final rong = _docSo(_rong.text);
    if (rong == null || rong <= 0) {
      setState(() => _loi = 'Nhập chiều rộng mác (mm), lớn hơn 0.');
      return;
    }
    setState(() => _loi = null);
    await widget.dieuKhien.capNhatCaiDat(
      widget.dieuKhien.caiDat.copyWith(rongMm: rong),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu khổ mác.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dieuKhien,
      builder: (context, _) {
        final dieuKhien = widget.dieuKhien;
        return Scaffold(
          backgroundColor: mauNenTrang,
          appBar: AppBar(
            title: const Text('Cài đặt'),
            centerTitle: true,
            backgroundColor: mauNenTrang,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const TieuDeMuc('Khổ mác'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'In dọc, chiều rộng mác đúng bằng cuộn giấy nhiệt '
                      'đang dùng (mặc định 80 mm). Chiều dài mác tự theo '
                      'nội dung, máy in tự cắt nên không cần nhập.',
                      style: TextStyle(fontSize: 14, color: mauChuPhu),
                    ),
                    const SizedBox(height: 12),
                    TruongNhap(
                      nhan: 'Rộng (mm)',
                      dieuKhien: _rong,
                      kieuBanPhim: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _loi!,
                        style: const TextStyle(
                          color: mauNguyHiem,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    NutChinh('Lưu khổ mác', onTap: _luuKhoMac),
                  ],
                ),
              ),
              const TieuDeMuc('Đồng bộ cloud'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_done,
                          color: dieuKhien.dongBo.daKetNoi
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dieuKhien.trangThaiDongBo,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Danh sách sản phẩm dùng chung 2 cửa hàng qua '
                      'Firebase project gio-lam. Mất mạng vẫn dùng '
                      'bình thường, có mạng app tự đồng bộ.',
                      style: TextStyle(fontSize: 14, color: mauChuPhu),
                    ),
                    if (!DefaultFirebaseOptions.coCauHinh) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa có mã API Firebase nên đồng bộ cloud đang '
                        'tắt. Dán apiKey vào lib/firebase_options.dart '
                        'rồi build lại (xem hướng dẫn trong README).',
                        style: TextStyle(fontSize: 14, color: mauNguyHiem),
                      ),
                    ],
                    const SizedBox(height: 12),
                    NutChinh(
                      'Đồng bộ ngay',
                      onTap: () => dieuKhien.dongBoNgay(),
                    ),
                  ],
                ),
              ),
              const TieuDeMuc('Giới thiệu'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'In Mác Giá',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phiên bản $phienBanApp',
                      style: const TextStyle(fontSize: 14, color: mauChuPhu),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'App in mác giá cho cửa hàng potraviny: nhập sản '
                      'phẩm 1 lần, lưu lại dùng tiếp, in mác dọc rộng '
                      '80 mm bằng máy in nhãn nhiệt, nhiều mẫu để chọn.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Font chữ Liberation (SIL Open Font License).',
                      style: TextStyle(fontSize: 13, color: mauChuPhu),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
