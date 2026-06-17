import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'activity_screen.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final List<Widget> _pages = [
    const DashboardScreen(),
    if (!kIsWeb) const ActivityScreen(),
    const DevicesScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];
  late final List<(IconData, IconData, String)> _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Inicio'),
    if (!kIsWeb)
      (Icons.directions_walk_outlined, Icons.directions_walk, 'Actividad'),
    (Icons.sensors_outlined, Icons.sensors_rounded, 'Dispositivos'),
    (Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Asistente'),
    (Icons.person_outline, Icons.person_rounded, 'Perfil'),
  ];
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 840;
    final body = IndexedStack(index: _index, children: _pages);
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(
              index: _index,
              onSelect: (i) => setState(() => _index = i),
              items: _items,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.lavenderSoft.withValues(alpha: 0.6),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final it in _items)
              NavigationDestination(
                  icon: Icon(it.$1), selectedIcon: Icon(it.$2), label: it.$3),
          ],
        ),
      ),
    );
  }
}
class _SideRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<(IconData, IconData, String)> items;
  const _SideRail(
      {required this.index, required this.onSelect, required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(4, 0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Row(
              children: [
                const CirceLogo(size: 38),
                const SizedBox(width: 12),
                GradientText('Circe',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          for (int i = 0; i < items.length; i++)
            _RailItem(
              icon: items[i].$1,
              activeIcon: items[i].$2,
              label: items[i].$3,
              selected: index == i,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text('Circe · v1.1',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
class _RailItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected
            ? AppColors.lavenderSoft.withValues(alpha: 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(selected ? activeIcon : icon,
                    color: selected ? AppColors.purple : AppColors.inkSoft,
                    size: 22),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.ink : AppColors.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}