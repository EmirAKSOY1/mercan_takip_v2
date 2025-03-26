import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';
import 'package:mercan_takip_v2/widgets/bottom_nav_bar.dart';
import 'package:mercan_takip_v2/services/auth_service.dart';

class DashedLinePainter extends CustomPainter {
  final Size screenSize;
  
  DashedLinePainter({required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()
      ..color = const Color.fromARGB(255, 231, 0, 0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final bluePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final orangePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    
    // Ekran genişliği ve yüksekliğine göre ölçeklendirme faktörleri
    double w = screenSize.width / 400.0;  // 400 referans genişlik
    double h = screenSize.height / 800.0; // 800 referans yükseklik
    
    // İç Isı için yol - orijinal koordinatları ölçeklendiriyoruz
    final path1 = Path();
    path1.moveTo(70 * w, 120 * h);
    path1.lineTo(70 * w, 160 * h);
    path1.lineTo(180 * w, 160 * h);
    path1.lineTo(180 * w, 190 * h);

    // Dış Isı için yol
    final path2 = Path();
    path2.moveTo(70 * w, 250 * h);
    path2.lineTo(70 * w, 300 * h);
    path2.lineTo(150 * w, 300 * h);

    // Nem için yol
    final path3 = Path();
    path3.moveTo(290 * w, 250 * h);
    
    path3.lineTo(290 * w, 290 * h);
    path3.lineTo(180 * w, 290 * h);

    // CO2 için yol
    final path4 = Path();
    path4.moveTo(300 * w, 80 * h);
    path4.lineTo(300 * w, 140 * h);

    // Tüm yolları çiz
    _drawDashedPath(canvas, path1, redPaint, dashWidth, dashSpace);
    _drawDashedPath(canvas, path2, bluePaint, dashWidth, dashSpace);
    _drawDashedPath(canvas, path3, orangePaint, dashWidth, dashSpace);
    _drawDashedPath(canvas, path4, redPaint, dashWidth, dashSpace);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    double distance = _calculatePathLength(path);
    double currentDistance = 0;
    bool draw = true;

    Path dashPath = Path();
    while (currentDistance < distance) {
      double currentLength = draw ? dashWidth : dashSpace;
      if (currentDistance + currentLength > distance) {
        currentLength = distance - currentDistance;
      }
      
      Path extractedPath = _extractPathSegment(path, currentDistance, currentLength);
      if (draw) {
        dashPath.addPath(extractedPath, Offset.zero);
      }
      
      currentDistance += currentLength;
      draw = !draw;
    }

    canvas.drawPath(dashPath, paint);
  }

  double _calculatePathLength(Path path) {
    double length = 0;
    path.computeMetrics().forEach((metric) {
      length += metric.length;
    });
    return length;
  }

  Path _extractPathSegment(Path path, double start, double length) {
    Path extractedPath = Path();
    double remainingLength = length;
    
    for (final metric in path.computeMetrics()) {
      if (start > metric.length) {
        start -= metric.length;
        continue;
      }
      
      final extractedSegment = metric.extractPath(start, start + remainingLength);
      extractedPath.addPath(extractedSegment, Offset.zero);
      
      remainingLength -= (metric.length - start);
      if (remainingLength <= 0) break;
      
      start = 0;
    }
    
    return extractedPath;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SensorDataScreen2 extends StatefulWidget {
  final String coopId;
  final String coopName;

  const SensorDataScreen2({
    Key? key,
    required this.coopId,
    required this.coopName,
  }) : super(key: key);

  @override
  State<SensorDataScreen2> createState() => _SensorDataScreen2State();
}

class _SensorDataScreen2State extends State<SensorDataScreen2> {
  bool _isLoading = true;
  Map<String, dynamic>? _sensorData;
  final AuthService _authService = AuthService();
  String? _integrationName;

  @override
  void initState() {
    super.initState();
    _loadIntegrationName();
    _fetchSensorData();
  }

  Future<void> _loadIntegrationName() async {
    final integrationName = await _authService.getIntegrationName();
    if (mounted) {
      setState(() {
        _integrationName = integrationName;
      });
    }
  }

  Future<void> _fetchSensorData() async {
    try {
      
      
      // Token'ı al
      final token = await _authService.getToken();
      if (token == null) {
        print('Token bulunamadı');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getSensorData?coopId=${widget.coopId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );



      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _sensorData = {
              'ic_sicaklik': data['ic_sicaklik']?.toString() ?? '0',
              'dis_sicaklik': data['dis_sicaklik']?.toString() ?? '0',
              'nem': data['nem']?.toString() ?? '0',
              'co2': data['co2']?.toString() ?? '0',
              'olum_sayisi': data['olum_sayisi']?.toString() ?? '0',
              'olum_orani': data['olum_orani']?.toString() ?? '0',
              'su_tuketimi': data['su_tuketimi']?.toString() ?? '0',
              'yem_tuketimi': data['yem_tuketimi']?.toString() ?? '0',
              'gun': data['gun']?.toString() ?? '0',
              'son_guncelleme': data['son_guncelleme']?.toString() ?? '',
            };
            _isLoading = false;
          });
          
        }
      } else if (response.statusCode == 401) {
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _integrationName ?? 'Yükleniyor...',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(currentRoute: '/sensors'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchSensorData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Kırmızı kart
                    Container(
                      margin: EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            widget.coopName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'SN: ${widget.coopId}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text('${_sensorData!['gun']}. Gün', 
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16
                            )
                          ),
                          SizedBox(height: 4),
                          Text(_sensorData!['son_guncelleme'], 
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14
                            )
                          ),
                        ],
                      ),
                    ),
                    
