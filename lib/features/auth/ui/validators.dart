import '../../../core/l10n/l10n.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value, AppLocalizations l) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return l.emailRequired;
  if (!_emailPattern.hasMatch(v)) return l.emailInvalid;
  return null;
}
