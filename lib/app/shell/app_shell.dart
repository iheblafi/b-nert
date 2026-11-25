import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/motion.dart';
import '../../core/l10n/l10n.dart';
import '../../features/app_lock/lock_screen.dart';

/// Bottom bar with four destinations and a central "+" (spec section 5).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StatefulNavigationShell get shell => widget.shell;

  @override
  void initState() {
    super.initState();
    // First screen after a password sign-in: offer biometric unlock.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => maybeOfferAppLock(context, ref),
    );
  }

  void _go(int i) {
    if (i != shell.currentIndex) Haptics.selection();
    shell.goBranch(i, initialLocation: shell.currentIndex == i);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final items = [
      (Icons.schedule_outlined, Icons.schedule_rounded, l.navTimes),
      (Icons.history_outlined, Icons.history_rounded, l.navHistory),
      (Icons.beach_access_outlined, Icons.beach_access_rounded, l.navAbsence),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l.navMore),
    ];
    Widget item(int i) => Expanded(
      child: _NavItem(
        icon: items[i].$1,
        selectedIcon: items[i].$2,
        label: items[i].$3,
        selected: shell.currentIndex == i,
        onTap: () => _go(i),
      ),
    );
    return Scaffold(
      body: shell,
      floatingActionButton: _NewEntryButton(
        tooltip: l.newEntry,
        onPressed: () {
          Haptics.tap();
          context.push('/entry/new');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x120B2545),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
          height: 72,
          child: Row(
            children: [
              item(0),
              item(1),
              const SizedBox(width: 76),
              item(2),
              item(3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raised gradient button with a soft brand-coloured glow.
class _NewEntryButton extends StatelessWidget {
  const _NewEntryButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PressScale(
    child: Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Container(
          key: const Key('newEntry'),
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand, AppColors.navy],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    const curve = Curves.easeOutCubic;
    const duration = Duration(milliseconds: 260);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The pill grows in behind the active icon.
              AnimatedContainer(
                duration: duration,
                curve: curve,
                width: selected ? 56 : 32,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: AnimatedSwitcher(
                  duration: duration,
                  child: Icon(
                    selected ? selectedIcon : icon,
                    key: ValueKey(selected),
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                // Long labels (Abwesenheit) shrink instead of being cut.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
