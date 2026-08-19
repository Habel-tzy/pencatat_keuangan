import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

  // Menjalankan perintah SQL persis seperti rancangan di SRS
  Future<void> _onCreate(Database db, int version) async {
    // 1. Membuat tabel saldo
    await db.execute('''
      CREATE TABLE saldo (  
        id INTEGER PRIMARY KEY,  
        jumlah REAL NOT NULL,  
        terakhir_update TEXT NOT NULL
      )
    ''');

    // 2. Membuat tabel pengeluaran
    await db.execute('''
      CREATE TABLE pengeluaran (  
        id INTEGER PRIMARY KEY AUTOINCREMENT,  
        keterangan TEXT NOT NULL,  
        jumlah REAL NOT NULL,  
        tanggal TEXT NOT NULL
      )
    ''');
  }
}