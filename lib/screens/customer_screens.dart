import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/app_drawer.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('عذراً، يجب تسجيل الدخول')),
      );
    }

    final transactions = appState.getTransactionsForCustomer(user.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً بك، ${user.name}'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...user.shopBalances.entries.map((entry) {
              final shopId = entry.key;
              final balance = entry.value;
              final shop = appState.getShopById(shopId);
              final shopName = shop?.name ?? 'حانوت مجهول';

              final shopTransactions = transactions
                  .where((t) => t.shopId == shopId)
                  .toList()
                  .reversed
                  .take(3)
                  .toList();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            const Color(0xFF003366),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
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
                            appState.formatCurrency(balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'آخر العمليات مع هذا المحل:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    context.push('/customer/add/$shopId'),
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 18,
                                ),
                                label: const Text('تقييد سلعة'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (shopTransactions.isEmpty)
                            const Text('لا توجد عمليات سابقة.')
                          else
                            ...shopTransactions.map(
                              (tx) => ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.shopping_bag,
                                  size: 20,
                                ),
                                title: Text(
                                  appState.formatCurrency(tx.totalAmount),
                                ),
                                subtitle: Text(
                                  tx.date.toString().substring(0, 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.push('/customer/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('ربط مع حانوت جديد (Scan QR)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class ScanQRCodeScreen extends StatefulWidget {
  const ScanQRCodeScreen({super.key});

  @override
  State<ScanQRCodeScreen> createState() => _ScanQRCodeScreenState();
}

class _ScanQRCodeScreenState extends State<ScanQRCodeScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الربط مع حانوت جديد')),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) async {
                if (!_isScanning) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null) {
                    setState(() => _isScanning = false);
                    final appState = context.read<AppState>();
                    final customerId = appState.currentUser?.id;
                    if (customerId != null) {
                      if (code.startsWith('link:')) {
                        final parts = code.split(':');
                        if (parts.length == 3) {
                          final shopId = parts[1];
                          final manualId = parts[2];
                          await appState.linkManualCustomerToReal(
                            manualId,
                            customerId,
                            shopId,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم ربط حسابك بالملف القديم بنجاح!')),
                            );
                            context.pushReplacement('/customer/add/$shopId');
                          }
                        }
                      } else if (code.startsWith('merchant-link:')) {
                        final parts = code.split(':');
                        if (parts.length == 2) {
                          final shopId = parts[1];
                          await appState.linkMerchantToShop(customerId, shopId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم الانضمام للمحل كتاجر مساعد بنجاح!')),
                            );
                            context.go('/owner');
                          }
                        }
                      } else {
                        await appState.linkCustomerToShop(customerId, code);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم الربط مع الحانوت بنجاح!')),
                          );
                          context.pushReplacement('/customer/add/$code');
                        }
                      }
                    }
                    break;
                  }
                }
              },
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'قم بتصوير رمز الحانوت للربط معه',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPurchaseScreen extends StatefulWidget {
  final String shopId;
  final String? customerId;
  const AddPurchaseScreen({super.key, required this.shopId, this.customerId});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final List<LedgerItem> _selectedItems = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'bakery_dining': return Icons.bakery_dining;
      case 'emoji_food_beverage': return Icons.emoji_food_beverage;
      case 'opacity': return Icons.opacity;
      case 'grid_view': return Icons.grid_view;
      case 'grain': return Icons.grain;
      case 'water_drop': return Icons.water_drop;
      default: return Icons.shopping_cart;
    }
  }

  void _addItem(LedgerItem item) {
    setState(() {
      final index = _selectedItems.indexWhere(
        (i) => i.name == item.name && i.price == item.price,
      );
      if (index != -1) {
        final existing = _selectedItems[index];
        _selectedItems[index] = LedgerItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantite: existing.quantite + item.quantite,
          iconName: existing.iconName,
        );
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _checkout() async {
    if (_selectedItems.isEmpty) return;
    final customerId = widget.customerId ?? context.read<AppState>().currentUser?.id;
    if (customerId != null) {
      await context.read<AppState>().addPurchase(customerId, widget.shopId, _selectedItems);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تقييد السلعة بنجاح!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final availableItems = appState.getItemsForShop(widget.shopId);
    final total = _selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantite));
    final filteredItems = availableItems
        .where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('تقييد السلعة')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'نصيحة: ورك مزيان (Long Press) على السلعة باش تحدد الكمية لي بغيت.',
                            style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'قلب على السلعة...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filteredItems.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filteredItems.length) {
                              return InkWell(
                                onTap: () {
                                  final nameCtrl = TextEditingController();
                                  final priceCtrl = TextEditingController();
                                  final qCtrl = TextEditingController(text: '1');
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('إضافة منتج آخر'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المنتج')),
                                          TextField(
                                            controller: priceCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'الثمن (${context.read<AppState>().currencyMode == CurrencyMode.rial ? 'بالريال' : 'بالدرهم'})',
                                            ),
                                          ),
                                          TextField(controller: qCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                                        TextButton(
                                          onPressed: () {
                                            final name = nameCtrl.text.trim();
                                            final p = double.tryParse(priceCtrl.text);
                                            final q = double.tryParse(qCtrl.text);
                                            if (name.isNotEmpty && p != null && q != null) {
                                              final actualPrice = appState.convertToDirham(p);
                                              _addItem(LedgerItem(name: name, price: actualPrice, quantite: q, iconName: 'shopping_cart'));
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
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 28),
                                        SizedBox(height: 4),
                                        Text('منتج آخر', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            final item = filteredItems[index];
                            return InkWell(
                              onTap: () => _addItem(LedgerItem(name: item.name, price: item.price, quantite: 1.0, iconName: item.iconName)),
                              onLongPress: () {
                                final qCtrl = TextEditingController(text: '1');
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('كمية من ${item.name}'),
                                    content: TextField(controller: qCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية', suffixText: 'قطع'), autofocus: true),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                                      TextButton(
                                        onPressed: () {
                                          final q = double.tryParse(qCtrl.text);
                                          if (q != null && q > 0) {
                                            _addItem(LedgerItem(name: item.name, price: item.price, quantite: q, iconName: item.iconName));
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text('تأكيد'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_getIconData(item.iconName), size: 28, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(height: 4),
                                      FittedBox(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Text(appState.formatCurrency(item.price), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            border: const Border(right: BorderSide(color: Colors.blue, width: 4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock, color: Colors.blue),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('قانون الكارني والنزاهة', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('تقدر تحيد السلعة دابة إلا غلطتي، ولكن من بعد ما تورك على "تأكيد التقييد" العملية كتسجل فالحين.', style: TextStyle(fontSize: 12)),
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
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('التقييد الحالي', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => _removeItem(index),
                                child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.quantite > 1 ? '${item.name} (x${item.quantite.toStringAsFixed(0)})' : item.name,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      appState.formatCurrency(item.price * item.quantite),
                                      style: TextStyle(
                                        color: Colors.blueGrey[700],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المجموع:', style: TextStyle(fontSize: 12)),
                      FittedBox(
                        child: Text(
                          appState.formatCurrency(total),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _selectedItems.isEmpty ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'تأكيد التقييد',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
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
