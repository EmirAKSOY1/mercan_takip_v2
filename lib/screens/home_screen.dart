import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/screens/sensor_data_screen.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';
import 'package:mercan_takip_v2/widgets/bottom_nav_bar.dart';
import 'package:mercan_takip_v2/services/auth_service.dart';

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
    'avgTemperature': '0',
    'avgHumidity': '0',
    'dailyAlarms': '0',
  };
  bool _isLoading = true;
  List<Coop> _activeCoops = [];
  String _userName = '';
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchGeneralData();
    _fetchActiveCoops();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userData = await _authService.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _userName = '${userData['name']}';
      });
    }
  }

  Future<void> _fetchGeneralData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getGeneralData'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _generalData = {
            'totalData': data['totalData']?.toString() ?? '0',
            'totalAnimals': data['totalAnimals']?.toString() ?? '0',
            'totalAlarms': data['totalAlarms']?.toString() ?? '0',
            'totalCoops': data['totalCoops']?.toString() ?? '0',
            'avgTemperature': data['avgTemperature']?.toString() ?? '0',
            'avgHumidity': data['avgHumidity']?.toString() ?? '0',
            'dailyAlarms': data['dailyAlarms']?.toString() ?? '0',
          };
        });
        print('API Response: $data'); // Debug için
        print('Converted Data: $_generalData'); // Debug için
      } else if (response.statusCode == 401) {
        // Token geçersiz veya süresi dolmuş
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print('API Error Status Code: ${response.statusCode}'); // Debug için
        print('API Error Body: ${response.body}'); // Debug için
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error in _fetchGeneralData: $e'); // Debug için
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchActiveCoops() async {
    try {
      // Token'ı al
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getCoops'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded Data: $data');
        
        if (mounted) {
          setState(() {
            _activeCoops = data.map((coop) {
              print('Processing coop: $coop');
              return Coop.fromJson(coop);
            }).toList();
            print('Processed Coops: $_activeCoops');
          });
        }
      } else if (response.statusCode == 401) {
        // Token geçersiz veya süresi dolmuş
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Failed to load active coops');
      }
    } catch (e) {
      print('Error in _fetchActiveCoops: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktif kümesler yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
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
                Text(
                  'Merhaba, $_userName',
                  style: const TextStyle(
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

      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchGeneralData(),
            _fetchActiveCoops(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Günlük Özet Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[900]!, Colors.red[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red[900]!.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
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
                      const Text(
                        'Günlük Özet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('dd.MM.yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        icon: Icons.thermostat,
                        label: 'Ort. Sıcaklık',
                        value: '${_generalData['avgTemperature']}°C',
                      ),
                      _buildSummaryItem(
                        icon: Icons.water_drop,
                        label: 'Ort. Nem',
                        value: '%${_generalData['avgHumidity']}',
                      ),
                      _buildSummaryItem(
                        icon: Icons.warning,
                        label: 'Uyarılar',
                        value: _generalData['dailyAlarms'],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // İstatistik Kartları
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Ekran genişliğine göre kart genişliğini belirle
                      final cardWidth = constraints.maxWidth < 600 
                          ? (constraints.maxWidth - 24) / 2 
                          : (constraints.maxWidth - 24) / 4;
                      
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              icon: Icons.data_usage,
                              iconColor: Colors.blue,
                              title: _generalData['totalData'],
                              subtitle: 'Toplam Veri',
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              icon: Icons.pets,
                              iconColor: Colors.green,
                              title: _generalData['totalAnimals'],
                              subtitle: 'Toplam Hayvan',
                              backgroundColor: Colors.green.withOpacity(0.1),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              icon: Icons.warning,
                              iconColor: Colors.red,
                              title: _generalData['totalAlarms'],
                              subtitle: 'Toplam Alarm',
                              backgroundColor: Colors.red.withOpacity(0.1),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              icon: Icons.home,
                              iconColor: Colors.purple,
                              title: _generalData['totalCoops'],
                              subtitle: 'Toplam Kümes',
                              backgroundColor: Colors.purple.withOpacity(0.1),
                            ),
                          ),
                        ],
                      );
                    },
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
                  coopId: coop.id.toString(),
                  coopName: coop.name,
                  day: coop.day,
                ),
                const SizedBox(height: 16),
              ],
            )).toList(),
          ],
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
            builder: (context) => SensorDataScreen2(
              coopId: coopId,
              coopName: coopName,
            ),
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
              'Seri No: $coopId',
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class Coop {
  final int id;
  final String name;
  final String? latitude;
  final String? longitude;
  final int? entegre_id;
  final int day;
  final String? created_at;
  final String? updated_at;

  Coop({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.entegre_id,
    required this.day,
    this.created_at,
    this.updated_at,
  });

  factory Coop.fromJson(Map<String, dynamic> json) {
    return Coop(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      entegre_id: json['entegre_id'],
      day: json['day'] ?? 0,
      created_at: json['created_at'],
      updated_at: json['updated_at'],
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