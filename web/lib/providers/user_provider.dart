import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/menu_item.dart';

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

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'isAddition': isAddition,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    title: map['title'],
    subtitle: map['subtitle'],
    amount: map['amount'],
    isAddition: map['isAddition'],
  );
}

class AdminOrder {
  final String id;
  final String tableNumber;
  final double amount;
  String status; // 'Pending', 'Preparing', 'Complete'
  final DateTime timestamp;

  AdminOrder({
    required this.id,
    required this.tableNumber,
    required this.amount,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tableNumber': tableNumber,
    'amount': amount,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AdminOrder.fromMap(Map<String, dynamic> map) => AdminOrder(
    id: map['id'],
    tableNumber: map['tableNumber'],
    amount: map['amount'],
    status: map['status'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}

class InventoryIngredient {
  final String name;
  double currentStock;
  final String unit;
  final double threshold;
  final String supplier;

  InventoryIngredient({
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.threshold,
    required this.supplier,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'currentStock': currentStock,
    'unit': unit,
    'threshold': threshold,
    'supplier': supplier,
  };

  factory InventoryIngredient.fromMap(Map<String, dynamic> map) => InventoryIngredient(
    name: map['name'],
    currentStock: map['currentStock'],
    unit: map['unit'],
    threshold: map['threshold'],
    supplier: map['supplier'],
  );
}

class StaffMember {
  final String name;
  final String role;
  final String skills;
  bool isOnShift;

  StaffMember({
    required this.name,
    required this.role,
    required this.skills,
    required this.isOnShift,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'role': role,
    'skills': skills,
    'isOnShift': isOnShift,
  };

  factory StaffMember.fromMap(Map<String, dynamic> map) => StaffMember(
    name: map['name'],
    role: map['role'],
    skills: map['skills'],
    isOnShift: map['isOnShift'],
  );
}

class UserProvider with ChangeNotifier {
  int _loyaltyCoins = 0;
  String _tablePin = '';
  String _tableNumber = '';
  
  bool _isLoggedIn = false;
  String? _phoneNumber;
  String? _userName;
  String? _userEmail;
  String _userRole = 'customer'; // 'customer' or 'admin'

  final List<Transaction> _transactionHistory = [];

  // Default initial users
  final Map<String, Map<String, String>> _registeredUsers = {
    'ayesha@gmail.com': {
      'name': 'Ayesha Tariq',
      'phone': '03001234567',
      'password': 'password123',
    },
    'tooba@gmail.com': {
      'name': 'Tooba Noor',
      'phone': '03007654321',
      'password': 'password123',
    },
  };

  // Tables and their dynamic PINs
  final Map<String, String> _tablePins = {
    'Table 1': '3296',
    'Table 2': '6419',
    'Table 3': '9339',
    'Table 4': '1234',
    'Table 5': '1687',
    'Table 6': '3729',
  };

  // Centralized Menu list (initially loaded from previous dummy list)
  List<MenuItem> _menuItems = [
    MenuItem(id: '1', name: 'Chicken karahi', description: 'Spicy chicken curry with tomatoes and fresh green chilies.', price: 1000, category: 'Mains', imagePath: 'https://images.unsplash.com/photo-1603496987351-f84a3ba5ee3f?q=80&w=500&auto=format&fit=crop', isSpicy: true),
    MenuItem(id: '2', name: 'Seekh Kabab', description: 'Minced meat kebabs cooked on skewers over charcoal.', price: 1200, category: 'Starters', imagePath: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=500&auto=format&fit=crop', isSpicy: false),
    MenuItem(id: '3', name: 'Naan Basket', description: 'Fresh baked naan bread basket, hot from the tandoor.', price: 200, category: 'Starters', imagePath: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=500&auto=format&fit=crop', isSpicy: false),
    MenuItem(id: '4', name: 'Iced Coffee', description: 'Refreshing iced coffee with milk and light sweetener.', price: 400, category: 'Drinks', imagePath: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?q=80&w=500&auto=format&fit=crop', isSpicy: false),
    MenuItem(id: '5', name: 'Mango Lassi', description: 'Creamy mango yogurt drink with a hint of cardamom.', price: 350, category: 'Drinks', imagePath: 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?q=80&w=500&auto=format&fit=crop', isSpicy: false),
    MenuItem(id: '6', name: 'Chocolate Lava Cake', description: 'Warm chocolate cake with a gooey molten center.', price: 600, category: 'Desserts', imagePath: 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?q=80&w=500&auto=format&fit=crop', isSpicy: false),
  ];

  final Set<String> _unavailableMenuItemIds = {'5'}; // Hide Mango Lassi initially as "Pending" or out of stock

  // Active orders for Dashboard
  List<AdminOrder> _orders = [
    AdminOrder(id: '1', tableNumber: 'Table 4', amount: 2564, status: 'Preparing', timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
    AdminOrder(id: '2', tableNumber: 'Table 2', amount: 890, status: 'Pending', timestamp: DateTime.now().subtract(const Duration(minutes: 18))),
    AdminOrder(id: '3', tableNumber: 'Table 7', amount: 4200, status: 'Complete', timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
  ];
  // Recipes definition mapping menu item IDs to required inventory ingredients and their amount
  final Map<String, Map<String, double>> _recipes = {
    '1': {'Chicken': 0.5, 'Tomatoes': 0.2, 'Cooking Oil': 0.1}, // Chicken Karahi (kg, kg, L)
    '2': {'Chicken': 0.3, 'Cooking Oil': 0.05},                  // Seekh Kabab (kg, L)
    '3': {'Naan Dough': 1.0},                                    // Naan Basket (Pcs)
    '4': {'Cooking Oil': 0.02},                                  // Iced Coffee (mock ingredient for demo)
    '5': {'Mango Pulp': 0.2},                                    // Mango Lassi (kg)
    '6': {'Cooking Oil': 0.05},                                  // Chocolate Lava Cake (mock L)
  };

  // Inventory Ingredients
  List<InventoryIngredient> _inventory = [
    InventoryIngredient(name: 'Chicken', currentStock: 2.1, unit: 'kg', threshold: 5.0, supplier: 'Al-Fatah Suppliers'),
    InventoryIngredient(name: 'Tomatoes', currentStock: 0.8, unit: 'kg', threshold: 2.0, supplier: 'National Foods LTD'),
    InventoryIngredient(name: 'Cooking Oil', currentStock: 4.5, unit: 'L', threshold: 3.0, supplier: 'National Foods LTD'),
    InventoryIngredient(name: 'Naan Dough', currentStock: 12, unit: 'Pcs', threshold: 10.0, supplier: 'Al-Fatah Suppliers'),
    InventoryIngredient(name: 'Mango Pulp', currentStock: 1.2, unit: 'kg', threshold: 2.0, supplier: 'National Foods LTD'),
  ];

  // Staff Registry
  List<StaffMember> _staff = [
    StaffMember(name: 'Ali Hassan', role: 'Head Chef', skills: 'Kitchen Mgmt', isOnShift: true),
    StaffMember(name: 'Bilal Ahmed', role: 'Line Cook', skills: 'Grill & BBQ', isOnShift: true),
    StaffMember(name: 'Sara Khan', role: 'Line Cook', skills: 'Beverages, Desserts', isOnShift: true),
    StaffMember(name: 'Raza Malik', role: 'Line Cook', skills: 'Bread & Rice', isOnShift: false),
    StaffMember(name: 'Nadia', role: 'Line Cook', skills: 'Grill & BBQ', isOnShift: true),
  ];

  // Wastage reports log
  double _wastageCost = 4500.0;

  // Getters
  int get loyaltyCoins => _loyaltyCoins;
  String get tablePin => _tablePin;
  String get tableNumber => _tableNumber;
  bool get isLoggedIn => _isLoggedIn;
  bool get isRegisteredUser => _isLoggedIn && _userName != 'Guest User';
  String? get phoneNumber => _phoneNumber;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String get userRole => _userRole;
  List<Transaction> get transactionHistory => [..._transactionHistory].reversed.toList();
  
  Map<String, String> get tablePins => _tablePins;
  List<MenuItem> get menuItems => _menuItems;
  Set<String> get unavailableMenuItemIds => _unavailableMenuItemIds;
  List<AdminOrder> get orders => _orders;
  List<InventoryIngredient> get inventory => _inventory;
  List<StaffMember> get staff => _staff;
  double get wastageCost => _wastageCost;

  UserProvider() {
    _loadFromPrefs();
  }

  // Asynchronously load states from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Registered Users
      final usersStr = prefs.getString('registered_users');
      if (usersStr != null) {
        final Map<String, dynamic> decoded = json.decode(usersStr);
        decoded.forEach((key, value) {
          _registeredUsers[key] = Map<String, String>.from(value);
        });
      }

      // 2. Active session
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (_isLoggedIn) {
        _phoneNumber = prefs.getString('phone_number');
        _userName = prefs.getString('user_name');
        _userEmail = prefs.getString('user_email');
        _userRole = prefs.getString('user_role') ?? 'customer';
      }
      // Always restore loyalty coins regardless of session state
      // so that coins are available as soon as user logs back in
      _loyaltyCoins = prefs.getInt('loyalty_coins') ?? 0;

      // 3. Transactions History
      final txStr = prefs.getString('transaction_history');
      if (txStr != null) {
        final List<dynamic> decodedList = json.decode(txStr);
        _transactionHistory.clear();
        _transactionHistory.addAll(decodedList.map((x) => Transaction.fromMap(x)));
      }

      // 4. Table PINs
      final pinsStr = prefs.getString('table_pins');
      if (pinsStr != null) {
        final Map<String, dynamic> decodedPins = json.decode(pinsStr);
        decodedPins.forEach((key, value) {
          _tablePins[key] = value.toString();
        });
      }

      // 5. Menu Items (CRUD additions)
      final menuStr = prefs.getString('menu_items');
      if (menuStr != null) {
        final List<dynamic> decodedMenu = json.decode(menuStr);
        _menuItems = decodedMenu.map((x) => MenuItem(
          id: x['id'],
          name: x['name'],
          description: x['description'],
          price: (x['price'] as num).toDouble(),
          category: x['category'],
          imagePath: x['imagePath'],
          isSpicy: x['isSpicy'] ?? false,
        )).toList();
      }

      // 6. Unavailable Items (Stock triggers)
      final unavailStr = prefs.getString('unavailable_menu_items');
      if (unavailStr != null) {
        final List<dynamic> decodedUnavail = json.decode(unavailStr);
        _unavailableMenuItemIds.clear();
        _unavailableMenuItemIds.addAll(decodedUnavail.map((x) => x.toString()));
      }

      // 7. Orders logs
      final ordersStr = prefs.getString('orders');
      if (ordersStr != null) {
        final List<dynamic> decodedOrders = json.decode(ordersStr);
        _orders = decodedOrders.map((x) => AdminOrder.fromMap(x)).toList();
      }

      // 8. Inventory stocks
      final invStr = prefs.getString('inventory');
      if (invStr != null) {
        final List<dynamic> decodedInv = json.decode(invStr);
        _inventory = decodedInv.map((x) => InventoryIngredient.fromMap(x)).toList();
      }

      // 9. Staff duty status
      final staffStr = prefs.getString('staff');
      if (staffStr != null) {
        final List<dynamic> decodedStaff = json.decode(staffStr);
        _staff = decodedStaff.map((x) => StaffMember.fromMap(x)).toList();
      }

      // 10. Wastage cost
      _wastageCost = prefs.getDouble('wastage_cost') ?? 4500.0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading SharedPreferences: $e');
    }
  }

  // Save changes to SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('registered_users', json.encode(_registeredUsers));
      await prefs.setBool('is_logged_in', _isLoggedIn);
      await prefs.setString('phone_number', _phoneNumber ?? '');
      await prefs.setString('user_name', _userName ?? '');
      await prefs.setString('user_email', _userEmail ?? '');
      await prefs.setString('user_role', _userRole);
      await prefs.setInt('loyalty_coins', _loyaltyCoins);

      final txList = _transactionHistory.map((x) => x.toMap()).toList();
      await prefs.setString('transaction_history', json.encode(txList));

      await prefs.setString('table_pins', json.encode(_tablePins));

      final menuList = _menuItems.map((x) => {
        'id': x.id,
        'name': x.name,
        'description': x.description,
        'price': x.price,
        'category': x.category,
        'imagePath': x.imagePath,
        'isSpicy': x.isSpicy,
      }).toList();
      await prefs.setString('menu_items', json.encode(menuList));

      await prefs.setString('unavailable_menu_items', json.encode(_unavailableMenuItemIds.toList()));

      final ordersList = _orders.map((x) => x.toMap()).toList();
      await prefs.setString('orders', json.encode(ordersList));

      final invList = _inventory.map((x) => x.toMap()).toList();
      await prefs.setString('inventory', json.encode(invList));

      final staffList = _staff.map((x) => x.toMap()).toList();
      await prefs.setString('staff', json.encode(staffList));

      await prefs.setDouble('wastage_cost', _wastageCost);
    } catch (e) {
      debugPrint('Error writing to SharedPreferences: $e');
    }
  }

  void setTableData(String tableNum) {
    _tableNumber = tableNum;
    notifyListeners();
  }

  void verifyPin(String pin) {
    _tablePin = pin;
    notifyListeners();
  }

  // Cycles/regenerates the PIN for a specific table
  void cycleTablePin(String table) {
    final randomPin = (1000 + (9000 * (DateTime.now().millisecond / 1000))).toInt().toString();
    _tablePins[table] = randomPin;
    _saveToPrefs();
    notifyListeners();
  }

  // Custom function to check table PIN dynamically
  bool checkTablePin(String table, String pin) {
    return _tablePins[table] == pin;
  }

  void login(String phone) {
    _isLoggedIn = true;
    _phoneNumber = phone;
    _userName = 'Guest User';
    _userEmail = 'guest@smartdine.com';
    _userRole = 'customer';
    // Guests do NOT receive loyalty coins — coins are only awarded on registration
    _saveToPrefs();
    notifyListeners();
  }

  bool loginWithEmail(String email, String password) {
    final lowerEmail = email.trim().toLowerCase();
    
    // Check for admin login
    if (lowerEmail == 'admin@smartdine.com' || lowerEmail == 'admin@smartdine.pk') {
      if (password == 'admin123') {
        _isLoggedIn = true;
        _userEmail = lowerEmail;
        _userName = 'System Admin';
        _phoneNumber = '0000000000';
        _userRole = 'admin';
        _saveToPrefs();
        notifyListeners();
        return true;
      }
    }

    if (_registeredUsers.containsKey(lowerEmail)) {
      final userData = _registeredUsers[lowerEmail]!;
      if (userData['password'] == password) {
        _isLoggedIn = true;
        _userEmail = lowerEmail;
        _userName = userData['name'];
        _phoneNumber = userData['phone'];
        _userRole = 'customer';

        // Award Welcome Bonus only if this user has never claimed it before.
        // We track this with a 'coins_claimed' flag stored per user.
        final alreadyClaimed = userData['coins_claimed'] == 'true';
        if (!alreadyClaimed) {
          _registeredUsers[lowerEmail]!['coins_claimed'] = 'true';
          addCoins(100, 'Welcome Bonus', 'Sign Up Reward');
        }

        _saveToPrefs();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool signUp(String name, String email, String phone, String password) {
    final lowerEmail = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(lowerEmail) || lowerEmail == 'admin@smartdine.com' || lowerEmail == 'admin@smartdine.pk') {
      return false; // User already exists
    }

    // Store user with coins_claimed = true so loginWithEmail never double-awards
    _registeredUsers[lowerEmail] = {
      'name': name,
      'phone': phone,
      'password': password,
      'coins_claimed': 'true',
    };

    _isLoggedIn = true;
    _userEmail = lowerEmail;
    _userName = name;
    _phoneNumber = phone;
    _userRole = 'customer';

    // Award Welcome Bonus on first registration
    addCoins(100, 'Welcome Bonus', 'Sign Up Reward');
    _saveToPrefs();
    notifyListeners();
    return true;
  }

  bool resetPassword(String email, String newPassword) {
    final lowerEmail = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(lowerEmail)) {
      _registeredUsers[lowerEmail]!['password'] = newPassword;
      _saveToPrefs();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool hasUser(String email) {
    return _registeredUsers.containsKey(email.trim().toLowerCase());
  }

  // Menu Management CRUD
  void addMenuItem(MenuItem item) {
    _menuItems.add(item);
    _saveToPrefs();
    notifyListeners();
  }

  void editMenuItem(MenuItem item) {
    final index = _menuItems.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      _menuItems[index] = item;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void deleteMenuItem(String id) {
    _menuItems.removeWhere((element) => element.id == id);
    _unavailableMenuItemIds.remove(id);
    _saveToPrefs();
    notifyListeners();
  }

  void toggleItemAvailability(String id) {
    if (_unavailableMenuItemIds.contains(id)) {
      _unavailableMenuItemIds.remove(id);
    } else {
      _unavailableMenuItemIds.add(id);
    }
    _saveToPrefs();
    notifyListeners();
  }

  // Helper to determine the maximum number of times a menu item can be ordered based on current inventory
  int getMaxAvailableQuantity(MenuItem item) {
    final recipe = _recipes[item.id];
    if (recipe == null || recipe.isEmpty) return 99; // Default upper bound if no recipe is set

    int minPossible = 99;
    recipe.forEach((ingredientName, requiredQty) {
      final ingredientIndex = _inventory.indexWhere((ing) => ing.name == ingredientName);
      if (ingredientIndex == -1) {
        minPossible = 0;
      } else {
        final currentStock = _inventory[ingredientIndex].currentStock;
        final possible = (currentStock / requiredQty).floor();
        if (possible < minPossible) {
          minPossible = possible;
        }
      }
    });
    return minPossible.clamp(0, 99);
  }

  // Helper to check if a full order cart can be fulfilled by the current inventory
  bool canPlaceOrder(Map<String, int> itemQuantities) {
    final Map<String, double> tempStock = {};
    for (var ing in _inventory) {
      tempStock[ing.name] = ing.currentStock;
    }

    for (var entry in itemQuantities.entries) {
      final itemId = entry.key;
      final qty = entry.value;
      final recipe = _recipes[itemId];
      if (recipe != null) {
        for (var ingredientEntry in recipe.entries) {
          final ingName = ingredientEntry.key;
          final totalRequired = ingredientEntry.value * qty;
          if (!tempStock.containsKey(ingName) || tempStock[ingName]! < totalRequired) {
            return false; // Insufficient stock
          }
          tempStock[ingName] = tempStock[ingName]! - totalRequired;
        }
      }
    }
    return true;
  }

  // Deducts the inventory stock based on ordered items and adds the order to the list
  void placeOrderWithInventory(String table, double amount, Map<String, int> itemQuantities) {
    for (var entry in itemQuantities.entries) {
      final itemId = entry.key;
      final qty = entry.value;
      final recipe = _recipes[itemId];
      if (recipe != null) {
        for (var ingredientEntry in recipe.entries) {
          final ingName = ingredientEntry.key;
          final totalRequired = ingredientEntry.value * qty;
          final index = _inventory.indexWhere((ing) => ing.name == ingName);
          if (index != -1) {
            _inventory[index].currentStock = (_inventory[index].currentStock - totalRequired).clamp(0.0, double.infinity);
          }
        }
      }
    }

    final newOrder = AdminOrder(
      id: (orders.length + 1).toString(),
      tableNumber: table.isNotEmpty ? table : 'Table 4',
      amount: amount,
      status: 'Pending',
      timestamp: DateTime.now(),
    );
    _orders.add(newOrder);
    _saveToPrefs();
    notifyListeners();
  }

  // Standard Order Placement
  void placeOrder(String table, double amount) {
    final newOrder = AdminOrder(
      id: (orders.length + 1).toString(),
      tableNumber: table,
      amount: amount,
      status: 'Pending',
      timestamp: DateTime.now(),
    );
    _orders.add(newOrder);
    _saveToPrefs();
    notifyListeners();
  }

  // Inventory adjustment & PO
  void adjustIngredientStock(String name, double amount) {
    final index = _inventory.indexWhere((element) => element.name.toLowerCase() == name.toLowerCase());
    if (index != -1) {
      _inventory[index].currentStock = amount;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void addIngredient(InventoryIngredient ingredient) {
    _inventory.add(ingredient);
    _saveToPrefs();
    notifyListeners();
  }

  void addWastage(double cost) {
    _wastageCost += cost;
    _saveToPrefs();
    notifyListeners();
  }

  void addStaffMember(StaffMember member) {
    _staff.add(member);
    _saveToPrefs();
    notifyListeners();
  }

  // Staff shift toggles
  void toggleStaffShift(String name) {
    final index = _staff.indexWhere((element) => element.name == name);
    if (index != -1) {
      _staff[index].isOnShift = !_staff[index].isOnShift;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void logout() {
    _isLoggedIn = false;
    _phoneNumber = null;
    _userName = null;
    _userEmail = null;
    _userRole = 'customer';
    _loyaltyCoins = 0;
    _transactionHistory.clear();
    _saveToPrefs();
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
    _saveToPrefs();
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
      _saveToPrefs();
      notifyListeners();
    }
  }
}
