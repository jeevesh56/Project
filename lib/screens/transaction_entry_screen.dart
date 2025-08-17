import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bill_analysis.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class TransactionEntryScreen extends StatefulWidget {
  final BillAnalysis billAnalysis;
  final File? imageFile;

  const TransactionEntryScreen({
    super.key,
    required this.billAnalysis,
    this.imageFile,
  });

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedTransactionType;
  bool _isSaving = false;

  final List<String> _expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Utilities',
    'Healthcare',
    'Education',
    'Home & Garden',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Other Income',
  ];

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.billAnalysis.merchant);
    _amountController = TextEditingController(text: widget.billAnalysis.amount.toStringAsFixed(2));
    _descriptionController = TextEditingController(text: widget.billAnalysis.items.join(', '));
    _selectedDate = widget.billAnalysis.date;
    _selectedCategory = widget.billAnalysis.category;
    _selectedTransactionType = widget.billAnalysis.transactionType;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_merchantController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        throw Exception('Invalid amount');
      }

      final database = FirebaseDatabase.instance;
      final transactionRef = database.ref('users/${user.uid}/transactions').push();

      final transactionData = {
        'merchant': _merchantController.text.trim(),
        'amount': amount,
        'currency': widget.billAnalysis.currency,
        'category': _selectedCategory,
        'transactionType': _selectedTransactionType,
        'description': _descriptionController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'source': 'ocr_scan',
        'confidence': widget.billAnalysis.confidence,
        'rawText': widget.billAnalysis.rawText,
      };

      await transactionRef.set(transactionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedTransactionType == 'expense' ? 'Expense' : 'Income'} saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to OCR screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Confirm Transaction'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (widget.imageFile != null)
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () => _showImagePreview(),
              tooltip: 'View scanned image',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence indicator
            _buildConfidenceCard(),
            
            const SizedBox(height: 16),
            
            // Transaction type selector
            _buildTransactionTypeSelector(),
            
            const SizedBox(height: 16),
            
            // Main form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Merchant field
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        labelText: 'Merchant *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Amount field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: (_selectedTransactionType == 'expense' 
                          ? _expenseCategories 
                          : _incomeCategories)
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Date picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Extracted items
            if (widget.billAnalysis.items.isNotEmpty) _buildExtractedItemsCard(),
            
            const SizedBox(height: 20),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTransactionType == 'expense' 
                      ? Colors.red 
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : Text(
                        'Save ${_selectedTransactionType == 'expense' ? 'Expense' : 'Income'}',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final confidence = widget.billAnalysis.confidence;
    Color confidenceColor;
    String confidenceText;
    
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
      confidenceText = 'High Confidence';
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
      confidenceText = 'Medium Confidence';
    } else {
      confidenceColor = Colors.red;
      confidenceText = 'Low Confidence';
    }

    return Card(
      color: confidenceColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.analytics,
              color: confidenceColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    confidenceText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: confidenceColor,
                    ),
                  ),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% accuracy',
                    style: TextStyle(
                      color: confidenceColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: confidence,
              backgroundColor: confidenceColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Expense'),
                    value: 'expense',
                    groupValue: _selectedTransactionType,
                    onChanged: (value) {
                      setState(() {
                        _selectedTransactionType = value!;
                        _selectedCategory = 'Other';
                      });
                    },
                    activeColor: Colors.red,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Income'),
                    value: 'income',
                    groupValue: _selectedTransactionType,
                    onChanged: (value) {
                      setState(() {
                        _selectedTransactionType = value!;
                        _selectedCategory = 'Other Income';
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Extracted Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.billAnalysis.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showImagePreview() {
    if (widget.imageFile != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Scanned Image'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: Image.file(
                  widget.imageFile!,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
