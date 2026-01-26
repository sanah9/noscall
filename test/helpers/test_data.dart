/// Test data constants
class TestData {
  /// Valid public key (64 character hexadecimal)
  static const String validPubkey = 
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  
  /// Invalid public key
  static const String invalidPubkey = 'invalid-pubkey';
  
  /// Valid Relay URL
  static const String validRelayUrl = 'wss://relay.example.com';
  
  /// Invalid Relay URL
  static const String invalidRelayUrl = 'invalid-url';
  
  /// Default recommended Relay list
  static const List<String> defaultRelays = [
    'wss://relay.nostr.band',
    'wss://relay.0xchat.com',
    'wss://nostr.wine',
    'wss://auth.nostr1.com',
    'ws://52.9.218.70:8989',
  ];
  
  /// Test user name
  static const String testUserName = 'Test User';
  
  /// Test user nickname
  static const String testUserNickname = 'testuser';
  
  /// Valid STUN server URL
  static const String validStunUrl = 'stun:stun.l.google.com:19302';
  
  /// Valid STUNS server URL
  static const String validStunsUrl = 'stuns:stun.l.google.com:19302';
  
  /// Valid TURN server URL
  static const String validTurnUrl = 'turn:username:password@turn.example.com:3478';
  
  /// Valid TURNS server URL
  static const String validTurnsUrl = 'turns:username:password@turn.example.com:5349';
  
  /// Invalid ICE server URL
  static const String invalidIceServerUrl = 'invalid-url';
  
  /// Empty ICE server URL
  static const String emptyIceServerUrl = '';
}
