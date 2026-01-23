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
}
