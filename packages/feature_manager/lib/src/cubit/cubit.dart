import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class Cubit<State> {
  Cubit(this._state);

  late final _stateController = StreamController<State>.broadcast();

  Stream<State> get stream => _stateController.stream;

  bool get isClosed => _stateController.isClosed;

  State _state;

  State get state => _state;

  void emit(State state) {
    try {
      if (isClosed) {
        throw StateError('Cannot emit new states after calling close');
      }
      if (state == _state) {
        return;
      }
      _state = state;
      _stateController.add(_state);
    } catch (_) {
      rethrow;
    }
  }

  @mustCallSuper
  Future<void> close() async {
    await _stateController.close();
  }
}
