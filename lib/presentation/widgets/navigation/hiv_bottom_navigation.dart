// lib/presentation/widgets/navigation/hiv_bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class HIVBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<HIVNavItem> items;

  const HIVBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;
              
              return Expanded(
                child: _NavItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onIndexChanged(index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final HIVNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? AppColors.primaryPurple : AppColors.slate;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: color,
                  size: 24,
                ),
                if (item.badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.all(item.badge! > 9 ? 2 : 4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          item.badge! > 99 ? '99+' : item.badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HIVNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int? badge;

  const HIVNavItem({
    required this.label,
    required this.icon,
    IconData? activeIcon,
    this.badge,
  }) : activeIcon = activeIcon ?? icon;
}

// Default navigation items
class HIVNavigationItems {
  static const discover = HIVNavItem(
    label: 'Découverte',
    icon: Icons.style_outlined,
    activeIcon: Icons.style,
  );

  static const matches = HIVNavItem(
    label: 'Matches',
    icon: Icons.favorite_outline,
    activeIcon: Icons.favorite,
  );

  static const messages = HIVNavItem(
    label: 'Messages',
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
  );

  static const resources = HIVNavItem(
    label: 'Ressources',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book,
  );

  static const profile = HIVNavItem(
    label: 'Profil',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  );

  static List<HIVNavItem> get defaultItems => [
        discover,
        matches,
        messages,
        resources,
        profile,
      ];
}

// Tab navigator wrapper for nested navigation
class HIVTabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;

  const HIVTabNavigator({
    Key? key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.routes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            if (routes.containsKey(settings.name)) {
              return routes[settings.name]!(context);
            }
            // Return a 404 page or redirect to initial route
            return routes[initialRoute]!(context);
          },
          settings: settings,
        );
      },
    );
  }
}

// Main scaffold with bottom navigation
class HIVMainScaffold extends StatefulWidget {
  final List<Widget> screens;
  final List<HIVNavItem>? navItems;
  final int initialIndex;

  const HIVMainScaffold({
    Key? key,
    required this.screens,
    this.navItems,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<HIVMainScaffold> createState() => _HIVMainScaffoldState();
}

class _HIVMainScaffoldState extends State<HIVMainScaffold> {
  late int _currentIndex;
  late List<HIVNavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _navItems = widget.navItems ?? HIVNavigationItems.defaultItems;
  }

  void _onIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.screens,
      ),
      bottomNavigationBar: HIVBottomNavigation(
        currentIndex: _currentIndex,
        onIndexChanged: _onIndexChanged,
        items: _navItems,
      ),
    );
  }
}