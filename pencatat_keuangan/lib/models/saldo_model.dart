class Saldo {
  final int id;
  final double jumlah;
  final String terakhirUpdate;

  Saldo({
    required this.id,
    required this.jumlah,
    required this.terakhirUpdate,
  });

  factory Saldo.fromMap(Map<String, dynamic> map) {
    return Saldo(
      id: map['id'],
      jumlah: map['jumlah'],
      terakhirUpdate: map['terakhir_update'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jumlah': jumlah,
      'terakhir_update': terakhirUpdate,
    };
  }
}