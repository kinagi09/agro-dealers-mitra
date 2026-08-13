import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'fertilizer_licence_screen.dart';
import 'pesticide_licence_screen.dart';
import 'seed_licence_screen.dart';
import 'notification_settings_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String? _shopName;
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkUnreadNotifications();
    FcmService().initAndRegister();
    // A push arriving while the app is open doesn't trigger the OS
    // notification tray, so refresh the badge here to reflect it right away.
    FirebaseMessaging.onMessage.listen((_) => _checkUnreadNotifications());
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getMyDealerProfile();
      setState(() {
        _shopName = profile['shop_name'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final notifications = await _apiService.getMyNotifications();
      final hasUnread = notifications.any((n) => n['is_read'] == false);
      if (mounted) setState(() => _hasUnreadNotifications = hasUnread);
    } catch (e) {
      // Silently ignore - the badge just won't show, no need to surface an
      // error for something this minor.
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _categoryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_active_outlined),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _checkUnreadNotifications();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isLoading ? '' : (_shopName ?? ''),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else ...[
              const Text(
                'Hello,',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                _shopName ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
            ],
            _categoryButton(
              label: 'Fertilizer Licence',
              icon: Icons.eco,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FertilizerLicenceScreen(),
                  ),
                );
              },
            ),
            _categoryButton(
              label: 'Pesticide Licence',
              icon: Icons.bug_report,
              color: Colors.deepOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PesticideLicenceScreen(),
                  ),
                );
              },
            ),
            _categoryButton(
              label: 'Seed Licence',
              icon: Icons.grass,
              color: Colors.brown,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SeedLicenceScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
