import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inbound_dialog.dart';
import '../widgets/outbound_dialog.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('库存管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => inventory.fetchItems(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: '搜索物品名称...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (val) {
                      // Implement search logic if API supports it or local filter
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showInboundDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('物品入库'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showOutboundDialog(context);
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('物品出库'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: inventory.items.length,
                    itemBuilder: (context, index) {
                      final item = inventory.items[index];
                      final isLowStock =
                          item['quantity'] <= item['low_stock_threshold'];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLowStock
                                ? Colors.red.withAlpha(51)
                                : Colors.blue.withAlpha(51),
                            child: Icon(
                              Icons.inventory_2,
                              color: isLowStock ? Colors.red : Colors.blue,
                            ),
                          ),
                          title: Text('${item['name']} (ID: ${item['id']})'),
                          subtitle: Text(
                            '分类: ${item['category']} | 品牌: ${item['brand'] ?? '-'} | 预警值: ${item['low_stock_threshold']}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item['quantity']} ${item['unit']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? Colors.red : Colors.green,
                                ),
                              ),
                              Text('￥${item['price']} / ${item['unit']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showInboundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const InboundDialog();
      },
    );
  }

  void _showOutboundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const OutboundDialog();
      },
    );
  }
}
