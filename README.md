# AppCompliance — Test IPA's

Twee iOS test-apps voor de [AppCompliance](https://github.com/eryq78) scanner.  
Elke app bevat bewust ingebouwde, detecteerbare fouten waarmee de scanner gevalideerd kan worden.

| App | Doel | Workflow |
|-----|------|----------|
| [BlockerTestApp](#1-blockertestapp) | 8 binary-detecteerbare App Store blockers | [▶ Starten](https://github.com/eryq78/IPA/actions/workflows/build-ipa.yml) |
| [FontPrivacyTestApp](#2-fontprivacytestapp) | Commerciële fonts · Deprecated SDKs · Kapotte privacy manifests | [▶ Starten](https://github.com/eryq78/IPA/actions/workflows/build-font-privacy-ipa.yml) |

---

## 1. BlockerTestApp

Bevat 8 bewust ingebouwde, technisch detecteerbare App Store blockers.

**[→ Workflow starten](https://github.com/eryq78/IPA/actions/workflows/build-ipa.yml)**

### Blockers

| # | Blocker | Locatie |
|---|---------|---------|
| 1 | Ontbrekende `NSCameraUsageDescription` | Info.plist |
| 2 | Private API (`dlopen`/`dlsym`) | Binary symbols |
| 3 | Ongeldige Game Center entitlement | .entitlements |
| 4 | Executable stack flag | Build settings |
| 5 | Debug artifact in bundle | debug_test_data.json |
| 6 | Ongeldige `MinimumOSVersion` | Info.plist |
| 7 | `UIRequiredDeviceCapabilities` mismatch | Info.plist |
| 8 | Verboden URL scheme (`itms-services`) | Info.plist |

Zie **[BLOCKERS.md](BLOCKERS.md)** en **[VERIFY.md](VERIFY.md)** voor volledige documentatie.

### Project structuur

```
BlockerTestApp/
├── BlockerTestApp.xcodeproj/
├── BlockerTestApp/
│   ├── BlockerConfig.swift              # Feature flags voor alle blockers
│   ├── Info.plist                       # Blockers 1, 6, 7, 8
│   ├── BlockerTestApp.entitlements      # Blocker 3
│   ├── Blockers.xcconfig                # Blocker 4
│   ├── Resources/debug_test_data.json   # Blocker 5
│   └── TestBlockers/
│       ├── Blocker1_MissingPrivacy.swift
│       ├── Blocker2_PrivateAPI.swift
│       └── Blocker3_InvalidEntitlement.swift
└── ci_scripts/
```

---

## 2. FontPrivacyTestApp

Bevat fouten in drie categorieën die Apple afkeurt: commerciële fonts zonder licentie, verouderde (deprecated) SDKs, en onjuiste of ontbrekende privacy manifests.

**[→ Workflow starten](https://github.com/eryq78/IPA/actions/workflows/build-font-privacy-ipa.yml)**

### Wat er fout zit

#### Fonts — 5 commercieel, 1 open source

| Bestand | Type | Licentiehouder |
|---------|------|----------------|
| `HelveticaNeue-Bold.ttf` | ❌ Commercieel | Linotype GmbH |
| `ProximaNova-Regular.ttf` | ❌ Commercieel | Mark Simonson Studio |
| `GothamBook.ttf` | ❌ Commercieel | Hoefler & Co |
| `BrandonGrotesque-Regular.ttf` | ❌ Commercieel | HVD Fonts |
| `FuturaPT-Medium.ttf` | ❌ Commercieel | ParaType |
| `Inter-Regular.ttf` | ✅ Open source | SIL OFL 1.1 |

Apple keurt apps af die commerciële fonts redistributen zonder geldige licentie (Guideline 5.2.2).

#### Deprecated SDKs

| Framework / Klasse | Deprecated sinds | Apple foutcode |
|--------------------|-----------------|----------------|
| `AddressBook.framework` | iOS 9.0 | ITMS-90683 |
| `OpenGLES.framework` | iOS 12.0 | ITMS-90789 |
| `NSURLConnection` | iOS 9.0 | — |

Detecteerbaar via `otool -L` (frameworks) en symbolen in de binary.

#### Privacy Manifest fouten

**App — `PrivacyInfo.xcprivacy` (aanwezig maar onjuist):**

| Fout | Details |
|------|---------|
| Ongeldig reason code | `CA92.1` bestaat niet in Apple's goedgekeurde lijst |
| `UserDefaults` niet gedeclareerd | Wel gebruikt in `FontLoader.swift` |
| `FileTimestamp` niet gedeclareerd | Wel gebruikt in `FontLoader.swift` |

**`FakeAnalyticsSDK.framework` — PrivacyInfo.xcprivacy aanwezig maar onjuist:**

| Fout | Details |
|------|---------|
| `NSPrivacyTracking = true` | Maar `NSPrivacyTrackingDomains` ontbreekt (verplicht) |
| Ongeldig reason code | `FAKE001` bestaat niet in Apple's goedgekeurde lijst |
| `NSPrivacyCollectedDataTypes` ontbreekt | SDK verzamelt device ID maar declareert niets |

**`FakeTrackerSDK.framework` — helemaal geen PrivacyInfo.xcprivacy:**

Apple rejection: ITMS-91053 — SDK gebruikt required reason APIs zonder enige privacy manifest.

### Project structuur

```
FontPrivacyTestApp/
├── FontPrivacyTestApp.xcodeproj/
├── FontPrivacyTestApp/
│   ├── AppDelegate.swift
│   ├── ViewController.swift             # Toont font samples
│   ├── DeprecatedAPIs.swift             # AddressBook, OpenGLES, NSURLConnection
│   ├── FontLoader.swift                 # Laadt fonts + UserDefaults/FileTimestamp
│   ├── Info.plist                       # UIAppFonts: alle 6 fonts gedeclareerd
│   └── PrivacyInfo.xcprivacy           # Kapotte privacy manifest (opzettelijk)
└── scripts/
    └── prepare_assets.sh               # Maakt font stubs + nep SDK frameworks
```

### Hoe de build werkt

De Xcode build compileert de Swift broncode en linkt de deprecated frameworks. Daarna injecteert `prepare_assets.sh` automatisch:

1. **5 commerciële font stubs** — geldige TTF-bestanden gegenereerd met Python/fonttools, met de juiste name-tables zodat scanners de family name herkennen
2. **Inter Regular** — gedownload van GitHub (rsms/inter, SIL OFL 1.1)
3. **FakeAnalyticsSDK.framework** — gecompileerde arm64 dylib met onjuiste PrivacyInfo.xcprivacy
4. **FakeTrackerSDK.framework** — gecompileerde arm64 dylib zonder PrivacyInfo.xcprivacy

---

## Bouwen — stap voor stap

### Vereisten

Geen macOS of Xcode nodig. Alles draait op GitHub's gratis macOS runners.

### Stap 1 — Workflow starten

Ga naar de gewenste workflow en klik op **Run workflow**:

- **BlockerTestApp:** https://github.com/eryq78/IPA/actions/workflows/build-ipa.yml
- **FontPrivacyTestApp:** https://github.com/eryq78/IPA/actions/workflows/build-font-privacy-ipa.yml

Of push een wijziging naar `main` — beide workflows starten dan automatisch.

### Stap 2 — IPA downloaden

1. Open de voltooide workflow run
2. Scroll naar **Artifacts** onderaan de pagina
3. Download het artifact:
   - `BlockerTestApp-IPA` → `BlockerTestApp.ipa`
   - `FontPrivacyTestApp-IPA` → `FontPrivacyTestApp.ipa`

### Stap 3 — Scannen

Geef het gedownloade `.ipa` bestand aan de AppCompliance scanner.
