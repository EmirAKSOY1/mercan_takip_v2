import 'package:flutter/material.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Üst Banner
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
                const Text(
                  'Ayarlar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulama ayarlarınızı buradan yönetebilirsiniz',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Profil Ayarları
          _buildSectionTitle('Profil Ayarları'),
          _buildSettingCard(
            icon: Icons.person_outline,
            title: 'Profil Bilgileri',
            subtitle: 'Ad, soyad ve iletişim bilgilerinizi güncelleyin',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            subtitle: 'Hesap şifrenizi güncelleyin',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Uygulama Ayarları
          _buildSectionTitle('Uygulama Ayarları'),
          _buildSettingCard(
            icon: Icons.notifications_outlined,
            title: 'Bildirim Ayarları',
            subtitle: 'Bildirim tercihlerinizi yönetin',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.language,
            title: 'Dil',
            subtitle: 'Uygulama dilini değiştirin',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Diğer
          _buildSectionTitle('Diğer'),
          _buildSettingCard(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: 'Uygulama versiyonu ve lisans bilgileri',
            onTap: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.delete_outline,
            title: 'Hesabı Sil',
            subtitle: 'Hesabınızı kalıcı olarak silin',
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
