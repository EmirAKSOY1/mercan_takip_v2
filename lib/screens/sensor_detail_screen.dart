import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/services/auth_service.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ChartData {
  final DateTime time;
  final double value;
  final double? secondaryValue;

  ChartData(this.time, this.value, {this.secondaryValue});
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
  
  String _maxValue = "0";
  String _minValue = "0";
  
  // Tarih aralığı için değişkenler
  DateTime? _startDate;
  DateTime? _endDate;

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
    
    // Başlangıçta son 24 saati ayarla
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(Duration(hours: 24));
    
    if (widget.sensorType == 'su_tuketimi' || widget.sensorType == 'yem_tuketimi') {
      _loadHourlyData();
    } else {
      _loadHistoricalData();
    }
  }

  // Tarih seçimi değiştiğinde çağrılacak fonksiyon
  void _onDateRangeChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      final range = args.value as PickerDateRange;
      setState(() {
        _startDate = range.startDate;
        _endDate = range.endDate ?? range.startDate;
      });
    }
  }

  // Filtreleme işlemi için yeni fonksiyon
  void _applyFilter() {
    if (widget.sensorType == 'su_tuketimi' || widget.sensorType == 'yem_tuketimi') {
      _loadHourlyData();
    } else {
      _loadHistoricalData();
    }
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

      final endDateWithOffset = _endDate?.add(Duration(days: 1));
      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getHistoricalData?coopId=${widget.coopId}&sensorId=${_getSensorId()}&startDate=${_startDate?.toIso8601String()}&endDate=${endDateWithOffset?.toIso8601String()}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && mounted) {
          final data = responseData['data'];
          
          // Max ve min değerlerini al (API'den geliyorsa)
          if (responseData.containsKey('max')) {
            _maxValue = responseData['max'].toString();
          }
          
          if (responseData.containsKey('min')) {
            _minValue = responseData['min'].toString();
          }
                    
          if (data != null && data.isNotEmpty) {
            final List<ChartData> chartData = [];
            
            for (var item in data) {
              final value = item[_getSensorCode()];
              final createdAt = item["tarih"];
              
              // SE değerinin olup olmadığını kontrol et (sadece ISI için)
              double? secondaryValue;
              if (widget.sensorType == 'ic_sicaklik' && item.containsKey('SE')) {
                final seValue = item["SE"];
                if (seValue != null) {
                  try {
                    secondaryValue = double.parse(seValue.toString());
                  } catch (e) {
                    print('SE değeri dönüştürme hatası: $e');
                  }
                }
              }
              
              if (value != null && createdAt != null) {
                try {
                  final doubleValue = double.parse(value.toString());
                  final time = DateTime.parse(createdAt);
                  
                  
                  if (!doubleValue.isNaN && !doubleValue.isInfinite) {
                    chartData.add(ChartData(time, doubleValue, secondaryValue: secondaryValue));
                  }
                } catch (e) {
                  print('Veri dönüştürme hatası: $e - value: $value, createdAt: $createdAt');
                }
              }
            }

            chartData.sort((a, b) => a.time.compareTo(b.time));

            if (mounted && chartData.isNotEmpty) {
              setState(() {
                _chartData = chartData;
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

  // Saatlik tüketim verilerini yükle (su ve yem için)
  Future<void> _loadHourlyData() async {
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

      final endDateWithOffset = _endDate?.add(Duration(days: 1));
      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getHourlyData?coopId=${widget.coopId}&dataId=${_getSensorId()}&startDate=${_startDate?.toIso8601String()}&endDate=${endDateWithOffset?.toIso8601String()}'),
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
            final List<ChartData> chartData = [];
            
            
            for (var item in data) {
              final value = item["consumption"];
              final createdAt = item["created_at"];
              
              if (value != null && createdAt != null) {
                try {
                  final doubleValue = double.parse(value.toString());
                  final time = DateTime.parse(createdAt);

                  if (!doubleValue.isNaN && !doubleValue.isInfinite) {
                    chartData.add(ChartData(time, doubleValue));
                  }
                } catch (e) {
                  print('Veri dönüştürme hatası (saatlik): $e - value: $value, createdAt: $createdAt');
                }
              }
            }

            // Tarihe göre sırala
            chartData.sort((a, b) => a.time.compareTo(b.time));
            
            // Max ve min değerlerini hesapla
            if (chartData.isNotEmpty) {
              double maxVal = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
              double minVal = chartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
              
              setState(() {
                _maxValue = maxVal.toStringAsFixed(1);
                _minValue = minVal.toStringAsFixed(1);
              });

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
              content: Text('Saatlik veri yüklenirken hata oluştu: ${errorData['message'] ?? response.statusCode}'),
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
            content: Text('Saatlik veri yüklenirken hata oluştu: $e'),
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
              onRefresh: widget.sensorType == 'su_tuketimi' || widget.sensorType == 'yem_tuketimi' 
                ? _loadHourlyData 
                : _loadHistoricalData,
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
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildMinMaxValue("Min", _minValue, Colors.blue),
                                  SizedBox(width: 16),
                                  _buildMinMaxValue("Max", _maxValue, Colors.red),
                                ],
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

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
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
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        shape: Border(),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tarih Aralığı',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getChartColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: _getChartColor(),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${DateFormat('dd.MM.yyyy').format(_startDate ?? DateTime.now())} - ${DateFormat('dd.MM.yyyy').format(_endDate ?? DateTime.now())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getChartColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  surface: Colors.white,
                                ),
                              ),
                              child: SfDateRangePicker(
                                selectionMode: DateRangePickerSelectionMode.range,
                                initialSelectedRange: PickerDateRange(_startDate, _endDate),
                                onSelectionChanged: _onDateRangeChanged,
                                showActionButtons: true,
                                showNavigationArrow: true,
                                allowViewNavigation: true,
                                enablePastDates: true,
                                maxDate: DateTime.now(),
                                selectionShape: DateRangePickerSelectionShape.rectangle,
                                selectionRadius: 8,
                                toggleDaySelection: true,
                                backgroundColor: Colors.white,
                                headerStyle: DateRangePickerHeaderStyle(
                                  textAlign: TextAlign.center,
                                  backgroundColor: Colors.transparent,
                                  textStyle: TextStyle(
                                    color: _getChartColor(),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                monthViewSettings: DateRangePickerMonthViewSettings(
                                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                                    textStyle: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  showTrailingAndLeadingDates: true,
                                  dayFormat: 'EEE',
                                  numberOfWeeksInView: 6,
                                ),
                                selectionTextStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                todayHighlightColor: _getChartColor(),
                                rangeSelectionColor: _getChartColor().withOpacity(0.1),
                                startRangeSelectionColor: _getChartColor(),
                                endRangeSelectionColor: _getChartColor(),
                                monthCellStyle: DateRangePickerMonthCellStyle(
                                  textStyle: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  todayTextStyle: TextStyle(
                                    color: _getChartColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  disabledDatesTextStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  cellDecoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  todayCellDecoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _getChartColor(),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                yearCellStyle: DateRangePickerYearCellStyle(
                                  textStyle: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  todayTextStyle: TextStyle(
                                    color: _getChartColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  disabledDatesTextStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  cellDecoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  todayCellDecoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _getChartColor(),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                confirmText: 'Filtrele',
                                cancelText: '',
                                onSubmit: (Object? value) {
                                  _applyFilter();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
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
                                widget.sensorType == 'su_tuketimi' || widget.sensorType == 'yem_tuketimi' 
                                ? 'Saatlik Tüketim' 
                                : 'Seçilen Tarih Aralığı',
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
                                  dateFormat: _getDateFormat(),
                                  intervalType: _getIntervalType(),
                                  interval: _getInterval(),
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
                                  // Su tüketimi ve yem tüketimi için sütun (column) grafik kullan
                                  if (widget.sensorType == 'su_tuketimi' || widget.sensorType == 'yem_tuketimi')
                                    ColumnSeries<ChartData, DateTime>(
                                      name: _getSensorName(),
                                      dataSource: _chartData,
                                      xValueMapper: (ChartData data, _) => data.time,
                                      yValueMapper: (ChartData data, _) => data.value,
                                      color: _getChartColor(),
                                      width: 0.8,
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                    )
                                  else
                                    LineSeries<ChartData, DateTime>(
                                      name: _getSensorName(),
                                      dataSource: _chartData,
                                      xValueMapper: (ChartData data, _) => data.time,
                                      yValueMapper: (ChartData data, _) => data.value,
                                      color: _getChartColor(),
                                      width: 3,
                                      markerSettings: MarkerSettings(
                                        isVisible: false,
                                      ),
                                    ),
                                  // Eğer iç sıcaklık ise ve SE değeri varsa ikinci seri olarak göster
                                  if (widget.sensorType == 'ic_sicaklik' && _chartData.any((data) => data.secondaryValue != null))
                                    LineSeries<ChartData, DateTime>(
                                      name: 'Sıcaklık Eğilimi',
                                      dataSource: _chartData,
                                      xValueMapper: (ChartData data, _) => data.time,
                                      yValueMapper: (ChartData data, _) => data.secondaryValue ?? 0,
                                      color: Colors.orange,
                                      width: 2,
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
                                    String valueText = '';
                                    
                                    // Ana değer
                                    if (seriesIndex == 0) {
                                      valueText = '${data.value.toStringAsFixed(1)} ${_getUnit()}';
                                    }
                                    // SE değeri (eğer varsa)
                                    else if (seriesIndex == 1 && data.secondaryValue != null) {
                                      valueText = 'SE: ${data.secondaryValue!.toStringAsFixed(1)}';
                                    }
                                    
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade800.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: seriesIndex == 0 ? _getChartColor() : Colors.orange,
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
                                                _getDateFormat().format(data.time),
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
                                                seriesIndex == 0 ? _getSensorIcon() : Icons.trending_up,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                valueText,
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
      case 'su_tuketimi': return '5';
      case 'yem_tuketimi': return '6';
      default: return '1';
    }
  }

  String _getSensorCode() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return 'ISI';
      case 'dis_sicaklik': return 'DI';
      case 'nem': return 'NE';
      case 'co2': return 'CO';
      case 'su_tuketimi': return 'SU';
      case 'yem_tuketimi': return 'YEM';
      default: return 'ISI';
    }
  }

  String _getUnit() {
    switch (widget.sensorType) {
      case 'ic_sicaklik':
      case 'dis_sicaklik': return '°C';
      case 'nem': return '%';
      case 'co2': return 'pm';
      case 'su_tuketimi': return 'L';
      case 'yem_tuketimi': return 'kg';
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
      case 'su_tuketimi':
        return const Color.fromARGB(255, 70, 91, 109);
      case 'yem_tuketimi':
        return const Color.fromARGB(255, 143, 111, 81);
      default: return Colors.black;
    }
  }

  Color _getChartColor() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return Color(0xFFFF6B6B);
      case 'dis_sicaklik': return Color(0xFFFF9F43);
      case 'nem': return Color(0xFF54A0FF);
      case 'co2': return Color(0xFF10AC84);
      case 'su_tuketimi': return Color.fromARGB(255, 70, 91, 109);
      case 'yem_tuketimi': return Color.fromARGB(255, 143, 111, 81);
      default: return Theme.of(context).primaryColor;
    }
  }

  IconData _getSensorIcon() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return Icons.thermostat;
      case 'dis_sicaklik': return Icons.wb_sunny;
      case 'nem': return Icons.water_drop;
      case 'co2': return Icons.cloud;
      case 'su_tuketimi': return Icons.water_drop;
      case 'yem_tuketimi': return Icons.restaurant;
      default: return Icons.sensors;
    }
  }

  String _getSensorName() {
    switch (widget.sensorType) {
      case 'ic_sicaklik': return 'İç Sıcaklık';
      case 'dis_sicaklik': return 'Dış Sıcaklık';
      case 'nem': return 'Nem';
      case 'co2': return 'CO2';
      case 'su_tuketimi': return 'Su Tüketimi';
      case 'yem_tuketimi': return 'Yem Tüketimi';
      default: return 'Sensör';
    }
  }

  // Min ve Max değerler için özel widget
  Widget _buildMinMaxValue(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            SizedBox(width: 4),
            Text(
              "$value ${_getUnit()}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Yeni yardımcı fonksiyonlar ekleyelim
  DateFormat _getDateFormat() {
    if (_startDate == null || _endDate == null) return DateFormat('HH:mm');
    
    final difference = _endDate!.difference(_startDate!);
    if (difference.inHours <= 24) {
      return DateFormat('HH:mm');
    } else if (difference.inDays <= 7) {
      return DateFormat('dd/MM HH:mm');
    } else {
      return DateFormat('dd/MM/yyyy');
    }
  }

  DateTimeIntervalType _getIntervalType() {
    if (_startDate == null || _endDate == null) return DateTimeIntervalType.minutes;
    
    final difference = _endDate!.difference(_startDate!);
    if (difference.inHours <= 24) {
      return DateTimeIntervalType.minutes;
    } else if (difference.inDays <= 7) {
      return DateTimeIntervalType.hours;
    } else {
      return DateTimeIntervalType.days;
    }
  }

  double _getInterval() {
    if (_startDate == null || _endDate == null) return 60;
    
    final difference = _endDate!.difference(_startDate!);
    if (difference.inHours <= 24) {
      return 60; // Her saat için bir gösterge
    } else if (difference.inDays <= 7) {
      return 4; // Her 4 saat için bir gösterge
    } else {
      return 1; // Her gün için bir gösterge
    }
  }
} 