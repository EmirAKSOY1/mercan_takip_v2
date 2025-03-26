import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/services/auth_service.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class SensorDetailScreen extends StatefulWidget {
  final String title;
  final String value;
  final String coopId;
  final String coopName;
  final String sensorType;
  final String sensorId;

  const SensorDetailScreen({
    Key? key,
    required this.title,
    required this.value,
    required this.coopId,
    required this.coopName,
    required this.sensorType,
    required this.sensorId,
  }) : super(key: key);

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  bool _isLoading = true;
  List<FlSpot> _chartData = [];
  final AuthService _authService = AuthService();
  double _minX = 0;
  double _maxX = 0;
  double _minY = 0;
  double _maxY = 0;
  double _currentScale = 1.0;
  double _baseScaleFactor = 1.0;
  double _viewportLeft = 0;
  double _viewportRight = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
      _chartData = [];
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getHistoricalData?coopId=${widget.coopId}&sensorId=${_getSensorId()}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && mounted) {
          final data = responseData['data'];
          
          if (data != null && data.isNotEmpty) {
            final List<FlSpot> chartData = [];
            final now = DateTime.now();
            
            for (int i = 0; i < data.length; i++) {
              final value = data[i][_getSensorCode()];
              if (value != null) {
                try {
                  final doubleValue = double.parse(value.toString());
                  if (!doubleValue.isNaN && !doubleValue.isInfinite) {
                    chartData.add(FlSpot(i.toDouble(), doubleValue));
                  }
                } catch (e) {
                  print('Veri dönüştürme hatası: $e');
                }
              }
            }

            if (mounted && chartData.isNotEmpty) {
              setState(() {
                _chartData = chartData;
                _minX = 0;
                _maxX = (chartData.length - 1).toDouble();
                _minY = chartData.map((spot) => spot.y).reduce(min);
                _maxY = chartData.map((spot) => spot.y).reduce(max);
                _viewportLeft = _maxX - 12;
                _viewportRight = _maxX;
                _isLoading = false;
              });
            } else {
              setState(() {
                _isLoading = false;
              });
            }
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          throw Exception(responseData['message'] ?? 'Bilinmeyen hata');
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
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Veri yüklenirken hata oluştu: ${errorData['message'] ?? response.statusCode}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _getTimeLabel(double value) {
    if (value < 0 || value >= _chartData.length) return '';
    final now = DateTime.now();
    final time = now.subtract(Duration(minutes: (_chartData.length - value.round() - 1) * 10));
    
    if (time.minute == 0) {
      return DateFormat('HH:00').format(time);
    }
    return '';
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScaleFactor = _currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _currentScale = (_baseScaleFactor * details.scale).clamp(1.0, 4.0);
      
      double viewportWidth;
      if (_currentScale <= 1.5) {
        viewportWidth = 12.0;
      } else if (_currentScale <= 2.5) {
        viewportWidth = 6.0;
      } else {
        viewportWidth = 3.0;
      }
      
      double center = (_viewportLeft + _viewportRight) / 2;
      _viewportLeft = (center - viewportWidth / 2).clamp(0.0, _maxX - viewportWidth);
      _viewportRight = _viewportLeft + viewportWidth;
    });
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
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistoricalData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.coopName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${widget.value} ${_getUnit()}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getValueColor(double.tryParse(widget.value) ?? 0),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getChartColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getSensorIcon(),
                              color: _getChartColor(),
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_chartData.isNotEmpty)
                      Container(
                        height: 350,
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.fromLTRB(8, 16, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 16),
                              child: Text(
                                'Son 24 Saat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onScaleStart: _onScaleStart,
                                onScaleUpdate: _onScaleUpdate,
                                child: LineChart(
                                  LineChartData(
                                    minX: _viewportLeft,
                                    maxX: _viewportRight,
                                    minY: _minY - (_maxY - _minY) * 0.1,
                                    maxY: _maxY + (_maxY - _minY) * 0.1,
                                    clipData: FlClipData.all(),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.grey.withOpacity(0.1),
                                        strokeWidth: 0.5,
                                        dashArray: [5, 5],
                                      ),
                                      getDrawingVerticalLine: (value) => FlLine(
                                        color: Colors.grey.withOpacity(0.1),
                                        strokeWidth: 0.5,
                                        dashArray: [5, 5],
                                      ),
                                      horizontalInterval: (_maxY - _minY) / 5,
                                      verticalInterval: 6,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          getTitlesWidget: (value, meta) {
                                            final label = _getTimeLabel(value);
                                            return label.isEmpty ? Container() : Transform.rotate(
                                              angle: -0.5,
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          },
                                          interval: 6,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) => Text(
                                            value.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          interval: (_maxY - _minY) / 5,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                                        left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _chartData,
                                        isCurved: true,
                                        color: _getChartColor(),
                                        barWidth: 2.5,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: _currentScale > 2.0,
                                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                            radius: 3,
                                            color: Colors.white,
                                            strokeWidth: 2,
                                            strokeColor: _getChartColor(),
                                          ),
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              _getChartColor().withOpacity(0.3),
                                              _getChartColor().withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor: Colors.blueGrey.shade800.withOpacity(0.9),
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((LineBarSpot touchedSpot) {
                                            final time = DateTime.now().subtract(
                                              Duration(minutes: (_chartData.length - touchedSpot.x.round() - 1) * 10),
                                            );
                                            return LineTooltipItem(
                                              DateFormat('HH:mm').format(time),
                                              const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: '\n${touchedSpot.y.toStringAsFixed(1)} ${_getUnit()}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getSensorId() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return '1';
      case 'dis_sicaklik': return '2';
      case 'nem': return '3';
      case 'co2': return '4';
      default: return '1';
    }
  }

  String _getSensorCode() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return 'ISI';
      case 'dis_sicaklik': return 'DI';
      case 'nem': return 'NE';
      case 'co2': return 'CO';
      default: return 'ISI';
    }
  }

  String _getUnit() {
    switch (widget.sensorType) {
      case 'ic_sicaklik':
      case 'dis_sicaklik': return '°C';
      case 'nem': return '%';
      case 'co2': return 'pm';
      default: return '';
    }
  }

  Color _getValueColor(double value) {
    switch (widget.sensorType) {
      case 'ic_sicaklik':
        if (value < 15 || value > 30) return Colors.red;
        if (value < 20 || value > 25) return Colors.orange;
        return Colors.green;
      case 'dis_sicaklik':
        if (value < 5 || value > 35) return Colors.red;
        if (value < 10 || value > 30) return Colors.orange;
        return Colors.green;
      case 'nem':
        if (value < 50 || value > 70) return Colors.red;
        if (value < 55 || value > 65) return Colors.orange;
        return Colors.green;
      case 'co2':
        if (value > 2000) return Colors.red;
        if (value > 1500) return Colors.orange;
        return Colors.green;
      default: return Colors.black;
    }
  }

  Color _getChartColor() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return Color(0xFFFF6B6B);
      case 'dis_sicaklik': return Color(0xFFFF9F43);
      case 'nem': return Color(0xFF54A0FF);
      case 'co2': return Color(0xFF10AC84);
      default: return Theme.of(context).primaryColor;
    }
  }

  IconData _getSensorIcon() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return Icons.thermostat;
      case 'dis_sicaklik': return Icons.wb_sunny;
      case 'nem': return Icons.water_drop;
      case 'co2': return Icons.cloud;
      default: return Icons.sensors;
    }
  }
} 