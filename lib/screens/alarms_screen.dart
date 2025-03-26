import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';
import 'package:mercan_takip_v2/widgets/bottom_nav_bar.dart';
import 'package:mercan_takip_v2/services/auth_service.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  final int _itemsPerPage = 10;
  int _currentPage = 0;
  int _totalItems = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _alarms = [];
  final AuthService _authService = AuthService();
  String? _selectedCoopId;
  List<Map<String, dynamic>> _coops = [{'id': '0', 'name': 'Tümü'}];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadCoops();
    _fetchAlarms();
  }

  Future<void> _loadCoops() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://62.171.140.229/api/getCoops'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _coops = [{'id': '0', 'name': 'Tümü'}, ...data];
        });
      }
    } catch (e) {
      print('Error loading coops: $e');
    }
  }

  Future<void> _fetchAlarms() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Sayfalama ve filtreleme parametreleri
      final page = _currentPage + 1;
      final perPage = _itemsPerPage;
      final coopFilter = _selectedCoopId != '0' ? _selectedCoopId : null;
      final startDateFilter = _startDate != null ? _startDate!.toIso8601String() : null;
      final endDateFilter = _endDate != null ? _endDate!.toIso8601String() : null;

      // API endpoint'i
      final uri = Uri.parse('http://62.171.140.229/api/getAlarms')
          .replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (coopFilter != null) 'coop': coopFilter,
        if (startDateFilter != null) 'start_date': startDateFilter,
        if (endDateFilter != null) 'end_date': endDateFilter,
      });

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _alarms = List<Map<String, dynamic>>.from(data['data']);
          _totalItems = data['total'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler yüklenirken bir hata oluştu')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _currentPage = 0;
      });
      _fetchAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/alarms'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Alarmlar'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _currentPage = 0;
          });
          await _fetchAlarms();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Üst Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red[900]!,
                    Colors.red[700]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alarmlar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toplam $_totalItems alarm',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filtreler
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.filter_list),
                title: const Text('Filtrele'),
                trailing: const Icon(Icons.arrow_drop_down),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kümes Seçin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCoopId ?? '0',
                              isExpanded: true,
                              items: _coops.map((coop) {
                                return DropdownMenuItem<String>(
                                  value: coop['id'].toString(),
                                  child: Text(coop['name']),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCoopId = newValue;
                                  _currentPage = 0;
                                });
                                _fetchAlarms();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tarih Aralığı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    _startDate != null
                                        ? _formatDateOnly(_startDate!.toIso8601String())
                                        : 'Başlangıç Tarihi',
                                    style: TextStyle(
                                      color: _startDate != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    _endDate != null
                                        ? _formatDateOnly(_endDate!.toIso8601String())
                                        : 'Bitiş Tarihi',
                                    style: TextStyle(
                                      color: _endDate != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_startDate != null || _endDate != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                  _currentPage = 0;
                                });
                                _fetchAlarms();
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Filtreyi Temizle'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alarm Listesi
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alarms.length,
                itemBuilder: (context, index) {
                  final alarm = _alarms[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm['description'] ?? 'Alarm açıklaması yok',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alarm['coop_name'] ?? 'Bilinmeyen Kümes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(alarm['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Sayfalama Kontrolleri
            if (_totalItems > _itemsPerPage)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonSize = constraints.maxWidth < 600 ? 36.0 : 40.0;
                    final iconSize = constraints.maxWidth < 600 ? 18.0 : 20.0;
                    final fontSize = constraints.maxWidth < 600 ? 14.0 : 16.0;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPageButton(
                          icon: Icons.first_page,
                          iconSize: iconSize,
                          buttonSize: buttonSize,
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage = 0;
                                  });
                                  _fetchAlarms();
                                }
                              : null,
                          tooltip: 'İlk Sayfa',
                        ),
                        const SizedBox(width: 8),
                        _buildPageButton(
                          icon: Icons.chevron_left,
                          iconSize: iconSize,
                          buttonSize: buttonSize,
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                  _fetchAlarms();
                                }
                              : null,
                          tooltip: 'Önceki Sayfa',
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Text(
                            'Sayfa ${_currentPage + 1}/${(_totalItems / _itemsPerPage).ceil()}',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildPageButton(
                          icon: Icons.chevron_right,
                          iconSize: iconSize,
                          buttonSize: buttonSize,
                          onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems && _totalItems > _itemsPerPage
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                  });
                                  _fetchAlarms();
                                }
                              : null,
                          tooltip: 'Sonraki Sayfa',
                        ),
                        const SizedBox(width: 8),
                        _buildPageButton(
                          icon: Icons.last_page,
                          iconSize: iconSize,
                          buttonSize: buttonSize,
                          onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems && _totalItems > _itemsPerPage
                              ? () {
                                  setState(() {
                                    _currentPage = (_totalItems / _itemsPerPage).ceil() - 1;
                                  });
                                  _fetchAlarms();
                                }
                              : null,
                          tooltip: 'Son Sayfa',
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required double iconSize,
    required double buttonSize,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.red[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onPressed != null ? Colors.red[100]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: onPressed != null ? Colors.red[700] : Colors.grey[400],
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day.toString().padLeft(2, '0')}.'
          '${dateTime.month.toString().padLeft(2, '0')}.'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatDateOnly(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day.toString().padLeft(2, '0')}.'
          '${dateTime.month.toString().padLeft(2, '0')}.'
          '${dateTime.year}';
    } catch (e) {
      return dateTimeStr;
    }
  }
} 