class Txn {
  final int? id;
  final int partyId;
  final int type; // 0 = You Gave, 1 = You Got
  final double amount;
  final String? note;
  final int datetime;

  Txn({
    this.id,
    required this.partyId,
    required this.type,
    required this.amount,
    this.note,
    required this.datetime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'party_id': partyId,
        'type': type,
        'amount': amount,
        'note': note,
        'datetime': datetime,
      };

  factory Txn.fromMap(Map<String, dynamic> m) => Txn(
        id: m['id'],
        partyId: m['party_id'],
        type: m['type'],
        amount: (m['amount'] as num).toDouble(),
        note: m['note'],
        datetime: m['datetime'],
      );
}
