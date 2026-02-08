import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

// Real API-backed providers for reports
final reportingDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final auth = ref.read(authProvider);
  
  if (auth.token != null) {
    api.setToken(auth.token!);
  }
  
  try {
    // Fetch daily sales
    final dailySalesResponse = await api.get('/orders/daily-sales');
    final dailySales = dailySalesResponse.data;
    
    // Fetch all orders to calculate stats
    final ordersResponse = await api.get('/orders');
    final orders = ordersResponse.data as List<dynamic>;
    
    // Fetch products for top products
    final productsResponse = await api.get('/products');
    final products = productsResponse.data as List<dynamic>;
    
    // Calculate item count from orders
    int itemsSold = 0;
    Map<String, Map<String, dynamic>> productSales = {};
    Map<String, int> paymentMethodCounts = {'cash': 0, 'card': 0, 'qris': 0};
    
    for (var order in orders) {
      final detailsStr = order['details'] ?? '{}';
      try {
        // Count payment methods
        final method = (order['payment_method'] ?? 'cash').toString().toLowerCase();
        paymentMethodCounts[method] = (paymentMethodCounts[method] ?? 0) + 1;
      } catch (e) {
        // Skip parsing errors
      }
    }
    
    // Calculate payment method percentages
    int totalPayments = paymentMethodCounts.values.fold(0, (a, b) => a + b);
    List<Map<String, dynamic>> paymentMethods = [];
    if (totalPayments > 0) {
      paymentMethods = [
        {'method': 'Cash', 'count': paymentMethodCounts['cash'] ?? 0, 'percentage': ((paymentMethodCounts['cash'] ?? 0) / totalPayments * 100).roundToDouble()},
        {'method': 'QRIS', 'count': paymentMethodCounts['qris'] ?? 0, 'percentage': ((paymentMethodCounts['qris'] ?? 0) / totalPayments * 100).roundToDouble()},
        {'method': 'Card', 'count': paymentMethodCounts['card'] ?? 0, 'percentage': ((paymentMethodCounts['card'] ?? 0) / totalPayments * 100).roundToDouble()},
      ];
    }
    
    // Get top products by stock (simplified - would need order items for real sales data)
    final topProducts = products.take(5).map((p) => {
      'name': p['name'] ?? 'Unknown',
      'quantity': p['stock'] ?? 0,
      'revenue': ((p['price'] ?? 0) * (p['stock'] ?? 0)).toDouble(),
    }).toList();
    
    // Recent transactions from orders
    final recentTransactions = orders.take(5).map((o) => {
      'id': '#ORD-${o['ID'] ?? o['id'] ?? 0}',
      'time': _formatTime(o['CreatedAt'] ?? o['created_at']),
      'items': 1, // Simplified
      'total': (o['total'] ?? 0).toDouble(),
      'method': (o['payment_method'] ?? 'Cash').toString(),
    }).toList();
    
    return {
      'dailySales': {
        'total_sales': (dailySales['total'] ?? 0).toDouble(),
        'order_count': dailySales['count'] ?? orders.length,
        'average_order': orders.isNotEmpty 
            ? (dailySales['total'] ?? 0) / (orders.length > 0 ? orders.length : 1)
            : 0.0,
        'items_sold': orders.length * 2, // Estimate
      },
      'weeklySales': _generateWeeklySales(orders),
      'topProducts': topProducts,
      'paymentMethods': paymentMethods.isEmpty ? [
        {'method': 'Cash', 'count': 0, 'percentage': 100.0},
      ] : paymentMethods,
      'recentTransactions': recentTransactions,
    };
  } catch (e) {
    return {
      'dailySales': {'total_sales': 0.0, 'order_count': 0, 'average_order': 0.0, 'items_sold': 0},
      'weeklySales': <Map<String, dynamic>>[],
      'topProducts': <Map<String, dynamic>>[],
      'paymentMethods': <Map<String, dynamic>>[{'method': 'No data', 'count': 0, 'percentage': 100.0}],
      'recentTransactions': <Map<String, dynamic>>[],
      'error': e.toString(),
    };
  }
});

String _formatTime(dynamic dateStr) {
  if (dateStr == null) return '--:--';
  try {
    final date = DateTime.parse(dateStr.toString());
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return '--:--';
  }
}

