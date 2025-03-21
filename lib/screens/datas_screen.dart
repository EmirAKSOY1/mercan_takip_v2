import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';
import 'package:mercan_takip_v2/widgets/bottom_nav_bar.dart';
import 'package:mercan_takip_v2/services/auth_service.dart';

class DatasScreen extends StatefulWidget {
  const DatasScreen({super.key});

  @override
  State<DatasScreen> createState() => _DatasScreenState();
}

class _DatasScreenState extends State<DatasScreen> {
  final int _itemsPerPage = 10;
  int _currentPage = 0;
  int _totalItems = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _records = [];
  final AuthService _authService = AuthService();
  String? _selectedCoopId;
  List<Map<String, dynamic>> _coops = [{'id': '0', 'name': 'Tümü'}];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadCoops();
    _fetchRecords();
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

  Future<void> _fetchRecords() async {
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
      final uri = Uri.parse('http://62.171.140.229/api/getRecords')
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
          _records = List<Map<String, dynamic>>.from(data['data']);
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
      _fetchRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/datas'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Kayıtlar'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _currentPage = 0;
          });
          await _fetchRecords();
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
                    Colors.indigo[900]!,
                    Colors.indigo[700]!,
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
                    'Kayıtlar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toplam $_totalItems kayıt',
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
                                _fetchRecords();
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
                                _fetchRecords();
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

            // Kayıt Listesi
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.data_usage, color: Colors.white),
                      ),
                      title: Text(record['coop_name'] ?? 'Bilinmeyen Kümes'),
                      subtitle: Text(
                        'Tarih: ${_formatDateTime(record['created_at'])}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDetailRow('İç Sıcaklık', '${record['ic_sicaklik']}°C'),
                              const SizedBox(height: 8),
                              _buildDetailRow('Dış Sıcaklık', '${record['dis_sicaklik']}°C'),
                              const SizedBox(height: 8),
                              _buildDetailRow('Nem', '%${record['nem']}'),
                              const SizedBox(height: 8),
                              _buildDetailRow('CO2', '${record['co2']} ppm'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Sayfalama Kontrolleri
            if (_totalItems > _itemsPerPage)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageButton(
                      icon: Icons.first_page,
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() {
                                _currentPage = 0;
                              });
                              _fetchRecords();
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildPageButton(
                      icon: Icons.chevron_left,
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _fetchRecords();
                            }
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Sayfa ${_currentPage + 1} / ${(_totalItems / _itemsPerPage).ceil()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildPageButton(
                      icon: Icons.chevron_right,
                      onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _fetchRecords();
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildPageButton(
                      icon: Icons.last_page,
                      onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems
                          ? () {
                              setState(() {
                                _currentPage = (_totalItems / _itemsPerPage).ceil() - 1;
                              });
                              _fetchRecords();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.blue[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.blue : Colors.grey,
          size: 20,
        ),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
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