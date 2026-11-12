class Party {
  final int? id;
  final String name;
  final String? phone;
  final int? categoryId;
  final double openingBalance;
  final int createdAt;

  Party({
    this.id,
    required this.name,
    this.phone,
    this.categoryId,
    this.openingBalance = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'category_id': categoryId,
        'opening_balance': openingBalance,
        'created_at': createdAt,
      };

  factory Party.fromMap(Map<String, dynamic> m) => Party(
        id: m['id'],
        name: m['name'],
        phone: m['phone'],
        categoryId: m['category_id'],
        openingBalance: (m['opening_balance'] as num).toDouble(),
        createdAt: m['created_at'],
      );
}
