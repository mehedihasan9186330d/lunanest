import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.tune, 'Build your own soundscape', 'Layer rain, ocean, wind and more. Each sound has its own volume.'),
    (Icons.bedtime_outlined, 'Drift off, gently', 'A sleep timer fades the sound out slowly, even with the screen locked.'),
    (Icons.download_for_offline_outlined, 'Free to use, Premium to go further', 'Plenty of sounds are free. Premium adds more sounds, mixes and offline downloads.'),
  ];

  void _finish() {
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(s.copyWith(onboardingDone: true));
    context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _finish, child: const Text('Skip'))),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(p.$1, size: 96, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 32),
                    Text(p.$2, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(p.$3, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                child: Text(last ? 'Get started' : 'Next'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
