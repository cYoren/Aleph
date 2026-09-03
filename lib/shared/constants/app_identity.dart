class AppIdentity {
  /// The name on the store and in the app.
  ///
  /// *Aleph* — the first letter of the first alphabet the app teaches. One
  /// word, the same in all eight interface languages, and it says "the source
  /// text" without spelling it out. Store listings pair it with the subtitle
  /// "Bible in Hebrew and Greek", which is where the searchable words live.
  static const publicAppName = 'Aleph';

  /// Shown in Settings for store compliance.
  ///
  /// Deliberately **not** derived from [publicAppName]: this is the trade name
  /// tied to the CNPJ below, and it changes only when the registration does.
  /// Renaming the app is a marketing decision; renaming this is a legal one.
  /// The registered legal name itself is not surfaced — it contains the
  /// owner's personal name, and the trade name plus CNPJ already identify the
  /// responsible entity.
  static const responsibleTradeName = 'Original Bible';
  static const responsibleCnpj = '64.661.660/0001-04';

  /// Shown on the About screen. A reader reporting a problem is asked for
  /// this, and it appeared nowhere in the app before.
  ///
  /// Kept in step with `version:` in pubspec.yaml by
  /// `test/app_identity_version_test.dart`, so a release bump that forgets
  /// this fails the suite rather than shipping a stale number.
  static const version = '1.0.4';
  static const buildNumber = '25';

  const AppIdentity._();
}
