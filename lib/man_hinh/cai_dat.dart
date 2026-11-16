// Màn hình Cài đặt: khổ mác, máy in mặc định, trạng thái đồng bộ
// cloud, nhật ký khởi động, giới thiệu app.
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../dieu_khien.dart';
import '../firebase_options.dart';
import '../giao_dien/chu_de.dart';
import '../main.dart';
import '../mo_hinh/cai_dat.dart';
import '../tien_ich/may_in.dart';

class ManHinhCaiDat extends StatefulWidget {
  final DieuKhienApp dieuKhien;

  const ManHinhCaiDat({super.key, required this.dieuKhien});

  @override
  State<ManHinhCaiDat> createState() => _ManHinhCaiDatState();
}

class _ManHinhCaiDatState extends State<ManHinhCaiDat> {
  late final TextEditingController _rong;
  String? _loi;

  /// Danh sách máy in đã tải (null khi chưa bấm tìm).
  List<Printer>? _mayIn;

  /// Đang tải danh sách máy in.
  bool _dangTaiMayIn = false;

  /// Lỗi khi tải danh sách máy in.
  String? _loiMayIn;

  /// Đường dẫn file nhật ký khởi động.
  String? _duongDanNhatKy;

  @override
  void initState() {
    super.initState();
    final cd = widget.dieuKhien.caiDat;
    _rong = TextEditingController(text: _soThanhChu(cd.rongMm));
    widget.dieuKhien.kho.duongDanNhatKy.then((duongDan) {
      if (mounted) setState(() => _duongDanNhatKy = duongDan);
    });
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

  /// Tải danh sách máy in của máy tính để chọn máy in mặc định.
  Future<void> _taiDanhSachMayIn() async {
    setState(() {
      _dangTaiMayIn = true;
      _loiMayIn = null;
    });
    try {
      final danhSach = await Printing.listPrinters();
      if (mounted) {
        setState(() {
          _mayIn = danhSach;
          if (danhSach.isEmpty) _loiMayIn = 'Không tìm thấy máy in nào.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loiMayIn = 'Không tải được máy in: $e');
    } finally {
      if (mounted) setState(() => _dangTaiMayIn = false);
    }
  }

  /// Lưu máy in đã chọn làm mặc định (lần sau in thẳng, khỏi chọn).
  Future<void> _chonMayIn(Printer mayIn) async {
    await widget.dieuKhien.capNhatCaiDat(
      widget.dieuKhien.caiDat.copyWith(
        mayInMacDinh: mayIn.url,
        tenMayInMacDinh: mayIn.name,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu máy in mặc định: ${mayIn.name}.')),
      );
    }
  }

  /// Xóa máy in mặc định (lần sau in lại hiện hộp thoại chọn máy in).
  Future<void> _xoaMayIn() async {
    await widget.dieuKhien.capNhatCaiDat(
      widget.dieuKhien.caiDat.copyWith(xoaMayInMacDinh: true),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa máy in mặc định.')));
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
              const TieuDeMuc('Font chữ'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Font cho chữ trên mác in. Mẫu Cổ điển và Nhẹ nhàng '
                      'thiết kế serif sẵn nên luôn giữ serif.',
                      style: TextStyle(fontSize: 14, color: mauChuPhu),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<FontMac>(
                      value: dieuKhien.caiDat.fontChu,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: FontMac.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.tenHienThi),
                            ),
                          )
                          .toList(),
                      onChanged: (f) async {
                        if (f != null) {
                          await widget.dieuKhien.capNhatCaiDat(
                            dieuKhien.caiDat.copyWith(fontChu: f),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const TieuDeMuc('Máy in mặc định'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đặt máy in 1 lần, lần sau bấm in là in thẳng, '
                      'không hiện hộp thoại chọn máy in mỗi lần. Cỡ '
                      'giấy/mác mặc định là chiều rộng mác ở mục "Khổ '
                      'mác" bên trên.',
                      style: TextStyle(fontSize: 14, color: mauChuPhu),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.print),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dieuKhien.caiDat.tenMayInMacDinh ??
                                'Chưa chọn máy in.',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    if (_loiMayIn != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _loiMayIn!,
                        style: const TextStyle(
                          color: mauNguyHiem,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_dangTaiMayIn)
                      const Center(child: CircularProgressIndicator())
                    else if (_mayIn == null)
                      NutChinh('Tìm máy in', onTap: _taiDanhSachMayIn)
                    else ...[
                      DropdownButton<Printer>(
                        value: timMayInTrongDanhSach(
                          _mayIn!,
                          dieuKhien.caiDat.mayInMacDinh,
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Chọn máy in'),
                        items: _mayIn!
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.name),
                              ),
                            )
                            .toList(),
                        onChanged: (m) {
                          if (m != null) _chonMayIn(m);
                        },
                      ),
                      if (dieuKhien.caiDat.mayInMacDinh != null) ...[
                        const SizedBox(height: 8),
                        NutChinh('Xóa máy in mặc định', onTap: _xoaMayIn),
                      ],
                    ],
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
              const TieuDeMuc('Nhật ký khởi động'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nếu app mở không lên hoặc tự tắt, gửi file nhật '
                      'ký này cho người làm app để xem lỗi.',
                      style: TextStyle(fontSize: 14, color: mauChuPhu),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _duongDanNhatKy ?? 'Đang tìm đường dẫn...',
                      style: const TextStyle(fontSize: 13),
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
