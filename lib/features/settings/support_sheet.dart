import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/support_service.dart';
import '../../core/usage_events.dart';

const String kPrivacyUrl = 'https://medhub.one/privacy';
const String kTermsUrl = 'https://medhub.one/terms';

Future<void> showSupportSheet(BuildContext context) async {
  await UsageEvents.record(UsageEvent.supportOpened);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const SupportSheet(),
  );
}

/// The tip jar.
///
/// It sells nothing, so it has no paywall job: no locked feature, no limit,
/// no restore (a tip is consumable). It still carries the two links and a
/// close, because money is being taken and the reader should be able to see
/// what they are agreeing to without leaving.
class SupportSheet extends StatefulWidget {
  /// Injected in tests. Production builds their own, because the sheet is
  /// opened from one place and has nothing to share.
  final SupportService? service;

  const SupportSheet({super.key, this.service});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  late final SupportService _support = widget.service ?? SupportService();
  late final bool _ownsService = widget.service == null;
  late final AppLocalizations _l10n = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _support.addListener(_onChanged);
    if (_ownsService) _support.load();
  }

  @override
  void dispose() {
    _support.removeListener(_onChanged);
    if (_ownsService) _support.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _support.state;
    final tiers = [
      (SupportTier.small, _l10n.supportTierSmall),
      (SupportTier.medium, _l10n.supportTierMedium),
      (SupportTier.large, _l10n.supportTierLarge),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l10n.supportTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _l10n.supportBody,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 18),
            if (state.thanked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _l10n.supportThanks,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (state.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (!state.hasProducts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _l10n.supportUnavailable,
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              for (final (tier, label) in tiers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: state.buying
                          ? null
                          : () => _support.buy(tier),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (state.products[tier] != null)
                            Text(state.products[tier]!.price),
                        ],
                      ),
                    ),
                  ),
                ),
            if (state.error != null) ...[
              const SizedBox(height: 6),
              Text(state.error!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 6),
            Text(
              _l10n.supportNote,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_l10n.supportClose),
                ),
                Row(
                  children: [
                    _LegalLink(label: _l10n.supportTerms, url: kTermsUrl),
                    const Text(' · ', style: TextStyle(fontSize: 12)),
                    _LegalLink(
                      label: _l10n.supportPrivacy,
                      url: kPrivacyUrl,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _open(context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  /// A link that cannot open still says where it goes: a button that does
  /// nothing reads as a broken app.
  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(url)),
      );
    }
  }
}
