import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../models/txn.dart';
import '../providers/app_provider.dart';
import '../utils.dart';
import 'add_txn_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  final int partyId;
  const PartyDetailScreen({super.key, required this.partyId});
  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  List<Txn> txns = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<AppProvider>().txnsFor(widget.partyId);
    if (mounted) {
      setState(() {
        txns = list;
        loading = false;
      });
    }
  }

  Future<void> _openAdd(int type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
            partyId: widget.partyId, initialType: type),
      ),
    );
    _load();
  }

  Future<void> _deleteTxn(Txn t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Remove this ${t.type == 0 ? "You Gave" : "You Got"} '
            'entry of ${currencyFmt.format(t.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AppProvider>().deleteTxn(t.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    Party? party;
    for (final x in p.parties) {
      if (x.id == widget.partyId) {
        party = x;
        break;
      }
    }
    if (party == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Party not found')),
      );
    }

    double bal = party.openingBalance;
    for (final t in txns) {
      bal += t.type == 0 ? t.amount : -t.amount;
    }
    final cat = p.categoryOf(party.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete party?'),
                  content: Text('Delete "${party!.name}" and all its entries?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true && mounted) {
                final nav = Navigator.of(context);
                await context.read<AppProvider>().deleteParty(party!.id!);
                nav.pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: bal > 0
                ? Colors.green.shade50
                : (bal < 0 ? Colors.red.shade50 : Colors.grey.shade100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(party.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                if (cat != null) Text(cat.name),
                if (party.phone != null) Text(party.phone!),
                const SizedBox(height: 8),
                Text(
                  bal > 0
                      ? 'You will get ${currencyFmt.format(bal)}'
                      : (bal < 0
                          ? 'You will give ${currencyFmt.format(bal.abs())}'
                          : 'Settled'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bal > 0
                        ? Colors.green
                        : (bal < 0 ? Colors.red : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : txns.isEmpty
                    ? const Center(child: Text('No entries yet'))
                    : ListView.builder(
                        itemCount: txns.length,
                        itemBuilder: (ctx, i) {
                          final t = txns[i];
                          final gave = t.type == 0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: gave
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              child: Icon(
                                gave ? Icons.arrow_upward : Icons.arrow_downward,
                                color: gave ? Colors.red : Colors.green,
                              ),
                            ),
                            title: Text(
                              '${gave ? "You Gave" : "You Got"}  ${currencyFmt.format(t.amount)}',
                              style: TextStyle(
                                  color: gave ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              dateTimeFmt.format(
                                  DateTime.fromMillisecondsSinceEpoch(t.datetime)) +
                                  (t.note != null ? '\n${t.note}' : ''),
                            ),
                            isThreeLine: t.note != null,
                            onLongPress: () => _deleteTxn(t),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red),
                    onPressed: () => _openAdd(0),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('You Gave'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green),
                    onPressed: () => _openAdd(1),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('You Got'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
