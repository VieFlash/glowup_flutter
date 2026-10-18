import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/budget_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/hair_page.dart';
import 'pages/nutrition_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/reports_page.dart';
import 'pages/schedule_page.dart';
import 'pages/settings_page.dart';
import 'pages/skin_page.dart';
import 'pages/sleep_page.dart';
import 'pages/workout_page.dart';
import 'state/app_state.dart';

const seedColor = Color(0xFF4A8665);

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: b);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
  return base.copyWith(
    scaffoldBackgroundColor: b == Brightness.light ? const Color(0xFFF7F7F5) : const Color(0xFF121110),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    visualDensity: VisualDensity.standard,
  );
}

/// Điều hướng toàn cục giữa các mục (dùng từ Dashboard và trang "Thêm").
final ValueNotifier<int> appNav = ValueNotifier<int>(0);

class NavDest {
  final String label;
  final String short;
  final IconData icon;
  final IconData selectedIcon;
  const NavDest(this.label, this.short, this.icon, this.selectedIcon);
}

const destinations = <NavDest>[
  NavDest('Tổng quan', 'Hôm nay', Icons.today_outlined, Icons.today),
  NavDest('Lịch trình', 'Lịch', Icons.view_agenda_outlined, Icons.view_agenda),
  NavDest('Tập luyện', 'Tập', Icons.fitness_center_outlined, Icons.fitness_center),
  NavDest('Dinh dưỡng', 'Ăn uống', Icons.restaurant_outlined, Icons.restaurant),
  NavDest('Giấc ngủ', 'Ngủ', Icons.bedtime_outlined, Icons.bedtime),
  NavDest('Chăm sóc da', 'Da', Icons.face_outlined, Icons.face),
  NavDest('Chăm sóc tóc', 'Tóc', Icons.content_cut_outlined, Icons.content_cut),
  NavDest('Báo cáo', 'Báo cáo', Icons.insights_outlined, Icons.insights),
  NavDest('Ngân sách', 'Ngân sách', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
  NavDest('Cài đặt', 'Cài đặt', Icons.settings_outlined, Icons.settings),
];

/// Chỉ số đặc biệt cho trang "Thêm" trên điện thoại
const int moreIndex = 100;

class GlowUpApp extends StatefulWidget {
  final AppState state;
  const GlowUpApp({super.key, required this.state});

  @override
  State<GlowUpApp> createState() => _GlowUpAppState();
}

class _GlowUpAppState extends State<GlowUpApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive || s == AppLifecycleState.detached) {
      widget.state.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => MaterialApp(
          title: 'Glow-up',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: widget.state.themeMode,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: widget.state.needsOnboarding ? const OnboardingPage() : const HomeShell(),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    appNav.addListener(_onNav);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = AppScope.read(context);
      if (st.loadError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(st.loadError!)));
        st.loadError = null;
      }
      st.messages.addListener(_onMessage);
    });
  }

  void _onNav() => setState(() {});

  void _onMessage() {
    final m = AppScope.read(context).messages.value;
    if (m != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  void dispose() {
    appNav.removeListener(_onNav);
    super.dispose();
  }

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardPage();
      case 1:
        return const SchedulePage();
      case 2:
        return const WorkoutPage();
      case 3:
        return const NutritionPage();
      case 4:
        return const SleepPage();
      case 5:
        return const SkinPage();
      case 6:
        return const HairPage();
      case 7:
        return const ReportsPage();
      case 8:
        return const BudgetPage();
      case 9:
        return const SettingsPage();
      default:
        return const MorePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 840;
    var index = appNav.value;
    if (wide && index == moreIndex) index = 0;

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                extended: MediaQuery.of(context).size.width >= 1100,
                selectedIndex: index,
                onDestinationSelected: (i) => appNav.value = i,
                labelType: MediaQuery.of(context).size.width >= 1100 ? null : NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: _Logo(),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: KeyedSubtree(key: ValueKey(index), child: _page(index))),
            ],
          ),
        ),
      );
    }

    final bottomSel = index < 4 ? index : 4;
    final showBack = index >= 4 && index <= 9;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: TextButton.icon(
                    onPressed: () => appNav.value = moreIndex,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Mục khác'),
                  ),
                ),
              ),
            Expanded(child: KeyedSubtree(key: ValueKey(index), child: _page(index))),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomSel,
        onDestinationSelected: (i) => appNav.value = i == 4 ? moreIndex : i,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (var i = 0; i < 4; i++)
            NavigationDestination(
              icon: Icon(destinations[i].icon),
              selectedIcon: Icon(destinations[i].selectedIcon),
              label: destinations[i].short,
            ),
          const NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Thêm'),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.spa, color: cs.onPrimary),
    );
  }
}

/// Trang "Thêm" trên điện thoại: lối vào các mục còn lại.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mục khác', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (var i = 4; i < destinations.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => appNav.value = i,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(destinations[i].selectedIcon, color: cs.primary),
                      Text(destinations[i].label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
