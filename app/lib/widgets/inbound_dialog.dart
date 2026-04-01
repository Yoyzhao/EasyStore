import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';

class InboundDialog extends StatefulWidget {
  const InboundDialog({super.key});

  @override
  State<InboundDialog> createState() => _InboundDialogState();
}

class _InboundDialogState extends State<InboundDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isNewItem = false;
  int? _selectedItemId;

  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _lowStockCtrl = TextEditingController(text: '10');
  final _quantityCtrl = TextEditingController(text: '1');
  final _remarkCtrl = TextEditingController();

  bool _isSubmitting = false;

  void _fillExistingData(Map<String, dynamic> item) {
    _nameCtrl.text = item['name'];
    _categoryCtrl.text = item['category'];
    _brandCtrl.text = item['brand'] ?? '';
    _unitCtrl.text = item['unit'];
    _priceCtrl.text = item['price'].toString();
    _lowStockCtrl.text = item['low_stock_threshold'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('物品入库'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('入库模式：'),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('已有物品'),
                      selected: !_isNewItem,
                      onSelected: (v) {
                        setState(() => _isNewItem = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('新物品'),
                      selected: _isNewItem,
                      onSelected: (v) {
                        setState(() {
                          _isNewItem = true;
                          _selectedItemId = null;
                          _nameCtrl.clear();
                          _categoryCtrl.clear();
                          _brandCtrl.clear();
                          _unitCtrl.clear();
                          _priceCtrl.clear();
                          _lowStockCtrl.text = '10';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_isNewItem)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedItemId,
                    decoration: const InputDecoration(
                      labelText: '选择已有物品',
                      border: OutlineInputBorder(),
                    ),
                    items: inventory.items.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text('${item['name']} (ID: ${item['id']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedItemId = val;
                        if (val != null) {
                          final item = inventory.items.firstWhere(
                            (i) => i['id'] == val,
                          );
                          _fillExistingData(item);
                        }
                      });
                    },
                    validator: (val) =>
                        !_isNewItem && val == null ? '请选择物品' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '物品名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? '请输入物品名称' : null,
                  readOnly: !_isNewItem,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: '分类',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? '分类不能为空' : null,
                        readOnly: !_isNewItem,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _brandCtrl,
                        decoration: const InputDecoration(
                          labelText: '品牌 (可选)',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: !_isNewItem,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                          labelText: '单位',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? '单位不能为空' : null,
                        readOnly: !_isNewItem,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                          labelText: '单价',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val == null || val.isEmpty ? '单价不能为空' : null,
                        readOnly: !_isNewItem,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lowStockCtrl,
                        decoration: const InputDecoration(
                          labelText: '低库存预警',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: !_isNewItem,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        decoration: const InputDecoration(
                          labelText: '入库数量',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final q = int.tryParse(val ?? '');
                          if (q == null || q < 1) return '数量必须大于0';
                          return null;
                        },
                      ),
                    ),
                  ],
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

                    final success = await inventory.inbound({
                      'name': _nameCtrl.text,
                      'category': _categoryCtrl.text,
                      'brand': _brandCtrl.text,
                      'quantity': int.parse(_quantityCtrl.text),
                      'price': double.parse(_priceCtrl.text),
                      'unit': _unitCtrl.text,
                      'low_stock_threshold': int.parse(_lowStockCtrl.text),
                      'image_url': '',
                      'item_link': '',
                      'operator': auth.username ?? 'Admin',
                      'remark': _remarkCtrl.text,
                    });

                    setState(() => _isSubmitting = false);
                    if (success) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('入库成功')));
                      Navigator.pop(context);
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('入库失败')));
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确认入库'),
        ),
      ],
    );
  }
}
