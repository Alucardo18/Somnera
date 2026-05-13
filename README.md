# 🎙️ Somnera — State-of-the-Art Sleep Diagnostics

[![Version](https://img.shields.io/badge/Version-2.1.0-blue.svg)](https://github.com/Alucardo18/Somnera)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-black.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Somnera es la cumbre de la tecnología de monitoreo de sueño en iOS. Diseñada para transformar el iPhone en un laboratorio de diagnóstico clínico personal, Somnera utiliza **fusión sensorial avanzada** y **aprendizaje profundo** para detectar ronquidos y apnea del sueño con una precisión sin precedentes.

<p align="center">
  <img src="Docs/Assets/dashboard_mockup.png" width="800" alt="Somnera Hero Dashboard">
</p>

## 🌌 Ingeniería de Vanguardia

Somnera integra un stack tecnológico de nivel industrial para ofrecer resultados precisos y confiables:

### 🧠 Sentinel V2: El Motor de Fusión Sensorial
Nuestro motor **Sentinel V2** implementa una validación cruzada avanzada para garantizar la integridad de los datos:
- **Crest Factor Noise Gating**: Algoritmo inteligente que analiza la relación pico-promedio de la señal para aislar la energía percusiva del ronquido humano, ignorando inteligentemente el ruido blanco de ventiladores o aire acondicionado.
- **Actigrafía de Alta Frecuencia**: Sincronización con **CoreMotion** (10Hz) para validar la inmovilidad física durante episodios de apnea, eliminando falsos positivos por movimiento ambiental.
- **Neural Snore Classification**: Identificación de eventos respiratorios mediante redes neuronales convolucionales optimizadas para el **Apple Neural Engine**.

### 🔬 Procesamiento de Señal (Edge AI)
- **Digital Twin 3D**: Reconstrucción anatómica de la vía aérea en tiempo real. Mediante análisis espectral de frecuencia (FFT), Somnera identifica si la obstrucción es **Nasal, Palatal o Lingual**, permitiendo un diagnóstico personalizado.
- **PSG Clinical Timeline**: Visualización de grado médico con resolución de **1 segundo** y una escala estandarizada de **0-90 dB**, permitiendo observar la profundidad y el esfuerzo de cada ciclo respiratorio.

<p align="center">
  <img src="Docs/Assets/recording_mockup.png" width="45%" />
  <img src="Docs/Assets/sessions_mockup.png" width="45%" />
</p>

### 💎 Diseño Premium & Insights
- **Sleep Galaxy Explorer**: Una interfaz inmersiva basada en materiales ultra-delgados y el concepto de "planetas del sueño" para navegar por el historial de sesiones sin fricción cognitiva.
- **Weekly Clinical Insights**: Análisis de tendencias que sintetiza el progreso respiratorio semanal y ofrece recomendaciones basadas en patrones de obstrucción detectados.

<p align="center">
  <img src="Docs/Assets/sentinel_mockup.png" width="800" alt="Sentinel V2 Analysis">
</p>

## 🛠️ Stack Tecnológico

- **Core**: Swift 5.9 + SwiftUI (MVVM Architecture).
- **IA**: Core ML, SoundAnalysis, Neural Engine Optimization.
- **Hardware**: CoreMotion (Accelerometer), AVAudioEngine (Low-latency audio pipeline).
- **Storage**: SwiftData para persistencia local de grado clínico.
- **Design**: Glassmorphism & Dynamic Motion Design.

## 🚀 Instalación

Este proyecto utiliza **XcodeGen** para una gestión de proyecto limpia y determinista.

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
