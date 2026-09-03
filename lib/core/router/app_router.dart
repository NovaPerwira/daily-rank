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
                // ── Center FAB-style "+" button ──────────────────────
                GestureDetector(
                  onTap: () => context.push('/add-transaction'),
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

  void _showCategoryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CATEGORIES',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _CategoryMenuItem(emoji: '💰', title: 'Financial', color: AppColors.financial, onTap: () { Navigator.pop(ctx); context.go('/financial'); }),
              _CategoryMenuItem(emoji: '💼', title: 'Career', color: AppColors.career, onTap: () { Navigator.pop(ctx); context.go('/career'); }),
              _CategoryMenuItem(emoji: '🔥', title: 'Habit', color: AppColors.habit, onTap: () { Navigator.pop(ctx); context.go('/habit'); }),
              _CategoryMenuItem(emoji: '📚', title: 'Knowledge', color: AppColors.knowledge, onTap: () { Navigator.pop(ctx); context.go('/knowledge'); }),
              _CategoryMenuItem(emoji: '💪', title: 'Health', color: AppColors.health, onTap: () { Navigator.pop(ctx); context.go('/health'); }),
              const SizedBox(height: 8),
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

class _CategoryMenuItem extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _CategoryMenuItem({
    required this.emoji,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
