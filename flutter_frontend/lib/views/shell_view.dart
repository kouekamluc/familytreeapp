import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../config/royal_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import '../services/api_service.dart';
import '../widgets/person_editor_dialog.dart';
import '../widgets/tree_manager_sheet.dart';
import '../widgets/user_profile_sheet.dart';
import '../widgets/kkevo_ui.dart';
import '../widgets/kkevo_brand.dart';
import '../widgets/kkevo_symbols.dart';
import '../widgets/language_sheet.dart';
import 'auth/login_view.dart';
import 'auth/account_settings_view.dart';
import 'family_connections_view.dart';
import 'report_issue_view.dart';
import 'home_view.dart';
import 'mobile/mobile_welcome_view.dart';
import 'people/person_detail_view.dart';
import 'people/people_list_view.dart';
import 'relationships/relationship_list_view.dart';
import 'kinship/kinship_calculator_view.dart';
import 'tree/tree_view.dart';
import 'vault/heritage_vault_view.dart';

class ShellView extends StatefulWidget {
  const ShellView({super.key});
  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _tabMotion;
  @override
  void initState() {
    super.initState();
    _tabMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
  }

  void _refreshStatus() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final api = context.read<ApiService>();
    if (api.isAuthenticated && !api.isPreviewMode) api.getFamilyAccess();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
      final tree = context.read<TreeProvider>();
      if (ModalRoute.of(context)?.isCurrent != false &&
          !tree.isLoading &&
          context.read<ApiService>().isAuthenticated) {
        tree.loadData();
      }
    }
  }

  @override
  void dispose() {
    _tabMotion.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int _index = 0;
  static const _labels = ['Home', 'Tree', 'People', 'Links', 'You'];
  static const _icons = [
    Icons.home_rounded,
    Icons.account_tree_rounded,
    Icons.people_alt_rounded,
    Icons.hub_rounded,
    Icons.person_rounded,
  ];
  static const _symbols = [
    FamilySymbol.home,
    FamilySymbol.tree,
    FamilySymbol.people,
    FamilySymbol.links,
    FamilySymbol.profile,
  ];
  void _go(int index) {
    if (index == _index) return;
    if (index == 0 || index == 4) _refreshStatus();
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    if (!MediaQuery.disableAnimationsOf(context)) _tabMotion.forward(from: 0);
  }

  void _profile(Person person) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PersonDetailView(
        person: person,
        onNavigateToPerson: _profile,
        onJumpToTree: _tree,
        onOpenKinship: _kinship,
      ),
    ),
  );
  void _tree(Person person) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    context.read<TreeProvider>().selectPerson(person);
    _go(1);
  }

  void _kinship(Person person) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const AppText('Understand our connections')),
        body: KinshipCalculatorView(initialPersonA: person),
      ),
    ),
  );
  Future<void> _login({bool register = false}) async {
    final auth = context.read<AuthProvider>();
    final tree = context.read<TreeProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const AppText('Kkevo Family')),
          body: LoginView(
            initialRegister: register,
            onLoginSuccess: () {
              Navigator.pop(ctx);
              tree.loadData(
                targetTreeId: auth.invitedTreeId,
                targetPersonId: auth.invitedPersonId,
              );
            },
          ),
        ),
      ),
    );
    if (mounted) _go(0);
  }

  Future<void> _explore() async {
    final auth = context.read<AuthProvider>();
    final tree = context.read<TreeProvider>();
    await auth.demoLogin();
    await tree.loadData();
    if (mounted) _go(0);
  }

  void _vault() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const AppText('Personal keys')),
        body: const HeritageVaultView(),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tree = context.watch<TreeProvider>();
    if (!auth.isAuthenticated) {
      return MobileWelcomeView(
        onExplore: _explore,
        onSignIn: () => _login(),
        onStart: () => _login(register: true),
      );
    }
    final pages = <Widget>[
      HomeView(
        key: ValueKey('home:${tree.contextKey}'),
        onNavigate: _go,
        onOpenPerson: _profile,
      ),
      TreeView(
        key: ValueKey('tree:${tree.contextKey}'),
        onOpenPersonDetail: _profile,
        onOpenKinshipForPerson: _kinship,
      ),
      PeopleListView(
        key: ValueKey('people:${tree.contextKey}'),
        onOpenPersonDetail: _profile,
        onJumpToTree: _tree,
        onSelectPersonForKinship: _kinship,
      ),
      RelationshipListView(
        key: ValueKey('links:${tree.contextKey}'),
        onNavigateToPerson: _profile,
        onJumpToTree: _tree,
      ),
      _account(auth, tree),
    ];
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final wide =
            constraints.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(ctx).scale(1) < 1.7;
        final content = Column(
          children: [
            if (auth.isPreviewMode)
              Material(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: AppText('Example family · fictional records'),
                      ),
                      TextButton(
                        onPressed: () => _login(register: true),
                        child: const AppText('Create my account'),
                      ),
                    ],
                  ),
                ),
              ),
            if (tree.errorMessage != null)
              Material(
                color: Theme.of(ctx).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          tree.isOfflineMode
                              ? 'Offline · your saved copy is available to view.'
                              : 'Unable to load this family.',
                        ),
                      ),
                      TextButton(
                        onPressed: tree.isLoading
                            ? null
                            : () => tree.loadData(),
                        child: const AppText('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: AnimatedBuilder(
                animation: _tabMotion,
                builder: (_, child) => Opacity(
                  opacity: .6 + .4 * _tabMotion.value,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - _tabMotion.value)),
                    child: child,
                  ),
                ),
                child: IndexedStack(index: _index, children: pages),
              ),
            ),
          ],
        );
        return PopScope(
          canPop: _index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _go(0);
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 64,
              titleSpacing: 16,
              title: Row(
                children: [
                  const KkevoMark(size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'kkevo family',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        Text(
                          tree.selectedTree?.name ?? 'Your story starts here',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: context.tr('Choose my family'),
                  onPressed: () => TreeManagerSheet.show(ctx),
                  icon: const Icon(Icons.unfold_more_rounded),
                ),
                IconButton(
                  tooltip: context.tr('My account'),
                  onPressed: () => _go(4),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        extended: true,
                        minExtendedWidth: 190,
                        onDestinationSelected: _go,
                        destinations: [
                          for (var i = 0; i < _labels.length; i++)
                            NavigationRailDestination(
                              icon: Icon(_icons[i]),
                              label: AppText(_labels[i]),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
            bottomNavigationBar: wide
                ? null
                : DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(ctx).colorScheme.outline,
                          width: 2,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      indicatorColor: Colors.transparent,
                      selectedIndex: _index,
                      onDestinationSelected: _go,
                      labelBehavior: MediaQuery.textScalerOf(ctx).scale(1) > 1.4
                          ? NavigationDestinationLabelBehavior.onlyShowSelected
                          : NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: [
                        for (var i = 0; i < _labels.length; i++)
                          NavigationDestination(
                            icon: KkevoSymbol(_symbols[i], muted: true),
                            selectedIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.primaryContainer,
                                border: Border.all(
                                  color: RoyalTheme.greenDepth,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: KkevoSymbol(_symbols[i]),
                            ),
                            label: context.tr(_labels[i]),
                          ),
                      ],
                    ),
                  ),
            floatingActionButton:
                (_index == 1 || _index == 2) && tree.canEditSelectedTree
                ? FloatingActionButton(
                    tooltip: context.tr('Add a person'),
                    onPressed: () => PersonEditorDialog.show(ctx),
                    child: const Icon(Icons.person_add_alt_1_rounded),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _account(AuthProvider auth, TreeProvider tree) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'Your place in the family',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              KkevoPanel(
                child: Row(
                  children: [
                    const KkevoIcon(Icons.person_rounded, size: 64),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.isPreviewMode
                                ? context.tr('Explore mode')
                                : auth.currentUser?.displayName ??
                                      context.tr('My account'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (!auth.isPreviewMode)
                            AppText('@${auth.currentUser?.username ?? ''}'),
                          AppText(
                            tree.canManageSelectedTree
                                ? 'Family owner'
                                : tree.canEditSelectedTree
                                ? 'Can contribute to this family'
                                : 'Viewing access',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (!auth.isPreviewMode) ...[
                _row(
                  Icons.flag_outlined,
                  'My reports',
                  'Follow concerns about shared family content',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportIssueView()),
                  ),
                ),
                _row(
                  Icons.diversity_1_rounded,
                  'Join a family',
                  context.watch<ApiService>().pendingFamilyRequests > 0
                      ? '${context.watch<ApiService>().pendingFamilyRequests} requests awaiting confirmation'
                      : 'With an invitation or your ancestors',
                  () => FamilyConnectionsView.show(context),
                ),
                if (tree.canManageSelectedTree)
                  _row(
                    Icons.verified_user_rounded,
                    'Invitations and access',
                    context.watch<ApiService>().pendingFamilyReviews > 0
                        ? '${context.watch<ApiService>().pendingFamilyReviews} family requests to review'
                        : 'Review requests and manage access',
                    () => FamilyConnectionsView.show(
                      context,
                      treeId: tree.selectedTree!.id,
                    ),
                  ),
                _row(
                  Icons.manage_accounts_outlined,
                  'Account and security',
                  'Email, password and deletion requests',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsView(),
                    ),
                  ),
                ),
                _row(
                  Icons.key_rounded,
                  'My personal keys',
                  'Sign in to your own account',
                  _vault,
                ),
              ],
              _row(
                Icons.account_tree_outlined,
                'My families',
                'Switch, import or export a tree',
                () => TreeManagerSheet.show(context),
              ),
              _row(
                Icons.language_rounded,
                'Language',
                'English · Français · Use phone language',
                () => LanguageSheet.show(context),
              ),
              _row(
                Icons.tune_rounded,
                'Preferences and accounts',
                'Language, appearance and active account',
                () => UserProfileSheet.show(
                  context,
                  onOpenTree: () => _go(1),
                  onOpenVault: _vault,
                  onSignOut: () async {
                    await auth.logout();
                    if (mounted) _go(0);
                  },
                ),
              ),
              const SizedBox(height: 20),
              KkevoButton(
                label: auth.isPreviewMode ? 'Create my account' : 'Sign out',
                secondary: true,
                onPressed: auth.isPreviewMode
                    ? () => _login(register: true)
                    : () async {
                        await auth.logout();
                        if (mounted) _go(0);
                      },
              ),
              const SizedBox(height: 20),
              const AppText(
                'Your family confirms your connections. Add to your story at your own pace.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget _row(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: KkevoPanel(
      padding: const EdgeInsets.all(6),
      child: ListTile(
        leading: KkevoIcon(icon, size: 44),
        title: AppText(title),
        subtitle: AppText(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: action,
      ),
    ),
  );
}
