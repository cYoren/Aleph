import '../../shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'explain_health.dart';
import 'explain_provider.dart';

/// Shows how well the AI has actually been performing on this device.
///
/// The failure this exists to catch is the quiet one: a hosted model degrades,
/// every request still returns 200, and answers just get worse. Success rate,
/// median latency, and the count of answers that came back unusable make that
/// visible, so switching models is a decision based on numbers rather than a
/// feeling that it "seems worse lately".
class ExplainDiagnosticsScreen extends ConsumerWidget {
  const ExplainDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final healthAsync = ref.watch(explainHealthProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final activeModel = ref.watch(explainModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.explainDiagnosticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.explainClearDiagnostics,
            onPressed: () async {
              await ExplainHealthStore().clear();
              ref.invalidate(explainHealthProvider);
            },
          ),
        ],
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.contentLoadError,
          onRetry: () => ref.invalidate(explainHealthProvider),
        ),
        data: (models) {
          if (models.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.explainNoData,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.explainDiagnosticsDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final model in models)
                _ModelCard(
                  health: model,
                  isActive: model.modelId == activeModel.modelId,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.health, required this.isActive});

  final ModelHealth health;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final verdict = switch (health.verdictCode) {
      ExplainHealthVerdict.unused => l10n.diagnosticsNotUsed,
      ExplainHealthVerdict.tooEarly => l10n.diagnosticsTooEarly,
      ExplainHealthVerdict.earlyProblems => l10n.diagnosticsEarlyProblems,
      ExplainHealthVerdict.failing => l10n.diagnosticsFailing,
      ExplainHealthVerdict.unreliable => l10n.diagnosticsUnreliable,
      ExplainHealthVerdict.slow => l10n.diagnosticsSlow,
      ExplainHealthVerdict.mostlyGood => l10n.diagnosticsMostlyGood,
      ExplainHealthVerdict.healthy => l10n.diagnosticsHealthy,
    };
    final attention = health.needsAttention;

    final accent = attention
        ? colorScheme.error
        : health.suspect > 0
        ? colorScheme.tertiary
        : colorScheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: attention
              ? colorScheme.error.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: attention ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    health.modelId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.diagnosticsInUse,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  attention
                      ? Icons.error_outline
                      : health.suspect > 0
                      ? Icons.warning_amber_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verdict,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _Stat(
                  label: l10n.diagnosticsSuccess,
                  value: '${(health.successRate * 100).round()}%',
                ),
                _Stat(
                  label: l10n.diagnosticsMedian,
                  value: '${(health.medianMs / 1000).toStringAsFixed(1)}s',
                ),
                _Stat(label: l10n.diagnosticsCalls, value: '${health.total}'),
                if (health.suspect > 0)
                  _Stat(
                    label: l10n.diagnosticsPoorAnswers,
                    value: '${health.suspect}',
                  ),
                if (health.errors > 0)
                  _Stat(
                    label: l10n.diagnosticsErrors,
                    value: '${health.errors}',
                  ),
              ],
            ),
            if (health.lastFailureNote != null) ...[
              const SizedBox(height: 10),
              Text(
                '${l10n.diagnosticsLastProblem}: ${health.lastFailureNote}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
