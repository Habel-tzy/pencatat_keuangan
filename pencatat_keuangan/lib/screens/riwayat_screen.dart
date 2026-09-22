import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/pengeluaran_model.dart';
import 'home_screen.dart'; // Impor untuk memakai AppColors

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Pengeluaran> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    final data = await _dbHelper.getRiwayatPengeluaran();
    setState(() {
      _riwayat = data;
      _isLoading = false;
    });
  }

  String _formatRupiah(double angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  String _formatTanggal(String tanggalString) {
    final tgl = DateTime.tryParse(tanggalString);
    if (tgl == null) return tanggalString;
    return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(tgl);
  }

  // Fungsi memunculkan pop-up konfirmasi hapus
  void _konfirmasiHapus(Pengeluaran item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Riwayat?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Uang sebesar ${_formatRupiah(item.jumlah)} akan dikembalikan ke saldo utama Anda.', 
          style: const TextStyle(color: AppColors.textMuted)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              
              // Panggil fungsi hapus di DbHelper
              await _dbHelper.hapusPengeluaran(item.id!, item.jumlah);
              
              // Muat ulang daftar agar baris yang dihapus menghilang dari layar
              _muatRiwayat(); 
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Semua Riwayat',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _riwayat.isEmpty
              ? _buildKosong()
              : _buildDaftarRiwayat(),
    );
  }

  Widget _buildKosong() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.surfaceBorder),
          SizedBox(height: 16),
          Text('Belum ada riwayat pengeluaran', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDaftarRiwayat() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _riwayat.length,
      itemBuilder: (context, index) {
        final item = _riwayat[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.keterangan,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTanggal(item.tanggal),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Bagian Nominal dan Ikon Hapus
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '−${_formatRupiah(item.jumlah)}',
                    style: const TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  // Tombol Hapus (Tempat Sampah)
                  GestureDetector(
                    onTap: () => _konfirmasiHapus(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 14),
                          SizedBox(width: 4),
                          Text('Hapus', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}