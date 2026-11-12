import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/party.dart';
import '../models/txn.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._();
  DBHelper._();
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'hisab_book.db');
    return openDatabase(
      path,
      version: 2, // Version badhakar 2 kar diya
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE parties(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            category_id INTEGER,
            opening_balance REAL DEFAULT 0,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
          )''');
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            party_id INTEGER NOT NULL,
            type INTEGER NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            datetime INTEGER NOT NULL,
            payment_mode INTEGER DEFAULT 0,
            image_path TEXT,
            FOREIGN KEY(party_id) REFERENCES parties(id) ON DELETE CASCADE
          )''');
        final seed = [
          {'name': 'Customer', 'color': 0xFF2196F3},
          {'name': 'Supplier', 'color': 0xFF4CAF50},
          {'name': 'Staff', 'color': 0xFFFF9800},
          {'name': 'Personal', 'color': 0xFF9C27B0},
        ];
        for (final c in seed) {
          await db.insert('categories', c);
        }
      },
      // Purani app wale users ke liye (agar unke phone mein data pehle se hai)
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN payment_mode INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE transactions ADD COLUMN image_path TEXT');
        }
      },
    );
  }

  // Categories
  Future<List<Category>> categories() async {
    final rows = await (await db).query('categories', orderBy: 'name');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> addCategory(Category c) async =>
      (await db).insert('categories', c.toMap()..remove('id'));

  Future<void> deleteCategory(int id) async =>
      (await db).delete('categories', where: 'id=?', whereArgs: [id]);

  // Parties
  Future<List<Party>> parties() async {
    final rows = await (await db).query('parties', orderBy: 'name');
    return rows.map(Party.fromMap).toList();
  }

  Future<int> addParty(Party pa) async =>
      (await db).insert('parties', pa.toMap()..remove('id'));

  Future<void> deleteParty(int id) async =>
      (await db).delete('parties', where: 'id=?', whereArgs: [id]);

  // Transactions
  Future<List<Txn>> transactionsForParty(int partyId) async {
    final rows = await (await db).query(
      'transactions',
      where: 'party_id=?',
      whereArgs: [partyId],
      orderBy: 'datetime DESC',
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<int> addTxn(Txn t) async =>
      (await db).insert('transactions', t.toMap()..remove('id'));

  // NAYA: Edit/Update ke liye
  Future<int> updateTxn(Txn t) async =>
      (await db).update('transactions', t.toMap(), where: 'id=?', whereArgs: [t.id]);

  Future<void> deleteTxn(int id) async =>
      (await db).delete('transactions', where: 'id=?', whereArgs: [id]);

  // Balance per party
  Future<Map<int, double>> balanceMap() async {
    final rows = await (await db).rawQuery('''
      SELECT p.id AS pid, p.opening_balance AS ob,
        COALESCE(SUM(CASE WHEN t.type=0 THEN t.amount ELSE 0 END),0) AS gave,
        COALESCE(SUM(CASE WHEN t.type=1 THEN t.amount ELSE 0 END),0) AS got
      FROM parties p LEFT JOIN transactions t ON t.party_id = p.id
      GROUP BY p.id
    ''');
    final map = <int, double>{};
    for (final r in rows) {
      map[r['pid'] as int] = (r['ob'] as num).toDouble() +
          (r['gave'] as num).toDouble() -
          (r['got'] as num).toDouble();
    }
    return map;
  }
}
