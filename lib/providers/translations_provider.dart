import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/translation.dart';
import 'database_provider.dart';

/// Provider for all available translations
final translationsProvider = FutureProvider<List<Translation>>((ref) async {
  final dao = ref.watch(bibleDaoProvider);
  return dao.getTranslations();
});
