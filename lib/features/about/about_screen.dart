/// Where the text, the dictionaries, the grammar and the letterforms came
/// from — and who is responsible for the app.
///
/// The app bundles a Hebrew Bible and a Greek New Testament, several
/// translations, Strong's lexicons, MACULA syntax trees under CC BY, and two
/// SIL typefaces whose licence requires attribution. None of that reached a
/// reader: the only credit anywhere in the app was one line inside the syntax
/// tree screen. `AGENTS.md` lists preserving attribution as a project rule, so
/// this screen is where it lives.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/constants/app_identity.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutSourcesTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Version first: it is what a reader is asked for when they report
          // something, and it was not visible anywhere in the app.
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(l10n.aboutVersionLabel),
            subtitle: Text(
              '${AppIdentity.publicAppName} '
              '${AppIdentity.version} (${AppIdentity.buildNumber})',
            ),
          ),
          const Divider(),

          _Section(l10n.aboutSourcesSectionTitle, scheme),
          _Source(
            icon: Icons.menu_book_outlined,
            title: l10n.sourceOriginalTextTitle,
            body: l10n.sourceOriginalTextBody,
          ),
          _Source(
            icon: Icons.translate,
            title: l10n.sourceTranslationsTitle,
            body: l10n.sourceTranslationsBody,
          ),
          _Source(
            icon: Icons.book_outlined,
            title: l10n.sourceLexiconTitle,
            body: l10n.sourceLexiconBody,
          ),
          _Source(
            icon: Icons.account_tree_outlined,
            title: l10n.sourceSyntaxTitle,
            body: l10n.sourceSyntaxBody,
          ),
          _Source(
            icon: Icons.font_download_outlined,
            title: l10n.sourceFontsTitle,
            body: l10n.sourceFontsBody,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l10n.aboutLicensesTitle),
            subtitle: Text(l10n.aboutLicensesDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppIdentity.publicAppName,
              applicationVersion:
                  '${AppIdentity.version} (${AppIdentity.buildNumber})',
            ),
          ),
          const Divider(),

          // Store compliance: the trade name and CNPJ identify the responsible
          // entity. Moved here from the foot of Settings, not removed.
          _Section(l10n.appResponsible, scheme),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(l10n.tradeNameLabel),
            subtitle: const Text(AppIdentity.responsibleTradeName),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.cnpjLabel),
            subtitle: const Text(AppIdentity.responsibleCnpj),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.scheme);

  final String title;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body, style: const TextStyle(height: 1.4)),
      isThreeLine: true,
    );
  }
}
