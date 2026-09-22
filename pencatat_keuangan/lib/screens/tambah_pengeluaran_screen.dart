import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Dibutuhkan untuk NumberFormat

// Mengimpor helper, model, dan warna dari home_screen
import '../database/db_helper.dart';
import '../models/pengeluaran_model.dart';
import 'home_screen.dart'; 

class TambahPengeluaranScreen extends StatefulWidget {
  const TambahPengeluaranScreen({super.key});

  @override
  State<TambahPengeluaranScreen> createState() => _TambahPengeluaranScreenState();
}

class _TambahPengeluaranScreenState extends State<TambahPengeluaranScreen> {
  final DbHelper _dbHelper = DbHelper();
  
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  bool _isSaving = false;

  // Formatter kustom untuk memformat angka secara otomatis dengan titik (.)
  String _formatAngkaRibuan(String input) {
    if (input.isEmpty) return '';
    // Hilangkan semua karakter non-angka
    String cleanString = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return '';
    
    // Ubah ke angka double/int lalu format ke ribuan gaya Indonesia
    double parsed = double.tryParse(cleanString) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(parsed);
  }

  Future<void> _simpan() async {
    final keterangan = _keteranganController.text.trim();
    // Ambil angka murni tanpa titik untuk disimpan ke database
    final teksNominal = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(teksNominal);

    if (keterangan.isEmpty || nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal dan keterangan harus diisi dengan benar!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final pengeluaranBaru = Pengeluaran(
      keterangan: keterangan,
      jumlah: nominal,
      tanggal: DateTime.now().toString(),
    );

    await _dbHelper.insertPengeluaran(pengeluaranBaru);

    if (mounted) {
      Navigator.pop(context, true);
    }
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
          'Tambah Pengeluaran',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Input Nominal dengan Pemisah Titik Otomatis ---
              const Text(
                'NOMINAL (RP)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                // Logika otomatis memasukkan titik saat diketik
                onChanged: (string) {
                  if (string.isEmpty) return;
                  String formatted = _formatAngkaRibuan(string);
                  _nominalController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                },
                style: const TextStyle(
                  color: AppColors.textPrimary, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    color: AppColors.accent, 
                    fontSize: 24, 
                    fontWeight: FontWeight.bold
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Input Keterangan ---
              const Text(
                'KETERANGAN',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _keteranganController,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Misal: Makan siang',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),

              // --- Tombol Simpan ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.accentText,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}