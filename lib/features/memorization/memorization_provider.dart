import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/daos/memorization_dao.dart';
import '../../data/models/memorization_passage.dart';
import '../../data/models/verse.dart';
import '../../providers/database_provider.dart';

final memorizationDaoProvider = Provider<MemorizationDao>((ref) {
  return MemorizationDao();
});

/// All passages the user is memorizing, soonest review first.
final memorizationPassagesProvider =
    FutureProvider<List<MemorizationPassage>>((ref) async {
      final dao = ref.watch(memorizationDaoProvider);
      return dao.getPassages();
    });

/// Verses of a chapter for practice, keyed by (bookId, chapter).
final practiceVersesProvider =
    FutureProvider.family<List<Verse>, (String, int)>((ref, args) async {
      final dao = ref.watch(bibleDaoProvider);
      return dao.getVersesForChapter(args.$1, args.$2);
    });
