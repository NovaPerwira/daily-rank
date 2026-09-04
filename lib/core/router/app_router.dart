import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/pages/splash_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/categories/financial/pages/financial_page.dart';
import '../../features/categories/career/pages/career_page.dart';
import '../../features/categories/habit/pages/habit_page.dart';
import '../../features/categories/knowledge/pages/knowledge_page.dart';
import '../../features/categories/health/pages/health_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/cashflow/pages/cashflow_page.dart';
import '../../features/cashflow/pages/add_transaction_page.dart';
import '../../features/cashflow/pages/scan_receipt_page.dart';
import '../../features/quests/pages/quests_page.dart';
import '../../features/stats/pages/stats_page.dart';
import '../constants/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (ctx, state) {
      final auth = ctx.read<AuthProvider>();
      final isAuth = auth.isAuthenticated;
      final location = state.matchedLocation;

      final publicRoutes = ['/splash', '/login', '/register'];
      if (!isAuth && !publicRoutes.contains(location)) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, state) => const RegisterPage(),
      ),
      // Shell route with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) => AppShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/quests',
            builder: (ctx, state) => const QuestsPage(),
          ),
          GoRoute(
            path: '/stats',
            builder: (ctx, state) => const StatsPage(),
          ),
          GoRoute(
            path: '/financial',
            builder: (ctx, state) => const FinancialPage(),
          ),
          GoRoute(
            path: '/career',
            builder: (ctx, state) => const CareerPage(),
          ),
          GoRoute(
            path: '/habit',
            builder: (ctx, state) => const HabitPage(),
          ),
          GoRoute(
            path: '/knowledge',
            builder: (ctx, state) => const KnowledgePage(),
          ),
          GoRoute(
            path: '/health',
            builder: (ctx, state) => const HealthPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (ctx, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/cashflow',
            builder: (ctx, state) => const CashflowPage(),
          ),
          GoRoute(
            path: '/add-transaction',
            builder: (ctx, state) => const AddTransactionPage(),
          ),
          GoRoute(
            path: '/scan-receipt',
            builder: (ctx, state) => const ScanReceiptPage(),
          ),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AppShell({super.key, required this.child, required this.state});

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/quests')) return 1;
    // index 2 = center "+" button, not a tab
    if (location.startsWith('/stats') ||
        location.startsWith('/financial') ||
        location.startsWith('/career') ||
        location.startsWith('/habit') ||
        location.startsWith('/knowledge') ||
        location.startsWith('/health')) {
      return 3;
    }
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = state.matchedLocation;
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: selectedIndex == 0,
                  onTap: () => context.go('/dashboard'),
                ),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Quests',
                  isActive: selectedIndex == 1,
                  onTap: () => context.go('/quests'),
                ),
                // ── Center FAB-style button ──────────────────────────
                GestureDetector(
                  onTap: () => _showAddMenu(context),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.financial],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights,
                  label: 'Stats',
                  isActive: selectedIndex == 3,
                  onTap: () => context.go('/stats'),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: selectedIndex == 4,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TAMBAH TRANSAKSI',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              // ── Scan Nota ──────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/scan-receipt');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.financial.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Nota',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Foto struk → item langsung terdeteksi otomatis',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Input Manual ────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/add-transaction');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Input Manual',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Isi nominal, kategori & catatan sendiri',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
