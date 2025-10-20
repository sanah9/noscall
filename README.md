# NosCall

A decentralized voice and video calling app built on Nostr protocol. Features end-to-end encrypted calls with cross-platform support.

## Features

- Voice and video calls
- Cross-platform support (iOS, Android)
- Call history and contact management
- Compatible with other Nostr clients
- End-to-end encryption

### Running the code

Before running the app, please update the dependencies:

```bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

Now you can run the project:

```bash
flutter run -d ios
flutter run -d android
```

### Tech Stack

- **Flutter**: 3.19+
- **Dart**: 3.0+
- **WebRTC**: flutter_webrtc for real-time communication
- **Nostr**: nostr_core_dart for protocol implementation

## Roadmap

Future versions will continue improving decentralized communication and customization capabilities.

### Planned Features
- [ ] **QR code scanning** for easy contact discovery
- [ ] **Profile settings** - Customize your user experience
- [ ] **Custom relay configuration** (Inbox relay)
- [ ] **ICE server configuration UI** - Advanced connectivity options
- [ ] **Login via Nostr Signer** - Enhanced security
- [ ] **Import follower/following list** - Seamless migration
- [ ] **Friend grouping and favorites** - Organize your contacts efficiently
- [ ] **NIP-05 identity support** - Use your Nostr identity seamlessly
- [ ] **Tor network support** - Additional privacy and anonymity
- [ ] **Push notifications** - Stay connected with real-time notifications
- [ ] **Voice messages and call recording** - Enhanced communication features
- [ ] **Dark mode and custom themes** - Personalized user experience
- [ ] **Desktop version support** - Full desktop experience
