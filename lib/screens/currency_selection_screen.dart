import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? selectedCurrency;
  final List<Map<String, dynamic>> currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'icon': Icons.attach_money, 'color': Colors.green},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'icon': Icons.euro_symbol, 'color': Colors.blue},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'icon': Icons.currency_pound, 'color': Colors.purple},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'icon': Icons.currency_yen, 'color': Colors.red},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$', 'icon': Icons.attach_money, 'color': Colors.orange},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'icon': Icons.attach_money, 'color': Colors.amber},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF', 'icon': Icons.currency_franc, 'color': Colors.indigo},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'icon': Icons.currency_yen, 'color': Colors.deepOrange},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'icon': Icons.currency_rupee, 'color': Colors.teal},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$', 'icon': Icons.attach_money, 'color': Colors.lime},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩', 'icon': Icons.currency_yen, 'color': Colors.cyan},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$', 'icon': Icons.attach_money, 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Select Currency',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
              ),

              // Description
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Choose your preferred currency for tracking expenses and income',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Currency Grid
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: currencies.length,
                          itemBuilder: (context, index) {
                            final currency = currencies[index];
                            final isSelected = selectedCurrency == currency['code'];
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCurrency = currency['code'];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? currency['color'].withValues(alpha: 0.1)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected 
                                        ? currency['color']
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: currency['color'].withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ] : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Currency Icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? currency['color']
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: isSelected ? [
                                          BoxShadow(
                                            color: currency['color'].withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ] : null,
                                      ),
                                      child: Icon(
                                        currency['icon'],
                                        color: isSelected 
                                            ? Colors.white
                                            : Colors.grey[700],
                                        size: 28,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Currency Code
                                    Text(
                                      currency['code'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                            ? currency['color']
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 6),
                                    
                                    // Currency Name
                                    Text(
                                      currency['name'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Currency Symbol
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? currency['color']
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected 
                                              ? currency['color']
                                              : Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        currency['symbol'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected 
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Continue Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedCurrency != null
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : [Colors.grey[400]!, Colors.grey[600]!],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (selectedCurrency != null ? Colors.green : Colors.grey)
                              .withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: selectedCurrency != null ? _continueWithCurrency : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        selectedCurrency != null 
                            ? 'Continue with $selectedCurrency'
                            : 'Select a Currency',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueWithCurrency() async {
    if (selectedCurrency != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedCurrency', selectedCurrency!);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    }
  }
}
