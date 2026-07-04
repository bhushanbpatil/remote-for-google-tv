# Remote for Google TV

A personal-use iOS remote for **Google TV** and **Android TV** devices on your home Wi‑Fi network.

Uses the [Android TV Remote v2](https://github.com/odyshewroman/AndroidTVRemoteControl) protocol (TLS pairing on port 6467, commands on 6466).

**Disclaimer:** This is not an official Google product and is not affiliated with, endorsed by, or connected to Google LLC.

## Features

- D-pad, Home, Back, Power, Volume, Mute
- Playback controls (previous, play/pause, next)
- Settings, Input, Menu, Captions
- Quick launch for popular streaming apps
- Bonjour discovery + manual IP entry
- Auto-reconnect when returning from background

## Requirements

- **iOS 17.0** or later
- iPhone on the **same Wi‑Fi** as the TV
- Google TV or Android TV with **Android TV Remote Service** (pre-installed on most Google TVs)
- Xcode to build and install on your device

## Build & run

1. Open `TCL_TV_Remote.xcodeproj` in Xcode
2. Select your iPhone as the run destination
3. Set your **Development Team** in Signing & Capabilities
4. Build and run (⌘R)
5. Allow **Local Network** access when prompted
6. Enter your TV's IP if discovery is empty, then enter the 6-character pairing code shown on the TV

## Supported devices

Works with most **Google TV** and **Android TV** devices (TCL, Chromecast with Google TV, Sony, Hisense, Nvidia Shield, etc.).

Does **not** work with Amazon Fire TV, Roku, Samsung, or LG smart TVs.

## App Store

See [docs/APP_STORE.md](docs/APP_STORE.md) for submission checklist, listing text, and review notes.

Privacy policy: [docs/privacy-policy.html](docs/privacy-policy.html) (host via GitHub Pages for the App Store URL).

## License

MIT — see [LICENSE](LICENSE).

Third-party library [AndroidTVRemoteControl](https://github.com/odyshewroman/AndroidTVRemoteControl) is also MIT licensed.
