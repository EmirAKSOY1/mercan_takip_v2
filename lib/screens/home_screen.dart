import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/screens/sensor_data_screen.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';
import 'package:mercan_takip_v2/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _generalData = {
    'totalData': '0',
    'totalAnimals': '0',
    'totalAlarms': '0',
    'totalCoops': '0',
  };
  bool _isLoading = true;
  List<Coop> _activeCoops = [];

  @override
  void initState() {
    super.initState();
    _fetchGeneralData();
    _fetchActiveCoops();
  }

  Future<void> _fetchGeneralData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://62.171.140.229/api/getGeneralData'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _generalData = {
            'totalData': data['totalData'],
            'totalAnimals': data['totalAnimals'],
            'totalAlarms': data['totalAlarms'],
            'totalCoops': data['totalCoops'],
          };
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri yüklenirken hata oluştu: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveCoops() async {
    try {
      final response = await http.get(Uri.parse('http://62.171.140.229/api/getCoops'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _activeCoops = data.map((coop) => Coop.fromJson(coop)).toList();
        });
      } else {
        throw Exception('Failed to load active coops');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktif kümesler yüklenirken hata oluştu: ${e.toString()}')),
      );
    }
  }

  String _getCurrentDay() {
    return DateFormat('EEEE', 'tr_TR').format(DateTime.now());
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çıkış yapılırken bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _getCurrentDay();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(currentRoute: '/home'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Merhaba, Agrokush',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.waving_hand, color: Colors.amber),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Premium Üye',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGeneralData,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hava Durumu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentDay, 20°C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Güneşli',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // İstatistik Kartları
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      icon: Icons.data_usage,
                      iconColor: Colors.blue,
                      title: _generalData['totalData'],
                      subtitle: 'Toplam Veri',
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                    _buildStatCard(
                      icon: Icons.pets,
                      iconColor: Colors.green,
                      title: _generalData['totalAnimals'],
                      subtitle: 'Toplam Hayvan',
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                    _buildStatCard(
                      icon: Icons.warning,
                      iconColor: Colors.red,
                      title: _generalData['totalAlarms'],
                      subtitle: 'Bugün Alarm',
                      backgroundColor: Colors.red.withOpacity(0.1),
                    ),
                    _buildStatCard(
                      icon: Icons.home,
                      iconColor: Colors.purple,
                      title: _generalData['totalCoops'],
                      subtitle: 'Toplam Kümes',
                      backgroundColor: Colors.purple.withOpacity(0.1),
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Aktif Kümesler Başlığı
          const Text(
            'Aktif Kümesler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Aktif Kümesler Listesi
          ..._activeCoops.map((coop) => Column(
            children: [
              _buildCoopCard(
                coopId: coop.coopId,
                coopName: coop.coopName,
                day: coop.day,
              ),
              const SizedBox(height: 16), // 16 piksel boşluk
            ],
          )).toList(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopCard({
    required String coopId,
    required String coopName,
    required int day,
  }) {
    // Her bar 5 günü temsil eder (45/9=5)
    final int activeIndicators = (day / 5).ceil();
    final indicators = List.generate(
      9, // Toplam 9 bar (45 gün / 5 = 9 bar)
      (index) => Container(
        width: 24,
        height: 8,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: index < activeIndicators ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorDataScreen2(coopId: coopId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      coopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$day. Gün',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              coopId,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: indicators,
            ),
          ],
        ),
      ),
    );
  }
}

class Coop {
  final String coopId;
  final String coopName;
  final int day;

  Coop({required this.coopId, required this.coopName, required this.day});

  factory Coop.fromJson(Map<String, dynamic> json) {
    return Coop(
      coopId: json['coopId'],
      coopName: json['coopName'],
      day: json['day'],
    );
  }
}
/*
class SensorDataScreen extends StatelessWidget {
  final String coopId;

  SensorDataScreen({required this.coopId});

  Future<List<dynamic>> _fetchSensorData() async {
    final response = await http.get(Uri.parse('http://62.171.140.229/api/getSensorData?coopId=$coopId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sensor data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensör Verileriii - $coopId'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchSensorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: \\${snapshot.error}'));
          } else {
            final sensorData = snapshot.data!;
            final latestData = sensorData.isNotEmpty ? sensorData.last : null;

            return Center(
              child: Stack(
                children: [
                  Image.asset('assets/images/coop_image.png'), // Kümes resmi
                  if (latestData != null) ...[
                    Positioned(
                      top: 20,
                      left: 20,
                      child: _buildSensorBox('Sıcaklık', '\\12°C'),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: _buildSensorBox('Nem', '\\40}%'),
                    ),
                    // Diğer sensör verileri için benzer Positioned widget'ları ekleyebilirsiniz
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSensorBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
} */