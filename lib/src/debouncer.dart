import 'dart:async';

/// Thrown when a later [Debouncer.run] replaces an in-flight wait.
class DebouncerCancelled implements Exception {
  /// Creates a cancellation from a superseded [Debouncer.run].
  const DebouncerCancelled();

  @override
  String toString() => 'DebouncerCancelled';
}

/// Delays work until [duration] has passed without another [run].
///
/// Use around any chatty API (search, autocomplete, save-while-typing).
/// A later [run] or [cancel] fails the previous future with
/// [DebouncerCancelled].
///
/// ```dart
/// final debounce = Debouncer();
///
/// Future<List<Person>> searchPeople(String query) {
///   if (query.isEmpty) return api.searchPeople(query);
///   return debounce.run(() => api.searchPeople(query));
/// }
/// ```
class Debouncer {
  /// Creates a debounce. Default pause is 300ms of quiet.
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  /// Quiet time before [run] invokes its callback.
  final Duration duration;

  Timer? _timer;
  Completer<void>? _wait;

  /// Waits for [duration] of quiet, then returns [action].
  ///
  /// A later [run] or [cancel] fails the previous future with
  /// [DebouncerCancelled].
  Future<T> run<T>(FutureOr<T> Function() action) async {
    await _arm();
    return action();
  }

  /// Cancels a pending wait. Does not stop a callback that has already started.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    final pending = _wait;
    _wait = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const DebouncerCancelled(), StackTrace.empty);
    }
  }

  /// Same as [cancel].
  void dispose() => cancel();

  Future<void> _arm() {
    cancel();
    final next = Completer<void>();
    _wait = next;
    _timer = Timer(duration, () {
      if (!next.isCompleted) next.complete();
    });
    return next.future;
  }
}
