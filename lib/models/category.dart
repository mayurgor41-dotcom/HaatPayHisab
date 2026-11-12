class Category {
  final int? id;
  final String name;
  final int color;
  Category({this.id, required this.name, required this.color});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color};
  factory Category.fromMap(Map<String, dynamic> m) =>
      Category(id: m['id'], name: m['name'], color: m['color']);
}
