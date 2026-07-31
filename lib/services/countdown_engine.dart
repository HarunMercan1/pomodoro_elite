import 'dart:math';

enum CountdownUpdate { unchanged, updated, completed }

class CountdownEngine {
  final DateTime Function() _now;

  int _remainingSeconds;
  DateTime? _deadline;
  bool _isRunning = false;
  bool _completionReported = false;

  CountdownEngine({
    required int initialSeconds,
    DateTime Function()? now,
  })  : assert(initialSeconds >= 0),
        _remainingSeconds = initialSeconds,
        _now = now ?? DateTime.now;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  DateTime? get deadline => _deadline;

  void reset(int seconds) {
    assert(seconds >= 0);
    _remainingSeconds = seconds;
    _deadline = null;
    _isRunning = false;
    _completionReported = false;
  }

  bool start() {
    if (_isRunning || _remainingSeconds <= 0) return false;

    _deadline = _now().add(Duration(seconds: _remainingSeconds));
    _isRunning = true;
    _completionReported = false;
    return true;
  }

  CountdownUpdate update() {
    if (!_isRunning || _deadline == null) {
      return CountdownUpdate.unchanged;
    }

    final millisecondsLeft = _deadline!.difference(_now()).inMilliseconds;
    final nextRemainingSeconds = max(
      0,
      (millisecondsLeft / Duration.millisecondsPerSecond).ceil(),
    );
    final didChange = nextRemainingSeconds != _remainingSeconds;
    _remainingSeconds = nextRemainingSeconds;

    if (_remainingSeconds == 0) {
      _isRunning = false;
      _deadline = null;
      if (!_completionReported) {
        _completionReported = true;
        return CountdownUpdate.completed;
      }
    }

    return didChange ? CountdownUpdate.updated : CountdownUpdate.unchanged;
  }

  void pause() {
    update();
    _deadline = null;
    _isRunning = false;
  }
}
