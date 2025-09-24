enum CallDirection {
  incoming('incoming'),
  outgoing('outgoing');

  final String value;
  const CallDirection(this.value);
}

enum CallStatus {
  completed('completed'),
  declined('declined'),
  failed('failed'),
  cancelled('cancelled');

  final String value;
  const CallStatus(this.value);
}

extension CallDirectionEx on CallDirection {
  static CallDirection? fromValue(dynamic value) =>
      CallDirection.values.where((e) => e.value == value).firstOrNull;

  String get displayName {
    switch (this) {
      case CallDirection.incoming:
        return 'Incoming';
      case CallDirection.outgoing:
        return 'Outgoing';
    }
  }
}

extension CallStatusEx on CallStatus {
  static CallStatus? fromValue(dynamic value) =>
      CallStatus.values.where((e) => e.value == value).firstOrNull;

  bool get isSuccessful {
    switch (this) {
      case CallStatus.completed:
        return true;
      case CallStatus.declined:
      case CallStatus.failed:
      case CallStatus.cancelled:
        return false;
    }
  }
}
