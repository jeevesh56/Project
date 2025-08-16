import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class TransactionEntryScreen extends StatefulWidget {
  final String userId;
  final Function() onTransactionAdded;

  const TransactionEntryScreen({
    super.key,
    required this.userId,
    required this.onTransactionAdded,
  });

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Food & Dining';
  bool _isExpense = true;
  bool _isListening = false;
  String _lastWords = '';
  
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food & Dining', 'icon': FontAwesomeIcons.utensils, 'color': Colors.red},
    {'name': 'Transportation', 'icon': FontAwesomeIcons.car, 'color': Colors.blue},
    {'name': 'Medicine', 'icon': FontAwesomeIcons.pills, 'color': Colors.green},
    {'name': 'Entertainment', 'icon': FontAwesomeIcons.film, 'color': Colors.purple},
    {'name': 'Shopping', 'icon': FontAwesomeIcons.shoppingBag, 'color': Colors.orange},
    {'name': 'Utilities', 'icon': FontAwesomeIcons.bolt, 'color': Colors.yellow},
    {'name': 'Education', 'icon': FontAwesomeIcons.graduationCap, 'color': Colors.indigo},
    {'name': 'Other', 'icon': FontAwesomeIcons.ellipsis, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _speechEnabled = true;
      });
    }
  }

  Future<void> _requestSpeechPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _speechEnabled = true;
      });
    }
  }

  void _startListening() async {
    await _requestSpeechPermission();
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _processVoiceInput(_lastWords);
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _processVoiceInput(String input) {
    input = input.toLowerCase();
    
    // Extract amount
    RegExp amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    Match? amountMatch = amountRegex.firstMatch(input);
    if (amountMatch != null) {
      _amountController.text = amountMatch.group(1)!;
    }

    // Extract category
    for (var category in categories) {
      if (input.contains(category['name'].toString().toLowerCase())) {
        setState(() {
          _selectedCategory = category['name'];
        });
        break;
      }
    }

    // Extract description
    String description = input;
    if (amountMatch != null) {
      description = description.replaceAll(amountMatch.group(1)!, '').trim();
    }
    for (var category in categories) {
      description = description.replaceAll(category['name'].toString().toLowerCase(), '').trim();
    }
    if (description.isNotEmpty) {
      _descriptionController.text = description;
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    try {
      double amount = double.parse(_amountController.text);
      if (!_isExpense) {
        amount = amount.abs();
      } else {
        amount = -amount.abs();
      }

      final transaction = {
        'amount': amount,
        'description': _descriptionController.text.isEmpty ? 'Transaction' : _descriptionController.text,
        'category': _selectedCategory,
        'date': DateTime.now().toIso8601String(),
        'type': _isExpense ? 'expense' : 'income',
      };

      final databaseRef = FirebaseDatabase.instance.ref();
      await databaseRef
          .child('users')
          .child(widget.userId)
          .child('transactions')
          .push()
          .set(transaction);

      widget.onTransactionAdded();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Toggle
            Container(
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
                  const Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isExpense = true),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _isExpense ? Colors.red : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_down,
                                  color: _isExpense ? Colors.white : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    color: _isExpense ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isExpense = false),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: !_isExpense ? Colors.green : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: !_isExpense ? Colors.white : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Income',
                                  style: TextStyle(
                                    color: !_isExpense ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 20),

            // Amount Input
            Container(
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
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection
            Container(
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
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'] as String,
                        child: Row(
                          children: [
                            FaIcon(
                              category['icon'] as IconData,
                              color: category['color'] as Color,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(category['name'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description Input
            Container(
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
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter description',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Voice Recognition Button
            if (_speechEnabled)
              Container(
                width: double.infinity,
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
                    const Text(
                      'Voice Recognition',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          _isListening ? FontAwesomeIcons.microphoneSlash : FontAwesomeIcons.microphone,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          'Listening... Say something like "I spent 50 dollars on food"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
