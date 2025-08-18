import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/manual_transaction_entry_screen.dart';
import 'screens/currency_selection_screen.dart';
import 'ocr_scanner_screen.dart';

class EnhancedDashboard extends StatefulWidget {
  final String userId;
  final String userName;

  const EnhancedDashboard({super.key, required this.userId, required this.userName});

  @override
  State<EnhancedDashboard> createState() => _EnhancedDashboardState();
}

class _EnhancedDashboardState extends State<EnhancedDashboard>
    with TickerProviderStateMixin {
  double balance = 0, income = 0, expenses = 0, savings = 0;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> aiInsights = [];
  List<Map<String, dynamic>> goals = [];
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> categories = [];

  bool loading = true;
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  DatabaseReference? _databaseRef;
  
  // Voice recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Chatbot
  List<Map<String, dynamic>> chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDatabase();
    _initializeSpeech();
    _generateAIInsights();
    _initializeGoals();
    _initializeBudgets();
    _initializeCategories();
    _initializeChatbot();
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

    _slideController.forward();
    _pulseController.repeat(reverse: true);
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

  void _initializeSpeech() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _speechEnabled = true;
      });
    }
  }

  void _initializeCategories() {
    categories = [
      {'name': 'Food & Dining', 'icon': FontAwesomeIcons.utensils, 'color': Colors.red, 'budget': 800.0, 'spent': 0.0},
      {'name': 'Transportation', 'icon': FontAwesomeIcons.car, 'color': Colors.blue, 'budget': 400.0, 'spent': 0.0},
      {'name': 'Medicine', 'icon': FontAwesomeIcons.pills, 'color': Colors.green, 'budget': 300.0, 'spent': 0.0},
      {'name': 'Entertainment', 'icon': FontAwesomeIcons.film, 'color': Colors.purple, 'budget': 500.0, 'spent': 0.0},
      {'name': 'Shopping', 'icon': FontAwesomeIcons.shoppingBag, 'color': Colors.orange, 'budget': 600.0, 'spent': 0.0},
      {'name': 'Utilities', 'icon': FontAwesomeIcons.bolt, 'color': Colors.yellow, 'budget': 350.0, 'spent': 0.0},
      {'name': 'Education', 'icon': FontAwesomeIcons.graduationCap, 'color': Colors.indigo, 'budget': 400.0, 'spent': 0.0},
      {'name': 'Other', 'icon': FontAwesomeIcons.ellipsis, 'color': Colors.grey, 'budget': 200.0, 'spent': 0.0},
    ];
  }

  void _initializeChatbot() {
    chatMessages = [
      {
        'message': 'Hello! I\'m your AI financial assistant. I can help you track expenses, set budgets, and answer questions about your finances. Try saying "I spent 50 dollars on food" or ask me anything!',
        'isUser': false,
        'timestamp': DateTime.now(),
      }
    ];
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

      double totalIncome = 0, totalExpenses = 0;

      for (var tx in txList) {
        double amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        if (amt > 0) {
          totalIncome += amt;
        } else {
          totalExpenses += amt.abs();
        }
      }

      setState(() {
        income = totalIncome;
        expenses = totalExpenses;
        balance = totalIncome - totalExpenses;
        savings = balance * 0.3;
        transactions = txList.take(10).toList();
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
    _chatController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Ensure index is within valid range (0-4 for 5 navigation items)
    if (index >= 0 && index < 5) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: _buildProfile(),
          ),
        ),
      ),
    );
  }

  // Helper method to get the correct screen based on index
  Widget _getScreenByIndex(int index) {
    switch (index) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildTransactions();
      case 2:
        return _buildAnalytics();
      case 3:
        return _buildGoals();
      case 4:
        return _buildChatbot();
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManualTransactionEntryScreen(
                userId: widget.userId,
                onTransactionAdded: () {
                  fetchDashboardData();
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildBody() {
    return _getScreenByIndex(_selectedIndex);
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildBalanceCard(),
          _buildOCRScannerButton(),
          _buildQuickStats(),
          _buildAIInsights(),
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
                                  // Profile icon on the left
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Don't use bottom nav index for profile
                      // Show profile directly instead
                      _showProfile();
                    });
                  },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Welcome text in center
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
                  // Transactions icon on the right
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1; // Transactions index
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 24,
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
              color: Colors.green.withOpacity(0.3),
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

  Widget _buildOCRScannerButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OCRScannerScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.8),
                Colors.purple.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.document_scanner,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "OCR Scanner",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Scan receipts & extract text",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
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
            color: Colors.grey.withOpacity(0.1),
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
                        color: Colors.grey.withOpacity(0.1),
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
      default:
        return Colors.grey;
    }
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
                  color: Colors.grey.withOpacity(0.1),
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
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
                      IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualTransactionEntryScreen(
                      userId: widget.userId,
                      onTransactionAdded: () {
                        fetchDashboardData();
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add your first transaction to get started',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManualTransactionEntryScreen(
                            userId: widget.userId,
                            onTransactionAdded: () {
                              fetchDashboardData();
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
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
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsCard(
              '📊 Spending Overview',
              'This month you\'ve spent \$${expenses.toStringAsFixed(2)} out of your total income of \$${income.toStringAsFixed(2)}.',
              Icons.pie_chart,
              Colors.blue,
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard(
              '💰 Savings Rate',
              'You\'re saving ${((savings / (income > 0 ? income : 1)) * 100).toStringAsFixed(1)}% of your income. ${savings > income * 0.2 ? 'Excellent!' : 'Consider increasing your savings rate.'}',
              Icons.savings,
              Colors.green,
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard(
              '📈 Financial Health Score',
              _getFinancialHealthScore(),
              Icons.health_and_safety,
              _getFinancialHealthColor(),
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard(
              '🎯 Goal Progress',
              'You\'re ${((goals.isNotEmpty ? (goals[0]['current'] as double) / (goals[0]['target'] as double) * 100 : 0)).toStringAsFixed(1)}% towards your ${goals.isNotEmpty ? goals[0]['title'] : 'financial'} goal.',
              Icons.flag,
              Colors.orange,
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard(
              '📅 Monthly Trend',
              _getMonthlyTrend(),
              Icons.trending_up,
              Colors.purple,
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard(
              '💡 Smart Insights',
              _getSmartInsights(),
              Icons.lightbulb,
              Colors.yellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String content, IconData icon, Color color) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getFinancialHealthScore() {
    double score = 0;
    
    // Balance factor (30%)
    if (balance > 0) {
      score += 30;
    } else if (balance > -income * 0.2) {
      score += 15;
    }
    
    // Savings rate factor (25%)
    double savingsRate = (savings / (income > 0 ? income : 1)) * 100;
    if (savingsRate >= 20) {
      score += 25;
    } else if (savingsRate >= 10) {
      score += 15;
    } else if (savingsRate >= 5) {
      score += 10;
    }
    
    // Expense ratio factor (25%)
    double expenseRatio = income > 0 ? expenses / income : 1;
    if (expenseRatio <= 0.6) {
      score += 25;
    } else if (expenseRatio <= 0.8) {
      score += 15;
    } else if (expenseRatio <= 1.0) {
      score += 10;
    }
    
    // Goal progress factor (20%)
    if (goals.isNotEmpty) {
      double goalProgress = (goals[0]['current'] as double) / (goals[0]['target'] as double) * 100;
      if (goalProgress >= 80) {
        score += 20;
      } else if (goalProgress >= 50) {
        score += 15;
      } else if (goalProgress >= 20) {
        score += 10;
      }
    }
    
    if (score >= 80) return 'Excellent (${score.toStringAsFixed(0)}/100) - Keep up the great work!';
    if (score >= 60) return 'Good (${score.toStringAsFixed(0)}/100) - You\'re on the right track.';
    if (score >= 40) return 'Fair (${score.toStringAsFixed(0)}/100) - Room for improvement.';
    return 'Needs Attention (${score.toStringAsFixed(0)}/100) - Focus on reducing expenses and increasing savings.';
  }

  Color _getFinancialHealthColor() {
    double score = 0;
    
    // Simplified score calculation
    if (balance > 0) score += 30;
    double savingsRate = (savings / (income > 0 ? income : 1)) * 100;
    if (savingsRate >= 20) score += 25;
    double expenseRatio = income > 0 ? expenses / income : 1;
    if (expenseRatio <= 0.6) score += 25;
    
    if (score >= 60) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getMonthlyTrend() {
    if (income == 0) return 'No income data available for trend analysis.';
    
    double savingsRate = (savings / income) * 100;
    double expenseRatio = expenses / income;
    
    if (savingsRate > 20 && expenseRatio < 0.7) {
      return 'Strong upward trend! Your savings rate is excellent and expenses are well-controlled.';
    } else if (savingsRate > 10 && expenseRatio < 0.8) {
      return 'Positive trend. You\'re building savings and managing expenses reasonably well.';
    } else if (savingsRate > 5 && expenseRatio < 0.9) {
      return 'Stable trend. Consider increasing your savings rate for better financial growth.';
    } else {
      return 'Needs attention. Focus on reducing expenses and increasing your savings rate.';
    }
  }

  String _getSmartInsights() {
    List<String> insights = [];
    
    if (expenses > income * 0.8) {
      insights.add('Your expenses are high relative to income. Consider reducing non-essential spending.');
    }
    
    if (savings < income * 0.1) {
      insights.add('Your savings rate is below the recommended 10%. Try to save more.');
    }
    
    if (balance < 0) {
      insights.add('You have negative balance. Focus on reducing expenses and increasing income.');
    }
    
    if (goals.isNotEmpty) {
      double goalProgress = (goals[0]['current'] as double) / (goals[0]['target'] as double) * 100;
      if (goalProgress < 50) {
        insights.add('Your goal progress is slow. Consider increasing your monthly contribution.');
      }
    }
    
    if (insights.isEmpty) {
      insights.add('Great job! Your financial habits are on track. Keep up the good work!');
    }
    
    return insights.take(3).join(' ');
  }

  Widget _buildGoals() {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
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
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChatbot() {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chatbot'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                return Align(
                  alignment: message['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message['isUser'] ? Colors.blue[200] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message['message'] as String,
                      style: TextStyle(
                        color: message['isUser'] ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                if (_speechEnabled)
                  IconButton(
                    onPressed: () async {
                      if (_isListening) {
                        await _speechToText.stop();
                        setState(() {
                          _isListening = false;
                          _lastWords = '';
                        });
                      } else {
                        await _requestSpeechPermission();
                        if (_speechEnabled) {
                          await _speechToText.listen(
                            onResult: (result) {
                              setState(() {
                                _lastWords = result.recognizedWords;
                                if (_lastWords.isNotEmpty) {
                                  _sendMessage(_lastWords);
                                }
                              });
                            },
                          );
                          setState(() {
                            _isListening = true;
                          });
                        }
                      }
                    },
                    icon: Icon(
                      _isListening ? FontAwesomeIcons.microphoneSlash : FontAwesomeIcons.microphone,
                      color: _isListening ? Colors.red : Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestSpeechPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _speechEnabled = true;
      });
    } else {
      debugPrint('Microphone permission not granted');
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  void _sendMessage(String text) {
    setState(() {
      _chatController.clear();
      chatMessages.add({
        'message': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    // Process the message and generate AI response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        String response = _processUserMessage(text);
        chatMessages.add({
          'message': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    });
  }

  String _processUserMessage(String message) {
    message = message.toLowerCase();
    
    // Check for budget adjustment commands
    if (message.contains('add') && message.contains('budget') || 
        message.contains('increase') && message.contains('budget') ||
        message.contains('set') && message.contains('budget')) {
      return _processBudgetAdjustmentCommand(message, true);
    }
    
    if (message.contains('remove') && message.contains('budget') || 
        message.contains('decrease') && message.contains('budget') ||
        message.contains('reduce') && message.contains('budget')) {
      return _processBudgetAdjustmentCommand(message, false);
    }
    
    // Check for expense adjustment commands
    if (message.contains('remove') && message.contains('expense') || 
        message.contains('delete') && message.contains('expense') ||
        message.contains('cancel') && message.contains('expense')) {
      return _processExpenseRemovalCommand(message);
    }
    
    // Check for transaction commands
    if (message.contains('spent') || message.contains('expense') || message.contains('paid')) {
      return _processTransactionCommand(message);
    }
    
    // Check for income commands
    if (message.contains('earned') || message.contains('income') || message.contains('received') ||
        message.contains('add') && message.contains('income')) {
      return _processIncomeCommand(message);
    }
    
    // Check for balance inquiries
    if (message.contains('balance') || message.contains('how much') || message.contains('total')) {
      return 'Your current balance is \$${balance.toStringAsFixed(2)}. Your total income is \$${income.toStringAsFixed(2)} and total expenses are \$${expenses.toStringAsFixed(2)}.';
    }
    
    // Check for budget inquiries
    if (message.contains('budget') || message.contains('spending')) {
      return 'You have spent \$${expenses.toStringAsFixed(2)} out of your budget. I recommend tracking your expenses by category to better manage your spending.';
    }
    
    // Check for savings inquiries
    if (message.contains('savings') || message.contains('save')) {
      return 'Your current savings are \$${savings.toStringAsFixed(2)}. That\'s ${((savings / (income > 0 ? income : 1)) * 100).toStringAsFixed(1)}% of your income. Great job!';
    }
    
    // Check for category inquiries
    if (message.contains('category') || message.contains('categories')) {
      return _getCategorySummary();
    }
    
    // Check for goal inquiries
    if (message.contains('goal') || message.contains('goals')) {
      return _getGoalSummary();
    }
    
    // Check for financial advice
    if (message.contains('advice') || message.contains('tip') || message.contains('suggestion')) {
      return _getFinancialAdvice();
    }
    
    // Check for transaction history
    if (message.contains('history') || message.contains('transactions') || message.contains('list')) {
      return _getTransactionSummary();
    }
    
    // Check for weather-like financial status
    if (message.contains('weather') || message.contains('forecast') || message.contains('outlook')) {
      return _getFinancialForecast();
    }
    
    // Default response with suggestions
    return 'I understand you said: "$message". I can help you with:\n\n' '💰 Track expenses: "I spent 50 dollars on food"\n' '💵 Add income: "I earned 1000 dollars"\n' '📊 Check balance: "What\'s my balance?"\n' '🎯 Manage budget: "Add 100 to my budget"\n' +
           '🗑️ Remove expenses: "Remove 20 from expenses"\n' +
           '📈 Get advice: "Give me financial advice"\n' +
           '🌤️ Financial forecast: "What\'s my financial weather?"\n\n' +
           'Try any of these commands!';
  }

  String _processTransactionCommand(String message) {
    // Extract amount
    RegExp amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    Match? amountMatch = amountRegex.firstMatch(message);
    
    if (amountMatch != null) {
      double amount = double.parse(amountMatch.group(1)!);
      
      // Extract category
      String category = 'Other';
      for (var cat in categories) {
        if (message.contains(cat['name'].toString().toLowerCase())) {
          category = cat['name'];
          break;
        }
      }
      
      // Add transaction
      _addTransaction(-amount, category, 'Voice transaction');
      
      return 'I\'ve recorded an expense of \$${amount.toStringAsFixed(2)} for $category. Your new balance is \$${(balance - amount).toStringAsFixed(2)}.';
    }
    
    return 'I couldn\'t understand the amount. Please try saying something like "I spent 50 dollars on food".';
  }

  String _processIncomeCommand(String message) {
    // Extract amount
    RegExp amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    Match? amountMatch = amountRegex.firstMatch(message);
    
    if (amountMatch != null) {
      double amount = double.parse(amountMatch.group(1)!);
      
      // Extract description from message
      String description = message;
      description = description.replaceAll(amountMatch.group(1)!, '').trim();
          
      // Remove common income words to get the actual description
      List<String> incomeWords = ['earned', 'income', 'received', 'add', 'dollars', 'dollar'];
      for (String word in incomeWords) {
        description = description.replaceAll(word, '').trim();
      }
      
      if (description.isEmpty) {
        description = 'Voice income';
      }
      
      // Add transaction without category for income
      _addTransaction(amount, 'Income', description);
      
      return 'I\'ve recorded income of \$${amount.toStringAsFixed(2)} for "$description". Your new balance is \$${(balance + amount).toStringAsFixed(2)}.';
    }
    
    return 'I couldn\'t understand the amount. Please try saying something like "I earned 1000 dollars" or "Add 500 to income".';
  }

  void _addTransaction(double amount, String category, String description) {
    final transaction = {
      'amount': amount,
      'description': description,
      'category': category,
      'date': DateTime.now().toIso8601String(),
      'type': amount > 0 ? 'income' : 'expense',
    };

    _databaseRef?.child('users')
        .child(widget.userId)
        .child('transactions')
        .push()
        .set(transaction);

    // Update local state
    setState(() {
      if (amount > 0) {
        income += amount;
      } else {
        expenses += amount.abs();
      }
      balance = income - expenses;
      savings = balance * 0.3;
    });
  }

  String _processBudgetAdjustmentCommand(String message, bool isAdding) {
    RegExp amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    Match? amountMatch = amountRegex.firstMatch(message);
    
    if (amountMatch != null) {
      double amount = double.parse(amountMatch.group(1)!);
      
      // Update budget (for now, we'll update the first budget category)
      if (budgets.isNotEmpty) {
        setState(() {
          if (isAdding) {
            budgets[0]['budget'] = (budgets[0]['budget'] as double) + amount;
          } else {
            budgets[0]['budget'] = (budgets[0]['budget'] as double) - amount;
          }
        });
        
        String action = isAdding ? 'increased' : 'decreased';
        return 'I\'ve $action your budget by \$${amount.toStringAsFixed(2)}. Your new budget is \$${(budgets[0]['budget'] as double).toStringAsFixed(2)}.';
      }
    }
    
    return 'I couldn\'t understand the amount. Please try saying something like "Add 100 to my budget" or "Remove 50 from my budget".';
  }

  String _processExpenseRemovalCommand(String message) {
    RegExp amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    Match? amountMatch = amountRegex.firstMatch(message);
    
    if (amountMatch != null) {
      double amount = double.parse(amountMatch.group(1)!);
      
      // For now, we'll simulate removing from expenses
      if (expenses >= amount) {
        setState(() {
          expenses -= amount;
          balance = income - expenses;
          savings = balance * 0.3;
        });
        
        return 'I\'ve removed \$${amount.toStringAsFixed(2)} from your expenses. Your new balance is \$${balance.toStringAsFixed(2)}.';
      } else {
        return 'You don\'t have enough expenses to remove \$${amount.toStringAsFixed(2)}. Your current expenses are \$${expenses.toStringAsFixed(2)}.';
      }
    }
    
    return 'I couldn\'t understand the amount. Please try saying something like "Remove 20 from expenses".';
  }

  String _getCategorySummary() {
    if (categories.isEmpty) return 'No categories found.';
    
    String summary = '📊 Your spending categories:\n\n';
    for (var category in categories) {
      double spent = category['spent'] as double;
      double budget = category['budget'] as double;
      double percentage = budget > 0 ? (spent / budget * 100) : 0;
      
      summary += '${category['name']}: \$${spent.toStringAsFixed(2)} / \$${budget.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)\n';
    }
    
    return summary;
  }

  String _getGoalSummary() {
    if (goals.isEmpty) return 'No financial goals set yet.';
    
    String summary = '🎯 Your financial goals:\n\n';
    for (var goal in goals) {
      double current = goal['current'] as double;
      double target = goal['target'] as double;
      double percentage = (current / target * 100);
      
      summary += '${goal['title']}: \$${current.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)\n';
    }
    
    return summary;
  }

  String _getFinancialAdvice() {
    List<String> advice = [
      '💡 Save 20% of your income for emergencies',
      '📈 Invest in diversified assets for long-term growth',
      '🎯 Set specific, measurable financial goals',
      '📊 Track your spending to identify patterns',
      '💰 Pay yourself first before other expenses',
      '🏠 Consider building equity through homeownership',
      '📚 Continuously educate yourself about personal finance',
      '🔄 Automate your savings and bill payments',
      '🎪 Live below your means to build wealth',
      '📱 Use apps like this one to stay on track!'
    ];
    
    // Random advice based on current financial situation
    if (expenses > income * 0.8) {
      advice.insert(0, '⚠️ Your expenses are high relative to income. Consider reducing non-essential spending.');
    }
    
    if (savings < income * 0.1) {
      advice.insert(0, '💸 Your savings rate is low. Try to save at least 10% of your income.');
    }
    
    if (balance < 0) {
      advice.insert(0, '🚨 You have negative balance. Focus on reducing expenses and increasing income.');
    }
    
    return 'Here\'s some financial advice for you:\n\n${advice.take(5).join('\n')}';
  }

  String _getTransactionSummary() {
    if (transactions.isEmpty) return 'No transactions found.';
    
    String summary = '📋 Recent transactions:\n\n';
    for (int i = 0; i < transactions.take(5).length; i++) {
      var transaction = transactions[i];
      double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      String description = transaction['description'] ?? 'Transaction';
      String category = transaction['category'] ?? 'Other';
      
      summary += '${amount > 0 ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)} - $description ($category)\n';
    }
    
    return summary;
  }

  String _getFinancialForecast() {
    String weather = '';
    String forecast = '';
    
    if (balance > 0 && expenses < income * 0.6) {
      weather = '☀️ Sunny';
      forecast = 'Excellent financial health! Keep up the good work.';
    } else if (balance > 0 && expenses < income * 0.8) {
      weather = '⛅ Partly Cloudy';
      forecast = 'Good financial health, but watch your spending.';
    } else if (balance > 0) {
      weather = '🌤️ Cloudy';
      forecast = 'Moderate financial health. Consider reducing expenses.';
    } else if (balance > -income * 0.2) {
      weather = '🌧️ Rainy';
      forecast = 'Financial health needs attention. Focus on reducing expenses.';
    } else {
      weather = '⛈️ Stormy';
      forecast = 'Critical financial situation. Immediate action needed.';
    }
    
    return '🌤️ Financial Weather Report:\n\n' 'Current: $weather\n' 'Forecast: $forecast\n\n' 'Balance: \$${balance.toStringAsFixed(2)}\n' 'Income: \$${income.toStringAsFixed(2)}\n' +
           'Expenses: \$${expenses.toStringAsFixed(2)}';
  }

  Widget _buildProfile() {
    return Container(
      color: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.purple[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 0; // Go back to dashboard
                          });
                        },
                      ),
                      const Spacer(),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileOption(Icons.settings, 'Settings', () {}),
                  _buildProfileOption(Icons.currency_exchange, 'Change Currency', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CurrencySelectionScreen(),
                      ),
                    );
                  }),
                  _buildProfileOption(Icons.security, 'Security', () {}),
                  _buildProfileOption(Icons.help, 'Help & Support', () {}),
                  _buildProfileOption(Icons.info, 'About', () {}),
                  _buildDarkModeToggle(),
                  _buildProfileOption(Icons.logout, 'Logout', () {
                    FirebaseAuth.instance.signOut();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
        title: Text(
          title,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
        leading: Icon(
          _isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: _isDarkMode ? Colors.amber : Colors.blue,
        ),
        title: Text(
          'Dark Mode',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: Switch(
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
          },
          activeColor: Colors.amber,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
          unselectedItemColor: Colors.grey[600],
          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
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
            icon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
