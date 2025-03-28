import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  final Size screenSize;
  
  DashedLinePainter({required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()
      ..color = Colors.red
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
    
    // İç Isı için yol
    final path1 = Path();
    path1.moveTo(70 * w, 100 * h);
    path1.lineTo(70 * w, 150 * h);
    path1.lineTo(180 * w, 150 * h);
    path1.lineTo(180 * w, 180 * h);

    // Dış Isı için yol
    final path2 = Path();
    path2.moveTo(70 * w, 250 * h);
    path2.lineTo(70 * w, 300 * h);
    path2.lineTo(150 * w, 300 * h);

    // Nem için yol
    final path3 = Path();
    path3.moveTo(300 * w, 250 * h);
    path3.lineTo(300 * w, 300 * h);
    path3.lineTo(180 * w, 300 * h);

    // CO2 için yol
    final path4 = Path();
    path4.moveTo(300 * w, 100 * h);
    path4.lineTo(300 * w, 150 * h);

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

class EscapeScreen extends StatelessWidget {
  const EscapeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesikli Çizgi Test Ekranı'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Kesikli çizgileri ayarlamak için test ekranı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
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
                  // İç Isı pozisyonu
                  Positioned(
                    top: 70,
                    left: 50,
                    child: _buildIndicator("İç Isı", Colors.red),
                  ),
                  // Dış Isı pozisyonu
                  Positioned(
                    bottom: 150,
                    left: 50,
                    child: _buildIndicator("Dış Isı", Colors.blue),
                  ),
                  // Nem pozisyonu
                  Positioned(
                    bottom: 150,
                    right: 50,
                    child: _buildIndicator("Nem", Colors.orange),
                  ),
                  // CO2 pozisyonu
                  Positioned(
                    top: 70,
                    right: 50,
                    child: _buildIndicator("CO2", Colors.red),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Çizgileri ayarlamak için DashedLinePainter sınıfındaki koordinatları değiştirin.',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Örnek koordinat: path1.moveTo(70 * w, 100 * h)',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIndicator(String label, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
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
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


  

  



