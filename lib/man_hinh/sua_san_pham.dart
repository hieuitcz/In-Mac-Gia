// Sheet thêm/sửa sản phẩm, kiểu iOS: trượt lên từ dưới, bo tròn.
// Các mục bắt buộc: tên tiếng Séc và giá (1 mức hoặc khoảng giá).
// Mã vạch nhập 12 số thì tự thêm số kiểm tra thành 13 số.
import 'package:flutter/material.dart';

import '../dieu_khien.dart';
import '../giao_dien/chu_de.dart';
import '../mo_hinh/san_pham.dart';
import '../tien_ich/dinh_dang.dart';

/// Mở sheet sửa sản phẩm. Trả về sản phẩm đã lưu, null khi hủy.
/// [onXoa] được gọi khi người dùng xác nhận xóa (chỉ khi sửa).
Future<SanPham?> moSuaSanPham(
  BuildContext context, {
  SanPham? sanPhamCu,
  Future<void> Function()? onXoa,
}) {
  return showModalBottomSheet<SanPham>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _FormSanPham(sanPhamCu: sanPhamCu, onXoa: onXoa),
  );
}

class _FormSanPham extends StatefulWidget {
  final SanPham? sanPhamCu;
  final Future<void> Function()? onXoa;

  const _FormSanPham({this.sanPhamCu, this.onXoa});

  @override
  State<_FormSanPham> createState() => _FormSanPhamState();
}

class _FormSanPhamState extends State<_FormSanPham> {
  late final TextEditingController _tenSec;
  late final TextEditingController _tenAnh;
  late final TextEditingController _maVach;
  late final TextEditingController _gia;
  late final TextEditingController _giaTu;
  late final TextEditingController _giaDen;
  late final TextEditingController _giaGiam;
  late final TextEditingController _khoiLuong;
  late final TextEditingController _dungTich;
  late final TextEditingController _thue;

  bool _laGiaKhoang = false;
  DateTime? _hanGiamGia;
  String _donVi = 'ks';
  String? _loi;

  static const _donViChoPhep = [
    'ks',
    'kg',
    'g',
    'l',
    'ml',
    'pc',
    'balení',
    'krabice',
  ];

  @override
  void initState() {
    super.initState();
    final cu = widget.sanPhamCu;
    _tenSec = TextEditingController(text: cu?.tenSec ?? '');
    _tenAnh = TextEditingController(text: cu?.tenAnh ?? '');
    _maVach = TextEditingController(text: cu?.maVach ?? '');
    _gia = TextEditingController(text: _soThanhChu(cu?.gia));
    _giaTu = TextEditingController(text: _soThanhChu(cu?.giaTu));
    _giaDen = TextEditingController(text: _soThanhChu(cu?.giaDen));
    _giaGiam = TextEditingController(text: _soThanhChu(cu?.giaGiam));
    _khoiLuong = TextEditingController(text: _soThanhChu(cu?.khoiLuongGam));
    _dungTich = TextEditingController(text: _soThanhChu(cu?.dungTichMl));
    _thue = TextEditingController(
      text: cu == null ? '12' : _soThanhChu(cu.tyLeThue),
    );
    _laGiaKhoang = cu?.coGiaKhoang ?? false;
    _hanGiamGia = cu?.hanGiamGia;
    _donVi = cu?.donVi ?? 'ks';
    if (!_donViChoPhep.contains(_donVi)) _donVi = 'ks';
  }

  static String _soThanhChu(double? so) {
    if (so == null) return '';
    if (so == so.truncateToDouble()) return so.toInt().toString();
    return so.toString().replaceAll('.', ',');
  }

  /// Đọc số người dùng nhập, chấp nhận cả dấu phẩy và dấu chấm.
  static double? _docSo(String chuoi) {
    final sach = chuoi.trim().replaceAll(',', '.');
    if (sach.isEmpty) return null;
    return double.tryParse(sach);
  }

  @override
  void dispose() {
    _tenSec.dispose();
    _tenAnh.dispose();
    _maVach.dispose();
    _gia.dispose();
    _giaTu.dispose();
    _giaDen.dispose();
    _giaGiam.dispose();
    _khoiLuong.dispose();
    _dungTich.dispose();
    _thue.dispose();
    super.dispose();
  }

  void _baoLoi(String loi) {
    setState(() => _loi = loi);
  }

