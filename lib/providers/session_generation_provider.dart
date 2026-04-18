import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionGenerationProvider =
    NotifierProvider<SessionGenerationNotifier, int>(
      SessionGenerationNotifier.new,
    );

class SessionGenerationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
