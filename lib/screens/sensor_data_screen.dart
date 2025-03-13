import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class SensorDataScreen2 extends StatelessWidget {
  final String coopId;

  SensorDataScreen2({required this.coopId});

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
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {},
        ),
        title: Text('Agrokush'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  Text('Kümes-1', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  SizedBox(height: 4),
                  Text('37. Gün', 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16
                    )
                  ),
                  SizedBox(height: 4),
                  Text('12.03.2025 15:27', 
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
                  // Dashed line for temperature
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
                    child: _buildSensorIndicator('23°C', 'İç Isı'),
                  ),
                  // CO2
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.02,
                    right: MediaQuery.of(context).size.width * 0.05,
                    child: _buildSensorIndicator('23 ppm', 'CO2'),
                  ),
                  // Dış Isı
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    left: MediaQuery.of(context).size.width * 0.1,
                    child: _buildSensorIndicator('23°C', 'Dış Isı'),
                  ),
                  // Nem
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    right: MediaQuery.of(context).size.width * 0.1,
                    child: _buildSensorIndicator('%23', 'Nem'),
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
                    child: _buildInfoCard('Ölüm Sayısı', '311', const Color.fromARGB(255, 196, 108, 108)!),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard('Ölüm Oranı', '311', const Color.fromARGB(255, 99, 148, 110)!),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard('Su Tüketimi', '311', const Color.fromARGB(255, 70, 91, 109)!),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard('Yem Tüketimi', '311', const Color.fromARGB(255, 143, 111, 81)!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Grafikler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Veriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alarmlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Paylaş',
          ),
        ],
      ),
    );
  }

  Widget _buildSensorIndicator(String value, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 14),
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