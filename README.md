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

## Bouwen via Xcode Cloud

### Stap 1: Repository koppelen

1. Open het project in Xcode (`BlockerTestApp/BlockerTestApp.xcodeproj`)
2. Ga naar **Product > Xcode Cloud > Create Workflow**
3. Koppel aan de GitHub repository `eryq78/IPA`
4. Selecteer het scheme **BlockerTestApp**

### Stap 2: Workflow configureren

- **Start condition**: Manual of bij push naar `main`
- **Environment**: Latest release Xcode, macOS
- **Actions**: Archive (iOS)
- **Post-actions**: De `ci_scripts/ci_post_xcodebuild.sh` draait automatisch

### Stap 3: Build starten

1. Start de workflow in Xcode of via App Store Connect
2. Download de .ipa uit het Artifacts tab van de build

### Lokaal archiveren (optioneel, vereist macOS)

```bash
cd BlockerTestApp
xcodebuild archive \
  -project BlockerTestApp.xcodeproj \
  -scheme BlockerTestApp \
  -configuration Release \
  -archivePath build/BlockerTestApp.xcarchive \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=NO

# Export naar .ipa (ad-hoc of development signing vereist)
xcodebuild -exportArchive \
  -archivePath build/BlockerTestApp.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```

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
