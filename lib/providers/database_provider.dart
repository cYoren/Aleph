import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/daos/bible_dao.dart';
import '../data/database/daos/srs_dao.dart';
import '../features/settings/settings_provider.dart';

/// The DAO is rebuilt when the interface language changes, which invalidates
/// every lexicon read downstream — that is the point: switching to Português
/// should change what the definition sheet says, not just the button labels.
final bibleDaoProvider = Provider<BibleDAO>((ref) {
  final language = ref.watch(
    settingsProvider.select((state) => state.appLanguage),
  );
  return BibleDAO(glossLanguage: language);
});

final srsDaoProvider = Provider<SrsDao>((ref) {
  return SrsDao();
});
