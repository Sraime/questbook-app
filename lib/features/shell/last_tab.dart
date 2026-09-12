import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the two tabs the reader was on before the chrome took them
/// somewhere else.
///
/// The bell and the drawer open pages that belong to no tab, so "back" from
/// them has no obvious destination. Sending everyone to the character list
/// would lose whoever came from a table; re-entering the tab they left keeps
/// them exactly where they were, sheet or session included.
class LastTabController extends Notifier<int> {
  @override
  int build() => 0;

  void remember(int index) {
    if (index != state) state = index;
  }
}

final lastTabProvider =
    NotifierProvider<LastTabController, int>(LastTabController.new);
