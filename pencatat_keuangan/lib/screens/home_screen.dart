import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Mengimpor halaman Riwayat
import 'riwayat_screen.dart';

// Mengimpor helper dan model dari file lain yang sudah dibuat sebelumnya
import '../database/db_helper.dart';
import '../models/saldo_model.dart';
import '../models/pengeluaran_model.dart';

// Impor halaman form tambah pengeluaran
import 'tambah_pengeluaran_screen.dart'; 

// ============================================================
// KONSTANTA TEMA (Warna & Style terpusat di satu tempat)
// Kalau mau ganti warna, cukup ubah di sini saja.
// ============================================================
class AppColors {
  // Warna tidak boleh dibuat instance-nya — cukup pakai langsung
  AppColors._();

  static const Color background   = Color(0xFF0F1923); // Navy gelap — latar utama
  static const Color surface      = Color(0xFF122030); // Navy terang — latar card
  static const Color surfaceBorder= Color(0xFF1A2F44); // Garis tepi card
  static const Color accent       = Color(0xFF4ADE80); // Hijau mint — aksi utama
  static const Color accentText   = Color(0xFF0A1610); // Teks di atas tombol hijau
  static const Color textPrimary  = Color(0xFFE8F4F8); // Teks putih kebiruan
  static const Color textSecondary= Color(0xFF7ABFDF); // Teks muted biru
  static const Color textMuted    = Color(0xFF2E5470); // Teks sangat redup
  static const Color danger       = Color(0xFFF87171); // Merah lembut — pengeluaran
  static const Color dangerSurface= Color(0xFF1A1218); // Latar tombol koreksi
  static const Color dangerBorder = Color(0xFF2A1E20); // Garis tombol koreksi
  static const Color divider      = Color(0xFF1A2A3A); // Garis pemisah
}

