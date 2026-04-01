import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('流转明细'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => inventory.fetchRecords(),
          ),
        ],
      ),
      body: inventory.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inventory.records.length,
              itemBuilder: (context, index) {
                final r = inventory.records[index];
                final isObj = r['type'] == 'in';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isObj
                          ? Colors.green.withAlpha(51)
                          : Colors.orange.withAlpha(51),
                      child: Icon(
                        isObj ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isObj ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text('${r['item_name']} (ID: ${r['item_id']})'),
                    subtitle: Text(
                      '操作人: ${r['operator']} | 备注: ${r['remark'] ?? '-'} \n时间: ${r['time']}',
                    ),
                    trailing: Text(
                      '${isObj ? '+' : '-'}${r['quantity']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isObj ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
