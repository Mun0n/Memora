import 'package:domain/domain.dart';

/// Deterministic fictional UUIDs for Demo UI creates (not production IDs).
final class DemoIds {
  DemoIds({int start = 0x600}) : _seq = start;

  int _seq;

  String nextUuid() {
    _seq += 1;
    final suffix = _seq.toRadixString(16).padLeft(12, '0');
    return '01932f00-0004-7000-8000-$suffix';
  }

  RoutineId nextRoutineId() => RoutineId(nextUuid());

  ReminderId nextReminderId() => ReminderId(nextUuid());

  RoutineProgressId nextProgressId() => RoutineProgressId(nextUuid());

  IdempotencyKey nextIdempotencyKey(String purpose) {
    return IdempotencyKey('demo-ui-$purpose-${nextUuid()}');
  }
}