// ============================================================
// HALAMAN UTAMA
// StatefulWidget dipakai karena halaman ini perlu memuat data
// dari database dan bisa berubah saat ada pengeluaran baru.
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Menyimpan referensi ke database helper
  final DbHelper _dbHelper = DbHelper();

  // Variabel untuk menampung data dari database.
  // Nullable (?) karena data belum tentu ada saat pertama kali buka aplikasi.
  Saldo? _saldo;
  List<Pengeluaran> _riwayat = [];

  // Flag untuk menampilkan indikator loading saat data sedang diambil
  bool _isLoading = true;

  // initState() adalah fungsi yang otomatis dipanggil Flutter
  // tepat sekali saat widget ini pertama kali dibuat.
  @override
  void initState() {
    super.initState();
    _muatData(); // Langsung muat data begitu halaman dibuka
  }

  // Fungsi untuk mengambil semua data yang dibutuhkan halaman ini
  Future<void> _muatData() async {
    // Jalankan kedua query secara bersamaan agar lebih cepat.
    // Future.wait() menunggu semua Future selesai sebelum lanjut.
    final results = await Future.wait([
      _dbHelper.getSaldo(),
      _dbHelper.getRiwayatPengeluaran(),
    ]);

    // Setelah data datang, perbarui state supaya UI ikut diperbarui.
    // setState() memberitahu Flutter untuk menggambar ulang widget ini.
    setState(() {
      _saldo   = results[0] as Saldo?;
      _riwayat = results[1] as List<Pengeluaran>;
      _isLoading = false;
    });
  }

  // ============================================================
  // Helper: Format angka menjadi format Rupiah
  // Contoh: 2450000 → "Rp 2.450.000"
  // ============================================================
  String _formatRupiah(double angka) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(angka);
  }

  // ============================================================
  // Helper: Hitung total pengeluaran bulan ini saja
  // ============================================================
  double _totalBulanIni() {
    final sekarang = DateTime.now();
    return _riwayat
        .where((p) {
          // Parsing teks tanggal dari database menjadi objek DateTime
          final tgl = DateTime.tryParse(p.tanggal);
          if (tgl == null) return false;
          // Filter: hanya pengeluaran di bulan dan tahun yang sama
          return tgl.month == sekarang.month && tgl.year == sekarang.year;
        })
        // Menjumlahkan semua .jumlah dari pengeluaran yang lolos filter
        .fold(0.0, (total, p) => total + p.jumlah);
  }

  // ============================================================
  // Helper: Format tanggal relatif (hari ini, kemarin, atau tanggal)
  // Contoh: "Hari ini, 12:15" / "Kemarin, 08:00" / "15 Agu, 10:30"
  // ============================================================
  String _formatTanggalRelatif(String tanggalString) {
    final tgl = DateTime.tryParse(tanggalString);
    if (tgl == null) return tanggalString;

    final sekarang = DateTime.now();
    final hari = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tglHari = DateTime(tgl.year, tgl.month, tgl.day);
    final jam = DateFormat('HH:mm').format(tgl);

    final selisih = hari.difference(tglHari).inDays;

    if (selisih == 0) return 'Hari ini, $jam';
    if (selisih == 1) return 'Kemarin, $jam';
    return '${DateFormat('d MMM', 'id_ID').format(tgl)}, $jam';
  }

  // ============================================================
  // BUILD: Fungsi utama yang menggambar seluruh tampilan halaman
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // Scaffold adalah "kerangka" halaman standar Flutter
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          // Tampilkan spinner kalau data masih dimuat
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          // Kalau data sudah siap, tampilkan konten utama
          : SafeArea(
              // SafeArea memastikan konten tidak tertutup notch/status bar HP
              child: RefreshIndicator(
                // RefreshIndicator: tarik ke bawah untuk refresh data
                onRefresh: _muatData,
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                child: SingleChildScrollView(
                  // physics: agar scroll tetap bisa dipicu meski konten pendek
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildSeksiSaldo(),
                      _buildDivider(),
                      _buildRingkasanBulan(),
                      _buildSeksiAksi(),
                      _buildRiwayatTerakhir(),
                      const SizedBox(height: 24), // Ruang di bawah
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // WIDGET BAGIAN: Header aplikasi (judul + ikon)
  // ============================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Judul aplikasi
          const Text(
            'DOMPET SAYA',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          // Tombol ikon notifikasi (placeholder, bisa dihubungkan nanti)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET BAGIAN: Kotak besar tampilan saldo utama
  // ============================================================
  Widget _buildSeksiSaldo() {
    // Ambil nilai saldo, default 0 kalau belum ada
    final jumlah = _saldo?.jumlah ?? 0.0;
    // Format waktu terakhir update
    final updateText = _saldo != null
        ? 'Diperbarui ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(
            DateTime.tryParse(_saldo!.terakhirUpdate) ?? DateTime.now(),
          )}'
        : 'Saldo belum diisi';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          // Label
          const Text(
            'SALDO TERSEDIA',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Baris angka saldo: "Rp" kecil + angka besar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Rp" kecil di pojok kiri atas angka
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Rp',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Angka saldo — elemen terbesar di halaman
              Text(
                // Format tanpa "Rp " karena sudah ada di sebelah kiri
                NumberFormat('#,###', 'id_ID').format(jumlah),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Waktu terakhir diperbarui
          Text(
            updateText,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET BAGIAN: Garis pemisah tipis
  // ============================================================
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.divider,
    );
  }

  // ============================================================
  // WIDGET BAGIAN: Dua kartu ringkasan (pengeluaran bulan ini + status)
  // ============================================================
  Widget _buildRingkasanBulan() {
    final total = _totalBulanIni();
    final saldo = _saldo?.jumlah ?? 0.0;
    // Tentukan status berdasarkan saldo
    final statusText = saldo <= 0
        ? 'Habis'
        : saldo < 100000
            ? 'Tipis'
            : 'Aman';
    final statusColor = saldo <= 0
        ? AppColors.danger
        : saldo < 100000
            ? const Color(0xFFFBBF24) // Kuning — waspada
            : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          // Kartu 1: Total pengeluaran bulan ini
          Expanded(
            child: _buildKartuRingkasan(
              label: 'Keluar bulan ini',
              nilai: _formatRupiah(total),
              nilaiColor: AppColors.danger,
            ),
          ),
          const SizedBox(width: 10),
          // Kartu 2: Status saldo
          Expanded(
            child: _buildKartuRingkasan(
              label: 'Status saldo',
              nilai: statusText,
              nilaiColor: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Sub-widget kartu ringkasan (dipakai dua kali di atas)
  Widget _buildKartuRingkasan({
    required String label,
    required String nilai,
    required Color nilaiColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nilai,
            style: TextStyle(
              color: nilaiColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET BAGIAN: Empat tombol aksi utama (2x2 Grid)
  // ============================================================
  Widget _buildSeksiAksi() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        children: [
          // --- BARIS 1: Pemasukan & Pengeluaran ---
          Row(
            children: [
              // Tombol Tambah Saldo
              Expanded(
                child: _buildTombolAksi(
                  label: 'Tambah saldo',
                  ikon: Icons.add_circle_outline_rounded,
                  warnaTeks: AppColors.accent,
                  warnaBorder: AppColors.accent.withValues(alpha: 0.35),
                  warnaBackground: AppColors.surface,
                  onTap: () => _tampilkanDialogTambahSaldo(context),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Tambah Pengeluaran
              Expanded(
                child: _buildTombolAksi(
                  label: 'Pengeluaran',
                  ikon: Icons.remove_circle_outline_rounded,
                  warnaTeks: AppColors.accentText,
                  warnaBorder: AppColors.accent,
                  warnaBackground: AppColors.accent,
                  onTap: () async {
                    final berhasilSimpan = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TambahPengeluaranScreen(),
                      ),
                    );
                    if (berhasilSimpan == true) {
                      _muatData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // --- BARIS 2: Riwayat & Koreksi ---
          Row(
            children: [
              // Tombol Lihat Riwayat
              Expanded(
                child: _buildTombolAksi(
                  label: 'Lihat riwayat',
                  ikon: Icons.history_rounded,
                  warnaTeks: AppColors.textSecondary,
                  warnaBorder: AppColors.surfaceBorder,
                  warnaBackground: AppColors.surface,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiwayatScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Koreksi Saldo
              Expanded(
                child: _buildTombolAksi(
                  label: 'Koreksi saldo',
                  ikon: Icons.edit_rounded,
                  warnaTeks: AppColors.danger,
                  warnaBorder: AppColors.dangerBorder,
                  warnaBackground: AppColors.dangerSurface,
                  onTap: () => _tampilkanDialogKoreksi(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sub-widget tombol aksi (dipakai untuk 4 tombol di atas)
  Widget _buildTombolAksi({
    required String label,
    required IconData ikon,
    required Color warnaTeks,
    required Color warnaBorder,
    required Color warnaBackground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: warnaBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: warnaBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, color: warnaTeks, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: warnaTeks,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ============================================================
  // WIDGET BAGIAN: Tiga pengeluaran terakhir (preview riwayat)
  // ============================================================
  Widget _buildRiwayatTerakhir() {
    // Ambil maksimal 3 pengeluaran terbaru saja untuk preview
    final preview = _riwayat.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header kartu riwayat
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: const Text(
                'PENGELUARAN TERAKHIR',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Tampilkan pesan kalau belum ada data sama sekali
            if (preview.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada pengeluaran tercatat.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              )
            // Tampilkan daftar pengeluaran
            else
              ...preview.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == preview.length - 1;
                return _buildItemRiwayat(item, isLast: isLast);
              }),
          ],
        ),
      ),
    );
  }

  // Sub-widget satu baris pengeluaran di kartu riwayat
  Widget _buildItemRiwayat(Pengeluaran item, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null // Baris terakhir tidak punya garis bawah
            : const Border(
                bottom: BorderSide(color: AppColors.background, width: 1),
              ),
      ),
      child: Row(
        children: [
          // Titik bulat penanda — item pertama lebih terang
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLast
                  ? AppColors.divider
                  : AppColors.accent.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 10),
          // Keterangan dan tanggal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.keterangan,
                  style: const TextStyle(
                    color: Color(0xFFB0D4E8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  // Potong teks kalau terlalu panjang
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  _formatTanggalRelatif(item.tanggal),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Nominal pengeluaran (merah dengan tanda minus)
          Text(
            '−${_formatRupiah(item.jumlah)}',
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG: Tambah Saldo (Pemasukan / Top Up)
  // showModalBottomSheet menampilkan panel dari bawah layar
  // ============================================================
  void _tampilkanDialogTambahSaldo(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Saldo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan nominal uang yang ingin ditambahkan ke saldo.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Nominal Tambah Saldo (Rp)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: AppColors.accent),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final teks = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final nominal = double.tryParse(teks);

                  if (nominal == null || nominal <= 0) return;

                  await _dbHelper.tambahSaldo(nominal);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _muatData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tambah Saldo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG: Koreksi Saldo (FR-02)
  // showModalBottomSheet menampilkan panel dari bawah layar
  // ============================================================
  void _tampilkanDialogKoreksi(BuildContext context) {
    // Controller untuk menangkap teks yang diketik pengguna
    final controller = TextEditingController(
      // Isi awal = saldo saat ini (tanpa desimal)
      text: _saldo != null
          ? _saldo!.jumlah.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Agar keyboard tidak menimpa input saat muncul
      isScrollControlled: true,
      builder: (ctx) => Padding(
        // EdgeInsets.only(bottom: viewInsets.bottom) = naik saat keyboard muncul
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ukuran panel menyesuaikan konten
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dialog
            const Text(
              'Koreksi saldo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan jumlah saldo yang benar.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            // Input field jumlah saldo baru
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Jumlah saldo baru (Rp)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: AppColors.accent),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 16),
            // Tombol simpan koreksi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Ambil teks, hilangkan karakter non-angka (titik/koma pemisah)
                  final teks = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final jumlahBaru = double.tryParse(teks);

                  // Validasi: jangan simpan kalau input kosong atau bukan angka
                  if (jumlahBaru == null) return;

                  // Simpan ke database lewat DbHelper
                  await _dbHelper.updateSaldo(jumlahBaru);
                  // Tutup modal
                  if (ctx.mounted) Navigator.pop(ctx);
                  // Refresh tampilan halaman utama
                  _muatData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan koreksi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}