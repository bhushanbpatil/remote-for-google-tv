# App Store submission guide

Use this when App Store Connect access is active.

## App Store Connect — create app

| Field | Value |
|-------|--------|
| **Name** | Remote for Google TV |
| **Bundle ID** | `com.bhushanbpatil.remote-for-google-tv` |
| **SKU** | `remote-google-tv-001` |
| **Primary category** | Utilities |
| **Price** | Free |

Register the bundle ID first in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) if Xcode doesn’t create it automatically.

## URLs

| Field | URL |
|-------|-----|
| **Privacy Policy** | Enable GitHub Pages (source: `/docs`), then use:<br>`https://bhushanbpatil.github.io/remote-for-google-tv/privacy-policy.html` |
| **Support** | `https://github.com/bhushanbpatil/remote-for-google-tv/issues` |

GitHub Pages: repo **Settings → Pages → Build from branch → main → /docs**.

## Description (paste into App Store Connect)

```
Control your Google TV or Android TV from your iPhone on the same Wi‑Fi network.

• D-pad navigation, Home, Back, Power
• Volume and mute
• Playback controls
• Quick launch for YouTube, Netflix, Disney+, Prime Video, Apple TV, HBO Max, Hulu, ESPN, Sling, Fox One
• Wi‑Fi discovery or manual IP entry
• One-time pairing with the code on your TV

REQUIREMENTS
• iPhone and TV on the same Wi‑Fi
• Google TV or Android TV with Android TV Remote Service

DISCLAIMER
This app is not affiliated with, endorsed by, or connected to Google LLC. Google TV is a trademark of Google LLC.

Does not work with Fire TV, Roku, Samsung, or LG TVs.
```

## Keywords

```
google tv,android tv,remote,smart tv,wifi,tv control,chromecast,streaming
```

## App Privacy questionnaire

- **Data collected:** No
- **Local network:** Yes — used to find and control the TV on your home network
- **Tracking:** No

## Review notes (paste for reviewer)

```
This app controls a Google TV or Android TV on the same local Wi‑Fi network using the standard Android TV Remote v2 protocol.

To test:
1. Allow Local Network permission when prompted
2. Enter TV IP or pick from discovery
3. Enter the 6-character pairing code shown on the TV
4. Use remote buttons

If no Google TV is available, the setup and pairing UI can still be reviewed. The app does not require login.

Not affiliated with Google LLC.
```

## Export compliance

Project is configured with `ITSAppUsesNonExemptEncryption = NO` (standard TLS only).

When submitting, answer: **No** — app uses only standard encryption.

## Screenshots needed

Minimum: **6.7" iPhone** (1290 × 2796). Capture:

1. Main remote (connected)
2. Connect TV / pairing screen

Run on iPhone or Simulator → screenshot.

## Upload build

1. Xcode → select **Any iOS Device (arm64)**
2. **Product → Archive**
3. **Distribute App → App Store Connect → Upload**
4. Wait for build processing in App Store Connect
5. TestFlight first (recommended), then submit for review

## Checklist

- [ ] Apple Developer membership active
- [ ] App Store Connect access works
- [ ] Bundle ID registered
- [ ] GitHub Pages privacy policy live
- [ ] Screenshots uploaded
- [ ] Paid Applications agreement signed (Agreements, Tax, and Banking)
- [ ] Build uploaded and selected
- [ ] Submit for review
