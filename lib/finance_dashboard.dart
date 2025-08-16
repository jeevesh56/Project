import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceDashboard extends StatefulWidget {
  final String userId;
  final String userName;

  const FinanceDashboard({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard> {
  double balance = 0, income = 0, expenses = 0, savings = 0;
  List<Map<String, dynamic>> expenseData = [];
  List<Map<String, dynamic>> trendData = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, String>> aiInsights = [];

  bool loading = true;
  DatabaseReference? _databaseRef;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  void _initializeDatabase() {
    try {
      // Use default app instance without repeatedly passing URLs
      _databaseRef = FirebaseDatabase.instance.ref();
      fetchDashboardData();
    } catch (e) {
      debugPrint("Database initialization error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() => loading = true);
      
      // Get transactions from Realtime Database
      if (_databaseRef == null) {
        setState(() => loading = false);
        return;
      }
      
      final txSnapshot = await _databaseRef!
          .child('users')
          .child(widget.userId)
          .child('transactions')
          .get();

      List<Map<String, dynamic>> txList = [];
      
      if (txSnapshot.exists) {
        final Map<dynamic, dynamic>? data = txSnapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              txList.add(Map<String, dynamic>.from(value));
            }
          });
        }
      }

      // Sort by date (newest first)
      txList.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date'] ?? '');
        DateTime dateB = DateTime.parse(b['date'] ?? '');
        return dateB.compareTo(dateA);
      });

      double totalIncome = 0, totalExpenses = 0;
      Map<String, double> categoryMap = {};
      Map<String, double> monthlyMap = {};

      for (var tx in txList) {
        double amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        String category = tx['category'] ?? 'Other';
        DateTime date = DateTime.parse(tx['date'] ?? DateTime.now().toIso8601String());
        String month = "${date.month}/${date.year}";

        if (amt > 0) {
          totalIncome += amt;
        } else {
          totalExpenses += amt.abs();
        }

        categoryMap[category] = (categoryMap[category] ?? 0) + amt.abs();
        monthlyMap[month] = (monthlyMap[month] ?? 0) + (amt < 0 ? amt.abs() : 0);
      }

      setState(() {
        income = totalIncome;
        expenses = totalExpenses;
        balance = totalIncome - totalExpenses;
        savings = balance * 0.3; // Example saving logic

        expenseData = categoryMap.entries
            .map((e) => {"category": e.key, "value": e.value})
            .toList();

        trendData = monthlyMap.entries
            .map((e) => {"month": e.key, "spent": e.value})
            .toList();

        transactions = txList.map((tx) => {
              "date": DateTime.parse(tx['date'] ?? DateTime.now().toIso8601String()),
              "desc": tx['desc'] ?? "",
              "category": tx['category'] ?? "",
              "amount": (tx['amount'] as num?)?.toDouble() ?? 0.0,
            }).toList();

        aiInsights = [
          {
            "title": "Spending Alert",
            "detail": "Food spending up 15% vs last month. Try reducing takeout."
          },
          {
            "title": "Savings Tip",
            "detail": "Move \$${savings.toStringAsFixed(0)} to savings for better financial health."
          }
        ];

        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
      // If it's just a missing transactions collection, that's fine
      if (e.toString().contains('index-not-defined') || e.toString().contains('permission-denied')) {
        // User exists but no transactions yet - this is normal
        setState(() {
          loading = false;
          // Keep default values (all zeros)
        });
      } else {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your financial data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mo-Mo",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Welcome, ${widget.userName}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate back to login page
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 16),
            _buildExpenseBreakdown(),
            const SizedBox(height: 16),
            _buildTrendChart(),
            const SizedBox(height: 16),
            _buildTransactionsList(),
            const SizedBox(height: 16),
            _buildAIInsights(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard("Balance", balance, Colors.blue),
        _summaryCard("Income", income, Colors.green),
        _summaryCard("Expenses", expenses, Colors.red),
        _summaryCard("Savings", savings, Colors.orange),
      ],
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${value.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: color,
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Expense Breakdown", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 16),
            if (expenseData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No expenses recorded yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ...expenseData.map((data) => _buildExpenseItem(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> data) {
    final category = data['category'] as String;
    final value = data['value'] as double;
    final percentage = expenses > 0 ? (value / expenses * 100) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "\$${value.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
          ),
          const SizedBox(height: 4),
          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Spending Trend", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 16),
            if (trendData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No spending data available",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: TrendChartPainter(trendData),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Transactions", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No transactions yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ...transactions.map((tx) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(tx['category']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(tx['category']),
                        color: _getCategoryColor(tx['category']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['desc'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            tx['category'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "\$${tx['amount'].toStringAsFixed(2)}",
                      style: TextStyle(
                        color: tx['amount'] < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  "AI Insights", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...aiInsights.map((ins) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ins['title'] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ins['detail'] ?? "",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Actions", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement add transaction
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Transaction feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("+ Add Transaction"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement set budget
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Set Budget feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text("Set Budget"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement AI smart scan
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Smart Scan feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.psychology),
                label: const Text("Run AI Smart Scan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      case 'health':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}

// Custom painter for the trend chart
class TrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  
  TrendChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final fillPath = Path();
    
    final width = size.width;
    final height = size.height;
    final padding = 40.0;
    final chartWidth = width - 2 * padding;
    final chartHeight = height - 2 * padding;
    
    double maxValue = 0;
    for (var item in data) {
      maxValue = maxValue < item['spent'] ? item['spent'] : maxValue;
    }
    
    if (maxValue == 0) return;
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = height - padding - (item['spent'] / maxValue) * chartHeight;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, height - padding);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(width - padding, height - padding);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = height - padding - (item['spent'] / maxValue) * chartHeight;
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
