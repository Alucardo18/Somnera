# 🎙️ Somnera — State-of-the-Art Sleep Diagnostics

[![Version](https://img.shields.io/badge/Version-2.0.0-blue.svg)](https://github.com/Alucardo18/Somnera)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-black.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Somnera es la cumbre de la tecnología de monitoreo de sueño en iOS. Diseñada para transformar el iPhone en un laboratorio de diagnóstico clínico personal, Somnera utiliza **fusión sensorial avanzada** y **aprendizaje profundo** para detectar ronquidos y apnea del sueño con una precisión sin precedentes, manteniendo la privacidad absoluta mediante un procesamiento 100% local (Edge AI).

![Somnera Dashboard](Docs/Assets/dashboard_mockup.png)

## 🌌 Tecnología de Vanguardia

Somnera integra un stack tecnológico de nivel industrial para ofrecer resultados precisos y confiables:

### 🧠 Sentinel V2: El Motor de Fusión Sensorial
A diferencia de las aplicaciones convencionales que dependen únicamente del audio, nuestro motor **Sentinel V2** utiliza una validación cruzada tripartita:
- **Acoustic Energy Analysis**: Monitoreo en tiempo real de la energía RMS del audio para detectar caídas críticas.
- **Actigrafía de Alta Frecuencia**: Integración con **CoreMotion** (10Hz) para validar la inmovilidad física durante episodios de apnea, eliminando falsos positivos.
- **Recovery Gasp Detection**: Identificación inteligente de picos de energía post-apnea mediante modelos de clasificación acústica.

### 🔬 Procesamiento de Señal y AI Local
- **Core ML & SoundAnalysis**: Implementación de un modelo de red neuronal convolucional (`SomneraClassifier`) optimizado para el Apple Neural Engine, capaz de identificar patrones de ronquidos en milisegundos.
- **DSP Avanzado (vDSP)**: Uso intensivo del framework **Accelerate** para filtrado bandpass y análisis espectral con consumo energético mínimo.
- **Audio Pipeline v2**: Grabación en formato **.caf (PCM Float32)** con amplificación dinámica x8 para una claridad diagnóstica superior durante la reproducción.

### 💎 Diseño Premium & UX
- **Glassmorphism Design System**: Una interfaz inmersiva basada en materiales ultra-delgados, gradientes dinámicos y micro-animaciones que reducen la fricción cognitiva durante el uso nocturno.
- **HealthKit Synergy**: Sincronización bidireccional con Apple Health, permitiendo una visión holística de la salud respiratoria del usuario.

![Sentinel V2 Analysis](Docs/Assets/sentinel_mockup.png)

## 🛠️ Stack Tecnológico

- **Core**: Swift 5.9 + SwiftUI (MVVM Architecture).
- **IA**: Core ML, SoundAnalysis, Neural Engine optimization.
- **Hardware**: CoreMotion (Accelerometer), AVFoundation (AVAudioEngine).
- **Health**: HealthKit Integration.
- **DevOps**: XcodeGen (Reproducible project management).

## 🚀 Instalación y Desarrollo

Este proyecto utiliza **XcodeGen** para una gestión de dependencias y configuración de proyecto limpia y determinista.

```bash
# 1. Instalar XcodeGen
brew install xcodegen

# 2. Generar el proyecto
xcodegen generate

# 3. Abrir en Xcode
open Somnera.xcodeproj
```

## ⚖️ Licencia

Este proyecto está bajo la **Licencia MIT**. Ver el archivo [LICENSE](LICENSE) para más detalles.

---
Desarrollado con ❤️ y tecnología de punta por **Emmanuel Gonzalez**
