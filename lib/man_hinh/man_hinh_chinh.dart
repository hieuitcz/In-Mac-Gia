// Màn hình chính: danh sách sản phẩm, tìm nhanh theo tên hoặc mã vạch,
// tick chọn để in mác hàng loạt. Chạm vào sản phẩm để sửa.
import 'package:flutter/material.dart';

import '../dieu_khien.dart';
import '../giao_dien/chu_de.dart';
import '../mau_mac/chuoi_mac.dart';
import '../mo_hinh/san_pham.dart';
import '../tien_ich/dinh_dang.dart';
import 'cai_dat.dart';
import 'man_hinh_in.dart';
import 'sua_san_pham.dart';

class ManHinhChinh extends StatefulWidget {
  final DieuKhienApp dieuKhien;

  const ManHinhChinh({super.key, required this.dieuKhien});

  @override
  State<ManHinhChinh> createState() => _ManHinhChinhState();
}

class _ManHinhChinhState extends State<ManHinhChinh> {
  final _tuKhoa = TextEditingController();

  /// Mã sản phẩm đã tick để in.
  final _daChon = <String>{};

  @override
  void dispose() {
    _tuKhoa.dispose();
    super.dispose();
  }

  Future<void> _themSanPham() async {
    final moi = await moSuaSanPham(context);
    if (moi != null) await widget.dieuKhien.themSanPham(moi);
  }

  Future<void> _suaSanPham(SanPham sp) async {
    final moi = await moSuaSanPham(
      context,
      sanPhamCu: sp,
      onXoa: () async {
        await widget.dieuKhien.xoaSanPham(sp.id);
        _daChon.remove(sp.id);
      },
    );
    if (moi != null) await widget.dieuKhien.suaSanPham(moi);
  }

  void _moManHinhIn() {
    final chon = widget.dieuKhien.sanPham
        .where((sp) => _daChon.contains(sp.id))
        .toList();
    if (chon.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManHinhIn(dieuKhien: widget.dieuKhien, sanPham: chon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dieuKhien,
      builder: (context, _) {
        final dieuKhien = widget.dieuKhien;
        final danhSach = dieuKhien.timKiem(_tuKhoa.text);
        return Scaffold(
          backgroundColor: mauNenTrang,
          appBar: AppBar(
            title: const Text('In Mác Giá'),
            centerTitle: true,
            backgroundColor: mauNenTrang,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Cài đặt',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManHinhCaiDat(dieuKhien: dieuKhien),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _tuKhoa,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc quét mã vạch...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: dieuKhien.dongBo.daKetNoi
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dieuKhien.trangThaiDongBo,
                        style: const TextStyle(fontSize: 13, color: mauChuPhu),
                      ),
                    ),
                    Text(
                      '${danhSach.length} sản phẩm',
                      style: const TextStyle(fontSize: 13, color: mauChuPhu),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: dieuKhien.dangTai
                    ? const Center(child: CircularProgressIndicator())
                    : danhSach.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.label_outline,
                              size: 56,
                              color: mauChuPhu,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _tuKhoa.text.isEmpty
                                  ? 'Chưa có sản phẩm.\nBấm + để thêm sản phẩm đầu tiên.'
                                  : 'Không tìm thấy sản phẩm.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: mauChuPhu,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: danhSach.length,
                        itemBuilder: (context, i) {
                          final sp = danhSach[i];
                          final chon = _daChon.contains(sp.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TheIOS(
                              onTap: () => _suaSanPham(sp),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: chon,
                                    activeColor: mauChinh,
                                    onChanged: (giaTri) {
                                      setState(() {
                                        if (giaTri == true) {
                                          _daChon.add(sp.id);
                                        } else {
                                          _daChon.remove(sp.id);
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sp.tenSec,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (sp.dangGiamGia)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: mauNguyHiem,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'GIẢM GIÁ',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (sp.tenAnh.isNotEmpty)
                                          Text(
                                            sp.tenAnh,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: mauChuPhu,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _giaHienThi(sp),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (sp.maVach.isNotEmpty)
                                          Text(
                                            dinhDangSoMaVach(sp.maVach),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: mauChuPhu,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_daChon.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đã chọn ${_daChon.length} sản phẩm',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _moManHinhIn,
                        icon: const Icon(Icons.print),
                        label: const Text('In mác'),
                        style: FilledButton.styleFrom(
                          backgroundColor: mauChinh,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          floatingActionButton: _daChon.isEmpty
              ? FloatingActionButton(
                  onPressed: _themSanPham,
                  backgroundColor: mauChinh,
                  tooltip: 'Thêm sản phẩm',
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  /// Dòng giá hiện trong danh sách: giá giảm (kèm giá gốc) hoặc giá thường.
  String _giaHienThi(SanPham sp) {
    final cd = widget.dieuKhien.caiDat;
    if (sp.coGiaKhoang) return giaChinhText(sp, cd);
    if (sp.dangGiamGia && sp.gia != null) {
      return '${dinhDangGia(sp.giaGiam!)}  (gốc ${dinhDangGia(sp.gia!)})';
    }
    final gia = sp.giaChinh;
    return gia == null ? '' : dinhDangGia(gia);
  }
}
