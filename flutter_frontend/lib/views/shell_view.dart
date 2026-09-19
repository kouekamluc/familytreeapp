import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'auth/login_view.dart';
import 'kinship/kinship_calculator_view.dart';
import 'landing_view.dart';
import 'people/people_list_view.dart';
import 'tree/tree_view.dart';

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  int _currentIndex = 0;
  Person? _kinshipPersonA;
  Person? _kinshipPersonB;

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openKinshipForPerson(Person person) {
    setState(() {
      _kinshipPersonA = person;
      _currentIndex = 2; // Kinship tab
    });
  }

  void _jumpToTree(Person person) {
    setState(() {
      _currentIndex = 1; // Tree tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final pages = [
          LandingView(
            onExploreTree: () => _navigateToIndex(1),
            onOpenKinship: () => _navigateToIndex(2),
            onOpenDirectory: () => _navigateToIndex(3),
          ),
          TreeView(
            onOpenKinshipForPerson: (person) => _openKinshipForPerson(person),
          ),
          KinshipCalculatorView(
            initialPersonA: _kinshipPersonA,
            initialPersonB: _kinshipPersonB,
          ),
          PeopleListView(
            onSelectPersonForKinship: (p) => _openKinshipForPerson(p),
            onJumpToTree: (p) => _jumpToTree(p),
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: RoyalTheme.brightGold),
                  ),
                  child: const Icon(Icons.shield, color: RoyalTheme.brightGold, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'ROYAL ANCESTRY',
                  style: GoogleFonts.cinzel(
                    color: RoyalTheme.brightGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            actions: [
              // Theme Toggle
              IconButton(
                tooltip: isDark ? 'Switch to Alabaster Light Theme' : 'Switch to Obsidian Dark Theme',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: RoyalTheme.brightGold,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
              const SizedBox(width: 8),
              // Auth Button
              if (authProvider.isAuthenticated)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PopupMenuButton<String>(
                    tooltip: 'Curator Menu',
                    child: Chip(
                      avatar: const CircleAvatar(
                        backgroundColor: RoyalTheme.brightGold,
                        child: Icon(Icons.person, color: Colors.black, size: 16),
                      ),
                      label: Text(
                        authProvider.currentUser?.displayName ?? 'Curator',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      backgroundColor: RoyalTheme.primaryGold.withOpacity(0.15),
                      side: const BorderSide(color: RoyalTheme.borderDark),
                    ),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Log Out'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'logout') {
                        authProvider.logout();
                      }
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    icon: const Icon(Icons.login, color: RoyalTheme.brightGold, size: 18),
                    label: const Text(
                      'Sign In',
                      style: TextStyle(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: LoginView(onLoginSuccess: () => Navigator.pop(ctx)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _navigateToIndex,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: isDark ? RoyalTheme.surfaceDark : Colors.white,
                      selectedIconTheme: const IconThemeData(color: RoyalTheme.brightGold),
                      unselectedIconTheme: const IconThemeData(color: Colors.grey),
                      selectedLabelTextStyle: GoogleFonts.cinzel(
                        color: RoyalTheme.brightGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelTextStyle: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: Text('Dynasty'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.account_tree_outlined),
                          selectedIcon: Icon(Icons.account_tree),
                          label: Text('Tree'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.hub_outlined),
                          selectedIcon: Icon(Icons.hub),
                          label: Text('Kinship'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: Text('Registry'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1, thickness: 1, color: RoyalTheme.borderDark),
                    Expanded(child: pages[_currentIndex]),
                  ],
                )
              : pages[_currentIndex],
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _navigateToIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: isDark ? RoyalTheme.surfaceDark : Colors.white,
                  selectedItemColor: RoyalTheme.brightGold,
                  unselectedItemColor: Colors.grey,
                  selectedLabelStyle: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Dynasty',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_tree_outlined),
                      activeIcon: Icon(Icons.account_tree),
                      label: 'Tree',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.hub_outlined),
                      activeIcon: Icon(Icons.hub),
                      label: 'Kinship',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people_outline),
                      activeIcon: Icon(Icons.people),
                      label: 'Registry',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
