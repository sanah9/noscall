import 'core.dart';

/// Chat core manager responsible for initializing and managing chat functionality components
///
/// Uses singleton pattern to ensure only one global instance
class ChatCoreManager {
  ChatCoreManager._internal();
  factory ChatCoreManager() => _instance;
  static final ChatCoreManager _instance = ChatCoreManager._internal();

  /// Initialize chat core functionality with configuration
  Future<void> initChatCoreWithConfig(ChatCoreInitConfig config) async {
    try {

      await EventCache.sharedInstance.loadAllEventsFromDB();
      // Initialize relay service
      await Relays.sharedInstance.init();
      // Initialize core components with configuration
      await _initCoreComponentsWithConfig(config);
    } catch (e, stack) {
      // Log error and rethrow
      print('ChatCoreManager initialization failed: $e, $stack');
      rethrow;
    }
  }

  /// Initialize core components with configuration
  Future<void> _initCoreComponentsWithConfig(ChatCoreInitConfig config) async {
    // Initialize core components in parallel for better performance
    await Future.wait([
      Future(() => Contacts.sharedInstance.init(callBack: config.contactUpdatedCallBack)),
    ]);
  }

  List<int> myProfileKinds() {
    return  [0, 3, 10000, 10002, 10050, 30000];
  }

  List<int> userProfileKinds() {
    return  [0, 10002, 10050, 30008];
  }

  bool isAcceptedEventKind(int kind) {
    final accepted = [];
    return accepted.isEmpty || accepted.contains(kind);
  }
}
