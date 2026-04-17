import 'package:flutter/material.dart';

Color _badgeBackground(BuildContext context, String value) {
  final normalized = value.trim().toLowerCase();
  final scheme = Theme.of(context).colorScheme;

  switch (normalized) {
    case 'rapproche':
    case 'rapproché':
    case 'regle':
    case 'réglé':
    case 'paye':
    case 'payé':
      return scheme.primaryContainer;
    case 'partiel':
    case 'en_attente':
    case 'en attente':
      return scheme.tertiaryContainer;
    case 'non_rapproche':
    case 'non rapproché':
    case 'impaye':
    case 'impayé':
      return scheme.errorContainer;
    default:
      return scheme.surfaceContainerHighest;
  }
}

Color _badgeForeground(BuildContext context, String value) {
  final normalized = value.trim().toLowerCase();
  final scheme = Theme.of(context).colorScheme;

  switch (normalized) {
    case 'rapproche':
    case 'rapproché':
    case 'regle':
    case 'réglé':
    case 'paye':
    case 'payé':
      return scheme.onPrimaryContainer;
    case 'partiel':
    case 'en_attente':
    case 'en attente':
      return scheme.onTertiaryContainer;
    case 'non_rapproche':
    case 'non rapproché':
    case 'impaye':
    case 'impayé':
      return scheme.onErrorContainer;
    default:
      return scheme.onSurfaceVariant;
  }
}

String _fallbackLabel(String? raw, String fallback) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return fallback;
  return value;
}

class FinanceLotStatusBadge extends StatelessWidget {
  const FinanceLotStatusBadge({
    super.key,
    required this.value,
    required this.fallback,
  });

  final String? value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final label = _fallbackLabel(value, fallback);
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: _badgeBackground(context, label),
      labelStyle: TextStyle(
        color: _badgeForeground(context, label),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class StatutRapprochementBadge extends StatelessWidget {
  const StatutRapprochementBadge({super.key, required this.statut});

  final String? statut;

  @override
  Widget build(BuildContext context) {
    return FinanceLotStatusBadge(value: statut, fallback: 'Non renseigné');
  }
}

class StatutPaiementBadge extends StatelessWidget {
  const StatutPaiementBadge({super.key, required this.statut});

  final String? statut;

  @override
  Widget build(BuildContext context) {
    return FinanceLotStatusBadge(value: statut, fallback: 'Non renseigné');
  }
}
