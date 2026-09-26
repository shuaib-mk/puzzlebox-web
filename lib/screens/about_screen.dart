import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/privacy_notice.dart';
import '../core/widgets/puzzle_pal.dart';
import '../core/widgets/neo_toast.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        NeoToast.show(
          context,
          'Link copied to clipboard',
          icon: Icons.link_rounded,
          color: const Color(0xFF38BDF8),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final primaryAccent = AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                ],
              ),
              child: PuzzlePal(size: 96),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Puzzlebox',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Version 3.0.0 • Build 10',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          // Card 1: Created by q04ti Card (with q04ti.dev & Buy Coffee nested)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Created by q04ti',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Puzzlebox is an open puzzle suite designed and crafted by q04ti. Free logic and word games for puzzle lovers everywhere.',
                        style: TextStyle(height: 1.5, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.black, thickness: 2, height: 1),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.getAccentColor(const Color(0xFF38BDF8), settings.palette),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.language_rounded, color: Colors.black, size: 18),
                    ),
                    title: const Text('q04ti.dev', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: const Text('Developer website & projects', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.open_in_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
                    onTap: () => _open(context, 'https://q04ti.dev'),
                  ),
                ),
                const Divider(color: Colors.black, thickness: 2, height: 1),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.getAccentColor(const Color(0xFFF43F5E), settings.palette),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                    ),
                    title: const Text('Buy q04ti a coffee', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: const Text('Support independent development', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.open_in_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
                    onTap: () => _open(context, 'https://buymeacoffee.com/q04ti'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Card 2: Key Contributor Card (with Etriq link nested)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Key Contributor',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Special thanks to Etriq for brilliant design collaboration, testing, and ongoing support.',
                        style: TextStyle(height: 1.5, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.black, thickness: 2, height: 1),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.language_rounded, color: Colors.black, size: 18),
                    ),
                    title: const Text('Etriq', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: const Text('etriq.online', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.open_in_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
                    onTap: () => _open(context, 'https://etriq.online'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Card 3: Remaining Links Container
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.code_rounded, color: isDark ? Colors.white : Colors.black),
                    title: const Text('GitHub Repository', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: const Text('Source code & releases', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.open_in_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black),
                    onTap: () => _open(context, 'https://github.com/shuaib-mk/puzzlebox'),
                  ),
                  const Divider(color: Colors.black, thickness: 2, height: 1),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: isDark ? Colors.white : Colors.black),
                    title: const Text('Privacy & Data', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: const Text('No tracking, ads, or account requirements', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.black, width: 2.5),
                        ),
                        title: Text('Your Data Stays Yours', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                        content: const SingleChildScrollView(child: Text(privacyNotice, style: TextStyle(fontWeight: FontWeight.w600))),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Colors.black, thickness: 2, height: 1),
                  ListTile(
                    leading: Icon(Icons.policy_outlined, color: isDark ? Colors.white : Colors.black),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: const Text('Official hosted privacy policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.open_in_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black),
                    onTap: () => _open(context, 'https://puzzlebox.q04ti.dev/#privacy-policy'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
