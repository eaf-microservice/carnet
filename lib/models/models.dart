import 'package:uuid/uuid.dart';

enum UserRole { shopOwner, customer }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? shopId; // The shop they own or are connected to
  final String? profileImageUrl;
  Map<String, double> shopBalances; // key: shopId, value: balance

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.shopId,
    this.profileImageUrl,
    Map<String, double>? shopBalances,
  }) : shopBalances = shopBalances ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'shopId': shopId,
      'profileImageUrl': profileImageUrl,
      'shopBalances': shopBalances,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final role = UserRole.values.firstWhere(
      (e) => e.name == map['role'],
      orElse: () => UserRole.customer,
    );
    final id = map['id'] ?? '';
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      role: role,
      shopId: map['shopId'] ?? (role == UserRole.shopOwner ? id : null),
      profileImageUrl: map['profileImageUrl'],
      shopBalances: (map['shopBalances'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

class LedgerItem {
  final String id;
  final String name;
  final double price;
  final double quantite;
  final String iconName;
  final String? shopId; // The shop this item belongs to

  LedgerItem({
    String? id,
    required this.name,
    required this.price,
    required this.quantite,
    required this.iconName,
    this.shopId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantite': quantite,
      'iconName': iconName,
      'shopId': shopId,
    };
  }

  factory LedgerItem.fromMap(Map<String, dynamic> map) {
    return LedgerItem(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantite: (map['quantite'] ?? 0.0).toDouble(),
      iconName: map['iconName'] ?? '',
      shopId: map['shopId'],
    );
  }
}

class LedgerTransaction {
  final String id;
  final String customerId;
  final String shopId;
  final String? merchantId; // The merchant who recorded this
  final List<LedgerItem> items;
  final double totalAmount;
  final DateTime date;

  LedgerTransaction({
    String? id,
    required this.customerId,
    required this.shopId,
    this.merchantId,
    required this.items,
    required this.totalAmount,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'shopId': shopId,
      'merchantId': merchantId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
    };
  }

  factory LedgerTransaction.fromMap(Map<String, dynamic> map) {
    return LedgerTransaction(
      id: map['id'],
      customerId: map['customerId'] ?? '',
      shopId: map['shopId'] ?? '',
      merchantId: map['merchantId'],
      items: (map['items'] as List? ?? [])
          .map((i) => LedgerItem.fromMap(i))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
}
