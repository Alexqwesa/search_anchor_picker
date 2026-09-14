import 'package:flutter/foundation.dart' show kDebugMode;

/// Exact debug counters for picker-owned lazy resources.
///
/// Tracking is disabled outside debug builds.
abstract final class PickerResourceTracker {
  static final Map<Type, Set<Object>> _live = {};
  static final Map<Type, int> _created = {};

  static void register<T extends Object>(T resource) {
    if (!kDebugMode) return;
    final resources = _live.putIfAbsent(T, Set<Object>.identity);
    final wasAdded = resources.add(resource);
    assert(
      wasAdded,
      '$T registered the same resource more than once.',
    );
    _created.update(T, (count) => count + 1, ifAbsent: () => 1);
  }

  static void unregister<T extends Object>(T resource) {
    if (!kDebugMode) return;
    final wasRemoved = _live[T]?.remove(resource) ?? false;
    assert(
      wasRemoved,
      '$T disposed an unregistered resource.',
    );
  }

  static Map<Type, int> get createdByType => Map.unmodifiable(_created);

  static Map<Type, int> get liveByType => Map.unmodifiable({
    for (final entry in _live.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value.length,
  });

  static void reset() {
    _live.clear();
    _created.clear();
  }
}
