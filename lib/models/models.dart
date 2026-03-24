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
  }) : this.shopBalances = shopBalances ?? {};
}

class LedgerItem {
  final String id;
  final String name;
  final double price;
  final String iconName;

  LedgerItem({required this.name, required this.price, required this.iconName})
    : id = const Uuid().v4();
}

class LedgerTransaction {
  final String id;
  final String customerId;
  final String shopId;
  final List<LedgerItem> items;
  final double totalAmount;
  final DateTime date;

  LedgerTransaction({
    required this.customerId,
    required this.shopId,
    required this.items,
    required this.totalAmount,
    required this.date,
  }) : id = const Uuid().v4();
}
