import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

/// Source notices stay available offline through the platform's license page.
void registerContentLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Aleph Bible data, Greek voice and fonts',
    ], await rootBundle.loadString('assets/attributions.txt'));
  });
}
