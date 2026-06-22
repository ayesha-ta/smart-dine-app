import 'package:flutter/material.dart';

class Transaction {
  final String title;
  final String subtitle;
  final int amount;
  final bool isAddition;

  Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isAddition,
  });
}

class UserProvider with ChangeNotifier {
  int _loyaltyCoins = 0;
  String _tablePin = '';
  String _tableNumber = '';
  
  bool _isLoggedIn = false;
  String? _phoneNumber;

  final List<Transaction> _transactionHistory = [];

  int get loyaltyCoins => _loyaltyCoins;
  String get tablePin => _tablePin;
  String get tableNumber => _tableNumber;
  bool get isLoggedIn => _isLoggedIn;
  String? get phoneNumber => _phoneNumber;
  List<Transaction> get transactionHistory => [..._transactionHistory].reversed.toList();

  void setTableData(String tableNum) {
    _tableNumber = tableNum;
    notifyListeners();
  }

  void verifyPin(String pin) {
    _tablePin = pin;
    notifyListeners();
  }

  void login(String phone) {
    _isLoggedIn = true;
    _phoneNumber = phone;
    
    // Add Welcome Bonus
    addCoins(100, 'Welcome Bonus', 'Sign Up Reward');
    notifyListeners();
  }

  void addCoins(int amount, String title, String subtitle) {
    _loyaltyCoins += amount;
    _transactionHistory.add(Transaction(
      title: title,
      subtitle: subtitle,
      amount: amount,
      isAddition: true,
    ));
    notifyListeners();
  }

  void deductCoins(int amount, String title, String subtitle) {
    if (_loyaltyCoins >= amount) {
      _loyaltyCoins -= amount;
      _transactionHistory.add(Transaction(
        title: title,
        subtitle: subtitle,
        amount: amount,
        isAddition: false,
      ));
      notifyListeners();
    }
  }
}
