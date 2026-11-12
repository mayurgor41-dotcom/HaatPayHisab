import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/category.dart';
import '../models/party.dart';
import '../models/txn.dart';

class AppProvider extends ChangeNotifier {
  List<Category> categories = [];
  List<Party> parties = [];
  Map<int, double> balances = {};
  bool loading = true;

  Future<void> init() async {
    await refreshCategories();
    await refreshParties();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshCategories() async {
    categories = await DBHelper.instance.categories();
    notifyListeners();
  }

  Future<void> refreshParties() async {
    parties = await DBHelper.instance.parties();
    balances = await DBHelper.instance.balanceMap();
    notifyListeners();
  }

  Future<void> addCategory(String name, Color color) async {
    await DBHelper.instance.addCategory(Category(name: name, color: color.value));
    await refreshCategories();
  }

  Future<void> deleteCategory(int id) async {
    await DBHelper.instance.deleteCategory(id);
    await refreshCategories();
    await refreshParties();
  }

  Future<void> addParty(Party p) async {
    await DBHelper.instance.addParty(p);
    await refreshParties();
  }

  Future<void> deleteParty(int id) async {
    await DBHelper.instance.deleteParty(id);
    await refreshParties();
  }

  Future<void> addTxn(Txn t) async {
    await DBHelper.instance.addTxn(t);
    await refreshParties();
  }

  Future<void> deleteTxn(int id) async {
    await DBHelper.instance.deleteTxn(id);
    await refreshParties();
  }

  Future<List<Txn>> txnsFor(int partyId) =>
      DBHelper.instance.transactionsForParty(partyId);

  Category? categoryOf(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
