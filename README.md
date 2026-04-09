# BlockerTestApp

Minimale iOS test-app voor [AppCompliance](https://github.com/eryq78) — bevat 8 bewust ingebouwde, technisch detecteerbare App Store blockers.

## Doel

Een .ipa produceren die binair-detecteerbare compliance violations bevat, zodat de AppCompliance scanner deze kan vinden en rapporteren.

## Project structuur

```
BlockerTestApp/
├── BlockerTestApp.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/BlockerTestApp.xcscheme
├── BlockerTestApp/
│   ├── AppDelegate.swift
│   ├── ViewController.swift
│   ├── BlockerConfig.swift              # Feature flags voor alle blockers
│   ├── Info.plist                        # Blockers 1, 6, 7, 8
│   ├── BlockerTestApp.entitlements       # Blocker 3 (met Game Center)
│   ├── BlockerTestApp-Clean.entitlements # Schone entitlements (controleversie)
│   ├── Blockers.xcconfig                 # Blocker 4 (executable stack flag)
│   ├── Clean.xcconfig                    # Schone build config
│   ├── Assets.xcassets/
│   ├── Resources/
│   │   └── debug_test_data.json          # Blocker 5 (debug artifact)
│   └── TestBlockers/
│       ├── TestBlockerRunner.swift
│       ├── Blocker1_MissingPrivacy.swift  # AVFoundation zonder privacy string
│       ├── Blocker2_PrivateAPI.swift      # dlopen/dlsym private framework
│       └── Blocker3_InvalidEntitlement.swift # GameKit referentie
├── ci_scripts/
│   ├── ci_post_clone.sh                  # Xcode Cloud post-clone
│   └── ci_post_xcodebuild.sh            # Xcode Cloud post-build verificatie
├── README.md
├── BLOCKERS.md
└── VERIFY.md
```

## Bouwen via GitHub Actions

Geen macOS of Xcode nodig. De build draait volledig op GitHub's macOS runners.

### Stap 1: Automatische build

De workflow draait automatisch bij elke push naar `main`. Je kunt hem ook handmatig starten:

1. Ga naar https://github.com/eryq78/IPA/actions
2. Klik op **Build BlockerTestApp IPA**
3. Klik op **Run workflow**

### Stap 2: IPA downloaden

1. Open de voltooide workflow run
2. Scroll naar **Artifacts**
3. Download **BlockerTestApp-IPA** — dit is je .ipa bestand

### Wat de workflow doet

- Bouwt een unsigned .ipa op een macOS 15 runner met Xcode 16.2
- Draait automatische verificatie van alle 8 blockers
- Upload de .ipa als downloadbaar artifact
- Geen Apple Developer account of signing vereist

## Controleversie (zonder blockers)

Om een schone build te maken:

1. Zet alle flags in `BlockerConfig.swift` op `false`
2. Vervang de xcconfig referentie in het project van `Blockers.xcconfig` naar `Clean.xcconfig`
3. Voeg `NSCameraUsageDescription` toe aan Info.plist
4. Verwijder `MinimumOSVersion`, `telephony`/`magnetometer` capabilities, `itms-services` scheme, en `UIBackgroundModes` uit Info.plist
5. Verwijder `debug_test_data.json` uit het Resources target

## Documentatie

- **[BLOCKERS.md](BLOCKERS.md)** — Volledige mapping per blocker naar Apple guideline en detectielocatie
- **[VERIFY.md](VERIFY.md)** — Verificatie checklist met concrete commando's per blocker
