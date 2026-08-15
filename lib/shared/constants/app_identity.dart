class AppIdentity {
  static const publicAppName = 'Original Bible';

  /// Shown in Settings for store compliance. The registered legal name is
  /// deliberately not surfaced in the app: it contains the owner's personal
  /// name, and the trade name plus CNPJ already identify the responsible
  /// entity.
  static const responsibleTradeName = publicAppName;
  static const responsibleCnpj = '64.661.660/0001-04';

  const AppIdentity._();
}
