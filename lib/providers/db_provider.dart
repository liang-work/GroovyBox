import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/db.dart';

part 'db_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  return AppDatabase();
}
