# VERIFY.md — Verificatie Checklist

Gebruik deze checklist om per blocker te bevestigen dat deze daadwerkelijk aanwezig is in de gebouwde .ipa.

## Voorbereiding

```bash
# Unzip de .ipa
mkdir -p /tmp/blocker-verify
cp BlockerTestApp.ipa /tmp/blocker-verify/
cd /tmp/blocker-verify
unzip -o BlockerTestApp.ipa

# Stel variabelen in
APP_PATH="Payload/BlockerTestApp.app"
BINARY="$APP_PATH/BlockerTestApp"
PLIST="$APP_PATH/Info.plist"
```

---

## Blocker 1: Ontbrekende NSCameraUsageDescription

**Verwacht:** AVFoundation symbols in binary, maar GEEN NSCameraUsageDescription in plist.

```bash
# Check: privacy key ONTBREEKT
plutil -p "$PLIST" | grep -i "NSCameraUsageDescription"
# Verwacht: geen output (key ontbreekt)

# Check: AVFoundation symbols AANWEZIG
strings "$BINARY" | grep -i "AVCaptureDevice"
# Verwacht: AVCaptureDevice referentie gevonden

# Check: framework gelinkt
otool -L "$BINARY" | grep AVFoundation
# Verwacht: /System/Library/Frameworks/AVFoundation.framework/AVFoundation
```

**Resultaat:** [ ] PASS — key ontbreekt, framework gelinkt

---

## Blocker 2: Private API usage (dlopen/dlsym)

**Verwacht:** Literal strings naar private frameworks in de binary.

```bash
# Check: private framework path in binary
strings "$BINARY" | grep "PrivateFrameworks"
# Verwacht: /System/Library/PrivateFrameworks/ChatKit.framework/ChatKit

# Check: dlopen/dlsym symbolen
nm "$BINARY" | grep -E "dlopen|dlsym"
# Verwacht: _dlopen en _dlsym referenties

# Check: private class naam
strings "$BINARY" | grep "CKConversation"
# Verwacht: CKConversation string gevonden
```

**Resultaat:** [ ] PASS — private framework path en dlopen/dlsym aanwezig

---

## Blocker 3: Ongeldige Game Center entitlement

**Verwacht:** Game Center entitlement in embedded entitlements.

```bash
# Check: entitlements in signed binary
codesign -d --entitlements :- "$APP_PATH" 2>/dev/null
# Verwacht: com.apple.developer.game-center = true

# Check: GameKit framework gelinkt
otool -L "$BINARY" | grep GameKit
# Verwacht: /System/Library/Frameworks/GameKit.framework/GameKit
```

**Resultaat:** [ ] PASS — game-center entitlement aanwezig

---

## Blocker 4: Executable stack (MH_ALLOW_STACK_EXECUTION)

**Verwacht:** MH_ALLOW_STACK_EXECUTION flag in Mach-O header.

```bash
# Check: Mach-O header flags
otool -l "$BINARY" | grep -A5 "LC_SEGMENT"
# Of specifiek:
otool -h "$BINARY"
# Verwacht: flags bevatten ALLOW_STACK_EXECUTION (0x20000)

# Alternatief: zoek in volledige load commands
otool -l "$BINARY" | grep -i "stack"
```

**Resultaat:** [ ] PASS — executable stack flag gezet

> **Let op:** Deze flag werkt mogelijk alleen op x86_64 architectuur. Op arm64 (iOS devices) kan de linker de flag negeren maar de intentie is nog steeds detecteerbaar in de build settings en eventueel in de Mach-O header.

---

## Blocker 5: Debug artifact in bundle

**Verwacht:** debug_test_data.json aanwezig in de app bundle.

```bash
# Check: bestand aanwezig in .ipa
unzip -l BlockerTestApp.ipa | grep "debug_test_data"
# Verwacht: Payload/BlockerTestApp.app/debug_test_data.json

# Check: inhoud bevat debug tokens
strings "$APP_PATH/debug_test_data.json" | grep "DEBUG_TOKEN"
# Verwacht: DEBUG_TOKEN_abc123, DEBUG_TOKEN_def456

# Check: staging endpoints
strings "$APP_PATH/debug_test_data.json" | grep "staging"
# Verwacht: staging-api.example.com
```

**Resultaat:** [ ] PASS — debug bestand met test tokens aanwezig

---

## Blocker 6: Ongeldige MinimumOSVersion

**Verwacht:** MinimumOSVersion 8.0 in Info.plist.

```bash
# Check: MinimumOSVersion in plist
plutil -p "$PLIST" | grep "MinimumOSVersion"
# Verwacht: "MinimumOSVersion" => "8.0"

# Check: deployment target in binary
otool -l "$BINARY" | grep -A4 "LC_BUILD_VERSION\|LC_VERSION_MIN"
# Verwacht: minos of sdk versie die iOS 8.0 of vergelijkbaar laag toont
```

**Resultaat:** [ ] PASS — MinimumOSVersion is 8.0

---

## Blocker 7: UIRequiredDeviceCapabilities mismatch

**Verwacht:** telephony en magnetometer in required capabilities.

```bash
# Check: capabilities in plist
plutil -p "$PLIST" | grep -A10 "UIRequiredDeviceCapabilities"
# Verwacht: array bevat "telephony" en "magnetometer"

# Specifieke check
/usr/libexec/PlistBuddy -c "Print :UIRequiredDeviceCapabilities" "$PLIST"
# Verwacht: Array met arm64, telephony, magnetometer, accelerometer
```

**Resultaat:** [ ] PASS — onnodige telephony en magnetometer capabilities aanwezig

---

## Blocker 8: Verboden URL scheme (itms-services)

**Verwacht:** itms-services in CFBundleURLSchemes.

```bash
# Check: URL schemes in plist
plutil -p "$PLIST" | grep -i "itms-services"
# Verwacht: "itms-services" gevonden

# Uitgebreide check
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes" "$PLIST"
# Verwacht: Array bevat "itms-services"

# Check: string in binary
strings "$BINARY" | grep "itms-services"
# Verwacht: itms-services string gevonden
```

**Resultaat:** [ ] PASS — verboden URL scheme geregistreerd

---

## Samenvatting tabel

Na het doorlopen van alle checks, vul deze tabel in:

| # | Blocker | Status |
|---|---------|--------|
| 1 | Missing NSCameraUsageDescription | [ ] |
| 2 | Private API (dlopen/dlsym) | [ ] |
| 3 | Invalid Game Center entitlement | [ ] |
| 4 | Executable stack flag | [ ] |
| 5 | Debug artifact in bundle | [ ] |
| 6 | MinimumOSVersion 8.0 | [ ] |
| 7 | UIRequiredDeviceCapabilities mismatch | [ ] |
| 8 | Forbidden itms-services URL scheme | [ ] |

## Opmerkingen

- **Blocker 4** (executable stack): Op arm64 kan de linker de flag mogelijk negeren. De `-allow_stack_execution` is primair een x86_64 concept. Controleer of de flag daadwerkelijk in de Mach-O header verschijnt na een arm64 build. Zo niet, is deze blocker alsnog detecteerbaar via de build settings in het project.
- **Blocker 3** (entitlement): Als Xcode Cloud met automatic signing werkt en Game Center niet als capability is geconfigureerd in App Store Connect, zal de entitlement mismatch optreden. Als automatic signing het probleem corrigeert, moet de entitlement handmatig worden geforceerd.
- Alle plist-gebaseerde blockers (1, 6, 7, 8) zijn het meest betrouwbaar — ze overleven altijd de build pipeline ongewijzigd.
