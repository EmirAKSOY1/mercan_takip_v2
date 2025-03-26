import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/services/auth_service.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}

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
  List<ChartData> _chartData = [];
  final AuthService _authService = AuthService();
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
      enableMouseWheelZooming: true,
      enableSelectionZooming: true,
      selectionRectColor: Colors.blue.withOpacity(0.1),
      selectionRectBorderColor: Colors.blue,
      selectionRectBorderWidth: 2,
      zoomMode: ZoomMode.x,
    );
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
          
          print('API yanıtı: ${responseData.toString().substring(0, min(200, responseData.toString().length))}...');
          print('API veri uzunluğu: ${data?.length ?? 0}');
          
          if (data != null && data.isNotEmpty) {
            final List<ChartData> chartData = [];
            
            // Örnek veriyi kontrol et
            if (data.length > 0) {
              print('İlk veri örneği: ${data[0].toString()}');
              print('Sensör kodu: ${_getSensorCode()}');
            }
            
            for (var item in data) {
              final value = item[_getSensorCode()];
              final createdAt = item["tarih"];
              
              print('İşleniyor - value: $value, createdAt: $createdAt');
              
              if (value != null && createdAt != null) {
                try {
                  final doubleValue = double.parse(value.toString());
                  final time = DateTime.parse(createdAt);
                  
                  print('Ekleniyor - zaman: $time, değer: $doubleValue');
                  
                  if (!doubleValue.isNaN && !doubleValue.isInfinite) {
                    chartData.add(ChartData(time, doubleValue));
                  }
                } catch (e) {
                  print('Veri dönüştürme hatası: $e - value: $value, createdAt: $createdAt');
                }
              }
            }

            // Tarihe göre sırala
            chartData.sort((a, b) => a.time.compareTo(b.time));
            print('Toplam işlenen veri: ${chartData.length}');
            
            if (chartData.isNotEmpty) {
              print('İlk veri: ${chartData.first.time} - ${chartData.first.value}');
              print('Son veri: ${chartData.last.time} - ${chartData.last.value}');
            }

            if (mounted && chartData.isNotEmpty) {
              setState(() {
                _chartData = chartData;
                _isLoading = false;
              });
            } else {
              setState(() {
                _isLoading = false;
              });
              print('Veri boş veya bileşen artık monte değil');
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
                                '${widget.value}',
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
                              child: SfCartesianChart(
                                primaryXAxis: DateTimeAxis(
                                  dateFormat: DateFormat('HH:mm'),
                                  intervalType: DateTimeIntervalType.minutes,
                                  interval: 60,
                                  minimum: _chartData.isNotEmpty ? _chartData.first.time : DateTime.now().subtract(Duration(hours: 24)),
                                  maximum: _chartData.isNotEmpty ? _chartData.last.time : DateTime.now(),
                                  labelRotation: -45,
                                  labelStyle: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  enableAutoIntervalOnZooming: true,
                                ),
                                primaryYAxis: NumericAxis(
                                  labelStyle: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                zoomPanBehavior: _zoomPanBehavior,
                                crosshairBehavior: CrosshairBehavior(
                                  enable: false,
                                ),
                                series: <CartesianSeries>[
                                  LineSeries<ChartData, DateTime>(
                                    dataSource: _chartData,
                                    xValueMapper: (ChartData data, _) => data.time,
                                    yValueMapper: (ChartData data, _) => data.value,
                                    color: _getChartColor(),
                                    width: 3,
                                    markerSettings: MarkerSettings(
                                      isVisible: false,
                                    ),
                                  ),
                                ],
                                tooltipBehavior: TooltipBehavior(
                                  enable: true,
                                  activationMode: ActivationMode.singleTap,
                                  tooltipPosition: TooltipPosition.pointer,
                                  duration: 0,
                                  color: Colors.blueGrey.shade800.withOpacity(0.9),
                                  borderWidth: 2,
                                  borderColor: _getChartColor(),
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  shouldAlwaysShow: true,
                                  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade800.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getChartColor(),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.white70,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                DateFormat('HH:mm').format(data.time),
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getSensorIcon(),
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${data.value.toStringAsFixed(1)} ${_getUnit()}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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