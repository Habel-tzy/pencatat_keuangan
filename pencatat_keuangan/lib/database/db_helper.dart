import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// Mengimpor "cetakan" data yang sudah kita buat sebelumnya
import '../models/saldo_model.dart';
import '../models/pengeluaran_model.dart';

class DbHelper {
  static Database? _db;
  static const String dbName = 'catatan_pengeluaran.db';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE saldo (  
        id INTEGER PRIMARY KEY,  
        jumlah REAL NOT NULL,  
        terakhir_update TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pengeluaran (  
        id INTEGER PRIMARY KEY AUTOINCREMENT,  
        keterangan TEXT NOT NULL,  
        jumlah REAL NOT NULL,  
        tanggal TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // FUNGSI CRUD UNTUK SALDO (Sesuai FR-01, FR-02, FR-07)
  // =========================================================

  // 1. Membaca Saldo Saat Ini
  Future<Saldo?> getSaldo() async {
    Database dbClient = await db;
    // Mencari data saldo dengan id = 1
    List<Map<String, dynamic>> maps = await dbClient.query('saldo', where: 'id = ?', whereArgs: [1]);
    
    if (maps.isNotEmpty) {
      return Saldo.fromMap(maps.first); // Mengubah data SQLite menjadi objek Dart
    }
    return null; // Mengembalikan null jika saldo belum pernah diisi
  }

  // 2. Memasukkan / Mengoreksi Saldo
  Future<void> updateSaldo(double jumlahBaru) async {
    Database dbClient = await db;
    var cekSaldo = await getSaldo();
    String waktu = DateTime.now().toString(); // Mengambil waktu saat ini

    if (cekSaldo == null) {
      // Jika kosong, lakukan INSERT (FR-01: Input Saldo Awal)
      await dbClient.insert('saldo', {
        'id': 1, // ID selalu 1 sesuai SRS
        'jumlah': jumlahBaru,
        'terakhir_update': waktu
      });
    } else {
      // Jika sudah ada, lakukan UPDATE (FR-02: Koreksi Saldo)
      await dbClient.update('saldo', {
        'jumlah': jumlahBaru,
        'terakhir_update': waktu
      }, where: 'id = ?', whereArgs: [1]);
    }
  }

  // =========================================================
  // FUNGSI CRUD UNTUK PENGELUARAN (Sesuai FR-03, FR-04, FR-05, FR-06)
  // =========================================================

  // 3. Tambah Pengeluaran & Kurangi Saldo Otomatis
  Future<void> insertPengeluaran(Pengeluaran pengeluaran) async {
    Database dbClient = await db;
    
    // Simpan riwayat ke tabel pengeluaran (FR-03 & FR-05)
    await dbClient.insert('pengeluaran', pengeluaran.toMap());

    // Kurangi saldo otomatis (FR-04)
    var saldoSaatIni = await getSaldo();
    if (saldoSaatIni != null) {
      double sisaSaldo = saldoSaatIni.jumlah - pengeluaran.jumlah;
      await updateSaldo(sisaSaldo); // Memanggil fungsi updateSaldo di atas
    }
  }

  // 4. Membaca Semua Riwayat Pengeluaran
  Future<List<Pengeluaran>> getRiwayatPengeluaran() async {
    Database dbClient = await db;
    
    // Mengambil semua data, diurutkan berdasarkan ID terbesar (terbaru)
    List<Map<String, dynamic>> maps = await dbClient.query('pengeluaran', orderBy: 'id DESC');
    
    // Mengubah daftar Map SQLite menjadi daftar Objek Pengeluaran Dart
    return List.generate(maps.length, (i) {
      return Pengeluaran.fromMap(maps[i]);
    });
  }
}