import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  late List<Map<String, String>> _pages;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      {'image': 'assets/images/onboarding1.png', 'title': 'Başlık 1', 'description': 'Bu, ilk sayfa açıklamasıdır.'},
      {'image': 'assets/images/onboarding2.png', 'title': 'Başlık 2', 'description': 'Bu, ikinci sayfa açıklamasıdır.'},
      {'image': 'assets/images/onboarding3.png', 'title': 'Başlık 3', 'description': 'Bu, üçüncü sayfa açıklamasıdır.'},
    ];
    _currentPage = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ekran genişliğine göre boyutları ayarla
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenWidth < 600;
            
            // Responsive boyutlar
            final titleFontSize = isSmallScreen ? 24.0 : 32.0;
            final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
            final buttonHeight = isSmallScreen ? 48.0 : 56.0;
            final buttonFontSize = isSmallScreen ? 16.0 : 18.0;
            final imageSize = isSmallScreen ? screenWidth * 0.6 : screenWidth * 0.7;
            final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
            final verticalPadding = isSmallScreen ? 16.0 : 24.0;
            
            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Image.asset(
                                _pages[index]['image']!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _pages[index]['title']!,
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[900],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  Text(
                                    _pages[index]['description']!,
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => Container(
                              width: isSmallScreen ? 8 : 10,
                              height: isSmallScreen ? 8 : 10,
                              margin: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors.red[900]
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              } else {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentPage < _pages.length - 1 ? 'İleri' : 'Başla',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 