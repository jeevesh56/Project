import 'package:flutter/material.dart';

class CategoryIcons {
  // Expense Categories with Icons
  static const Map<String, IconData> expenseCategories = {
    'Food & Dining': Icons.restaurant,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Healthcare': Icons.local_hospital,
    'Education': Icons.school,
    'Housing': Icons.home,
    'Utilities': Icons.electric_bolt,
    'Insurance': Icons.security,
    'Taxes': Icons.receipt_long,
    'Personal Care': Icons.face,
    'Travel': Icons.flight,
    'Gifts': Icons.card_giftcard,
    'Subscriptions': Icons.subscriptions,
    'Fitness': Icons.fitness_center,
    'Pets': Icons.pets,
    'Home Maintenance': Icons.build,
    'Clothing': Icons.checkroom,
    'Technology': Icons.computer,
    'Books': Icons.book,
    'Music': Icons.music_note,
    'Sports': Icons.sports_soccer,
    'Beauty': Icons.face_retouching_natural,
    'Automotive': Icons.directions_car_filled,
    'Legal': Icons.gavel,
    'Banking': Icons.account_balance,
    'Investment Expense': Icons.trending_up,
    'Charity': Icons.volunteer_activism,
    'Other Expense': Icons.more_horiz,
  };

  // Income Categories with Icons
  static const Map<String, IconData> incomeCategories = {
    'Salary': Icons.work,
    'Freelance': Icons.laptop,
    'Investment Income': Icons.trending_up,
    'Business': Icons.business,
    'Rental': Icons.home_work,
    'Interest': Icons.account_balance,
    'Dividends': Icons.pie_chart,
    'Commission': Icons.percent,
    'Bonus': Icons.star,
    'Refund': Icons.replay,
    'Gift Income': Icons.card_giftcard,
    'Lottery': Icons.celebration,
    'Inheritance': Icons.family_restroom,
    'Sale': Icons.sell,
    'Other Income': Icons.add_circle,
  };

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food & Dining': Colors.orange,
    'Transportation': Colors.blue,
    'Shopping': Colors.pink,
    'Entertainment': Colors.purple,
    'Healthcare': Colors.red,
    'Education': Colors.indigo,
    'Housing': Colors.brown,
    'Utilities': Colors.amber,
    'Insurance': Colors.teal,
    'Taxes': Colors.deepOrange,
    'Personal Care': Colors.cyan,
    'Travel': Colors.lightBlue,
    'Gifts': Colors.deepPurple,
    'Subscriptions': Colors.lime,
    'Fitness': Colors.green,
    'Pets': Colors.lightGreen,
    'Home Maintenance': Colors.deepPurple,
    'Clothing': Colors.blueGrey,
    'Technology': Colors.indigo,
    'Books': Colors.brown,
    'Music': Colors.pink,
    'Sports': Colors.green,
    'Beauty': Colors.pink,
    'Automotive': Colors.grey,
    'Legal': Colors.deepOrange,
    'Banking': Colors.blue,
    'Investment Expense': Colors.green,
    'Charity': Colors.red,
    'Other Expense': Colors.grey,
    // Income categories
    'Salary': Colors.green,
    'Freelance': Colors.blue,
    'Investment Income': Colors.green,
    'Business': Colors.indigo,
    'Rental': Colors.orange,
    'Interest': Colors.blue,
    'Dividends': Colors.green,
    'Commission': Colors.purple,
    'Bonus': Colors.amber,
    'Refund': Colors.green,
    'Gift Income': Colors.pink,
    'Lottery': Colors.orange,
    'Inheritance': Colors.brown,
    'Sale': Colors.green,
  };

  // Get category icon
  static IconData getIcon(String categoryName, bool isIncome) {
    if (isIncome) {
      return incomeCategories[categoryName] ?? Icons.category;
    } else {
      return expenseCategories[categoryName] ?? Icons.category;
    }
  }

  // Get category color
  static Color getColor(String categoryName) {
    return categoryColors[categoryName] ?? Colors.grey;
  }

  // Get all expense categories
  static List<String> getExpenseCategories() {
    return expenseCategories.keys.toList();
  }

  // Get all income categories
  static List<String> getIncomeCategories() {
    return incomeCategories.keys.toList();
  }

  // Get all categories
  static List<String> getAllCategories() {
    return [...expenseCategories.keys, ...incomeCategories.keys];
  }
}
