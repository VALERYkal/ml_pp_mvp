import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../features/profil/providers/profil_provider.dart';
import '../../../shared/utils/date_formatter.dart';
import '../domain/integrity_check.dart';
import '../providers/integrity_providers.dart';

enum _SeverityFilter { all, critical, warn }

/// Écran Integrity Checks (Phase 2)
/// Source: public.system_alerts. Workflow ACK/RESOLVE pour admin/directeur.
class IntegrityChecksScreen extends ConsumerStatefulWidget {
  const IntegrityChecksScreen({super.key});

  @override
  ConsumerState<IntegrityChecksScreen> createState() =>
      _IntegrityChecksScreenState();
}

class _IntegrityChecksScreenState extends ConsumerState<IntegrityChecksScreen> {
  _SeverityFilter _severityFilter = _SeverityFilter.all;
  String? _loadingAlertId;

  String? get _severityFilterToNullableString {
    return switch (_severityFilter) {
      _SeverityFilter.all => null,
      _SeverityFilter.critical => 'CRITICAL',
      _SeverityFilter.warn => 'WARN',
    };
  }

  static _SeverityFilter _severityFilterFromString(String? s) {
    return switch (s) {
      'CRITICAL' => _SeverityFilter.critical,
      'WARN' => _SeverityFilter.warn,
      _ => _SeverityFilter.all,
    };
  }

