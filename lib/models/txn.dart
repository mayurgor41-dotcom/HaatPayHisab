class Txn {
  final int? id;
  final int partyId;
  final int type; // 0 = You Gave, 1 = You Got
  final double amount;
  final String? note;
  final int datetime;
  final int paymentMode; // 0 = Cash, 1 = Online (Naya)
  final String? imagePath; // Photo ka path (Naya)

  Txn({
    this.id,
    required this.partyId,
    required this.type,
    required this.amount,
    this.note,
    required this.datetime,
    this.paymentMode = 0,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'party_id': partyId,
        'type': type,
        'amount': amount,
        'note': note,
        'datetime': datetime,
        'payment_mode': paymentMode,
        'image_path': imagePath,
      };

  factory Txn.fromMap(Map<String, dynamic> m) => Txn(
        id: m['id'],
        partyId: m['party_id'],
        type: m['type'],
        amount: (m['amount'] as num).toDouble(),
        note: m['note'],
        datetime: m['datetime'],
        paymentMode: m['payment_mode'] ?? 0,
        imagePath: m['image_path'],
      );
}
