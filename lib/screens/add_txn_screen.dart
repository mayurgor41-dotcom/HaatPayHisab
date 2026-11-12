import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/txn.dart';
import '../providers/app_provider.dart';
import '../utils.dart';

class AddTransactionScreen extends StatefulWidget {
  final int partyId;
  final int initialType;
  final Txn? existingTxn; // Edit ke liye

  const AddTransactionScreen({
    super.key, 
    required this.partyId, 
    required this.initialType,
    this.existingTxn,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late int type;
  late int paymentMode;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  DateTime dt = DateTime.now();
  String? imagePath;

  @override
  void initState() {
    super.initState();
    type = widget.initialType;
    paymentMode = 0; // Default Cash
    
    // Agar edit kar rahe hain toh purani values daalein
    if (widget.existingTxn != null) {
      type = widget.existingTxn!.type;
      paymentMode = widget.existingTxn!.paymentMode;
      amountCtrl.text = widget.existingTxn!.amount.toString();
      noteCtrl.text = widget.existingTxn!.note ?? '';
      dt = DateTime.fromMillisecondsSinceEpoch(widget.existingTxn!.datetime);
      imagePath = widget.existingTxn!.imagePath;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => imagePath = pickedFile.path);
    }
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
    
    final txnData = Txn(
      id: widget.existingTxn?.id,
      partyId: widget.partyId,
      type: type,
      amount: amt,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      datetime: dt.millisecondsSinceEpoch,
      paymentMode: paymentMode,
      imagePath: imagePath,
    );

    if (widget.existingTxn == null) {
      await provider.addTxn(txnData);
    } else {
      await provider.updateTxn(txnData);
    }
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
    final isEdit = widget.existingTxn != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Entry' : (type == 0 ? 'You Gave' : 'You Got'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('You Gave'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 1, label: Text('You Got'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {type},
              onSelectionChanged: (s) => setState(() => type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: !isEdit,
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
                labelText: 'Note / Details (optional)',
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
            const SizedBox(height: 16),
            const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Cash'), icon: Icon(Icons.money)),
                ButtonSegment(value: 1, label: Text('Online'), icon: Icon(Icons.phone_android)),
              ],
              selected: {paymentMode},
              onSelectionChanged: (s) => setState(() => paymentMode = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Receipt / Proof (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(imagePath!), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save, 
              child: Text(isEdit ? 'Update Entry' : 'Save Entry')
            ),
          ],
        ),
      ),
    );
  }
}
