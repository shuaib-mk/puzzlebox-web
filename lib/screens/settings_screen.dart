import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/neo_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/app_feedback_service.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paletteOptions = const [
      ('Mixed Multi-Color', Color(0xFFFACC15), 0),
      ('Sunflower Yellow', Color(0xFFFACC15), 1),
      ('Lime Green', Color(0xFF4ADE80), 2),
      ('Rose Pink', Color(0xFFF43F5E), 3),
      ('Electric Cyan', Color(0xFF38BDF8), 4),
      ('Neon Violet', Color(0xFFC084FC), 5),
      ('Neon Orange', Color(0xFFFB923C), 6),
      ('Minimal Slate', Color(0xFF94A3B8), 7),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.getAccentColor(const Color(0xFFFACC15), state.palette),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                  Text(
                    'Customize Neo theme & preferences',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          const _Label('ACCENT COLOR PALETTE'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: paletteOptions.map((opt) {
              return ChoiceChip(
                avatar: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: opt.$2,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
                label: Text(opt.$1),
                selected: state.palette == opt.$3,
                onSelected: (_) => notifier.setPalette(opt.$3),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          const _Label('APPEARANCE MODE'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: const Text('Light', style: TextStyle(fontWeight: FontWeight.w900)),
                  icon: Icon(Icons.light_mode_outlined, color: isDark ? Colors.white : Colors.black),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: const Text('Dark', style: TextStyle(fontWeight: FontWeight.w900)),
                  icon: Icon(Icons.dark_mode_outlined, color: isDark ? Colors.white : Colors.black),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: const Text('System', style: TextStyle(fontWeight: FontWeight.w900)),
                  icon: Icon(Icons.settings_brightness_outlined, color: isDark ? Colors.white : Colors.black),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (v) => notifier.setThemeMode(v.first),
            ),
          ),
          const SizedBox(height: 28),

          const _Label('GAMEPLAY PREFERENCES'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Default Difficulty',
                    labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black),
                  ),
                  value: state.defaultDifficulty,
                  items: ['Easy', 'Medium', 'Hard']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontWeight: FontWeight.w900))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setDefaultDifficulty(v);
                  },
                ),
                const Divider(color: Colors.black, thickness: 2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.neoPalettes[state.palette.clamp(0, 4)],
                  title: const Text('Haptic Feedback', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  subtitle: const Text('Tactile vibrations on key taps & game wins'),
                  value: state.hapticsEnabled,
                  onChanged: (v) {
                    notifier.setHapticsEnabled(v);
                    if (v) AppFeedbackService.testHaptic();
                  },
                ),
                const Divider(color: Colors.black, thickness: 2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.neoPalettes[state.palette.clamp(0, 4)],
                  title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  subtitle: const Text('Audio feedback during play'),
                  value: state.soundEnabled,
                  onChanged: (v) {
                    notifier.setSoundEnabled(v);
                    if (v) AppFeedbackService.testSound();
                  },
                ),
                const Divider(color: Colors.black, thickness: 2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.neoPalettes[state.palette.clamp(0, 4)],
                  title: const Text('Daily Five Hard Mode', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  subtitle: const Text('Must use revealed hints in subsequent guesses'),
                  value: state.hardModeEnabled,
                  onChanged: notifier.setHardModeEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const _Label('LEGAL & PRIVACY'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              trailing: Icon(Icons.open_in_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
              onTap: () async {
                final uri = Uri.parse('https://puzzlebox.q04ti.dev/#privacy-policy');
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
                  await Clipboard.setData(const ClipboardData(text: 'https://puzzlebox.q04ti.dev/#privacy-policy'));
                  if (context.mounted) {
                    NeoToast.show(
                      context,
                      'Link copied to clipboard',
                      icon: Icons.link_rounded,
                      color: const Color(0xFF38BDF8),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}
