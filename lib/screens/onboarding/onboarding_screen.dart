import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Verileriniz Kontrol Altında!',
      description: 'Sensörlerinizden gelen tüm verileri anlık takip edin, kümesinizi verimli yönetin. 🚀',
      image: 'assets/images/onboarding1.png',
    ),
    OnboardingPageData(
      title: 'Akıllı Çözümlerle Geleceğe!',
      description: 'Yapay zeka desteğiyle kümesinizi daha verimli yönetin, verileri analiz edin ve en iyi kararları alın. 🤖',
      image: 'assets/images/onboarding2.png',
    ),
    OnboardingPageData(
      title: 'Her An Haberdar Olun!',
      description: 'Önemli uyarıları kaçırmayın, kümesinizdeki değişikliklerden anında haberdar olun. 🔔',
      image: 'assets/images/onboarding3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkipPressed() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      
      if (!mounted) return;
      
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return OnboardingPage(data: pages[index]);
              },
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage < pages.length - 1)
                          TextButton(
                            onPressed: _onSkipPressed,
                            child: const Text('Geç'),
                          ),
                        if (_currentPage < pages.length - 1)
                          ElevatedButton(
                            onPressed: _onNextPressed,
                            child: const Text('Sonraki'),
                          )
                        else
                          Expanded(
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _onSkipPressed,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 48),
                                ),
                                child: const Text('Başla'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 