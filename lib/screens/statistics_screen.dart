import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _coops = [];
  String _selectedCoopId = '0';

  @override
  void initState() {
    super.initState();
    _loadCoops();
    _loadSampleData();
  }

  void _loadSampleData() {
    // Örnek kümes verileri
    _coops = [
      {'id': '0', 'name': 'Tümü'},
      {'id': '1', 'name': 'Kümes 1'},
      {'id': '2', 'name': 'Kümes 2'},
      {'id': '3', 'name': 'Kümes 3'},
    ];

    // Örnek istatistik verileri
    _stats = {
      'total_coops': 3,
      'active_sensors': 15,
      'total_alarms': 8,
      'temperature_data': List.generate(7, (index) {
        return {
          'x': index.toDouble(),
          'y': 25.0 + (index * 0.5) + (index % 2 == 0 ? 0.3 : -0.3),
        };
      }),
      'humidity_data': List.generate(7, (index) {
        return {
          'x': index.toDouble(),
          'y': 65.0 + (index * 0.3) + (index % 2 == 0 ? -0.2 : 0.2),
        };
      }),
    };

    setState(() => _isLoading = false);
  }

  Future<void> _loadCoops() async {
    // API entegrasyonu olmadığı için boş bırakıyoruz
  }

  Future<void> _fetchStatistics() async {
    // API entegrasyonu olmadığı için örnek verileri yeniden yüklüyoruz
    _loadSampleData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kümes Seçimi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCoopId,
                          isExpanded: true,
                          items: _coops.map((coop) {
                            return DropdownMenuItem(
                              value: coop['id'].toString(),
                              child: Text(coop['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCoopId = value);
                              _fetchStatistics();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Genel İstatistikler
                    _buildStatCard(
                      title: 'Toplam Kümes',
                      value: _stats['total_coops']?.toString() ?? '0',
                      icon: Icons.business,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Aktif Sensörler',
                      value: _stats['active_sensors']?.toString() ?? '0',
                      icon: Icons.sensors,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Toplam Uyarı',
                      value: _stats['total_alarms']?.toString() ?? '0',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),

                    // Grafikler
                    _buildChartSection(
                      title: 'Sıcaklık Ortalamaları',
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _stats['temperature_data']?.map<FlSpot>((data) {
                                  return FlSpot(
                                    data['x'].toDouble(),
                                    data['y'].toDouble(),
                                  );
                                }).toList() ?? [],
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildChartSection(
                      title: 'Nem Ortalamaları',
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _stats['humidity_data']?.map<FlSpot>((data) {
                                  return FlSpot(
                                    data['x'].toDouble(),
                                    data['y'].toDouble(),
                                  );
                                }).toList() ?? [],
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
} 