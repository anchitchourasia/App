// lib/core/auto_refresh_mixin.dart
//
// Drop-in polling mixin — mirrors web vehicles.ts startPolling() pattern.
// Usage: add `with AutoRefreshMixin` to your State class,
//        then call startPolling(_load) in initState and
//        stopPolling() in dispose (handled automatically).

import 'dart:async';
import 'package:flutter/widgets.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _pollTimer;

  /// Interval matches web frontend: 30 seconds
  static const _pollInterval = Duration(seconds: 30);

  /// Call this in initState AFTER your first _load():
  ///   startPolling(_load);
  void startPolling(Future<void> Function() loader) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      // 🛑 guard: don't call setState if widget is gone (mirrors takeUntil)
      if (!mounted) return;
      await loader();
    });
  }

  /// Auto-called on dispose — no manual cleanup needed
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
