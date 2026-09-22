class Pengeluaran {
  final int? id; 
  final String keterangan;
  final double jumlah;
  final String tanggal;

  Pengeluaran({
    this.id,
    required this.keterangan,
    required this.jumlah,
    required this.tanggal,
  });

  factory Pengeluaran.fromMap(Map<String, dynamic> map) {
    return Pengeluaran(
      id: map['id'],
      keterangan: map['keterangan'],
      jumlah: map['jumlah'],
      tanggal: map['tanggal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'keterangan': keterangan,
      'jumlah': jumlah,
      'tanggal': tanggal,
    };
  }
}