                    // Kümes resmi ve sensör verileri
                    Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            top: 70,
                            left: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/images/coop_image.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DashedLinePainter(
                                screenSize: MediaQuery.of(context).size,
                              ),
                            ),
                          ),
                          // İç Isı
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.08,
                            left: MediaQuery.of(context).size.width * 0.1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/sensor_detail',
                                  arguments: {
                                    'title': 'İç Sıcaklık Detayı',
                                    'value': '${_sensorData!['ic_sicaklik']}°C',
                                    'coopId': widget.coopId,
                                    'coopName': widget.coopName,
                                    'sensorType': 'ic_sicaklik',
                                    'sensorId': 1,
                                  },
                                );
                              },
                              child: _buildSensorIndicator('${_sensorData!['ic_sicaklik']}°C', 'İç Isı'),
                            ),
                          ),
                          // CO2
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.02,
                            right: MediaQuery.of(context).size.width * 0.05,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/sensor_detail',
                                  arguments: {
                                    'title': 'CO2 Detayı',
                                    'value': '${_sensorData!['co2']} ppm',
                                    'coopId': widget.coopId,
                                    'coopName': widget.coopName,
                                    'sensorType': 'co2',
                                    'sensorId': 2,
                                  },
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_sensorData!['co2']}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          ' ppm',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'CO2',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Dış Isı
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.15,
                            left: MediaQuery.of(context).size.width * 0.1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/sensor_detail',
                                  arguments: {
                                    'title': 'Dış Sıcaklık Detayı',
                                    'value': '${_sensorData!['dis_sicaklik']}°C',
                                    'coopId': widget.coopId,
                                    'coopName': widget.coopName,
                                    'sensorType': 'dis_sicaklik',
                                    'sensorId': 3,

                                  },
                                );
                              },
                              child: _buildSensorIndicator('${_sensorData!['dis_sicaklik']}°C', 'Dış Isı'),
                            ),
                          ),
                          // Nem
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.15,
                            right: MediaQuery.of(context).size.width * 0.1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/sensor_detail',
                                  arguments: {
                                    'title': 'Nem Detayı',
                                    'value': '%${_sensorData!['nem']}',
                                    'coopId': widget.coopId,
                                    'coopName': widget.coopName,
                                    'sensorType': 'nem',
                                    'sensorId': 4,
                                  },
                                );
                              },
                              child: _buildSensorIndicator('%${_sensorData!['nem']}', 'Nem'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alt kısımdaki kartlar
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard('Ölüm Sayısı', _sensorData!['olum_sayisi'], const Color.fromARGB(255, 196, 108, 108)!),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoCard('Ölüm Oranı', _sensorData!['olum_orani'], const Color.fromARGB(255, 99, 148, 110)!),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard('Su Tüketimi', _sensorData!['su_tuketimi'], const Color.fromARGB(255, 70, 91, 109)!),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoCard('Yem Tüketimi', _sensorData!['yem_tuketimi'], const Color.fromARGB(255, 143, 111, 81)!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildSensorIndicator(String value, String label) {
    return Container(
      width: 100,
      height: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String count, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
            ],
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 