  /// Filtre entity_type: null = ALL, sinon valeur distincte
  String? _entityTypeFilter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(integrityAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrity Checks'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(integrityAlertsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  err.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(integrityAlertsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (list) => _buildBody(context, list),
      ),
    );
  }

  void _onDataLoaded(List<IntegrityCheck> list) {
    if (!mounted) return;
    if (_entityTypeFilter != null &&
        !list.any((c) => c.entityType == _entityTypeFilter)) {
      setState(() => _entityTypeFilter = null);
    }
  }

  List<IntegrityCheck> _applyFilters(List<IntegrityCheck> list) {
    var filtered = list;
    switch (_severityFilter) {
      case _SeverityFilter.all:
        break;
      case _SeverityFilter.critical:
        filtered = filtered.where((c) => c.isCritical).toList();
        break;
      case _SeverityFilter.warn:
        filtered = filtered.where((c) => c.isWarn).toList();
        break;
    }
    if (_entityTypeFilter != null) {
      filtered =
          filtered.where((c) => c.entityType == _entityTypeFilter).toList();
    }
    return filtered;
  }

  List<String> _distinctEntityTypes(List<IntegrityCheck> list) {
    final types = <String>{};
    for (final c in list) {
      if (c.entityType.isNotEmpty) types.add(c.entityType);
    }
    return types.toList()..sort();
  }

  Widget _buildBody(BuildContext context, List<IntegrityCheck> list) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDataLoaded(list));

    final filtered = _applyFilters(list);
    final entityTypes = _distinctEntityTypes(list);

    final totalFiltered = filtered.length;
    final criticalFiltered =
        filtered.where((c) => c.isCritical).length;
    final warnFiltered = filtered.where((c) => c.isWarn).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compteurs (filtrés) + "sur X checks chargés"
          Row(
            children: [
              _CountChip(label: 'TOTAL', count: totalFiltered),
              const SizedBox(width: 8),
              _CountChip(
                label: 'CRITICAL',
                count: criticalFiltered,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              _CountChip(
                label: 'WARN',
                count: warnFiltered,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'sur ${list.length} checks chargés',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 16),

          // Filtre severity
          Text(
            'Sévérité',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment(
                value: null,
                label: Text('ALL'),
                icon: Icon(Icons.filter_list),
              ),
              ButtonSegment(
                value: 'CRITICAL',
                label: Text('CRITICAL'),
                icon: Icon(Icons.error),
              ),
              ButtonSegment(
                value: 'WARN',
                label: Text('WARN'),
                icon: Icon(Icons.warning),
              ),
            ],
            selected: {_severityFilterToNullableString},
            onSelectionChanged: (Set<String?> selected) {
              setState(() => _severityFilter = _severityFilterFromString(selected.single));
            },
          ),
          const SizedBox(height: 16),

          // Filtre entity_type
          Text(
            'Type d\'entité',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          DropdownButton<String?>(
            value: _entityTypeFilter,
            isExpanded: true,
            hint: const Text('ALL'),
            items: [
              const DropdownMenuItem(value: null, child: Text('ALL')),
              ...entityTypes.map(
                (t) => DropdownMenuItem(value: t, child: Text(t)),
              ),
            ],
            onChanged: (v) => setState(() => _entityTypeFilter = v),
          ),
          const SizedBox(height: 16),

          // Liste
          if (filtered.isEmpty)
            Text(
              'Aucun check détecté.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.9),
                  ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final check = filtered[index];
                final role = ref.watch(userRoleProvider);
                final canMutate = role == UserRole.admin ||
                    role == UserRole.directeur;
                return _IntegrityCheckTile(
                  check: check,
                  onTap: () => _showDetailDialog(context, check),
                  onAck: canMutate ? () => _onAck(context, check) : null,
                  onResolve: canMutate ? () => _onResolve(context, check) : null,
                  isLoading: _loadingAlertId == check.id,
                );
              },
            ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, IntegrityCheck check) {
    showDialog(
      context: context,
      builder: (ctx) => _IntegrityDetailDialog(check: check),
    );
  }

  Future<void> _onAck(BuildContext context, IntegrityCheck check) async {
    if (_loadingAlertId != null) return;
    setState(() => _loadingAlertId = check.id);
    try {
      await ref.read(integrityRepositoryProvider).ackAlert(check.id);
      if (!context.mounted) return;
      ref.invalidate(integrityAlertsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerte acquittée')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingAlertId = null);
    }
  }

  Future<void> _onResolve(BuildContext context, IntegrityCheck check) async {
    if (_loadingAlertId != null) return;
    setState(() => _loadingAlertId = check.id);
    try {
      await ref.read(integrityRepositoryProvider).resolveAlert(check.id);
      if (!context.mounted) return;
      ref.invalidate(integrityAlertsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerte résolue')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingAlertId = null);
    }
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;

  const _CountChip({
    required this.label,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: c.withValues(alpha: 0.2),
        child: Text(
          count.toString(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: c,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      label: Text(label),
      side: BorderSide(color: c.withValues(alpha: 0.6)),
    );
  }
}

class _IntegrityCheckTile extends StatelessWidget {
  final IntegrityCheck check;
  final VoidCallback onTap;
  final VoidCallback? onAck;
  final VoidCallback? onResolve;
  final bool isLoading;

  const _IntegrityCheckTile({
    required this.check,
    required this.onTap,
    this.onAck,
    this.onResolve,
    this.isLoading = false,
  });

  Color _severityColor(BuildContext context) {
    if (check.isCritical) {
      return Theme.of(context).colorScheme.error;
    }
    if (check.isWarn) {
      return Theme.of(context).colorScheme.tertiary;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  IconData _severityIcon() {
    if (check.isCritical) return Icons.error;
    if (check.isWarn) return Icons.warning;
    return Icons.info_outline;
  }

  Widget? _buildTrailing(BuildContext context) {
    final actions = <Widget>[];
    if (onAck != null && check.canAck) {
      actions.add(
        FilledButton.tonal(
          onPressed: isLoading ? null : onAck,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('ACK'),
        ),
      );
    }
    if (onResolve != null && check.canResolve) {
      actions.add(
        FilledButton(
          onPressed: isLoading ? null : onResolve,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('RESOLVE'),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (actions.isNotEmpty) ...actions,
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _severityColor(context).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _severityColor(context).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            check.isResolved ? 'RESOLVED' : check.severity,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _severityColor(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _severityIcon(),
        color: _severityColor(context),
        size: 24,
      ),
      title: Text(
        '${check.checkCode} • ${check.entityType}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(check.message),
      trailing: _buildTrailing(context),
      onTap: onTap,
    );
  }
}

class _IntegrityDetailDialog extends StatelessWidget {
  final IntegrityCheck check;

  const _IntegrityDetailDialog({required this.check});

  @override
  Widget build(BuildContext context) {
    final prettyJson = check.payload.isEmpty
        ? 'Aucun détail'
        : const JsonEncoder.withIndent('  ').convert(check.payload);

    return AlertDialog(
      title: Text('Détail — ${check.checkCode}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'check_code', value: check.checkCode),
            _DetailRow(label: 'severity', value: check.severity),
            _DetailRow(label: 'status', value: check.status),
            _DetailRow(label: 'entity_type', value: check.entityType),
            _DetailRow(label: 'entity_id', value: check.entityId),
            _DetailRow(
              label: 'last_detected_at',
              value: DateFormatter.formatDateTime(check.detectedAt),
            ),
            const SizedBox(height: 12),
            Text(
              'Payload',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                prettyJson,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copyPayload(context, prettyJson),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copier'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  void _copyPayload(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copié')),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
