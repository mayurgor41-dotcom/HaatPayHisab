import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils.dart';
import 'add_party_screen.dart';
import 'party_detail_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});
  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  String search = '';
  int? filterCat;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (p.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final activeCat = (filterCat != null && p.categories.any((c) => c.id == filterCat))
        ? filterCat
        : null;

    final parties = p.parties.where((pt) {
      if (activeCat != null && pt.categoryId != activeCat) return false;
      if (search.isNotEmpty && !pt.name.toLowerCase().contains(search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final total = parties.fold<double>(0, (s, x) => s + (p.balances[x.id] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('HisabBook'),
        actions: [
          if (total != 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Net: ${currencyFmt.format(total.abs())}',
                  style: TextStyle(
                    color: total > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search parties...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', activeCat == null, () => setState(() => filterCat = null)),
                ...p.categories.map((c) =>
                    _chip(c.name, activeCat == c.id, () => setState(() => filterCat = c.id))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: parties.isEmpty
                ? const Center(child: Text('No parties yet. Tap + to add.'))
                : ListView.builder(
                    itemCount: parties.length,
                    itemBuilder: (ctx, i) {
                      final party = parties[i];
                      final bal = p.balances[party.id] ?? 0;
                      final cat = p.categoryOf(party.categoryId);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              cat != null ? Color(cat.color) : Colors.grey,
                          child: Text(
                            party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(party.name),
                        subtitle: cat != null ? Text(cat.name) : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFmt.format(bal.abs()),
                              style: TextStyle(
                                color: bal > 0
                                    ? Colors.green
                                    : (bal < 0 ? Colors.red : Colors.grey),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              bal > 0
                                  ? 'You will get'
                                  : (bal < 0 ? 'You will give' : 'Settled'),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartyDetailScreen(partyId: party.id!),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPartyScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
