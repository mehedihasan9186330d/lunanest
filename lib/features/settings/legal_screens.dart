import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

import '../../core/env.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.assetPath});
  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return const Center(child: Text('Could not load this document.'));
          return SingleChildScrollView(padding: const EdgeInsets.all(20), child: SelectableText(snap.data ?? ''));
        },
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Icon(Icons.nightlight_round, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text('LunaNest — Sleep & Relax', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const Text('Find Your Calm. Drift Into Sleep.', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Version 0.1.0', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text('LunaNest is a relaxation aid. It is not a medical device and does not diagnose, treat or cure any condition, '
            'including sleep disorders. If you have trouble sleeping, talk to a healthcare professional.'),
      ]),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final email = Env.supportEmail;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact support')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Common questions', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('• Sound stops when the screen locks? Allow notifications and disable battery optimization for LunaNest in system settings.\n'
            '• Premium missing after reinstall? Open Settings → Restore purchases while signed in to the same store account.\n'
            '• Downloads failing? Check your connection and free storage, then tap Retry.'),
        const SizedBox(height: 24),
        if (email.isEmpty)
          const Text('Support email is not configured in this build. (Set SUPPORT_EMAIL at build time.)')
        else
          FilledButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: Text('Email $email'),
            onPressed: () async {
              try {
                await launchUrl(Uri(scheme: 'mailto', path: email, queryParameters: {'subject': 'LunaNest support'}));
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No email app found. Write to $email')));
                }
              }
            },
          ),
      ]),
    );
  }
}
