// Màn hình in mác: chọn mẫu template, chỉnh cỡ chữ, bật/tắt các
// công tắc như trên phần mềm cũ, xem trước đúng khổ thật rồi mới in.
// In hàng loạt: tick nhiều sản phẩm ở màn hình chính, nhập số lượng
// từng loại rồi in 1 lần.
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../dieu_khien.dart';
import '../giao_dien/chu_de.dart';
import '../mau_mac/mau_mac.dart';
import '../mau_mac/ve_mac_pdf.dart';
import '../mau_mac/xem_truoc_mac.dart';
import '../mo_hinh/cai_dat.dart';
import '../mo_hinh/san_pham.dart';

class ManHinhIn extends StatefulWidget {
  final DieuKhienApp dieuKhien;
  final List<SanPham> sanPham;

  const ManHinhIn({super.key, required this.dieuKhien, required this.sanPham});

  @override
  State<ManHinhIn> createState() => _ManHinhInState();
}

class _ManHinhInState extends State<ManHinhIn> {
  /// Số lượng in của từng sản phẩm (mặc định 1).
  late final Map<String, int> _soLuong;

  /// Tỉ lệ cỡ chữ đang kéo trên thanh trượt (chưa thả tay thì chưa lưu).
  double? _tiLeDangKeo;

  bool _dangIn = false;

  @override
  void initState() {
    super.initState();
    _soLuong = {for (final sp in widget.sanPham) sp.id: 1};
  }

  CaiDat get _caiDat => widget.dieuKhien.caiDat;

  int get _tongSoMac => _soLuong.values.fold(0, (a, b) => a + b);

  /// Mẫu thực tế đang xem trước (sau khi áp công tắc "In riêng mã vạch"
  /// và "In mác giá đang giảm giá"). Thanh trượt cỡ chữ chỉnh mẫu này.
  MauMac get _mauDangXem {
    if (widget.sanPham.isEmpty) return _caiDat.mauMac;
    return mauThucTe(widget.sanPham.first, _caiDat);
  }

  /// Cài đặt dùng để xem trước: khi đang kéo thanh trượt thì dùng
  /// tỉ lệ đang kéo, thả tay ra mới lưu xuống file.
  CaiDat get _caiDatXemTruoc {
    if (_tiLeDangKeo == null) return _caiDat;
    return _caiDat.voiTiLeChu(_mauDangXem, _tiLeDangKeo!);
  }

  Future<void> _doiCaiDat(CaiDat moi) async {
    await widget.dieuKhien.capNhatCaiDat(moi);
  }

