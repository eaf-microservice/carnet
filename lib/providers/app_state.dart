import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  List<LedgerItem> _availableItems = [];
  List<LedgerTransaction> _transactions = [];

  StreamSubscription? _usersSub;
  StreamSubscription? _itemsSub;
  StreamSubscription? _txSub;

  AppState() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        _cancelSubscriptions();
        notifyListeners();
      } else {
        await _fetchCurrentUser(user.uid);
        _startSubscriptions();
      }
    });
  }

  void _cancelSubscriptions() {
    _usersSub?.cancel();
    _itemsSub?.cancel();
    _txSub?.cancel();
  }

  void _startSubscriptions() {
    _cancelSubscriptions();

    // Sync Users — also keep _currentUser fresh in real-time
    _usersSub = _firestore.collection('users').snapshots().listen((snap) {
      _allUsers = snap.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
      // Keep _currentUser in sync with its Firestore document
      if (_currentUser != null) {
        final updated = _allUsers.cast<AppUser?>().firstWhere(
          (u) => u?.id == _currentUser!.id,
          orElse: () => null,
        );
        if (updated != null) _currentUser = updated;
      }
      notifyListeners();
    }, onError: (e) => debugPrint('Error fetching users: $e'));

    // Sync Items
    _itemsSub = _firestore.collection('items').snapshots().listen((snap) {
      _availableItems = snap.docs
          .map((doc) => LedgerItem.fromMap(doc.data()))
          .toList();
      notifyListeners();
    }, onError: (e) => debugPrint('Error fetching items: $e'));

    // Sync Transactions
    _txSub = _firestore.collection('transactions').snapshots().listen((snap) {
      _transactions = snap.docs
          .map((doc) => LedgerTransaction.fromMap(doc.data()))
          .toList();
      notifyListeners();
    }, onError: (e) => debugPrint('Error fetching transactions: $e'));
  }

  Future<void> _fetchCurrentUser(String uid) async {
    try {
      debugPrint('Fetching user data for: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('User data found: $data');
        _currentUser = AppUser.fromMap(data);
        debugPrint('AppUser object created for: ${_currentUser?.name}');
        notifyListeners();
      } else {
        debugPrint('User document does not exist in Firestore for: $uid');
      }
    } catch (e, stack) {
      debugPrint('CRITICAL ERROR fetching current user: $e');
      debugPrint(stack.toString());
    }
  }

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  List<AppUser> getCustomersForShop(String shopId) {
    return _allUsers
        .where(
          (u) =>
              u.role == UserRole.customer && u.shopBalances.containsKey(shopId),
        )
        .toList();
  }

  List<LedgerItem> get availableItems => _availableItems;
  List<LedgerTransaction> get transactions => [..._transactions];

  AppUser? getCustomerById(String id) => _allUsers.cast<AppUser?>().firstWhere(
    (u) => u?.id == id,
    orElse: () => null,
  );

  AppUser? getShopById(String id) => _allUsers.cast<AppUser?>().firstWhere(
    (u) => u?.id == id && u?.role == UserRole.shopOwner,
    orElse: () => null,
  );

  List<LedgerTransaction> getTransactionsForCustomer(String customerId) {
    return _transactions.where((t) => t.customerId == customerId).toList();
  }

  // Actions
  Future<void> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = AppUser(
      id: cred.user!.uid,
      name: name,
      role: role,
      shopId: role == UserRole.shopOwner ? cred.user!.uid : null,
    );
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // Check if user exists in Firestore, if not create
    final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      final newUser = AppUser(
        id: cred.user!.uid,
        name: googleUser.displayName ?? 'مستخدم جوجل',
        role: UserRole.customer, // Default to customer
      );
      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> addManualCustomer(String name, String shopId) async {
    // Generate a unique ID for the manual customer
    final customerId = 'manual_${const Uuid().v4()}';
    final customer = AppUser(
      id: customerId,
      name: name,
      role: UserRole.customer,
      shopBalances: {shopId: 0.0},
    );
    
    await _firestore.collection('users').doc(customerId).set(customer.toMap());
  }

  Future<void> linkManualCustomerToReal(
    String manualId,
    String realId,
    String shopId,
  ) async {
    // 1. Get manual customer data
    final manualCustomer = getCustomerById(manualId);
    if (manualCustomer == null) return;

    final balance = manualCustomer.shopBalances[shopId] ?? 0;

    // 2. Update real user's balance
    final realUserRef = _firestore.collection('users').doc(realId);
    final realUserDoc = await realUserRef.get();
    if (realUserDoc.exists) {
      final realUser = AppUser.fromMap(realUserDoc.data()!);
      Map<String, double> newBalances = Map.of(realUser.shopBalances);
      newBalances[shopId] = (newBalances[shopId] ?? 0) + balance;

      await realUserRef.update({
        'shopBalances': newBalances,
      });
    }

    // 3. Migrate transactions
    final txQuery = await _firestore
        .collection('transactions')
        .where('customerId', isEqualTo: manualId)
        .where('shopId', isEqualTo: shopId)
        .get();

    final batch = _firestore.batch();
    for (var doc in txQuery.docs) {
      batch.update(doc.reference, {'customerId': realId});
    }

    // 4. Delete manual customer
    batch.delete(_firestore.collection('users').doc(manualId));

    await batch.commit();
  }

  Future<void> linkCustomerToShop(String customerId, String shopId) async {
    final customer = getCustomerById(customerId);
    if (customer != null && !customer.shopBalances.containsKey(shopId)) {
      customer.shopBalances[shopId] = 0.0;
      await _firestore.collection('users').doc(customerId).update({
        'shopBalances': customer.shopBalances,
      });
    }
  }

  Future<void> addPurchase(
    String customerId,
    String shopId,
    List<LedgerItem> items,
  ) async {
    if (items.isEmpty) return;
    final customer = getCustomerById(customerId);
    if (customer == null) return;

    // ignore: avoid_types_as_parameter_names
    double total = items.fold(0.0, (sum, item) => sum + (item.price * item.quantite));
    
    debugPrint('Saving purchase for $customerId in shop $shopId. Total: $total');
    
    try {
      final tx = LedgerTransaction(
        customerId: customerId,
        shopId: shopId,
        merchantId: _currentUser?.id,
        items: items,
        totalAmount: total,
        date: DateTime.now(),
      );

      await _firestore.collection('transactions').doc(tx.id).set(tx.toMap());
      debugPrint('Transaction saved: ${tx.id}');

      // Update balance
      customer.shopBalances[shopId] = (customer.shopBalances[shopId] ?? 0) + total;
      await _firestore.collection('users').doc(customerId).update({
        'shopBalances': customer.shopBalances,
      });
      debugPrint('Balance updated in Firestore for $customerId');
    } catch (e, stack) {
      debugPrint('ERROR in addPurchase saving to Firestore: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> addItemToShop(LedgerItem item) async {
    final ownerShopId = _currentUser?.shopId;
    if (ownerShopId == null) {
      debugPrint('ERROR: addItemToShop failed because ownerShopId is null. CurrentUser: ${_currentUser?.id}, Role: ${_currentUser?.role}');
      return;
    }

    final newItem = LedgerItem(
      id: item.id,
      name: item.name,
      price: item.price,
      quantite: item.quantite,
      iconName: item.iconName,
      shopId: ownerShopId,
    );

    debugPrint('Adding item to shop shelf: ${newItem.name}');
    try {
      await _firestore.collection('items').doc(newItem.id).set(newItem.toMap());
      debugPrint('Item saved successfully: ${newItem.id}');
    } catch (e) {
      debugPrint('Error saving item: $e');
    }
  }

  Future<void> removeItemFromShop(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  List<LedgerItem> getItemsForShop(String shopId) {
    return _availableItems.where((i) => i.shopId == shopId || i.shopId == null).toList();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final txIndex = _transactions.indexWhere((t) => t.id == transactionId);
    if (txIndex == -1) return;

    final tx = _transactions[txIndex];
    final customer = getCustomerById(tx.customerId);

    if (customer != null) {
      customer.shopBalances[tx.shopId] =
          (customer.shopBalances[tx.shopId] ?? 0) - tx.totalAmount;
      if (customer.shopBalances[tx.shopId]! < 0) {
        customer.shopBalances[tx.shopId] = 0;
      }

      await _firestore.collection('users').doc(tx.customerId).update({
        'shopBalances': customer.shopBalances,
      });
    }

    await _firestore.collection('transactions').doc(transactionId).delete();
  }

  Future<void> updateTransactionItemTotalPrice(
    String transactionId,
    String itemId,
    double newPrice,
  ) async {
    // Re-implementing logic for Firestore
    final txIndex = _transactions.indexWhere((t) => t.id == transactionId);
    if (txIndex == -1) return;

    final tx = _transactions[txIndex];
    final itemIndex = tx.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final oldItem = tx.items[itemIndex];

    final newItem = LedgerItem(
      id: oldItem.id,
      name: oldItem.name,
      price: newPrice,
      quantite: oldItem.quantite,
      iconName: oldItem.iconName,
    );

    // Update local copy
    tx.items[itemIndex] = newItem;
    
    // Recalculate total from scratch for safety
    final newTotal = tx.items.fold(0.0, (sum, item) => sum + (item.price * item.quantite));
    final totalDiff = newTotal - tx.totalAmount;

    await _firestore.collection('transactions').doc(transactionId).update({
      'items': tx.items.map((i) => i.toMap()).toList(),
      'totalAmount': newTotal,
    });

    final customer = getCustomerById(tx.customerId);
    if (customer != null) {
      customer.shopBalances[tx.shopId] = (customer.shopBalances[tx.shopId] ?? 0) + totalDiff;
      await _firestore.collection('users').doc(tx.customerId).update({
        'shopBalances': customer.shopBalances,
      });
    }
  }

  Future<void> linkMerchantToShop(String userId, String shopId) async {
    final userRef = _firestore.collection('users').doc(userId);
    await userRef.update({
      'shopId': shopId,
      'role': UserRole.shopOwner.name,
    });
  }

  /// Returns all users who are co-merchants of a given shop (excluding the original owner).
  List<AppUser> getMerchantsForShop(String shopId, String ownerId) {
    return _allUsers
        .where((u) =>
            u.shopId == shopId &&
            u.role == UserRole.shopOwner &&
            u.id != ownerId)
        .toList();
  }

  /// Revokes a merchant's access to the shop.
  Future<void> revokeMerchantFromShop(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'shopId': null,
      'role': UserRole.customer.name,
    });
  }

  /// Transfers full shop ownership to another user.
  /// The new owner gets the shopId; the old owner loses it.
  Future<void> transferShopOwnership(String newOwnerId, String shopId) async {
    final batch = _firestore.batch();
    // New owner gets the shop
    batch.update(_firestore.collection('users').doc(newOwnerId), {
      'shopId': shopId,
      'role': UserRole.shopOwner.name,
    });
    // Old owner is demoted (keep as customer)
    if (_currentUser != null && _currentUser!.id != newOwnerId) {
      batch.update(_firestore.collection('users').doc(_currentUser!.id), {
        'shopId': null,
        'role': UserRole.customer.name,
      });
    }
    await batch.commit();
  }
}
