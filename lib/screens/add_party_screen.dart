import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../providers/app_provider.dart';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});
  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final balCtrl = TextEditingController();
  int? categoryId;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (nameCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter party name')));
      return;
    }
    final provider = context.read<AppProvider>();
    await provider.addParty(Party(
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      categoryId: categoryId,
      openingBalance: double.tryParse(balCtrl.text) ?? 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<AppProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Party')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Party Name *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: categoryId,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...cats.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => categoryId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Opening Balance (optional)',
                helperText: 'Positive = they owe you • Negative = you owe them',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
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
