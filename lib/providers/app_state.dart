import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppUser? _currentUser;

  // Mock Data
  final List<AppUser> _users = [
    AppUser(id: 'shop_1', name: 'بقالة السعادة', role: UserRole.shopOwner),
    AppUser(id: 'shop_2', name: 'لوزين المحطة', role: UserRole.shopOwner),
    AppUser(
      id: 'cust_1',
      name: 'أحمد المحسني',
      role: UserRole.customer,
      shopId: 'shop_1',
      shopBalances: {'shop_1': 32.70, 'shop_2': 15.00},
    ),
    AppUser(
      id: 'cust_2',
      name: 'سي محمد بناني',
      role: UserRole.customer,
      shopId: 'shop_1',
      shopBalances: {'shop_1': 145.50},
    ),
    AppUser(
      id: 'cust_3',
      name: 'فاطمة الزهراء',
      role: UserRole.customer,
      shopId: 'shop_1',
      shopBalances: {'shop_1': 0.0},
    ),
  ];

  final List<LedgerItem> _availableItems = [
    LedgerItem(name: 'خبز دار', price: 1.20, iconName: 'bakery_dining'),
    LedgerItem(
      name: 'أتاي (السبع)',
      price: 13.00,
      iconName: 'emoji_food_beverage',
    ),
    LedgerItem(name: 'زيت لوسيور (1 لتر)', price: 18.50, iconName: 'opacity'),
    LedgerItem(name: 'سكر قالب', price: 13.00, iconName: 'grid_view'),
    LedgerItem(name: 'دقيق ميمونة (1 كجم)', price: 8.00, iconName: 'grain'),
    LedgerItem(name: 'سيدي علي (1.5 لتر)', price: 6.00, iconName: 'water_drop'),
  ];

  final List<LedgerTransaction> _transactions = [];

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  List<AppUser> get customers =>
      _users.where((u) => u.role == UserRole.customer).toList();
  List<LedgerItem> get availableItems => _availableItems;
  List<LedgerTransaction> get transactions => [..._transactions];

  AppUser? getCustomerById(String id) => _users.cast<AppUser?>().firstWhere(
    (u) => u?.id == id,
    orElse: () => null,
  );

  AppUser? getShopById(String id) => _users.cast<AppUser?>().firstWhere(
    (u) => u?.id == id && u?.role == UserRole.shopOwner,
    orElse: () => null,
  );

  List<LedgerTransaction> getTransactionsForCustomer(String customerId) {
    return _transactions.where((t) => t.customerId == customerId).toList();
  }

  // Actions
  void login(String userId) {
    _currentUser = _users.cast<AppUser?>().firstWhere(
      (u) => u?.id == userId,
      orElse: () => null,
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void addPurchase(String customerId, List<LedgerItem> items) {
    if (items.isEmpty) return;

    final customer = getCustomerById(customerId);
    if (customer == null) return;

    double total = items.fold(0, (sum, item) => sum + item.price);

    // Create transaction
    final tx = LedgerTransaction(
      customerId: customerId,
      shopId: customer.shopId ?? 'shop_1',
      items: items,
      totalAmount: total,
      date: DateTime.now(),
    );

    _transactions.add(tx);

    // Update balance
    customer.shopBalances[tx.shopId] =
        (customer.shopBalances[tx.shopId] ?? 0) + total;

    notifyListeners();
  }

  void deleteTransaction(String transactionId) {
    final txIndex = _transactions.indexWhere((t) => t.id == transactionId);
    if (txIndex == -1) return;

    final tx = _transactions[txIndex];
    final customer = getCustomerById(tx.customerId);

    if (customer != null) {
      customer.shopBalances[tx.shopId] =
          (customer.shopBalances[tx.shopId] ?? 0) - tx.totalAmount;
      if (customer.shopBalances[tx.shopId]! < 0)
        customer.shopBalances[tx.shopId] = 0;
    }

    _transactions.removeAt(txIndex);
    notifyListeners();
  }

  void updateTransactionItemTotalPrice(
    String transactionId,
    String itemId,
    double newPrice,
  ) {
    // Note: Since LedgerItem has final price, we will recreate the item and update the transaction total.
    final txIndex = _transactions.indexWhere((t) => t.id == transactionId);
    if (txIndex == -1) return;

    final tx = _transactions[txIndex];
    final itemIndex = tx.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final oldItem = tx.items[itemIndex];
    final priceDiff = newPrice - oldItem.price;

    final newItem = LedgerItem(
      name: oldItem.name,
      price: newPrice,
      iconName: oldItem.iconName,
    );

    // Replace item
    tx.items[itemIndex] = newItem;

    // Since LedgerTransaction has final totalAmount, we need to create a new transaction to replace the old one
    // or just make them mutable. Since they are final, let's create a new transaction object:
    final newTx = LedgerTransaction(
      customerId: tx.customerId,
      shopId: tx.shopId,
      items: tx.items,
      totalAmount: tx.totalAmount + priceDiff,
      date: tx.date,
    );

    _transactions[txIndex] = newTx;

    // Update customer balance
    final customer = getCustomerById(tx.customerId);
    if (customer != null) {
      customer.shopBalances[tx.shopId] =
          (customer.shopBalances[tx.shopId] ?? 0) + priceDiff;
    }

    notifyListeners();
  }
}
