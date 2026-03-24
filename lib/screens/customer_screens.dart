import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class CustomerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (user == null)
      return const Scaffold(
        body: Center(child: Text('عذراً، يجب تسجيل الدخول')),
      );

    final transactions = appState.getTransactionsForCustomer(user.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً بك، ${user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              appState.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Multi-Shop Balances
            ...user.shopBalances.entries.map((entry) {
              final shopId = entry.key;
              final balance = entry.value;
              final shop = appState.getShopById(shopId);
              final shopName = shop?.name ?? 'حانوت مجهول';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      const Color(0xFF003366),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'كريدي $shopName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${balance.toStringAsFixed(2)} درهم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.push('/customer/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('مسح كود الحانوت'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'آخر العمليات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              const Text('لا توجد عمليات سابقة.')
            else
              ...transactions.reversed.take(10).map((tx) {
                final shop = appState.getShopById(tx.shopId);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text('${tx.totalAmount.toStringAsFixed(2)} درهم'),
                    subtitle: Text(
                      '${shop?.name ?? ''} - ${tx.date.toString().substring(0, 16)}',
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class ScanQRCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح كود الحانوت')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.qr_code_scanner, size: 100),
            ),
            const SizedBox(height: 32),
            const Text(
              'قم بتوجيه الكاميرا نحو كود الحانوت',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Simulate scan success
                final customerId = context.read<AppState>().currentUser?.id;
                if (customerId != null) {
                  context.pushReplacement('/customer/add/$customerId');
                }
              },
              child: const Text('محاكاة المسح الناجح'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddPurchaseScreen extends StatefulWidget {
  final String? customerId;
  const AddPurchaseScreen({Key? key, this.customerId}) : super(key: key);

  @override
  _AddPurchaseScreenState createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final List<LedgerItem> _selectedItems = [];

  IconData _getIconData(String name) {
    switch (name) {
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'emoji_food_beverage':
        return Icons.emoji_food_beverage;
      case 'opacity':
        return Icons.opacity;
      case 'grid_view':
        return Icons.grid_view;
      case 'grain':
        return Icons.grain;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.shopping_cart;
    }
  }

  void _addItem(LedgerItem item) {
    setState(() {
      _selectedItems.add(item);
    });
  }

  void _checkout() {
    if (_selectedItems.isEmpty) return;
    final customerId =
        widget.customerId ?? context.read<AppState>().currentUser?.id;
    if (customerId != null) {
      context.read<AppState>().addPurchase(customerId, _selectedItems);
      context.pop(); // Go back after success
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تقييد السلعة بنجاح!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableItems = context.read<AppState>().availableItems;
    final total = _selectedItems.fold(0.0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(title: const Text('تقييد السلعة')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items Grid
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عزل السلعة اللي خديتي باش تزيدها فالكريدي',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: availableItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == availableItems.length) {
                        return InkWell(
                          onTap: () {
                            final nameController = TextEditingController();
                            final priceController = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('إضافة منتج آخر'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم المنتج',
                                      ),
                                    ),
                                    TextField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'الثمن (درهم)',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final name = nameController.text.trim();
                                      final price = double.tryParse(
                                        priceController.text,
                                      );
                                      if (name.isNotEmpty &&
                                          price != null &&
                                          price > 0) {
                                        _addItem(
                                          LedgerItem(
                                            name: name,
                                            price: price,
                                            iconName: 'shopping_cart',
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('إضافة'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 36,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'منتج آخر',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final item = availableItems[index];
                      return InkWell(
                        onTap: () => _addItem(item),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getIconData(item.iconName),
                                  size: 36,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${item.price.toStringAsFixed(2)} درهم',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Integrity Rule Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'قانون الكارني والنزاهة',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'باش تضمن أن التقييد فالكارني دقيق، ميمكنش تمسح السلعة من بعد ما تختارها. تأكد مزيان من الكمية عاد ورك على تأكيد.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Cart (Ledger)
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التقييد اللي دابا',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        // Notice there is NO delete button here! Rule enforced.
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item.name)),
                              Text(
                                '${item.price.toStringAsFixed(2)} درهم',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع'),
                      Text(
                        '${total.toStringAsFixed(2)} درهم',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedItems.isEmpty ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'تأكيد التقييد',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
