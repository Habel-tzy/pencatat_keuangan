import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

  // 1. Membaca Saldo Saat Ini
  Future<Saldo?> getSaldo() async {
    Database dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('saldo', where: 'id = ?', whereArgs: [1]);
    
    if (maps.isNotEmpty) {
      return Saldo.fromMap(maps.first);
    }
    return null;
  }

  // 2. Memasukkan / Mengoreksi Saldo
  Future<void> updateSaldo(double jumlahBaru) async {
    Database dbClient = await db;
    var cekSaldo = await getSaldo();
    String waktu = DateTime.now().toString();

    if (cekSaldo == null) {
      await dbClient.insert('saldo', {
        'id': 1,
        'jumlah': jumlahBaru,
        'terakhir_update': waktu
      });
    } else {
      await dbClient.update('saldo', {
        'jumlah': jumlahBaru,
        'terakhir_update': waktu
      }, where: 'id = ?', whereArgs: [1]);
    }
  }

  // 3. Tambah Pengeluaran & Kurangi Saldo Otomatis
  Future<void> insertPengeluaran(Pengeluaran pengeluaran) async {
    Database dbClient = await db;
    await dbClient.insert('pengeluaran', pengeluaran.toMap());

    var saldoSaatIni = await getSaldo();
    if (saldoSaatIni != null) {
      double sisaSaldo = saldoSaatIni.jumlah - pengeluaran.jumlah;
      await updateSaldo(sisaSaldo);
    }
  }

  // 4. Membaca Semua Riwayat Pengeluaran
  Future<List<Pengeluaran>> getRiwayatPengeluaran() async {
    Database dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('pengeluaran', orderBy: 'id DESC');
    
    return List.generate(maps.length, (i) {
      return Pengeluaran.fromMap(maps[i]);
    });
  }

  // 5. Menghapus Pengeluaran & Mengembalikan Saldo
  Future<void> hapusPengeluaran(int idPengeluaran, double nominalYangDikembalikan) async {
    Database dbClient = await db;
    
    // 1. Hapus data dari tabel pengeluaran berdasarkan ID
    await dbClient.delete(
      'pengeluaran',
      where: 'id = ?',
      whereArgs: [idPengeluaran],
    );

    // 2. Kembalikan uang ke saldo utama
    var saldoSaatIni = await getSaldo();
    if (saldoSaatIni != null) {
      double saldoBaru = saldoSaatIni.jumlah + nominalYangDikembalikan;
      await updateSaldo(saldoBaru); // Update ke database
    }
  }

  // 6. Menambah Saldo Utama (Top Up / Pemasukan)
  Future<void> tambahSaldo(double nominal) async {
    var saldoSaatIni = await getSaldo();
    double saldoBaru = (saldoSaatIni?.jumlah ?? 0.0) + nominal;
    await updateSaldo(saldoBaru);
  }
}