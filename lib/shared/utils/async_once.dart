import 'dart:async';

class AsyncOnce<T> {
  T? _value;
  Future<T>? _inFlight;
  bool _hasValue = false;

  T? get valueOrNull => _hasValue ? _value : null;

  Future<T> getOrCreate(Future<T> Function() create) {
    if (_hasValue) {
      return Future<T>.value(_value as T);
    }

    final current = _inFlight;
    if (current != null) {
      return current;
    }

    final completer = Completer<T>();
    _inFlight = completer.future;

    Future<T>.sync(create).then(
      (value) {
        _value = value;
        _hasValue = true;
        _inFlight = null;
        completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        _inFlight = null;
        completer.completeError(error, stackTrace);
      },
    );

    return completer.future;
  }

  void clear() {
    _value = null;
    _hasValue = false;
    _inFlight = null;
  }
}
