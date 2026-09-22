import 'package:flutter/material.dart';
// Wajib diimpor agar kalender/waktu bahasa Indonesia (id_ID) bisa jalan
import 'package:intl/date_symbol_data_local.dart'; 

// Memanggil layar Home Screen yang baru saja Anda buat
import 'screens/home_screen.dart';

void main() async {
  // Wajib dipanggil jika kita menggunakan fungsi async di dalam main()
  WidgetsFlutterBinding.ensureInitialized();

  // Mengaktifkan format tanggal lokal Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dompet Saya',
      // Menghilangkan pita merah tulisan "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        // Menyesuaikan dengan tema gelap (Dark Mode) di HomeScreen Anda
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // Titik awal aplikasi langsung diarahkan ke HomeScreen
      home: const HomeScreen(), 
    );
  }
}