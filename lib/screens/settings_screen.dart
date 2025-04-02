import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';//İngilizce ve Türkçe için dil seçimi yapılıyor.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String) onLocaleChanged;
  
  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLocale = 'tr_TR';

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLocale = prefs.getString('locale') ?? 'tr_TR';
    });
  }

  Future<void> _changeLanguage(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    setState(() {
      _currentLocale = locale;
    });
    widget.onLocaleChanged(locale);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;//İngilizce ve Türkçe için dil seçimi yapılıyor.
    
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/settings'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo[900]!,
                  Colors.indigo[700]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsDescription,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(l10n.profileSettings),
          _buildSettingCard(
            icon: Icons.person_outline,
            title: l10n.profileInfo,
            subtitle: l10n.profileInfoDescription,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            subtitle: l10n.changePasswordDescription,
            onTap: () {},
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(l10n.appSettings),
          _buildSettingCard(
            icon: Icons.notifications_outlined,
            title: l10n.notificationSettings,
            subtitle: l10n.notificationSettingsDescription,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.language,
            title: l10n.language,
            subtitle: l10n.languageDescription,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.language),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Türkçe'),
                        onTap: () {
                          _changeLanguage('tr_TR');
                          Navigator.pop(context);
                        },
                        trailing: _currentLocale == 'tr_TR'
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      ),
                      ListTile(
                        title: const Text('English'),
                        onTap: () {
                          _changeLanguage('en_US');
                          Navigator.pop(context);
                        },
                        trailing: _currentLocale == 'en_US'
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(l10n.other),
          _buildSettingCard(
            icon: Icons.info_outline,
            title: l10n.about,
            subtitle: l10n.aboutDescription,
            onTap: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.delete_outline,
            title: l10n.deleteAccount,
            subtitle: l10n.deleteAccountDescription,
            onTap: () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red[50]
                      : Colors.indigo[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? Colors.red[700]
                      : Colors.indigo[900],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? Colors.red[700]
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}