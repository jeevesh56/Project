class BillAnalysis {
  final String merchant;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String transactionType; // 'expense' or 'income'
  final List<String> items;
  final String rawText;
  final double confidence;

  BillAnalysis({
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.transactionType,
    required this.items,
    required this.rawText,
    required this.confidence,
  });

  factory BillAnalysis.fromJson(Map<String, dynamic> json) {
    return BillAnalysis(
      merchant: json['merchant'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? 'Other',
      transactionType: json['transactionType'] ?? 'expense',
      items: List<String>.from(json['items'] ?? []),
      rawText: json['rawText'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category': category,
      'transactionType': transactionType,
      'items': items,
      'rawText': rawText,
      'confidence': confidence,
    };
  }
}

class BillAnalyzer {
  static const Map<String, List<String>> _expenseKeywords = {
    'Food & Dining': [
      'restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'mcdonalds', 'kfc',
      'starbucks', 'subway', 'dominos', 'food', 'meal', 'lunch', 'dinner',
      'breakfast', 'snack', 'grocery', 'supermarket', 'market', 'bakery',
      'deli', 'fast food', 'takeout', 'delivery', 'kitchen', 'grill', 'bar',
      'pub', 'tavern', 'bistro', 'diner', 'buffet', 'catering'
    ],
    'Transportation': [
      'uber', 'lyft', 'taxi', 'bus', 'train', 'metro', 'subway', 'gas',
      'fuel', 'petrol', 'parking', 'toll', 'transport', 'car', 'auto',
      'automotive', 'service station', 'oil change', 'repair', 'maintenance',
      'airport', 'shuttle', 'rental', 'lease', 'insurance', 'registration'
    ],
    'Shopping': [
      'amazon', 'walmart', 'target', 'costco', 'shop', 'store', 'mall',
      'clothing', 'shoes', 'electronics', 'apparel', 'fashion', 'retail',
      'department store', 'boutique', 'outlet', 'discount', 'sale',
      'jewelry', 'accessories', 'cosmetics', 'beauty', 'personal care'
    ],
    'Entertainment': [
      'netflix', 'spotify', 'youtube', 'movie', 'cinema', 'theater',
      'concert', 'game', 'entertainment', 'fun', 'leisure', 'amusement',
      'park', 'museum', 'gallery', 'show', 'performance', 'ticket',
      'subscription', 'streaming', 'music', 'video', 'gaming'
    ],
    'Utilities': [
      'electricity', 'water', 'gas', 'internet', 'phone', 'mobile',
      'utility', 'bill', 'service', 'wifi', 'cable', 'satellite',
      'power', 'energy', 'heating', 'cooling', 'trash', 'sewage',
      'telephone', 'landline', 'cellular', 'data', 'broadband'
    ],
    'Healthcare': [
      'pharmacy', 'drugstore', 'medical', 'doctor', 'hospital', 'clinic',
      'medicine', 'health', 'dental', 'vision', 'insurance', 'prescription',
      'physician', 'specialist', 'emergency', 'ambulance', 'laboratory',
      'x-ray', 'mri', 'therapy', 'rehabilitation', 'wellness'
    ],
    'Education': [
      'school', 'university', 'college', 'course', 'book', 'textbook',
      'education', 'learning', 'tuition', 'fee', 'academy', 'institute',
      'training', 'workshop', 'seminar', 'conference', 'library',
      'student', 'scholarship', 'loan', 'grant', 'certification'
    ],
    'Home & Garden': [
      'home', 'garden', 'furniture', 'decor', 'repair', 'maintenance',
      'hardware', 'tools', 'cleaning', 'household', 'improvement',
      'renovation', 'construction', 'contractor', 'plumber', 'electrician',
      'landscaping', 'lawn', 'pest control', 'security', 'alarm'
    ],
  };

  static const Map<String, List<String>> _incomeKeywords = {
    'Salary': ['salary', 'wage', 'payroll', 'income', 'earnings', 'payment', 'paycheck', 'compensation'],
    'Freelance': ['freelance', 'contract', 'consulting', 'project', 'gig', 'independent', 'self-employed'],
    'Investment': ['dividend', 'interest', 'investment', 'stock', 'bond', 'mutual fund', 'etf', 'portfolio', 'capital gains'],
    'Business': ['business', 'revenue', 'sales', 'profit', 'income', 'enterprise', 'company', 'corporation', 'llc'],
    'Other Income': ['refund', 'rebate', 'bonus', 'commission', 'tip', 'gift', 'inheritance', 'settlement', 'award'],
  };

  static const List<String> _amountPatterns = [
    r'\$?\d+\.\d{2}', // $123.45 or 123.45
    r'\$?\d+,\d{3}\.\d{2}', // $1,234.56
    r'\d+\.\d{2}\s*USD', // 123.45 USD
    r'TOTAL.*?\$?\d+\.\d{2}', // TOTAL: $123.45
    r'AMOUNT.*?\$?\d+\.\d{2}', // AMOUNT: $123.45
    r'DUE.*?\$?\d+\.\d{2}', // DUE: $123.45
    r'BALANCE.*?\$?\d+\.\d{2}', // BALANCE: $123.45
  ];

  static const List<String> _datePatterns = [
    r'\d{1,2}/\d{1,2}/\d{2,4}', // MM/DD/YYYY or M/D/YY
    r'\d{1,2}-\d{1,2}-\d{2,4}', // MM-DD-YYYY
    r'\d{4}-\d{2}-\d{2}', // YYYY-MM-DD
    r'\w{3}\s+\d{1,2},\s+\d{4}', // Jan 15, 2024
    r'\d{1,2}\s+\w{3}\s+\d{4}', // 15 Jan 2024
  ];

  // Enhanced merchant detection patterns
  static const List<String> _merchantIndicators = [
    'receipt from',
    'thank you for your purchase at',
    'purchase at',
    'transaction at',
    'payment to',
    'bill from',
    'invoice from',
  ];

  static BillAnalysis analyzeBill(String rawText) {
    final text = rawText.toLowerCase();
    
    // Extract amount
    double amount = _extractAmount(text);
    
    // Extract date
    DateTime date = _extractDate(text) ?? DateTime.now();
    
    // Determine transaction type and category
    String transactionType = 'expense';
    String category = 'Other';
    
    // Check if it's income
    for (String incomeCategory in _incomeKeywords.keys) {
      if (_incomeKeywords[incomeCategory]!.any((keyword) => text.contains(keyword))) {
        transactionType = 'income';
        category = incomeCategory;
        break;
      }
    }
    
    // If not income, check expense categories
    if (transactionType == 'expense') {
      for (String expenseCategory in _expenseKeywords.keys) {
        if (_expenseKeywords[expenseCategory]!.any((keyword) => text.contains(keyword))) {
          category = expenseCategory;
          break;
        }
      }
    }
    
    // Extract merchant name
    String merchant = _extractMerchant(text);
    
    // Extract items
    List<String> items = _extractItems(text);
    
    // Calculate confidence based on extracted data
    double confidence = _calculateConfidence(text, amount, merchant, category);
    
    return BillAnalysis(
      merchant: merchant,
      amount: amount,
      currency: 'USD',
      date: date,
      category: category,
      transactionType: transactionType,
      items: items,
      rawText: rawText,
      confidence: confidence,
    );
  }

  static double _extractAmount(String text) {
    // Look for common amount patterns with improved regex
    final amountRegex = RegExp(r'\$?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
    final matches = amountRegex.allMatches(text);
    
    if (matches.isNotEmpty) {
      // Get the largest amount (usually the total)
      double maxAmount = 0.0;
      for (Match match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        final amount = double.tryParse(amountStr) ?? 0.0;
        if (amount > maxAmount && amount < 100000) { // Reasonable amount limit
          maxAmount = amount;
        }
      }
      return maxAmount;
    }
    
    return 0.0;
  }

  static DateTime? _extractDate(String text) {
    // Look for date patterns with improved regex
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final match = dateRegex.firstMatch(text);
    
    if (match != null) {
      final month = int.tryParse(match.group(1) ?? '1') ?? 1;
      final day = int.tryParse(match.group(2) ?? '1') ?? 1;
      final year = int.tryParse(match.group(3) ?? '2024') ?? 2024;
      
      // Handle 2-digit years
      final fullYear = year < 100 ? (year < 50 ? 2000 + year : 1900 + year) : year;
      
      try {
        return DateTime(fullYear, month, day);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  static String _extractMerchant(String text) {
    final lines = text.split('\n');
    
    // First, look for merchant indicators
    for (String line in lines) {
      final cleanLine = line.trim().toLowerCase();
      
      for (String indicator in _merchantIndicators) {
        if (cleanLine.contains(indicator)) {
          final startIndex = cleanLine.indexOf(indicator) + indicator.length;
          final merchantName = line.trim().substring(startIndex).trim();
          if (merchantName.isNotEmpty) {
            return merchantName;
          }
        }
      }
    }
    
    // Look for common merchant patterns
    for (String line in lines) {
      final cleanLine = line.trim().toLowerCase();
      
      // Skip empty lines and common header words
      if (cleanLine.isEmpty || 
          cleanLine.contains('receipt') || 
          cleanLine.contains('invoice') ||
          cleanLine.contains('total') ||
          cleanLine.contains('amount') ||
          cleanLine.contains('date') ||
          cleanLine.contains('time') ||
          cleanLine.contains('cashier') ||
          cleanLine.contains('register')) {
        continue;
      }
      
      // If line looks like a merchant name (not too long, no numbers, not all caps)
      if (cleanLine.length > 3 && 
          cleanLine.length < 50 && 
          !RegExp(r'\d').hasMatch(cleanLine) &&
          !RegExp(r'^[A-Z\s]+$').hasMatch(line.trim()) && // Not all caps
          !cleanLine.contains('tax') &&
          !cleanLine.contains('subtotal')) {
        return line.trim();
      }
    }
    
    return 'Unknown Merchant';
  }

  static List<String> _extractItems(String text) {
    final lines = text.split('\n');
    final items = <String>[];
    
    for (String line in lines) {
      final cleanLine = line.trim().toLowerCase();
      
      // Look for lines that might be items (contain numbers but not totals)
      if (cleanLine.contains('\$') && 
          !cleanLine.contains('total') &&
          !cleanLine.contains('subtotal') &&
          !cleanLine.contains('tax') &&
          !cleanLine.contains('tip') &&
          !cleanLine.contains('discount') &&
          !cleanLine.contains('coupon')) {
        
        // Extract item name (everything before the price)
        final priceMatch = RegExp(r'\$?\d+\.\d{2}').firstMatch(cleanLine);
        if (priceMatch != null) {
          final itemName = cleanLine.substring(0, priceMatch.start).trim();
          if (itemName.isNotEmpty && itemName.length > 2) {
            items.add(line.trim());
          }
        }
      }
    }
    
    return items;
  }

  static double _calculateConfidence(String text, double amount, String merchant, String category) {
    double confidence = 0.0;
    
    // Amount confidence (40% weight)
    if (amount > 0) confidence += 0.4;
    
    // Merchant confidence (30% weight)
    if (merchant != 'Unknown Merchant') confidence += 0.3;
    
    // Category confidence (20% weight)
    if (category != 'Other') confidence += 0.2;
    
    // Text length confidence (10% weight)
    if (text.length > 50) confidence += 0.1;
    
    return confidence;
  }
}
