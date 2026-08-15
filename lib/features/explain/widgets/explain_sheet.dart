import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../explain_provider.dart';
import '../explain_service.dart';

/// Bottom sheet holding an AI explanation of one passage.
///
/// The disclaimer is not decoration: the model is a good tutor and a
/// confident one, and a beginner has no way to catch it when it is wrong.
/// Saying so plainly is part of the feature working properly.
class ExplainSheet extends ConsumerWidget {
  const ExplainSheet({super.key, required this.reference, required this.request});

  final String reference;
  final ExplainRequest request;

  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String reference,
    required ExplainRequest request,
  }) {
    ref.read(explainProvider.notifier).request(request);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExplainSheet(reference: reference, request: request),
    ).whenComplete(() => ref.read(explainProvider.notifier).reset());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(explainProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.explainTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            reference,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _Body(
                  state: state,
                  scrollController: scrollController,
                  onRetry: () =>
                      ref.read(explainProvider.notifier).request(request),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRetry,
  });

  final ExplainState state;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    switch (state) {
      case ExplainLoading():
        // The model reasons before answering, so this reliably takes a few
        // seconds. Say what is happening rather than showing a bare spinner.
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.explainLoading,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );

      case ExplainReady(:final text):
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SelectableText(
              text,
              style: const TextStyle(fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.explainDisclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case ExplainFailed(:final failure):
        final message = switch (failure) {
          ExplainFailure.offline => l10n.explainErrorOffline,
          ExplainFailure.rateLimited => l10n.explainErrorRateLimited,
          _ => l10n.explainErrorGeneric,
        };
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 36,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: Text(l10n.explainRetry),
                ),
              ],
            ),
          ),
        );

      case ExplainIdle():
        return const SizedBox.shrink();
    }
  }
}