  void _luu() {
    final tenSec = _tenSec.text.trim();
    if (tenSec.isEmpty) {
      _baoLoi('Nhập tên tiếng Séc của sản phẩm.');
      return;
    }
    final maVach = chuanHoaMaVach(_maVach.text);
    if (maVach == null) {
      _baoLoi('Mã vạch phải là 12 hoặc 13 chữ số, đúng số kiểm tra.');
      return;
    }
    double? gia;
    double? giaTu;
    double? giaDen;
    if (_laGiaKhoang) {
      giaTu = _docSo(_giaTu.text);
      giaDen = _docSo(_giaDen.text);
      if (giaTu == null || giaDen == null || giaTu <= 0 || giaDen <= giaTu) {
        _baoLoi('Nhập giá từ và giá đến, giá đến phải lớn hơn giá từ.');
        return;
      }
    } else {
      gia = _docSo(_gia.text);
      if (gia == null || gia <= 0) {
        _baoLoi('Nhập giá bán (Kč), lớn hơn 0.');
        return;
      }
    }
    final giaGiam = _docSo(_giaGiam.text);
    if (_giaGiam.text.trim().isNotEmpty && (giaGiam == null || giaGiam <= 0)) {
      _baoLoi('Giá giảm phải là số lớn hơn 0.');
      return;
    }
    final thue = _docSo(_thue.text) ?? 12;
    final cu = widget.sanPhamCu;
    Navigator.of(context).pop(
      SanPham(
        id: cu?.id ?? DieuKhienApp.taoIdMoi(),
        tenSec: tenSec,
        tenAnh: _tenAnh.text.trim(),
        maVach: maVach,
        gia: gia,
        giaTu: giaTu,
        giaDen: giaDen,
        giaGiam: giaGiam,
        hanGiamGia: giaGiam == null ? null : _hanGiamGia,
        donVi: _donVi,
        khoiLuongGam: _docSo(_khoiLuong.text),
        dungTichMl: _docSo(_dungTich.text),
        tyLeThue: thue,
        capNhat: DateTime.now(),
      ),
    );
  }

  Future<void> _chonNgayHetHan() async {
    final homNay = DateTime.now();
    final chon = await showDatePicker(
      context: context,
      initialDate: _hanGiamGia ?? homNay,
      firstDate: homNay,
      lastDate: DateTime(homNay.year + 2),
      helpText: 'Ngày hết hạn giảm giá',
    );
    if (chon != null) setState(() => _hanGiamGia = chon);
  }

  Future<void> _xoa() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Xóa "${_tenSec.text.trim()}" khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: mauNguyHiem)),
          ),
        ],
      ),
    );
    if (dongY == true && widget.onXoa != null) {
      await widget.onXoa!();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dangSua = widget.sanPhamCu != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dangSua ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TruongNhap(
              nhan: 'Tên tiếng Séc *',
              dieuKhien: _tenSec,
              goiY: 'Ví dụ: Eidam 45% 500 g',
            ),
            const SizedBox(height: 12),
            TruongNhap(
              nhan: 'Tên tiếng Anh',
              dieuKhien: _tenAnh,
              goiY: 'Ví dụ: Eidam cheese 45% 500 g',
            ),
            const SizedBox(height: 12),
            TruongNhap(
              nhan: 'Mã vạch EAN-13',
              dieuKhien: _maVach,
              goiY: '12 hoặc 13 chữ số, để trống nếu không có',
              kieuBanPhim: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Bán theo khoảng giá'),
              subtitle: const Text('Ví dụ: từ 70 đến 100 Kč'),
              value: _laGiaKhoang,
              activeThumbColor: mauChinh,
              contentPadding: EdgeInsets.zero,
              onChanged: (giaTri) => setState(() => _laGiaKhoang = giaTri),
            ),
            if (_laGiaKhoang) ...[
              Row(
                children: [
                  Expanded(
                    child: TruongNhap(
                      nhan: 'Giá từ (Kč) *',
                      dieuKhien: _giaTu,
                      goiY: '70',
                      kieuBanPhim: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TruongNhap(
                      nhan: 'Giá đến (Kč) *',
                      dieuKhien: _giaDen,
                      goiY: '100',
                      kieuBanPhim: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              TruongNhap(
                nhan: 'Giá bán (Kč) *',
                dieuKhien: _gia,
                goiY: '99,90',
                kieuBanPhim: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TruongNhap(
                    nhan: 'Giá giảm (Kč)',
                    dieuKhien: _giaGiam,
                    goiY: 'Để trống nếu không giảm',
                    kieuBanPhim: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hết hạn giảm giá',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _chonNgayHetHan,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _hanGiamGia == null
                                ? 'Chọn ngày'
                                : dinhDangNgaySec(_hanGiamGia!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Đơn vị',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _donVi,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: _donViChoPhep
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (giaTri) {
                if (giaTri != null) setState(() => _donVi = giaTri);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TruongNhap(
                    nhan: 'Khối lượng (g)',
                    dieuKhien: _khoiLuong,
                    goiY: '500 — để tính đơn giá',
                    kieuBanPhim: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TruongNhap(
                    nhan: 'Dung tích (ml)',
                    dieuKhien: _dungTich,
                    goiY: '250',
                    kieuBanPhim: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TruongNhap(
              nhan: 'Thuế VAT (%)',
              dieuKhien: _thue,
              goiY: '12',
              kieuBanPhim: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_loi != null) ...[
              const SizedBox(height: 12),
              Text(
                _loi!,
                style: const TextStyle(color: mauNguyHiem, fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            NutChinh('Lưu', onTap: _luu),
            if (dangSua) ...[
              const SizedBox(height: 12),
              NutChinh('Xóa sản phẩm', nguyHiem: true, onTap: _xoa),
            ],
          ],
        ),
      ),
    );
  }
}
