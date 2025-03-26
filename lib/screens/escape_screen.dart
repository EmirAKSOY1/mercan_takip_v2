import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:mercan_takip_v2/services/auth_service.dart';

class EscapeScreen extends StatefulWidget {
  const EscapeScreen({Key? key}) : super(key: key);

  @override
  State<EscapeScreen> createState() => _EscapeScreenState();
}

class _EscapeScreenState extends State<EscapeScreen> {
  List<ChartData> chartData = [];
  bool isLoading = true;
  String? errorMessage;
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
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
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
        Uri.parse('http://62.171.140.229/api/getHistoricalData?coopId=21354&sensorId=3'),
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
            final List<ChartData> points = [];
            
            for (var item in data) {
              final value = item["NE"];
              if (value != null) {
                try {
                  final doubleValue = double.parse(value.toString());
                  if (!doubleValue.isNaN && !doubleValue.isInfinite) {
                    points.add(ChartData(
                      DateTime.parse(item["created_at"]),
                      doubleValue,
                    ));
                  }
                } catch (e) {
                  print('Veri dönüştürme hatası: $e');
                }
              }
            }

            if (mounted) {
              setState(() {
                chartData = points;
                isLoading = false;
              });
            }
          } else {
            setState(() {
              errorMessage = "Veri bulunamadı";
              isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        throw Exception("API'den veri çekilemedi: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Veri yüklenirken hata oluştu: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensör Verileri'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchData,
                        child: Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: 350,
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
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
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(
                          dateFormat: DateFormat('HH:mm'),
                          intervalType: DateTimeIntervalType.minutes,
                          interval: 60,
                          minimum: chartData.isNotEmpty ? chartData.first.time : DateTime.now().subtract(Duration(hours: 24)),
                          maximum: chartData.isNotEmpty ? chartData.last.time : DateTime.now(),
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
                            dataSource: chartData,
                            xValueMapper: (ChartData data, _) => data.time,
                            yValueMapper: (ChartData data, _) => data.value,
                            color: Colors.blue,
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
                          borderColor: Colors.blue,
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
                                  color: Colors.blue,
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
                                        Icons.water_drop,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${data.value.toStringAsFixed(1)} %',
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
                  ),
                ),
    );
  }
}

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}


  

  



