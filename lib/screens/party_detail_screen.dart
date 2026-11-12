import 'dart:io';
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
  List<Txn> allTxns = [];
  List<Txn> filteredTxns = [];
  bool loading = true;
  
  // Date filter ke liye
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<AppProvider>().txnsFor(widget.partyId);
    if (mounted) {
      setState(() {
        allTxns = list;
        _applyFilter();
        loading = false;
      });
    }
  }

  void _applyFilter() {
    if (startDate == null || endDate == null) {
      filteredTxns = allTxns;
    } else {
      filteredTxns = allTxns.where((t) {
        final dt = DateTime.fromMillisecondsSinceEpoch(t.datetime);
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        final sDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
        final eDate = DateTime(endDate!.year, endDate!.month, endDate!.day);
        return dateOnly.isAfter(sDate.subtract(const Duration(days: 1))) && 
               dateOnly.isBefore(eDate.add(const Duration(days: 1)));
      }).toList();
    }
    setState(() {});
  }

  Future<void> _openEntry(int type, [Txn? existingTxn]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          partyId: widget.partyId, 
          initialType: type,
          existingTxn: existingTxn,
        ),
      ),
    );
    _load(); // Wapas aakar refresh karein
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: startDate != null && endDate != null 
          ? DateTimeRange(start: startDate!, end: endDate!) 
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _applyFilter();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
      _applyFilter();
    });
  }

  Future<void> _deleteTxn(Txn t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Remove this ${t.type == 0 ? "You Gave" : "You Got"} entry of ${currencyFmt.format(t.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Party not found')));
    }

    double bal = party.openingBalance;
    for (final t in allTxns) {
      bal += t.type == 0 ? t.amount : -t.amount;
    }
    final cat = p.categoryOf(party.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [
          IconButton(
            icon: Icon(startDate != null ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              // delete party code...
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Banner
          if (startDate != null)
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${dateFmt.format(startDate!)} to ${dateFmt.format(endDate!)}', style: const TextStyle(fontSize: 12)),
                  TextButton(onPressed: _clearFilter, child: const Text('Clear Filter', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: bal > 0 ? Colors.green.shade50 : (bal < 0 ? Colors.red.shade50 : Colors.grey.shade100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(party.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (cat != null) Text(cat.name),
                const SizedBox(height: 8),
                Text(
                  bal > 0 ? 'You will get ${currencyFmt.format(bal)}' : (bal < 0 ? 'You will give ${currencyFmt.format(bal.abs())}' : 'Settled'),
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: bal > 0 ? Colors.green : (bal < 0 ? Colors.red : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredTxns.isEmpty
                    ? const Center(child: Text('No entries found'))
                    : ListView.builder(
                        itemCount: filteredTxns.length,
                        itemBuilder: (ctx, i) {
                          final t = filteredTxns[i];
                          final gave = t.type == 0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: gave ? Colors.red.shade50 : Colors.green.shade50,
                              child: Icon(gave ? Icons.arrow_upward : Icons.arrow_downward, color: gave ? Colors.red : Colors.green),
                            ),
                            title: Text(
                              '${gave ? "You Gave" : "You Got"}  ${currencyFmt.format(t.amount)}',
                              style: TextStyle(color: gave ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateTimeFmt.format(DateTime.fromMillisecondsSinceEpoch(t.datetime)) + 
                                     ' • ${t.paymentMode == 0 ? "Cash" : "Online"}'),
                                if (t.note != null) Text(t.note!, style: const TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: t.imagePath != null 
                                ? const Icon(Icons.attachment, color: Colors.grey) 
                                : null,
                            onTap: () => _openEntry(t.type, t), // Tap to Edit
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                    onPressed: () => _openEntry(0),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('You Gave'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, foregroundColor: Colors.green),
                    onPressed: () => _openEntry(1),
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
