import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class FinanceDashboard extends StatefulWidget {
  final String userId;
  final String userName;

  const FinanceDashboard({super.key, required this.userId, required this.userName});

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard>
    with TickerProviderStateMixin {
  double balance = 0, income = 0, expenses = 0, savings = 0;
  List<Map<String, dynamic>> expenseData = [];
  List<Map<String, dynamic>> trendData = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> aiInsights = [];
  List<Map<String, dynamic>> goals = [];
  List<Map<String, dynamic>> budgets = [];

  bool loading = true;
  int _selectedIndex = 0;
  DatabaseReference? _databaseRef;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDatabase();
    _generateAIInsights();
    _initializeGoals();
    _initializeBudgets();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _initializeDatabase() {
    try {
      _databaseRef = FirebaseDatabase.instance.ref();
      fetchDashboardData();
    } catch (e) {
      debugPrint("Database initialization error: $e");
      setState(() => loading = false);
    }
  }

  void _generateAIInsights() {
    aiInsights = [
      {
        'icon': FontAwesomeIcons.lightbulb,
        'title': 'Smart Spending Alert',
        'message': 'Your dining expenses are 25% higher than last month. Consider cooking at home more often.',
        'type': 'warning',
      },
      {
        'icon': FontAwesomeIcons.trophy,
        'title': 'Savings Goal Achieved!',
        'message': 'Congratulations! You\'ve reached 80% of your emergency fund goal.',
        'type': 'success',
      },
      {
        'icon': FontAwesomeIcons.chartLine,
        'title': 'Positive Trend',
        'message': 'Your income has increased by 15% this month compared to last month.',
        'type': 'info',
      },
      {
        'icon': FontAwesomeIcons.bullseye,
        'title': 'Budget Recommendation',
        'message': 'Based on your spending patterns, we recommend increasing your entertainment budget by 10%.',
        'type': 'suggestion',
      },
    ];
  }

  void _initializeGoals() {
    goals = [
      {
        'title': 'Emergency Fund',
        'target': 10000.0,
        'current': 8000.0,
        'icon': FontAwesomeIcons.shieldHalved,
        'color': Colors.blue,
      },
      {
        'title': 'Vacation Fund',
        'target': 5000.0,
        'current': 2500.0,
        'icon': FontAwesomeIcons.plane,
        'color': Colors.green,
      },
      {
        'title': 'New Car',
        'target': 25000.0,
        'current': 5000.0,
        'icon': FontAwesomeIcons.car,
        'color': Colors.orange,
      },
    ];
  }

  void _initializeBudgets() {
    budgets = [
      {
        'category': 'Food & Dining',
        'budget': 800.0,
        'spent': 650.0,
        'icon': FontAwesomeIcons.utensils,
        'color': Colors.red,
      },
      {
        'category': 'Transportation',
        'budget': 400.0,
        'spent': 320.0,
        'icon': FontAwesomeIcons.car,
        'color': Colors.blue,
      },
      {
        'category': 'Entertainment',
        'budget': 300.0,
        'spent': 280.0,
        'icon': FontAwesomeIcons.film,
        'color': Colors.purple,
      },
      {
        'category': 'Shopping',
        'budget': 500.0,
        'spent': 450.0,
        'icon': FontAwesomeIcons.shoppingBag,
        'color': Colors.pink,
      },
    ];
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() => loading = true);
      
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
        savings = balance * 0.3; // Assume 30% savings rate
        
        transactions = txList.take(10).toList();
        
        expenseData = categoryMap.entries.map((e) => {
          'category': e.key,
          'amount': e.value,
        }).toList();
        
        trendData = monthlyMap.entries.map((e) => {
          'month': e.key,
          'amount': e.value,
        }).toList();
        
        loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildTransactions();
      case 2:
        return _buildAnalytics();
      case 3:
        return _buildGoals();
      case 4:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildBalanceCard(),
          _buildQuickStats(),
          _buildAIInsights(),
          _buildRecentTransactions(),
          _buildBudgetOverview(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Balance', '\$${balance.toStringAsFixed(2)}', Icons.account_balance_wallet),
                    _buildStatItem('Income', '\$${income.toStringAsFixed(2)}', Icons.trending_up),
                    _buildStatItem('Expenses', '\$${expenses.toStringAsFixed(2)}', Icons.trending_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings: \$${savings.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+12.5%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatCard(
              'Income',
              '\$${income.toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.green,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildQuickStatCard(
              'Expenses',
              '\$${expenses.toStringAsFixed(2)}',
              Icons.trending_down,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 AI Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: aiInsights.length,
              itemBuilder: (context, index) {
                final insight = aiInsights[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getInsightColor(insight['type'] as String? ?? 'info').withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FaIcon(
                              insight['icon'] as IconData? ?? Icons.info,
                              color: _getInsightColor(insight['type'] as String? ?? 'info'),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              insight['title'] as String? ?? 'Insight',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        insight['message'] as String? ?? 'No message available.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      case 'suggestion':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentTransactions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _onItemTapped(1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.take(5).length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                final isIncome = amount > 0;
                
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome ? Icons.trending_up : Icons.trending_down,
                      color: isIncome ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction['description'] ?? 'Transaction',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    transaction['category'] ?? 'Other',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBudgetOverview() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final percentage = (budget['spent'] / budget['budget'] * 100).clamp(0.0, 100.0);
                
                return Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: budget['color'].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FaIcon(
                              budget['icon'],
                              color: budget['color'],
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  budget['category'],
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '\$${budget['spent'].toStringAsFixed(0)} / \$${budget['budget'].toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: percentage > 80 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 80 ? Colors.red : budget['color'],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          final isIncome = amount > 0;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.1),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                transaction['description'] ?? 'Transaction',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${transaction['category'] ?? 'Other'} • ${transaction['date'] ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Text(
                '${isIncome ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalytics() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAnalyticsCard('Spending by Category', expenseData),
            const SizedBox(height: 20),
            _buildAnalyticsCard('Monthly Trends', trendData),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ...data.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(item['category'] ?? item['month'] ?? 'Unknown'),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: (item['amount'] as double) / data.fold(0.0, (sum, e) => sum + (e['amount'] as double)),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '\$${(item['amount'] as double).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildGoals() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Financial Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...goals.map((goal) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: goal['color'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: FaIcon(
                          goal['icon'],
                          color: goal['color'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${goal['current'].toStringAsFixed(0)} / \$${goal['target'].toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${((goal['current'] / goal['target']) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: goal['color'],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: (goal['current'] / goal['target']).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(goal['color']),
                    minHeight: 8,
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Financial Tracker',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileOption(Icons.settings, 'Settings', () {}),
            _buildProfileOption(Icons.security, 'Security', () {}),
            _buildProfileOption(Icons.help, 'Help & Support', () {}),
            _buildProfileOption(Icons.info, 'About', () {}),
            _buildProfileOption(Icons.logout, 'Logout', () {
              FirebaseAuth.instance.signOut();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
