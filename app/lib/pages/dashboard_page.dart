import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../providers/inventory_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).fetchDashboardData();
      Provider.of<InventoryProvider>(context, listen: false).fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Provider.of<DashboardProvider>(context);
    final inventory = Provider.of<InventoryProvider>(context);

    if (dashboard.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = dashboard.stats;

    return Scaffold(
      appBar: AppBar(title: const Text('控制面板')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard(
                  '总物品种类',
                  stats['total_items'].toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  '总库存价值',
                  '￥${stats['total_value']}',
                  Icons.monetization_on,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  '库存告警',
                  stats['low_stock_items'].toString(),
                  Icons.warning,
                  Colors.red,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  '近期出入库',
                  '${(stats['recent_inbound'] ?? 0) + (stats['recent_outbound'] ?? 0)}',
                  Icons.swap_vert,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '近期出入库趋势',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: _buildTrendChart(dashboard.trend),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '最新操作记录',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...inventory.records
                              .take(5)
                              .map(
                                (r) => ListTile(
                                  leading: Icon(
                                    r['type'] == 'in'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: r['type'] == 'in'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  title: Text(r['item_name'] ?? 'Unknown'),
                                  subtitle: Text(
                                    '${r['operator']} · ${r['time'].toString().substring(0, 10)}',
                                  ),
                                  trailing: Text(
                                    '${r['type'] == 'in' ? '+' : '-'}${r['quantity']}',
                                    style: TextStyle(
                                      color: r['type'] == 'in'
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(Map<String, dynamic> trend) {
    if (trend['dates'] == null || trend['dates'].isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final dates = List<String>.from(trend['dates']);
    final inbound = List<num>.from(trend['inbound']);
    final outbound = List<num>.from(trend['outbound']);

    double maxY = 0;
    for (var v in inbound) {
      if (v > maxY) maxY = v.toDouble();
    }
    for (var v in outbound) {
      if (v > maxY) maxY = v.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dates[value.toInt()].substring(5)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              inbound.length,
              (i) => FlSpot(i.toDouble(), inbound[i].toDouble()),
            ),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: List.generate(
              outbound.length,
              (i) => FlSpot(i.toDouble(), outbound[i].toDouble()),
            ),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
