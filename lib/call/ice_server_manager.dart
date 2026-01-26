import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ICEServerManager {
  ICEServerManager._();

  static final ICEServerManager shared = ICEServerManager._();

  static const String _prefsKey = 'noscall_custom_ice_servers';

  List<ICEServerModel> get defaultICEServers => [
    ICEServerModel(
      url: 'turn:0xchat:Prettyvs511@52.76.210.159:5349',
    ),
    // ICEServerModel(
    //   url: 'turn:0xchat:Prettyvs511@rtc2.0xchat.com:5349',
    // ),
    ICEServerModel(
      url: 'turn:0xchat:Prettyvs511@13.213.17.140:5349',
    ),
    ICEServerModel(
      url: 'turn:0xchat:Prettyvs511@15.222.242.167:5349',
    ),
    // ICEServerModel(
    //   url: 'turn:0xchat:Prettyvs511@rtc5.0xchat.com:5349',
    // ),
    // ICEServerModel(
    //   url: 'turn:0xchat:Prettyvs511@rtc6.0xchat.com:5349',
    // ),
  ];

  /// Get ICE servers (custom if available, otherwise default)
  Future<List<ICEServerModel>> getICEServers() async {
    final customServers = await loadCustomServers();
    if (customServers.isNotEmpty) {
      return customServers;
    }
    return defaultICEServers;
  }

  /// Load custom ICE servers from SharedPreferences
  Future<List<ICEServerModel>> loadCustomServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ICEServerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save custom ICE servers to SharedPreferences
  Future<bool> saveCustomServers(List<ICEServerModel> servers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = servers.map((server) => server.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Clear custom ICE servers (reset to default)
  Future<bool> clearCustomServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_prefsKey);
    } catch (e) {
      return false;
    }
  }
}

class ICEServerModel {
  String url;

  ICEServerModel({
    this.url = '',
  });

  List<Map<String, String>> get serverConfigs {
    if (!isTurnAddress) {
      return [
        _normalConfig,
      ];
    }
    return [
      _turnConfig,
    ];
  }

  Map<String, String> get _normalConfig => {
    'url': url,
  };

  Map<String, String> get _turnConfig => {
    'urls': 'turn:$domain',
    'username': username,
    'credential': credential,
  };


  bool get isTurnAddress => url.startsWith('turn');

  String get username {
    if (!isTurnAddress) return '';

    final credentialsPart = url.split('@')[0];
    return credentialsPart.split(':')[1];
  }

  String get credential {
    if (!isTurnAddress) return '';

    final credentialsPart = url.split('@')[0];
    return credentialsPart.split(':')[2];
  }

  String get host => isTurnAddress ? domain.split(':')[0] : url;

  String get domain => (isTurnAddress && url.contains('@')) ? url.split('@')[1] : url;

  factory ICEServerModel.fromJson(Map<String, dynamic> json) {
    return ICEServerModel(
      url: json['url'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ICEServerModel &&
              runtimeType == other.runtimeType &&
              url == other.url;

  @override
  int get hashCode => url.hashCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
      };
}
