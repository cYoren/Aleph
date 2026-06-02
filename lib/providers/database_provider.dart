import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/daos/bible_dao.dart';
import '../data/database/daos/srs_dao.dart';

final bibleDaoProvider = Provider<BibleDAO>((ref) {
  return BibleDAO();
});

final srsDaoProvider = Provider<SrsDao>((ref) {
  return SrsDao();
});
