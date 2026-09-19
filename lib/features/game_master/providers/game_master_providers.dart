import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/local/session_board_dao.dart';

final sessionBoardDaoProvider = Provider<SessionBoardDao>(
  (ref) => SessionBoardDao(ref.watch(appDatabaseProvider)),
);
