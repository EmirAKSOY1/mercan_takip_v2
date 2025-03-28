import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BottomNavigationBar(
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      selectedItemColor: currentIndex >= 0 ? Colors.blue : Colors.grey,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          /*case 1:
            Navigator.pushReplacementNamed(context, '/datas');
            break;*/
          case 1:
            Navigator.pushReplacementNamed(context, '/alarms');
            break;
        }
      },
      items:  [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: l10n.dashboard,
        ),
        /*
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          label: 'Kayıtlar',
        ),*/
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          label: l10n.alarms,
        ),
      ],
    );
  }
} 