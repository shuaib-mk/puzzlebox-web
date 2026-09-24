import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/privacy_notice.dart';
import '../core/widgets/puzzle_pal.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Link copied')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
      children: [
        const Center(child: PuzzlePal(size: 120)),
        const SizedBox(height: 12),
        Text(
          'Puzzlebox',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          'Version 2.2.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Made by q04ti',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Puzzlebox is designed and developed by q04ti, an independent developer. Free puzzles, made for everyone who loves to play.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.language_rounded),
          title: const Text('q04ti.dev'),
          subtitle: const Text('Website and projects'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(context, 'https://q04ti.dev'),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Key Contributor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'A massive thank you to Etriq for their brilliant collaboration and continuous support.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.language_rounded),
          title: const Text('Etriq'),
          subtitle: const Text('etriq.online'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(context, 'https://etriq.online'),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_rounded),
          title: const Text('Buy q04ti a coffee'),
          subtitle: const Text('Optional support'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(context, 'https://buymeacoffee.com/q04ti'),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('GitHub'),
          subtitle: const Text('Source, releases and changelog'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(context, 'https://github.com/shuaib-mk/puzzlebox'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy'),
          subtitle: const Text('No ads, analytics or accounts'),
          onTap: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Your data stays yours'),
              content: const SingleChildScrollView(child: Text(privacyNotice)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Open-source licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Puzzlebox',
            applicationVersion: '2.2.0',
            applicationLegalese: 'Puzzlebox © 2026 q04ti.',
          ),
        ),
      ],
    ),
  );
}
