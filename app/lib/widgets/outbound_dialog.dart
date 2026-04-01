import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';

class OutboundDialog extends StatefulWidget {
  const OutboundDialog({super.key});

  @override
  State<OutboundDialog> createState() => _OutboundDialogState();
}

class _OutboundDialogState extends State<OutboundDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedItemId;
  int _currentStock = 0;
  int _quantity = 1;
  final _usageCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('物品出库'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: '选择物品',
                    border: OutlineInputBorder(),
                  ),
                  items: inventory.items.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'] as int,
                      child: Text('${item['name']} (库存: ${item['quantity']})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedItemId = val;
                      final item = inventory.items.firstWhere(
                        (i) => i['id'] == val,
                      );
                      _currentStock = item['quantity'];
                      if (_quantity > _currentStock) _quantity = 1;
                    });
                  },
                  validator: (val) => val == null ? '请选择物品' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _currentStock.toString(),
                        decoration: const InputDecoration(
                          labelText: '当前库存',
                          border: OutlineInputBorder(),
                        ),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _quantity.toString(),
                        decoration: const InputDecoration(
                          labelText: '出库数量',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _quantity = int.tryParse(val) ?? 1,
                        validator: (val) {
                          final q = int.tryParse(val ?? '');
                          if (q == null || q < 1) return '数量不合法';
                          if (q > _currentStock) return '不能大于当前库存';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usageCtrl,
                  decoration: const InputDecoration(
                    labelText: '用途/去向',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? '请输入用途' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientCtrl,
                  decoration: const InputDecoration(
                    labelText: '领用人',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? '请输入领用人' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _remarkCtrl,
                  decoration: const InputDecoration(
                    labelText: '备注 (可选)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isSubmitting = true);
                    final remark = _usageCtrl.text.isNotEmpty
                        ? '用途/去向: ${_usageCtrl.text}${_remarkCtrl.text.isNotEmpty ? ' - ${_remarkCtrl.text}' : ''}'
                        : _remarkCtrl.text;

                    final success = await inventory.outbound({
                      'item_id': _selectedItemId,
                      'quantity': _quantity,
                      'operator': auth.username ?? 'Admin',
                      'usage': _usageCtrl.text,
                      'recipient': _recipientCtrl.text,
                      'remark': remark,
                    });
                    setState(() => _isSubmitting = false);
                    if (success) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('出库成功')));
                      Navigator.pop(context);
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('出库失败')));
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确认出库'),
        ),
      ],
    );
  }
}
