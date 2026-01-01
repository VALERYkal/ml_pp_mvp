import 'package:flutter/material.dart';

/// Timeline moderne pour afficher les statuts
class ModernStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<StatusStep> steps;
  final Color? accentColor;

  const ModernStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.steps,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = this.accentColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.timeline, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Progression du cours',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeline(context, theme, accentColor),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = step.status == currentStatus;
        final isCompleted = _isStepCompleted(step.status);

        return Expanded(
          child: Row(
            children: [
              _buildStepIndicator(
                context,
                theme,
                accentColor,
                step,
                isActive,
                isCompleted,
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? accentColor.withValues(alpha: 0.3)
                          : theme.dividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
    StatusStep step,
    bool isActive,
    bool isCompleted,
  ) {
    final color = isCompleted || isActive
        ? accentColor
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: isActive ? 2 : 1),
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isActive || isCompleted
                ? accentColor
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _isStepCompleted(String status) {
    final currentIndex = steps.indexWhere(
      (step) => step.status == currentStatus,
    );
    final stepIndex = steps.indexWhere((step) => step.status == status);
    return stepIndex < currentIndex;
  }
}

/// Classe pour représenter une étape de statut
class StatusStep {
  final String status;
  final String label;
  final IconData icon;

  const StatusStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}
