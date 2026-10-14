import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/explore/category_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/mixer/mixer_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/player/player_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/settings/legal_screens.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Fade + gentle rise for full-screen routes (player, premium). Instant when the
/// system asks to reduce motion.
CustomTransitionPage<void> _riseIn(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondary, child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );

GoRouter buildRouter() => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:id',
                    builder: (context, state) => CategoryScreen(categoryId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/mixer', builder: (context, state) => const MixerScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                      path: 'privacy',
                      builder: (context, state) =>
                          const LegalScreen(title: 'Privacy Policy', assetPath: 'assets/legal/privacy.txt')),
                  GoRoute(
                      path: 'terms',
                      builder: (context, state) =>
                          const LegalScreen(title: 'Terms of Use', assetPath: 'assets/legal/terms.txt')),
                  GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
                  GoRoute(path: 'support', builder: (context, state) => const SupportScreen()),
                ],
              ),
            ]),
          ],
        ),
        GoRoute(
          path: '/player',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => _riseIn(state, const PlayerScreen()),
        ),
        GoRoute(
          path: '/premium',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => _riseIn(state, const PremiumScreen()),
        ),
      ],
    );
