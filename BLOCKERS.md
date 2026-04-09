# BLOCKERS.md — Blocker-to-Guideline Mapping

Elke blocker in BlockerTestApp is technisch detecteerbaar vanuit de .ipa, binary of build artifacts.

---

## Blocker 1: Ontbrekende privacy usage description

| Veld | Waarde |
|------|--------|
| **Naam** | Missing NSCameraUsageDescription |
| **Apple Guideline** | 5.1.1 — Data Collection and Storage |
| **Reden afwijzing** | App linkt AVFoundation en referenceert AVCaptureDevice maar declareert geen NSCameraUsageDescription in Info.plist. iOS toont crash bij camera-toegang; Apple wijst af bij detectie van framework-gebruik zonder bijbehorende privacy string. |
| **Detecteerbaar in** | (1) `Info.plist` — afwezigheid van key NSCameraUsageDescription. (2) Binary symbols — `nm` of `strings` toont AVCaptureDevice/AVFoundation referenties. |
| **Bestand** | `BlockerTestApp/Info.plist`, `TestBlockers/Blocker1_MissingPrivacy.swift` |
| **Aan/uit** | `BlockerConfig.missingPrivacyDescription` + voeg key toe aan/verwijder uit Info.plist |

---

## Blocker 2: Non-public API usage (dlopen/dlsym)

| Veld | Waarde |
|------|--------|
| **Naam** | Private API via dlopen/dlsym |
| **Apple Guideline** | 2.5.1 — Software Requirements |
| **Reden afwijzing** | App gebruikt dlopen/dlsym om een private framework (ChatKit) te laden. Apple's geautomatiseerde scanner detecteert dlopen/dlsym calls + paden naar PrivateFrameworks. |
| **Detecteerbaar in** | Binary via `strings` of `nm` — toont literal string `/System/Library/PrivateFrameworks/ChatKit.framework/ChatKit` en symbolen `_dlopen`, `_dlsym`. |
| **Bestand** | `TestBlockers/Blocker2_PrivateAPI.swift` |
| **Aan/uit** | `BlockerConfig.privateAPIUsage` |

---

## Blocker 3: Ongeldige entitlement (Game Center)

| Veld | Waarde |
|------|--------|
| **Naam** | Invalid com.apple.developer.game-center entitlement |
| **Apple Guideline** | 2.4.1 — Hardware Compatibility / Code signing requirements |
| **Reden afwijzing** | Entitlements bestand bevat Game Center entitlement die niet in het provisioning profile zit. Dit veroorzaakt een signing mismatch die Apple's validatie detecteert. |
| **Detecteerbaar in** | Embedded entitlements via `codesign -d --entitlements :- <app>` — toont `com.apple.developer.game-center`. Binary linkt ook GameKit.framework. |
| **Bestand** | `BlockerTestApp.entitlements`, `TestBlockers/Blocker3_InvalidEntitlement.swift` |
| **Aan/uit** | `BlockerConfig.invalidEntitlement` + wissel entitlements bestand (BlockerTestApp.entitlements vs BlockerTestApp-Clean.entitlements) |

---

## Blocker 4: Executable stack (linker flag)

| Veld | Waarde |
|------|--------|
| **Naam** | MH_ALLOW_STACK_EXECUTION flag |
| **Apple Guideline** | 2.5.1 — Software Requirements + Apple platform security requirements |
| **Reden afwijzing** | Binary is gelinkt met `-allow_stack_execution`, wat de MH_ALLOW_STACK_EXECUTION flag zet in de Mach-O header. Dit is een security violation — executable stacks zijn verboden op iOS. |
| **Detecteerbaar in** | Mach-O header via `otool -l <binary>` — zoek naar `MH_ALLOW_STACK_EXECUTION` in de flags. |
| **Bestand** | `Blockers.xcconfig` (OTHER_LDFLAGS), project.pbxproj build settings |
| **Aan/uit** | Verwijder `-allow_stack_execution` uit OTHER_LDFLAGS of wissel naar `Clean.xcconfig` |

---

## Blocker 5: Debug artifact in bundle

| Veld | Waarde |
|------|--------|
| **Naam** | Debug/test data shipped in production bundle |
| **Apple Guideline** | 2.1 — App Completeness |
| **Reden afwijzing** | Het bestand `debug_test_data.json` bevat test-gebruikers, debug tokens en staging API endpoints. Dit hoort niet in een productie-app en duidt op een onvolledige release. |
| **Detecteerbaar in** | Bundle contents via `unzip -l <ipa>` — bestand verschijnt als `Payload/BlockerTestApp.app/debug_test_data.json`. Inhoud detecteerbaar via `strings` (bevat "DEBUG_TOKEN", "staging_api"). |
| **Bestand** | `Resources/debug_test_data.json` |
| **Aan/uit** | Verwijder het bestand uit het Resources build phase target |

---

## Blocker 6: Ongeldige MinimumOSVersion

| Veld | Waarde |
|------|--------|
| **Naam** | MinimumOSVersion 8.0 (niet meer ondersteund) |
| **Apple Guideline** | 2.1 — App Completeness |
| **Reden afwijzing** | iOS 8.0 wordt niet meer ondersteund als deployment target. Apple vereist minimaal iOS 16.0 voor nieuwe submissions (per 2024). Dit signaleert een misconfiguratie of verouderde build. |
| **Detecteerbaar in** | `Info.plist` — key `MinimumOSVersion` met waarde `8.0`. Ook zichtbaar in Mach-O load commands via `otool -l <binary>` (LC_VERSION_MIN_IPHONEOS of LC_BUILD_VERSION). |
| **Bestand** | `Info.plist`, `Blockers.xcconfig` (IPHONEOS_DEPLOYMENT_TARGET) |
| **Aan/uit** | Wijzig `IPHONEOS_DEPLOYMENT_TARGET` naar 16.0+ en verwijder de expliciete MinimumOSVersion key uit Info.plist |

---

## Blocker 7: UIRequiredDeviceCapabilities mismatch

| Veld | Waarde |
|------|--------|
| **Naam** | Overbodige/beperkende device capabilities |
| **Apple Guideline** | 2.4.1 — Hardware Compatibility |
| **Reden afwijzing** | App claimt `telephony` (alleen iPhones) en `magnetometer` als vereiste capabilities. Dit blokkeert installatie op iPads en devices zonder magnetometer, terwijl de app deze features niet nodig heeft. Apple wijst af als capabilities niet overeenkomen met daadwerkelijk gebruik. |
| **Detecteerbaar in** | `Info.plist` — key `UIRequiredDeviceCapabilities` bevat `telephony` en `magnetometer`. |
| **Bestand** | `Info.plist` |
| **Aan/uit** | Verwijder `telephony` en `magnetometer` uit de UIRequiredDeviceCapabilities array |

---

## Blocker 8: Verboden URL scheme (itms-services)

| Veld | Waarde |
|------|--------|
| **Naam** | itms-services:// URL scheme registration |
| **Apple Guideline** | 2.5.2 — Software Requirements |
| **Reden afwijzing** | De `itms-services://` URL scheme wordt gebruikt voor enterprise OTA app-distributie buiten de App Store. Registratie van dit scheme in een App Store app is niet toegestaan en wordt automatisch gedetecteerd. |
| **Detecteerbaar in** | `Info.plist` — key `CFBundleURLTypes` bevat `itms-services` in `CFBundleURLSchemes`. Ook detecteerbaar via `strings` op de binary (de URL scheme wordt in de binary opgenomen). |
| **Bestand** | `Info.plist` |
| **Aan/uit** | Verwijder `itms-services` uit de CFBundleURLSchemes array |
