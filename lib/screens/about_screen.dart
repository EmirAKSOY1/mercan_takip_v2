import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versiyon bilgisi alınamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/about'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Hakkında'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Logo ve Uygulama Adı
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.track_changes,
                          size: 80,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mercan Takip',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Versiyon $_version (Build $_buildNumber)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Uygulama Bilgileri
                _buildInfoCard(
                  title: 'Uygulama Hakkında',
                  content: 'Mercan Takip, kümes yönetimini kolaylaştırmak için tasarlanmış bir mobil uygulamadır. '
                      'Sensör verilerini gerçek zamanlı takip etmenizi, alarmları yönetmenizi ve '
                      'kümes performansını analiz etmenizi sağlar.',
                ),
                const SizedBox(height: 16),

                // İletişim Bilgileri
                _buildInfoCard(
                  title: 'İletişim',
                  content: 'Destek ve iletişim için:\n\n'
                      'E-posta: info@mercantakip.com\n'
                      'Telefon: +90 850 123 4567\n'
                      'Adres: Merkez Mahallesi, Teknoloji Caddesi No:123\n'
                      '34000 İstanbul',
                ),
                const SizedBox(height: 16),

                // Lisans Bilgileri
                _buildInfoCard(
                  title: 'Lisans',
                  content: '© 2024 Mercan Takip. Tüm hakları saklıdır.\n\n'
                      'Bu uygulama, Mercan Takip kullanıcıları için özel olarak geliştirilmiştir '
                      've ticari kullanım için lisans gerektirir.',
                ),
                const SizedBox(height: 16),

                // Gizlilik Politikası
                _buildInfoCard(
                  title: 'Gizlilik Politikası',
                  content: 'Mercan Takip olarak kişisel verilerinizin güvenliği bizim için önemlidir. '
                      'Verileriniz şifreli olarak saklanır ve üçüncü taraflarla paylaşılmaz. '
                      'Detaylı bilgi için gizlilik politikamızı inceleyebilirsiniz.',
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 