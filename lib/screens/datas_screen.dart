import 'package:flutter/material.dart';
import 'package:mercan_takip_v2/widgets/app_drawer.dart';
import 'package:mercan_takip_v2/widgets/bottom_nav_bar.dart';

class DatasScreen extends StatefulWidget {
  const DatasScreen({super.key});

  @override
  State<DatasScreen> createState() => _DatasScreenState();
}

class _DatasScreenState extends State<DatasScreen> {
  final int _itemsPerPage = 5;
  int _currentPage = 0;
  final int _totalItems = 10; // Örnek veri sayısı

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
      body: ListView(
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
                  'Tüm kayıtlarınızı buradan görüntüleyebilirsiniz',
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
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list),
                        const SizedBox(width: 8),
                        const Text('Filtrele'),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kayıt Listesi
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemsPerPage,
            itemBuilder: (context, index) {
              final itemIndex = _currentPage * _itemsPerPage + index;
              if (itemIndex >= _totalItems) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.data_usage, color: Colors.white),
                  ),
                  title: Text('Kümes-${itemIndex + 1}'),
                  subtitle: Text('Tarih: ${DateTime.now().toString().split(' ')[0]}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('İç Sıcaklık', '32°C'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Dış Sıcaklık', '25°C'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Nem', '%65'),
                          const SizedBox(height: 8),
                          _buildDetailRow('CO2', '800 ppm'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Amonyak', '15 ppm'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Modern Sayfalama Kontrolleri
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İlk Sayfa Butonu
                _buildPageButton(
                  icon: Icons.first_page,
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage = 0;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                // Önceki Sayfa Butonu
                _buildPageButton(
                  icon: Icons.chevron_left,
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                // Sayfa Numaraları
                ...List.generate(
                  (_totalItems / _itemsPerPage).ceil(),
                  (index) => _buildPageNumberButton(index),
                ),
                const SizedBox(width: 8),
                // Sonraki Sayfa Butonu
                _buildPageButton(
                  icon: Icons.chevron_right,
                  onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                // Son Sayfa Butonu
                _buildPageButton(
                  icon: Icons.last_page,
                  onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems
                      ? () {
                          setState(() {
                            _currentPage = (_totalItems / _itemsPerPage).ceil() - 1;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildPageNumberButton(int pageIndex) {
    final isActive = pageIndex == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentPage = pageIndex;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '${pageIndex + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.blue,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 