  Future<void> _inMac() async {
    if (_dangIn) return;
    setState(() => _dangIn = true);
    try {
      final mucIn = widget.sanPham
          .map((sp) => (sanPham: sp, soLuong: _soLuong[sp.id] ?? 1))
          .toList();
      final taiLieu = await taoTaiLieuMac(mucIn: mucIn, caiDat: _caiDat);
      final daIn = await Printing.layoutPdf(
        onLayout: (_) async => taiLieu.save(),
        format: khoGiayMac(_caiDat),
        name: 'Mac gia',
      );
      if (mounted && daIn) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gửi lệnh in.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không in được: $e')));
      }
    } finally {
      if (mounted) setState(() => _dangIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dieuKhien,
      builder: (context, _) {
        final cd = _caiDat;
        final mau = _mauDangXem;
        final tiLe = _tiLeDangKeo ?? cd.tiLeChuCua(mau);
        final spDau = widget.sanPham.isNotEmpty ? widget.sanPham.first : null;
        return Scaffold(
          backgroundColor: mauNenTrang,
          appBar: AppBar(
            title: const Text('In mác'),
            centerTitle: true,
            backgroundColor: mauNenTrang,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const TieuDeMuc('Mẫu in'),
              TheIOS(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<MauMac>(
                      value: cd.mauMac,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: MauMac.values
                          .map(
                            (m) =>
                                DropdownMenuItem(value: m, child: Text(m.ten)),
                          )
                          .toList(),
                      onChanged: (m) {
                        if (m != null) _doiCaiDat(cd.copyWith(mauMac: m));
                      },
                    ),
                    Text(
                      cd.mauMac.moTa,
                      style: const TextStyle(fontSize: 13, color: mauChuPhu),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Cỡ chữ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          tooltip: 'Thu nhỏ chữ',
                          onPressed: () {
                            final moi = (tiLe - 0.05).clamp(0.7, 1.3);
                            _doiCaiDat(cd.voiTiLeChu(mau, moi));
                          },
                        ),
                        Text(
                          '${(tiLe * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Phóng to chữ',
                          onPressed: () {
                            final moi = (tiLe + 0.05).clamp(0.7, 1.3);
                            _doiCaiDat(cd.voiTiLeChu(mau, moi));
                          },
                        ),
                        TextButton(
                          onPressed: () => _doiCaiDat(cd.voiTiLeChu(mau, 1.0)),
                          child: const Text('100%'),
                        ),
                      ],
                    ),
                    Slider(
                      value: tiLe,
                      min: 0.7,
                      max: 1.3,
                      divisions: 12,
                      label: '${(tiLe * 100).round()}%',
                      activeColor: mauChinh,
                      onChanged: (giaTri) {
                        // Kéo tới đâu, xem trước đổi tới đó.
                        setState(() => _tiLeDangKeo = giaTri);
                      },
                      onChangeEnd: (giaTri) {
                        // Thả tay ra mới lưu xuống file để lần sau khỏi chỉnh.
                        _tiLeDangKeo = null;
                        _doiCaiDat(cd.voiTiLeChu(mau, giaTri));
                      },
                    ),
                    Text(
                      'Chỉnh cho mẫu "${mau.ten}". Tên hoặc giá dài thì '
                      'thu nhỏ lại cho vừa 1 dòng. Cỡ chữ lưu theo từng mẫu.',
                      style: const TextStyle(fontSize: 13, color: mauChuPhu),
                    ),
                  ],
                ),
              ),
              const TieuDeMuc('Xem trước'),
              TheIOS(
                child: Column(
                  children: [
                    if (spDau != null)
                      Center(
                        child: XemTruocMac(
                          sanPham: spDau,
                          mau: cd.mauMac,
                          caiDat: _caiDatXemTruoc,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'In dọc — rộng ${cd.rongMm.toInt()} mm, dài tự theo '
                      'nội dung, máy in tự cắt. Đổi rộng trong Cài đặt.',
                      style: const TextStyle(fontSize: 13, color: mauChuPhu),
                    ),
                  ],
                ),
              ),
              const TieuDeMuc('Lựa chọn'),
              TheIOS(
                child: Column(
                  children: [
                    HangCongTac(
                      tieuDe: 'In chữ đậm',
                      giaTri: cd.inChuDam,
                      onChanged: (v) => _doiCaiDat(cd.copyWith(inChuDam: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In chữ hoa',
                      giaTri: cd.inChuHoa,
                      onChanged: (v) => _doiCaiDat(cd.copyWith(inChuHoa: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In cả mã vạch',
                      giaTri: cd.inMaVach,
                      onChanged: (v) => _doiCaiDat(cd.copyWith(inMaVach: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In riêng mã vạch',
                      moTa: 'Bỏ qua mẫu đã chọn, chỉ in mã vạch.',
                      giaTri: cd.inRiengMaVach,
                      onChanged: (v) =>
                          _doiCaiDat(cd.copyWith(inRiengMaVach: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In mác giá đang giảm giá',
                      moTa: 'Sản phẩm giảm giá thì in theo mẫu giảm giá.',
                      giaTri: cd.inMacGiamGia,
                      onChanged: (v) =>
                          _doiCaiDat(cd.copyWith(inMacGiamGia: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In ngày hết hạn giảm giá',
                      giaTri: cd.inNgayHetHan,
                      onChanged: (v) =>
                          _doiCaiDat(cd.copyWith(inNgayHetHan: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In giá bình thường trên mác giá giảm giá',
                      moTa: 'Hiện giá gốc gạch ngang cùng giá giảm.',
                      giaTri: cd.inGiaThuongTrenMacGiam,
                      onChanged: (v) =>
                          _doiCaiDat(cd.copyWith(inGiaThuongTrenMacGiam: v)),
                    ),
                    HangCongTac(
                      tieuDe: 'In giá không thuế',
                      moTa: 'Giá in ra đã trừ thuế VAT.',
                      giaTri: cd.inGiaKhongThue,
                      onChanged: (v) =>
                          _doiCaiDat(cd.copyWith(inGiaKhongThue: v)),
                    ),
                  ],
                ),
              ),
              const TieuDeMuc('Sản phẩm sẽ in'),
              ...widget.sanPham.map((sp) {
                final soLuong = _soLuong[sp.id] ?? 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TheIOS(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sp.tenSec,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (sp.tenAnh.isNotEmpty)
                                Text(
                                  sp.tenAnh,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: mauChuPhu,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: soLuong > 1
                              ? () => setState(
                                  () => _soLuong[sp.id] = soLuong - 1,
                                )
                              : null,
                        ),
                        Text(
                          '$soLuong',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              setState(() => _soLuong[sp.id] = soLuong + 1),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              NutChinh(
                _dangIn ? 'Đang in...' : 'In $_tongSoMac mác',
                onTap: _dangIn ? null : _inMac,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn máy in nhãn nhiệt trong hộp thoại in hiện ra.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: mauChuPhu),
              ),
            ],
          ),
        );
      },
    );
  }
}
