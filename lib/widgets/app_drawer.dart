import 'package:carnet/widgets/about.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) return const Drawer();

    final isOwner = user.role == UserRole.shopOwner;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user.role == UserRole.shopOwner ? 'صاحب محل' : 'زبون',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name.isEmpty ? '?' : user.name[0],
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                ),
                opacity: 0.1,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isOwner) ...[
                  _DrawerTile(
                    icon: Icons.people,
                    title: 'الكليان',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/owner/customers');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.shelves,
                    title: 'الرفوف المحل',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/owner/shelves');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.qr_code,
                    title: 'كود المحل',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/owner/qr');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.person_add_alt_1,
                    title: 'دعوة تاجر جديد',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/owner/merchant-qr');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.store,
                    title: 'انضمام لمحل',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/owner/join-shop');
                    },
                  ),
                ] else ...[
                  _DrawerTile(
                    icon: Icons.qr_code_scanner,
                    title: 'إضافة محل جديد',
                    onTap: () {
                      Navigator.pop(context);
                      // Custom logic for customer to scan QR
                      // For now just navigate if there's a route, or we can trigger FAB action
                    },
                  ),
                ],
                const Divider(),
                _DrawerTile(
                  icon: Icons.person,
                  title: 'الملف الشخصي',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    appState.currencyMode == CurrencyMode.rial
                        ? Icons.money
                        : Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    appState.currencyMode == CurrencyMode.rial
                        ? 'العرض بالريال'
                        : 'العرض بالدرهم',
                  ),
                  trailing: Switch(
                    value: appState.currencyMode == CurrencyMode.rial,
                    onChanged: (bool value) {
                      appState.setCurrencyMode(
                        value ? CurrencyMode.rial : CurrencyMode.dirham,
                      );
                    },
                  ),
                ),
                const Divider(),
                _DrawerTile(
                  icon: Icons.info,
                  title: 'حول التطبيق',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutMe(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            color: Colors.red,
            onTap: () async {
              await appState.logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _showAboutMe(BuildContext context) {
    final appState = context.read<AppState>();
    return AboutMe(
      applicationName: 'كارني الكريدي',
      version: appState.appVersion,
      logo: Image.asset('assets/icon/icon.png', height: 100),
      legalese: "جميع الحقوق محفوظة لتطبيق كارني الكريدي",
      description:
          'تطبيق كارني الكريدي هو تطبيق لإدارة الحسابات بين التجار والزبائن',
    ).showCustomAbout(context);
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: color),
      ),
      onTap: onTap,
    );
  }
}
