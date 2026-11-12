import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/txn.dart';
import '../providers/app_provider.dart';
import '../utils.dart';

class AddTransactionScreen extends StatefulWidget {
  final int partyId;
  final int initialType;
  const AddTransactionScreen(
      {super.key, required this.partyId, required this.initialType});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late int type;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  DateTime dt = DateTime.now();

  @override
  void initState() {
    super.initState();
    type = widget.initialType;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final amt = double.tryParse(amountCtrl.text) ?? 0;
    if (amt <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final provider = context.read<AppProvider>();
    await provider.addTxn(Txn(
      partyId: widget.partyId,
      type: type,
      amount: amt,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      datetime: dt.millisecondsSinceEpoch,
    ));
    nav.pop();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: dt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dt),
    );
    if (t == null) return;
    setState(() => dt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type == 0 ? 'You Gave' : 'You Got')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                    value: 0,
                    label: Text('You Gave'),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: 1,
                    label: Text('You Got'),
                    icon: Icon(Icons.arrow_downward)),
              ],
              selected: {type},
              onSelectionChanged: (s) => setState(() => type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400)),
              leading: const Icon(Icons.calendar_today),
              title: Text(dateTimeFmt.format(dt)),
              trailing: const Icon(Icons.edit),
              onTap: _pickDateTime,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
