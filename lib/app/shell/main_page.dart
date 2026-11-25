import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/motion.dart';
import '../../core/l10n/l10n.dart';
import '../../features/demo/demo_mode.dart';
import '../../features/demo/demo_ui.dart';

/// Frame of every main screen: title and the bell (spec section 5, F10).
class MainPage extends StatelessWidget {
  const MainPage({
    required this.title,
    required this.body,
    this.demo = false,
    super.key,
  });

  final String title;
  final Widget body;

  /// Shows the "Beispieldaten" badge next to the title.
  final bool demo;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          if (demo) ...[const SizedBox(width: Gap.s), const DemoBadge()],
        ],
      ),
      actions: const [
        BellButton(),
        SizedBox(width: Gap.s),
      ],
    ),
    body: body,
  );
}

/// The bell in a soft round button, with the unread count.
class BellButton extends ConsumerWidget {
  const BellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final unread = ref.watch(demoDataProvider)?.unreadCount ?? 0;
    return IconButton(
      key: const Key('bell'),
      tooltip: context.l10n.notifications,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
      onPressed: () {
        Haptics.selection();
        context.push('/notifications');
      },
    );
  }
}

/// Friendly empty state: a small illustration, a title and one sentence.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Illustration(icon: icon),
            const SizedBox(height: Gap.l),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.s),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: 168,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardTheme.color,
              boxShadow: softShadow(theme.brightness),
            ),
            child: Icon(icon, size: 40, color: scheme.primary),
          ),
          const Positioned(top: 14, right: 22, child: _Dot(size: 12)),
          Positioned(
            bottom: 18,
            left: 16,
            child: _Dot(size: 8, color: scheme.primary.withValues(alpha: 0.35)),
          ),
          const Positioned(top: 34, left: 8, child: _Dot(size: 6)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, this.color = AppColors.mint});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

/// Screens outside the bar that are not built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.empty,
    super.key,
  });

  final String title;
  final EmptyState empty;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: empty,
  );
}
