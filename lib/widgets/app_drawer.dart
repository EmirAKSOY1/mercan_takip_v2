import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MERCAN',
                        style: TextStyle(
                          color: Colors.indigo[900],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TAKIP',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard_rounded,
              title: l10n.dashboard,
              isSelected: currentRoute == '/home',
              onTap: () {
                if (currentRoute != '/home') {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/home');
                }
              },
            ),/*
            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'İstatistikler',
              isSelected: currentRoute == '/statistics',
              onTap: () {
                
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/statistics');
                
                
              },
            ),*/
            /*_buildDrawerItem(
              icon: Icons.bookmark_rounded,
              title: 'Kayıtlar',
              isSelected: currentRoute == '/datas',
              onTap: () {

                Navigator.pop(context);
                Navigator.pushNamed(context, '/datas');
              },
            ),*/
            _buildDrawerItem(
              icon: Icons.notifications_rounded,
              title: l10n.alarms,
              isSelected: currentRoute == '/alarms',
              onTap: () {

                Navigator.pop(context);
                Navigator.pushNamed(context, '/alarms');
              },
            ),
            _buildDrawerItem(
              icon: Icons.calendar_today,
              title: l10n.terms,
              isSelected: currentRoute == '/periods',
              onTap: () {

                Navigator.pop(context);
                Navigator.pushNamed(context, '/periods');
              },
            ),
            _buildDrawerItem(
              icon: Icons.summarize,
              title: l10n.reports,
              isSelected: currentRoute == '/reports',
              onTap: () {

                Navigator.pop(context);
                Navigator.pushNamed(context, '/reports');
              },
            ),
            const SizedBox(height: 26),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.other,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: l10n.settings,
              isSelected: currentRoute == '/settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline_rounded,
              title: l10n.help,
              isSelected: currentRoute == '/help',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/help');
              },
            ),
            _buildDrawerItem(
              icon: Icons.science,
              title: 'Test Ekranı',
              isSelected: currentRoute == '/escape',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/escape');
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: l10n.logout,
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Çıkış Yap'),
                    content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Çıkış Yap',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.indigo[900] : Colors.grey[600],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.indigo[900] : Colors.grey[800],
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
      dense: true,
    );
  }
} 