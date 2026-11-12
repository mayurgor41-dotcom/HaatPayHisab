import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

const _palette = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.brown,
  Colors.indigo,
];

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.builder(
        itemCount: p.categories.length,
        itemBuilder: (ctx, i) {
          final c = p.categories[i];
          return ListTile(
            leading: CircleAvatar(
                backgroundColor: Color(c.color), radius: 14),
            title: Text(c.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, c.id!, c.name),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final selectedColor = ValueNotifier<Color>(_palette.first);
    final provider = context.read<AppProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            ValueListenableBuilder<Color>(
              valueListenable: selectedColor,
              builder: (_, c, __) => Wrap(
                children: [
                  for (final cc in _palette)
                    GestureDetector(
                      onTap: () => selectedColor.value = cc,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cc,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: c == cc
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await provider.addCategory(nameCtrl.text.trim(), selectedColor.value);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, int id, String name) async {
    final provider = context.read<AppProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "$name"? Parties in this category will become uncategorized.'),
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
      await provider.deleteCategory(id);
    }
  }
}
