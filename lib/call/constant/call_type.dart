enum CallingType {
  audio('audio'),
  video('video');

  final String value;
  const CallingType(this.value);
}

extension CallingTypeEx on CallingType {
  static CallingType? fromValue(dynamic value) =>
      CallingType.values.where((e) => e.value == value).firstOrNull;

  bool get isVideo {
    switch (this) {
      case CallingType.audio:
        return false;
      case CallingType.video:
        return true;
    }
  }

  String get text => value;
}

enum CallingRole {
  caller,       // Caller
  callee,       // Callee
}

enum CallingState {
  ringing,      // Waiting for answer or received invitation
  connecting,   // Both parties answered, establishing connection
  connected,    // Call established, audio/video channels stable
  ended,        // Call ended (normal hangup or failed)
}

enum AudioOutputType {
  none(0),
  speaker(1),
  bluetooth(2);

  final int value;
  const AudioOutputType(this.value);
}

enum CallActionType {
  answer,
  end,
}
