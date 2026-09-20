import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/accessibility_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tree_provider.dart';
import '../widgets/heritage_key_sheet.dart';
import '../widgets/royal_button.dart';
import '../widgets/user_profile_sheet.dart';
import 'auth/login_view.dart';

import 'kinship/kinship_calculator_view.dart';
import 'landing_view.dart';
import 'mobile/mobile_welcome_view.dart';
import 'people/person_detail_view.dart';
import 'people/people_list_view.dart';
import 'relationships/relationship_list_view.dart';
import 'tree/tree_view.dart';
import 'vault/heritage_vault_view.dart';

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  int _dashboardIndex = 0; // 0: Tree, 1: Registry, 2: Kinship, 3: Alliances, 4: Heritage Vault
  late final PageController _pageController;
  Person? _kinshipPersonA;
  Person? _kinshipPersonB;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _dashboardIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToDashboardIndex(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _dashboardIndex = index;
    });
    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openKinshipForPerson(Person person) {
    setState(() {
      _kinshipPersonA = person;
      _dashboardIndex = 2; // Kinship tab
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _jumpToTree(Person person) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.selectPerson(person);
    setState(() {
      _dashboardIndex = 0; // Tree tab
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openPersonDetail(Person person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDetailView(
          person: person,
          onNavigateToPerson: (p) => _openPersonDetail(p),
          onJumpToTree: (p) => _jumpToTree(p),
          onOpenKinship: (p) => _openKinshipForPerson(p),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131620) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: RoyalTheme.brightGold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LoginView(
                    onLoginSuccess: () {
                      Navigator.pop(ctx);
                      treeProvider.loadData();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: LoginView(
            onLoginSuccess: () {
              Navigator.pop(ctx);
              treeProvider.loadData();
            },
          ),
        ),
      );
    }
  }

  void _showAddPersonDialog(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    final firstController = TextEditingController();
    final lastController = TextEditingController();
    final tradController = TextEditingController();
    final villageController = TextEditingController();
    int genTier = 1;

    Widget buildForm(StateSetter setDialogState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: firstController,
            decoration: const InputDecoration(labelText: 'First Name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lastController,
            decoration: const InputDecoration(labelText: 'Last Name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tradController,
            decoration: const InputDecoration(
              labelText: 'Customary Title (e.g. Tadji, Ma, Fo)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: villageController,
            decoration: const InputDecoration(
              labelText: 'Village of Origin (e.g. Bandjoun)',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: genTier,
            decoration: const InputDecoration(labelText: 'Generation Tier'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('👑 Gen 1 • Founding Patriarch / Matriarch')),
              DropdownMenuItem(value: 2, child: Text('🛡️ Gen 2 • Royal Elder / Dignitary')),
              DropdownMenuItem(value: 3, child: Text('🌿 Gen 3 • Modern Pillar / Descendant')),
              DropdownMenuItem(value: 4, child: Text('🌱 Gen 4 • Next Generation Youth')),
            ],
            onChanged: (val) {
              if (val != null) setDialogState(() => genTier = val);
            },
          ),
        ],
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131620) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: RoyalTheme.brightGold.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enroll Dynasty Member',
                      style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    buildForm(setDialogState),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: RoyalButton(
                            label: 'Add to Dynasty',
                            height: 44,
                            fontSize: 14,
                            onPressed: () async {
                              if (firstController.text.trim().isEmpty) return;
                              await treeProvider.addPerson({
                                'first_name': firstController.text.trim(),
                                'last_name': lastController.text.trim().isNotEmpty ? lastController.text.trim() : 'Kkevo',
                                'traditional_name': tradController.text.trim().isNotEmpty ? tradController.text.trim() : null,
                                'village_of_origin': villageController.text.trim().isNotEmpty ? villageController.text.trim() : 'Bandjoun',
                                'generation_tier': genTier,
                                'is_living': true,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Enroll Royal Dynasty Member',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: buildForm(setDialogState),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              RoyalButton(
                label: 'Add to Dynasty',
                height: 40,
                fontSize: 13,
                onPressed: () async {
                  if (firstController.text.trim().isEmpty) return;
                  await treeProvider.addPerson({
                    'first_name': firstController.text.trim(),
                    'last_name': lastController.text.trim().isNotEmpty ? lastController.text.trim() : 'Kkevo',
                    'traditional_name': tradController.text.trim().isNotEmpty ? tradController.text.trim() : null,
                    'village_of_origin': villageController.text.trim().isNotEmpty ? villageController.text.trim() : 'Bandjoun',
                    'generation_tier': genTier,
                    'is_living': true,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final treeProvider = Provider.of<TreeProvider>(context);
    final isDark = themeProvider.isDark;
    final isAuthenticated = authProvider.isAuthenticated;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = MediaQuery.of(context).size.shortestSide < 600;
        final isWide = !isPhone && constraints.maxWidth >= 960 && constraints.maxHeight >= 640;

        // =========================================================
        // CASE A: GUEST / LOGGED-OUT VISITORS
        // =========================================================
        if (!isAuthenticated) {
          // Native Mobile Onboarding Experience (<860px)
          if (!isWide) {
            return MobileWelcomeView(
              onExplore: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final tree = Provider.of<TreeProvider>(context, listen: false);
                await auth.demoLogin();
                await tree.loadData(
                  targetTreeId: auth.invitedTreeId,
                  targetPersonId: auth.invitedPersonId,
                );
                setState(() {
                  _dashboardIndex = 0;
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              },
              onSignIn: () => HeritageKeySheet.show(
                context,
                onLoginSuccess: () {
                  setState(() {
                    _dashboardIndex = 0;
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                },
              ),
            );
          }


          // Desktop Web Landing Portal (>=860px)
          return Scaffold(
            body: Column(
              children: [
                _buildPublicWebNavbar(context, isDark, themeProvider, isWide),
                Expanded(
                  child: LandingView(
                    onSignIn: () => _showLoginDialog(context),
                    onJoin: () => _showLoginDialog(context),
                    onExploreDemo: () async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final tree = Provider.of<TreeProvider>(context, listen: false);
                      await auth.demoLogin();
                      await tree.loadData();
                    },
                  ),
                ),
              ],
            ),
          );
        }

        // =========================================================
        // CASE B: AUTHENTICATED USERS (Side Nav + Full Canvas)
        // =========================================================
        final dashboardPages = [
          TreeView(
            onOpenKinshipForPerson: (person) => _openKinshipForPerson(person),
            onOpenPersonDetail: (person) => _openPersonDetail(person),
          ),
          PeopleListView(
            onSelectPersonForKinship: (p) => _openKinshipForPerson(p),
            onJumpToTree: (p) => _jumpToTree(p),
            onOpenPersonDetail: (p) => _openPersonDetail(p),
          ),
          KinshipCalculatorView(
            initialPersonA: _kinshipPersonA,
            initialPersonB: _kinshipPersonB,
          ),
          RelationshipListView(
            onNavigateToPerson: (p) => _openPersonDetail(p),
            onJumpToTree: (p) => _jumpToTree(p),
          ),
          const HeritageVaultView(),
        ];

        // Desktop layout with SIDE NAVIGATION (eliminates stacked double navbars!)
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                // Luxury Vertical Side Navigation Bar
                _buildDashboardSideNavBar(
                  context,
                  isDark,
                  themeProvider,
                  authProvider,
                  treeProvider,
                ),

                // Main Page Canvas
                Expanded(
                  child: dashboardPages[_dashboardIndex],
                ),
              ],
            ),
          );
        }

        // Mobile Layout Fallback (Sleek Native Android Material 3 Shell)
        return PopScope(
          canPop: _dashboardIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_dashboardIndex != 0) {
              _navigateToDashboardIndex(0);
            }
          },
          child: Scaffold(
            appBar: _buildDashboardMobileAppBar(
              context,
              isDark,
              themeProvider,
              authProvider,
              treeProvider,
            ),
            body: PageView(
              controller: _pageController,
              physics: _dashboardIndex == 0
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _dashboardIndex = index;
                });
              },
              children: dashboardPages,
            ),
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 66,
                backgroundColor: isDark ? const Color(0xFF0C0E14) : const Color(0xFFFAFBFD),
                indicatorColor: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.22 : 0.18),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? RoyalTheme.brightGold
                        : (isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B)),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 22,
                    color: isSelected
                        ? RoyalTheme.brightGold
                        : (isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B)),
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _dashboardIndex,
                onDestinationSelected: _navigateToDashboardIndex,
                elevation: 0,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.account_tree_outlined),
                    selectedIcon: Icon(Icons.account_tree, color: RoyalTheme.brightGold),
                    label: 'Arbre',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people, color: RoyalTheme.brightGold),
                    label: 'Membres',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon: Icon(Icons.hub, color: RoyalTheme.brightGold),
                    label: 'Parenté',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.link_outlined),
                    selectedIcon: Icon(Icons.link, color: RoyalTheme.brightGold),
                    label: 'Alliances',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.vpn_key_outlined),
                    selectedIcon: Icon(Icons.vpn_key_rounded, color: RoyalTheme.brightGold),
                    label: 'Clés',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // 1. PUBLIC GUEST TOP NAVIGATION BAR (For Visitors & Unauthenticated)
  // =========================================================================
  Widget _buildPublicWebNavbar(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
    bool isWide,
  ) {
    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111319) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: RoyalTheme.primaryGold.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Crest & Title
          Expanded(
            child: Row(
              children: [
                Container(
                  width: isWide ? 44 : 36,
                  height: isWide ? 44 : 36,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF141722) : const Color(0xFFF9F5EC),
                    border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: RoyalTheme.brightGold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFFD4AF37), Color(0xFFC5A059)],
                        ).createShader(bounds),
                        child: Text(
                          'KKEVO FAMILY',
                          style: GoogleFonts.cinzel(
                            fontSize: isWide ? 18 : 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: isWide ? 2.2 : 1.2,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isWide)
                        Text(
                          'ROYAL HERITAGE & LIVING ROOTS',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: isDark ? RoyalTheme.lightGold : const Color(0xFF855B14),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Public Value Tags (Desktop)
          if (isWide)
            Row(
              children: [
                _buildPublicTag(Icons.lock_outline_rounded, 'Family Privacy Protected', isDark),
                const SizedBox(width: 20),
                _buildPublicTag(Icons.auto_stories_outlined, 'Sacred Customary Vault', isDark),
                const SizedBox(width: 20),
                _buildPublicTag(Icons.account_tree_outlined, 'Multi-Generation Lineage', isDark),
              ],
            ),

          // Right: Theme Toggle & Sign In
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isDark ? 'Switch to Alabaster Light Mode' : 'Switch to Obsidian Dark Mode',
                icon: Container(
                  width: isWide ? 38 : 34,
                  height: isWide ? 38 : 34,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF7F2E7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: RoyalTheme.primaryGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: RoyalTheme.brightGold,
                    size: 18,
                  ),
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
              if (isWide) ...[
                const SizedBox(width: 12),
                RoyalButton(
                  label: 'Explore Demo Vault',
                  icon: const Icon(Icons.flash_on_rounded, size: 15, color: Colors.black),
                  variant: RoyalButtonVariant.gold,
                  height: 42,
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final tree = Provider.of<TreeProvider>(context, listen: false);
                    await auth.demoLogin();
                    await tree.loadData();
                  },
                ),
              ],
              const SizedBox(width: 8),
              RoyalButton(
                label: 'Sign In',
                icon: const Icon(Icons.login_rounded, size: 14, color: Colors.black),
                variant: RoyalButtonVariant.gold,
                height: isWide ? 42 : 36,
                fontSize: 12.5,
                padding: EdgeInsets.symmetric(horizontal: isWide ? 18 : 12),
                onPressed: () => _showLoginDialog(context),
              ),
              if (isWide) ...[
                const SizedBox(width: 10),
                RoyalButton(
                  label: 'Join Dynasty',
                  icon: const Icon(Icons.how_to_reg_rounded, size: 15, color: RoyalTheme.brightGold),
                  variant: RoyalButtonVariant.outline,
                  height: 42,
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  onPressed: () => _showLoginDialog(context),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublicTag(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: RoyalTheme.brightGold),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFC7C1B7) : const Color(0xFF555048),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 2. AUTHENTICATED DASHBOARD SIDE NAVIGATION BAR (Desktop Left Sidebar)
  // =========================================================================
  Widget _buildDashboardSideNavBar(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
    AuthProvider authProvider,
    TreeProvider treeProvider,
  ) {
    final memberCount = treeProvider.people.length;

    return Container(
      width: 272,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F121A) : const Color(0xFFFAFBFD),
        border: Border(
          right: BorderSide(
            color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF141722) : const Color(0xFFF9F5EC),
                    border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: RoyalTheme.brightGold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFFD4AF37), Color(0xFFC5A059)],
                        ).createShader(bounds),
                        child: Text(
                          'KKEVO FAMILY',
                          style: GoogleFonts.cinzel(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'ROYAL HERITAGE VAULT',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? RoyalTheme.lightGold : const Color(0xFF855B14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active Lineage Badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161A26) : const Color(0xFFF0EBE0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RoyalTheme.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('👑', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treeProvider.selectedTree?.name ?? 'Royal Lineage',
                        style: GoogleFonts.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? RoyalTheme.lightGold : const Color(0xFF855B14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$memberCount Living & Ancestral Pillars',
                        style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Primary Navigation Links (Dual-line, plain language & intuitive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildSideNavLink(
                  label: 'Family Tree',
                  subtitle: 'Visual Pedigree Chart',
                  icon: Icons.account_tree_rounded,
                  index: 0,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildSideNavLink(
                  label: 'Family Registry',
                  subtitle: 'Members & Generations',
                  icon: Icons.people_alt_rounded,
                  index: 1,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildSideNavLink(
                  label: 'Kinship Solver',
                  subtitle: 'How are two related?',
                  icon: Icons.hub_rounded,
                  index: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildSideNavLink(
                  label: 'Royal Alliances',
                  subtitle: 'Marriages & Unions',
                  icon: Icons.link_rounded,
                  index: 3,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildSideNavLink(
                  label: 'Heritage Vault',
                  subtitle: 'Passkeys & Access Keys',
                  icon: Icons.vpn_key_rounded,
                  index: 4,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Add Relative Quick CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RoyalButton(
              label: 'Enroll Relative',
              icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.black),
              variant: RoyalButtonVariant.gold,
              height: 42,
              fontSize: 13,
              onPressed: () => _showAddPersonDialog(context),
            ),
          ),

          const Spacer(),

          // Bottom Section: Accessibility Text Size + Theme Mode + Curator Badge + Red Logout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0D14) : const Color(0xFFF1F3F7),
              border: Border(
                top: BorderSide(
                  color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                // Senior / Accessibility Large Text Mode Toggle
                Consumer<AccessibilityProvider>(
                  builder: (context, access, _) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: access.isSeniorMode
                            ? RoyalTheme.primaryGold.withValues(alpha: 0.16)
                            : (isDark ? const Color(0xFF151822) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: access.isSeniorMode
                              ? RoyalTheme.brightGold
                              : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => access.toggleSeniorMode(),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_size_rounded,
                              color: access.isSeniorMode ? RoyalTheme.brightGold : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    access.isSeniorMode ? 'Large Text: ON' : 'Large Text: OFF',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Senior / High Legibility',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: access.isSeniorMode,
                              onChanged: (_) => access.toggleSeniorMode(),
                              activeTrackColor: RoyalTheme.brightGold.withValues(alpha: 0.5),
                              activeThumbColor: RoyalTheme.brightGold,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Theme Toggle Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDark ? 'Obsidian Dark Mode' : 'Alabaster Light Mode',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      tooltip: 'Toggle Theme',
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: RoyalTheme.brightGold,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Curator Profile Card & Logout Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151822) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => UserProfileSheet.show(context),
                        borderRadius: BorderRadius.circular(14),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: RoyalTheme.brightGold,
                          child: Text(
                            (authProvider.currentUser?.displayName ?? 'C')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => UserProfileSheet.show(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.currentUser?.displayName ?? 'Curator',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Dynasty Profile & Scope ⚙️',
                                style: TextStyle(fontSize: 9.5, color: RoyalTheme.brightGold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sign out button
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                        tooltip: 'Sign Out & Lock Archive',
                        onPressed: () {
                          authProvider.logout();
                          treeProvider.clearData();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavLink({
    required String label,
    required String subtitle,
    required IconData icon,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _dashboardIndex == index;

    return InkWell(
      onTap: () => _navigateToDashboardIndex(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? RoyalTheme.primaryGold.withValues(alpha: 0.22)
                  : RoyalTheme.primaryGold.withValues(alpha: 0.18))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: RoyalTheme.brightGold.withValues(alpha: 0.7),
                  width: 1.2,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? RoyalTheme.brightGold.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? RoyalTheme.brightGold
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isSelected
                          ? (isDark ? RoyalTheme.lightGold : const Color(0xFF855B14))
                          : (isDark ? Colors.grey[200] : const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isDark ? RoyalTheme.brightGold.withValues(alpha: 0.9) : const Color(0xFF855B14))
                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: RoyalTheme.brightGold,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: RoyalTheme.brightGold.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. MOBILE APP BAR (For Small Screens)
  // =========================================================================
  PreferredSizeWidget _buildDashboardMobileAppBar(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
    AuthProvider authProvider,
    TreeProvider treeProvider,
  ) {
    final access = Provider.of<AccessibilityProvider>(context);

    return AppBar(
      titleSpacing: 12,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF141722) : const Color(0xFFF9F5EC),
              border: Border.all(color: RoyalTheme.brightGold),
            ),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'KKEVO FAMILY',
              style: GoogleFonts.cinzel(
                color: RoyalTheme.brightGold,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Mon Profil & Portée',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          icon: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RoyalTheme.brightGold.withValues(alpha: 0.16),
              border: Border.all(color: RoyalTheme.brightGold, width: 1.5),
            ),
            child: Center(
              child: Text(
                (authProvider.currentUser?.displayName ?? 'C')[0].toUpperCase(),
                style: const TextStyle(
                  color: RoyalTheme.brightGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            UserProfileSheet.show(context);
          },
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Add Family Member',
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.person_add_alt_1_rounded, color: RoyalTheme.brightGold, size: 20),
          onPressed: () => _showAddPersonDialog(context),
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.vpn_key_outlined, color: RoyalTheme.brightGold, size: 20),
          tooltip: 'Heritage Vault',
          onPressed: () => _navigateToDashboardIndex(4),
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: RoyalTheme.brightGold,
            size: 20,
          ),
          tooltip: isDark ? 'Alabaster Light' : 'Obsidian Dark',
          onPressed: () => themeProvider.toggleTheme(),
        ),
        const SizedBox(width: 2),
        PopupMenuButton<String>(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.more_vert_rounded, color: RoyalTheme.brightGold, size: 20),
          color: isDark ? const Color(0xFF161A26) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: RoyalTheme.borderDark),
          ),
          onSelected: (val) {
            if (val == 'profile') {
              UserProfileSheet.show(context);
            } else if (val == 'vault') {
              _navigateToDashboardIndex(4);
            } else if (val == 'accessibility') {
              access.toggleSeniorMode();
            } else if (val == 'logout') {
              authProvider.logout();
              treeProvider.clearData();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.badge_rounded, color: RoyalTheme.brightGold, size: 18),
                  SizedBox(width: 10),
                  Text('Profil & Portée Dynastique', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'vault',
              child: Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: RoyalTheme.brightGold, size: 18),
                  SizedBox(width: 10),
                  Text('Heritage Vault', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'accessibility',
              child: Row(
                children: [
                  Icon(
                    Icons.format_size_rounded,
                    color: access.isSeniorMode ? RoyalTheme.brightGold : Colors.grey,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    access.isSeniorMode ? 'Disable Large Text' : 'Senior Large Text',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out & Lock Vault',
                    style: TextStyle(fontSize: 13, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
