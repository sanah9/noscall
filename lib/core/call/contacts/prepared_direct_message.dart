class PreparedDirectMessage {
  const PreparedDirectMessage({
    required this.messageId,
    required this.eventJson,
    required this.createdAt,
  });
  final String messageId;
  final String eventJson;
  final int createdAt;
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'eventJson': eventJson,
    'createdAt': createdAt,
  };
  factory PreparedDirectMessage.fromJson(Map<String, dynamic> json) =>
      PreparedDirectMessage(
        messageId: json['messageId'] as String,
        eventJson: json['eventJson'] as String,
        createdAt: json['createdAt'] as int,
      );
}