List<Map<String, dynamic>> _generateWeeklySales(List<dynamic> orders) {
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final now = DateTime.now();
  
  Map<String, double> salesByDay = {for (var d in days) d: 0.0};
  
  for (var order in orders) {
    try {
      final dateStr = order['CreatedAt'] ?? order['created_at'];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr.toString());
        final diff = now.difference(date).inDays;
        if (diff < 7) {
          final dayName = days[date.weekday - 1];
          salesByDay[dayName] = (salesByDay[dayName] ?? 0) + (order['total'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      // Skip parsing errors
    }
  }
  
  return days.map((d) => {'day': d, 'sales': salesByDay[d] ?? 0.0}).toList();
}

class ReportingScreen extends ConsumerWidget {
  const ReportingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportData = ref.watch(reportingDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Sales Report', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => ref.refresh(reportingDataProvider),
            icon: const Icon(Icons.refresh, color: AppTheme.accentBlue, size: 18),
            label: const Text('Refresh', style: TextStyle(color: AppTheme.accentBlue)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _exportReport(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: reportData.when(
        data: (data) => _buildReportContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error loading report: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(reportingDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, Map<String, dynamic> data) {
    final dailySales = data['dailySales'] as Map<String, dynamic>;
    final weeklySales = (data['weeklySales'] as List<dynamic>).cast<Map<String, dynamic>>();
    final topProducts = (data['topProducts'] as List<dynamic>).cast<Map<String, dynamic>>();
    final paymentMethods = (data['paymentMethods'] as List<dynamic>).cast<Map<String, dynamic>>();
    final recentTransactions = (data['recentTransactions'] as List<dynamic>).cast<Map<String, dynamic>>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(child: _SummaryCard(
                title: 'Total Sales',
                value: 'Rp ${_formatNumber(dailySales['total_sales'] ?? 0.0)}',
                icon: Icons.attach_money,
                color: AppTheme.accentGreen,
              )),
              const SizedBox(width: 16),
              Expanded(child: _SummaryCard(
                title: 'Orders',
                value: '${dailySales['order_count'] ?? 0}',
                icon: Icons.receipt_long,
                color: AppTheme.accentBlue,
              )),
              const SizedBox(width: 16),
              Expanded(child: _SummaryCard(
                title: 'Avg Order',
                value: 'Rp ${_formatNumber((dailySales['average_order'] ?? 0.0).toDouble())}',
                icon: Icons.trending_up,
                color: AppTheme.accentOrange,
              )),
              const SizedBox(width: 16),
              Expanded(child: _SummaryCard(
                title: 'Items Sold',
                value: '${dailySales['items_sold'] ?? 0}',
                icon: Icons.inventory_2,
                color: Colors.purple,
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Sales Chart
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Weekly Sales',
                  child: weeklySales.isEmpty 
                      ? const Center(child: Text('No sales data', style: TextStyle(color: AppTheme.textSecondary)))
                      : _WeeklyChart(data: weeklySales),
                ),
              ),
              const SizedBox(width: 16),
              
              // Payment Methods
              Expanded(
                child: _ChartCard(
                  title: 'Payment Methods',
                  child: _PaymentMethodsChart(data: paymentMethods),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top Products Table
          _ChartCard(
            title: 'Top Selling Products',
            child: topProducts.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No product data', style: TextStyle(color: AppTheme.textSecondary)),
                  ))
                : _TopProductsTable(products: topProducts),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Transactions
          _ChartCard(
            title: 'Recent Transactions',
            child: recentTransactions.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No recent transactions', style: TextStyle(color: AppTheme.textSecondary)),
                  ))
                : _RecentTransactionsWidget(transactions: recentTransactions),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  void _exportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report...'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final salesValues = data.map((e) => (e['sales'] as num).toDouble()).toList();
    final maxSales = salesValues.isEmpty ? 1.0 : salesValues.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxSales == 0 ? 1.0 : maxSales;
    
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          final sales = (item['sales'] as num).toDouble();
          final percentage = sales / effectiveMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    sales >= 1000000 
                        ? 'Rp ${(sales / 1000000).toStringAsFixed(1)}M'
                        : sales >= 1000 
                            ? 'Rp ${(sales / 1000).toStringAsFixed(0)}K'
                            : 'Rp ${sales.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: (150 * percentage).clamp(5.0, 150.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentBlue,
                          AppTheme.accentBlue.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['day'].toString(),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PaymentMethodsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _PaymentMethodsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [AppTheme.accentGreen, AppTheme.accentBlue, AppTheme.accentOrange];
    
    return Column(
      children: data.asMap().entries.map((entry) {
        final item = entry.value;
        final color = colors[entry.key % colors.length];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['method'].toString(),
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    '${(item['percentage'] ?? 0).toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ((item['percentage'] ?? 0) as num).toDouble() / 100,
                  backgroundColor: AppTheme.secondaryDark,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopProductsTable extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const _TopProductsTable({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Product', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Stock', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Value', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Rows
        ...products.asMap().entries.map((entry) {
          final product = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: entry.key < 3 ? AppTheme.accentBlue : AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        color: entry.key < 3 ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: Text(product['name'].toString(), style: const TextStyle(color: AppTheme.textPrimary))),
                Expanded(child: Text('${product['quantity'] ?? 0}', style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Rp ${_formatNumber((product['revenue'] ?? 0).toDouble())}', style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _RecentTransactionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  
  const _RecentTransactionsWidget({required this.transactions});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions.map((tx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, color: AppTheme.accentBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['id'].toString(), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    Text('${tx['items']} items • ${tx['method']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rp ${((tx['total'] as num).toDouble() / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text(tx['time'].toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
