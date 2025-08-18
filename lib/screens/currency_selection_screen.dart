import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Text(
              'Please select the currency you want to use',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Currency List
          Expanded(
            child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final currency = currencies[index];
                    final isSelected = selectedCurrency == currency['code'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 0,
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedCurrency = currency['code'];
                          });
                        },
                        leading: Icon(
                          currency['icon'],
                          color: isSelected ? Colors.blue : Colors.grey[600],
                          size: 24,
                        ),
                        title: Text(
                          currency['name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '${currency['code']} ${currency['symbol']}',
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.grey[800],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.blue.shade50,
                      ),
                    );
                  },
                ),
            ),

          // Continue Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: selectedCurrency != null ? _continueWithCurrency : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                selectedCurrency != null 
                    ? 'Continue'
                    : 'Select a Currency',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithCurrency() async {
    if (selectedCurrency != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', selectedCurrency!);
      
      if (mounted) {
        // Navigate to the dashboard instead of login page
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    }
  }
}
