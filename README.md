# 🎙️ SOMNERA — Guía del Proyecto

> Leer antes de hacer cualquier cambio al código o configuración.

## Setup Rápido

```bash
# Instalar XcodeGen (una vez)
brew install xcodegen

# Regenerar proyecto Xcode (cada vez que cambies project.yml)
cd /Users/emmanuel/Documents/ANTIGRAVITY/SNORE-APP
xcodegen generate
open Somnera.xcodeproj
```

## Reglas que no se rompen

| Regla | Razón |
|-------|-------|
| El tap de AVAudioEngine usa **formato nativo** del hardware | Usar otro formato → crash inmediato |
| `Info.plist` se define en **`project.yml`** | XcodeGen lo sobreescribe en cada generación |
| `SNAudioStreamAnalyzer` recibe el formato **convertido** (16kHz) | Si recibe el nativo, las clasificaciones son incorrectas |
| No editar `Somnera.xcodeproj` directamente | Se sobreescribe con `xcodegen generate` |
| Probar background audio en **dispositivo físico** | El simulador no reproduce el comportamiento real |

## Arquitectura en 30 segundos

```
Micrófono
  → AudioCaptureService (tap nativo + AVAudioConverter 16kHz)
    → DSPFilter (bandpass 80-2500Hz + VAD gate 38dB)
      → SnoreDetectionService (SoundAnalysis + Core ML)
      → ApneaDetectionService (silencio ≥ 10s)
        → RecordingViewModel @MainActor (UI + Storage)
          → SessionStorageService (JSON, 7 sesiones rolling)
          → HealthKitService (Apple Health sync)
```

## Stack

- **Swift 5.9** · **SwiftUI** · **iOS 17+** · **iPhone only**
- **AVFoundation** — captura audio
- **Accelerate/vDSP** — DSP eficiente en hardware
- **SoundAnalysis** — clasificación on-device
- **Core ML** — modelo `SomneraClassifier.mlmodel`
- **HealthKit** — exportar datos de sueño
- **JSON Codable** — persistencia local (no Core Data)
- **XcodeGen** — gestión del proyecto Xcode

## Conocimiento completo

Ver: `/Users/emmanuel/.gemini/antigravity/skills/RoncoSkill.md`
