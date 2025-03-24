import 'package:flutter/material.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/help'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Yardım'),
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nasıl Yardımcı Olabiliriz?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulama hakkında merak ettiğiniz her şey burada',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SSS Bölümü
          const Text(
            'Sıkça Sorulan Sorular',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: 'Kümes verilerini nasıl görüntüleyebilirim?',
            answer: 'Ana sayfadaki "Aktif Kümesler" bölümünden ilgili kümesi seçerek detaylı verileri görüntüleyebilirsiniz. Her kümes için sıcaklık, nem ve diğer sensör verilerini gerçek zamanlı olarak takip edebilirsiniz.',
          ),
          _buildFAQItem(
            question: 'Alarmları nasıl takip edebilirim?',
            answer: 'Alarmlar sayfasından tüm alarmlarınızı görüntüleyebilirsiniz. Kümes ve tarih bazlı filtreleme yaparak istediğiniz alarmları bulabilirsiniz. Ayrıca ana sayfadaki günlük özet kartından günlük alarm sayısını görebilirsiniz.',
          ),
          _buildFAQItem(
            question: 'Kayıtları nasıl filtreleyebilirim?',
            answer: 'Kayıtlar sayfasında kümes seçimi ve tarih aralığı belirleyerek filtreleme yapabilirsiniz. Ayrıca sayfalama özelliği ile kayıtları daha kolay inceleyebilirsiniz.',
          ),
          _buildFAQItem(
            question: 'İstatistikleri nasıl görüntüleyebilirim?',
            answer: 'İstatistikler sayfasından genel istatistikleri ve grafikleri görüntüleyebilirsiniz. Kümes bazlı filtreleme yaparak detaylı analizler elde edebilirsiniz.',
          ),
          const SizedBox(height: 24),

          // İletişim Bölümü
          const Text(
            'İletişim',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email_outlined,
            title: 'E-posta',
            subtitle: 'info@mercantakip.com',
            onTap: () {
              // E-posta gönderme işlemi
            },
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone_outlined,
            title: 'Telefon',
            subtitle: '+90 850 123 4567',
            onTap: () {
              // Telefon arama işlemi
            },
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.chat_outlined,
            title: 'Canlı Destek',
            subtitle: 'Pazartesi - Cumartesi: 09:00 - 18:00',
            onTap: () {
              // Canlı destek başlatma işlemi
            },
          ),
          const SizedBox(height: 24),

          // Destek Merkezi
          const Text(
            'Destek Merkezi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.location_on_outlined,
            title: 'Adres',
            subtitle: 'Merkez Mahallesi, Teknoloji Caddesi No:123\n34000 İstanbul',
            onTap: () {
              // Harita açma işlemi
            },
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            title: 'Çalışma Saatleri',
            subtitle: 'Pazartesi - Cumartesi: 09:00 - 18:00\nPazar: Kapalı',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo[900]),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 