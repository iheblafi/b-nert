import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/main_page.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/motion.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/language.dart';
import '../../core/l10n/language_picker.dart';
import '../../core/security/biometrics.dart';
import '../app_lock/app_lock.dart';
import '../app_lock/lock_screen.dart';
import '../auth/state/session.dart';
import '../demo/demo_mode.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final signedIn = session is SignedIn ? session : null;
    final access = signedIn?.context.access;
    return MainPage(
      title: l.navMore,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.xl),
        children: [
          if (signedIn != null) _ProfileCard(session: signedIn),
          const SizedBox(height: Gap.l),
          // Approvals (F9) appear only for users who may approve (spec 3).
          if (access?.seesApprovals ?? false) ...[
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: ListTile(
                key: const Key('approvals'),
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(l.approvals),
                subtitle: Text(l.comingSoon),
              ),
            ),
            const SizedBox(height: Gap.l),
          ],
          _SectionTitle(l.settingsSection),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Column(
              children: [
                ListTile(
                  key: const Key('language'),
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(l.language),
                  subtitle: Text(languageName(ref.watch(languageProvider), l)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Haptics.selection();
                    showLanguagePicker(context, ref);
                  },
                ),
                if (ref.watch(biometricsAvailableProvider).value ?? false)
                  SwitchListTile(
                    key: const Key('appLockSwitch'),
                    secondary: Icon(
                      Icons.fingerprint,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l.appLockSetting),
                    subtitle: Text(l.appLockSettingHint),
                    value: ref.watch(appLockProvider).enabled,
                    onChanged: (on) {
                      Haptics.selection();
                      on
                          ? enableAppLock(context, ref)
                          : ref.read(appLockProvider.notifier).disable();
                    },
                  ),
                SwitchListTile(
                  key: const Key('demoSwitch'),
                  secondary: Icon(
                    Icons.science_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l.demoSetting),
                  subtitle: Text(l.demoSettingHint),
                  value: ref.watch(demoModeProvider),
                  onChanged: (on) {
                    Haptics.selection();
                    ref.read(demoModeProvider.notifier).set(on);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.l),
          _SectionTitle(l.accountSection),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: ListTile(
              key: const Key('signOut'),
              leading: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l.signOut,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Haptics.tap();
                ref.read(sessionProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.s, 0, Gap.s, Gap.s),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Initials on the brand gradient, name and e-mail.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.session});

  final SignedIn session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = session.context.firstName?.trim() ?? '';
    final last = session.context.lastName?.trim() ?? '';
    final name = [first, last].where((s) => s.isNotEmpty).join(' ');
    final initials = [
      first,
      last,
    ].where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).join();
    final email = session.user.email;
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brand, AppColors.navy],
              ),
            ),
            child: initials.isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.white)
                : Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(name, style: theme.textTheme.titleMedium),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
