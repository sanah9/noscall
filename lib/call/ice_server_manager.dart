class ICEServerManager {
  ICEServerManager._();

  static final ICEServerManager shared = ICEServerManager._();

  List<ICEServerModel> get defaultICEServers => [
    ICEServerModel(
      url: 'turn:0xchat:Prettyvs511@rtc.0xchat.com:5349',
    ),
    ICEServerModel(
      url: 'turn:0xchat:Prettyvs511@rtc2.0xchat.com:5349',
    ),
    ICEServerModel(
      url: 'turn:0xchat:Prettyvs511@rtc3.0xchat.com:5349',
    ),
    // ICEServerModel(
    //   url: 'turn:0xchat:Prettyvs511@rtc4.0xchat.com:5349',
    // ),
    // ICEServerModel(
    //   url: 'turn:0xchat:Prettyvs511@rtc5.0xchat.com:5349',
    // ),
    // ICEServerModel(
    //   url: 'turn:0xchat:Prettyvs511@rtc6.0xchat.com:5349',
    // ),
  ];
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

  Map<String, dynamic> toJson(ICEServerModel iceServerModel) =>
      <String, dynamic>{
        'url': iceServerModel.url,
      };
}
