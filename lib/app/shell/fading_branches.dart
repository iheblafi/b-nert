import 'package:material_ui/material_ui.dart';

/// The tab navigators, cross-fading when the tab changes. All stay alive
/// so each tab keeps its scroll position and back stack; hidden ones are
/// offstage once faded, so they cost nothing and are not read out.
class FadingBranches extends StatelessWidget {
  const FadingBranches({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < children.length; i++)
        _Branch(active: i == index, child: children[i]),
    ],
  );
}

class _Branch extends StatefulWidget {
  const _Branch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.active ? 1 : 0,
  )..addStatusListener((_) => setState(() {}));

  @override
  void didUpdateWidget(_Branch old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _fade.forward() : _fade.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !widget.active && _fade.isDismissed,
    child: TickerMode(
      enabled: widget.active,
      child: IgnorePointer(
        ignoring: !widget.active,
        child: ExcludeSemantics(
          excluding: !widget.active,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}
