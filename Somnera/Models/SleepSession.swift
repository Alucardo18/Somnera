import Foundation

/// In-memory model representing a completed sleep session.
struct SleepSession: Identifiable, Codable {
    let id: UUID
    var startDate: Date
    var endDate: Date
    var snoreEvents: [SnoreEvent]
    var apneaEvents: [ApneaEvent]
    var audioFilePath: String?        // Relative path inside Documents/
    var peakDecibels: Float
    var decibelTimeline: [Float]      // Average dB sampled every 5 seconds

    // MARK: - Computed

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var snoreDurationSeconds: Double {
        snoreEvents.reduce(0) { $0 + $1.durationSeconds }
    }

    var snorePercentage: Double {
        guard duration > 0 else { return 0 }
        return min(100, (snoreDurationSeconds / duration) * 100)
    }

    /// 0–100 score: weighted average of % time snoring + intensity + apnea severity
    var snoreScore: Int {
        let percentWeight = snorePercentage * 0.5                    // Máximo 50 pts por duración
        let dbWeight = Double(peakDecibels / 90.0) * 20              // Máximo 20 pts por volumen
        
        // Cálculo de Severidad de Apnea
        let apneaRiskPoints = apneaEvents.reduce(0.0) { total, event in
            if event.durationSeconds < 15 {
                return total + 2.0  // Leve
            } else if event.durationSeconds < 30 {
                return total + 5.0  // Moderada
            } else {
                return total + 12.0 // Crítica
            }
        }
        
        return min(100, Int(percentWeight + dbWeight + apneaRiskPoints))
    }

    var apneaEventCount: Int { apneaEvents.count }

    var formattedDuration: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    /// Returns the top snoring events (highest confidence * intensity)
    var highlights: [SnoreEvent] {
        snoreEvents
            .sorted { ($0.confidence * Double($0.peakDecibels)) > ($1.confidence * Double($1.peakDecibels)) }
            .prefix(5)
            .sorted { $0.offsetSeconds < $1.offsetSeconds } // Sort back by time
    }

    /// Generates a human-readable summary of the night with high variation (50+ options)
    var insightSummary: String {
        let seed = abs(id.hashValue)
        func pick(_ options: [String]) -> String { options[seed % options.count] }

        // CASE 1: Perfect Night (10 options)
        if apneaEvents.isEmpty && snoreScore < 15 {
            return pick([
                "¡Noche perfecta! Tu respiración fue constante y silenciosa. Tu calidad de descanso es óptima.",
                "Silencio total. No detectamos ronquidos ni interrupciones. Estás recuperando energías al máximo.",
                "Increíble calidad de sueño. Tu sistema respiratorio funcionó sin ningún esfuerzo esta noche.",
                "Dormiste como un tronco. Tu flujo de aire fue impecable y rítmico durante toda la sesión.",
                "Cero ronquidos detectados. Tu garganta y vías aéreas se mantuvieron despejadas por completo.",
                "Una noche de catálogo. Sin ruidos ni pausas; tu cuerpo ha tenido un descanso reparador profundo.",
                "Felicidades, tu respiración fue de manual: silenciosa, rítmica y profunda.",
                "Puntuación de oro. Tu entorno fue tranquilo y tu respiración no mostró signos de estrés.",
                "Descanso de alta calidad. No hubo vibraciones en tus vías aéreas ni interrupciones de oxígeno.",
                "Tu mejor noche hasta ahora. El análisis no muestra nada más que paz y aire fluyendo libremente."
            ])
        }
        
        // CASE 2: Critical Apnea (10 options)
        let hasCriticalApnea = apneaEvents.contains { $0.durationSeconds > 30 }
        if hasCriticalApnea {
            return pick([
                "Detectamos pausas respiratorias prolongadas (>30s). Esto reduce severamente tu oxígeno. Es importante que consultes con un especialista.",
                "Alerta de apnea crítica. Tuviste interrupciones de respiración muy largas. Considera usar una almohada más alta o dormir de lado.",
                "Tu descanso fue interrumpido por pausas de oxígeno peligrosas. No ignores estas señales; tu corazón se esfuerza de más.",
                "La IA identificó episodios de asfixia prolongada. Estas pausas roban energía a tu cerebro; busca asesoría médica.",
                "Pausas respiratorias severas detectadas. Tuviste momentos de más de 30 segundos sin aire. Esto es una señal de alerta importante.",
                "Tu cuerpo luchó por aire en varios momentos críticos. Considera evitar el alcohol antes de dormir para relajar menos los músculos.",
                "Atención: pausas respiratorias de alto riesgo. Tu puntuación refleja el estrés que tu sistema sufrió esta noche.",
                "Detectamos interrupciones de aire que requieren atención. Dormir en posición inclinada podría ayudarte temporalmente.",
                "Episodios de apnea crítica registrados. Tu flujo de aire se detuvo por periodos alarmantes. No dejes pasar este dato.",
                "Alerta de salud: tu respiración se detuvo significativamente. Los ronquidos previos fueron la señal de una obstrucción severa."
            ])
        }
        
        // CASE 3: Moderate Apnea / High Activity (10 options)
        if apneaEventCount > 0 {
            return pick([
                "Tu noche fue movida. Detectamos \(apneaEventCount) pausas respiratorias breves. Tus ronquidos ocuparon el \(Int(snorePercentage))% de la noche.",
                "Notamos \(apneaEventCount) episodios de apnea leve. Aunque son breves, fragmentan tu sueño. Intenta evitar dormir boca arriba.",
                "Respiración irregular detectada. Hubo \(apneaEventCount) momentos donde tu flujo de aire se detuvo. Un humidificador podría ayudarte.",
                "Tu descanso se fragmentó \(apneaEventCount) veces por falta de aire. Esto explica si te sientes cansado al despertar.",
                "Ronquidos seguidos de \(apneaEventCount) pequeñas pausas. Tu cuerpo no está llegando al sueño profundo debido a estas alertas.",
                "Actividad respiratoria inestable. Detectamos \(apneaEventCount) eventos de apnea. Revisa si tienes congestión nasal antes de dormir.",
                "Tuviste \(apneaEventCount) micro-despertares respiratorios. Esto ocurre cuando tu cerebro te obliga a respirar tras una pausa.",
                "Episodios de apnea moderada detectados. Intenta usar tiras nasales para mejorar el flujo de aire inicial.",
                "Tu puntuación bajó debido a \(apneaEventCount) pausas de aire. Aun breves, estas pausas estresan tu sistema cardiovascular.",
                "Patrón de ronquido con apneas leves. Es un buen momento para monitorizar tu peso o posición al dormir."
            ])
        }
        
        // CASE 4: High Snoring Intensity (10 options)
        if snoreScore > 50 {
            return pick([
                "Ronquidos intensos detectados durante gran parte de la noche. Tu nivel de esfuerzo respiratorio fue alto (\(Int(peakDecibels)) dB).",
                "Noche ruidosa. Tus ronquidos alcanzaron picos de \(Int(peakDecibels)) dB. Esto puede indicar una obstrucción nasal o cansancio extremo.",
                "Mucho esfuerzo en tu respiración. Roncaste el \(Int(snorePercentage))% de la noche con alta intensidad. Revisa si tienes congestión.",
                "Tu vibración laríngea fue muy alta hoy. Con \(Int(peakDecibels)) dB, tus vías aéreas están trabajando bajo mucha presión.",
                "Ronquidos persistentes detectados. Aunque no hubo apneas, el volumen sugiere que tus vías están muy estrechas al dormir.",
                "Nivel de ruido elevado: \(Int(peakDecibels)) dB. Intenta cenar más ligero y más temprano para reducir la presión en el diafragma.",
                "Tu garganta mostró mucha resistencia al paso del aire. Roncaste casi la mitad de la noche (\(Int(snorePercentage))%).",
                "Esfuerzo respiratorio notable. Sin apneas, pero con un volumen que fragmenta el descanso de quienes te rodean y el tuyo.",
                "Vibración intensa en las vías respiratorias. Esto suele causar sequedad de garganta e inflamación al despertar.",
                "Análisis sonoro: ronquidos de alto impacto. Tu cuerpo está haciendo un sobreesfuerzo para mantener el flujo de aire."
            ])
        }
        
        // CASE 5: Normal/Stable (10 options)
        return pick([
            "Noche estable con algunos ronquidos aislados. No detectamos riesgos respiratorios importantes.",
            "Descanso balanceado. Hubo algo de ruido, pero tu respiración se mantuvo rítmica la mayor parte del tiempo.",
            "Ronquidos leves detectados. En general, una noche segura y con buen flujo de aire.",
            "Patrón de sueño saludable. Unos pocos ronquidos no afectan tu oxigenación general.",
            "Respiración mayormente tranquila. Los eventos de sonido fueron breves y no interrumpieron tu ritmo.",
            "Buena noche. Tu flujo de aire es consistente. Sigue así, tu higiene de sueño parece estar funcionando.",
            "Análisis positivo: respiración rítmica con ruidos mínimos. Tu descanso ha sido de buena calidad.",
            "Noche tranquila. Solo detectamos pequeñas vibraciones ocasionales que no representan riesgo.",
            "Tu garganta se mantuvo despejada casi toda la noche. Un nivel de ronquido muy aceptable.",
            "Buen descanso. Tu respiración fue estable y eficiente durante las \(formattedDuration) de sesión."
        ])
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date = Date(),
        snoreEvents: [SnoreEvent] = [],
        apneaEvents: [ApneaEvent] = [],
        audioFilePath: String? = nil,
        peakDecibels: Float = 0,
        decibelTimeline: [Float] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.snoreEvents = snoreEvents
        self.apneaEvents = apneaEvents
        self.audioFilePath = audioFilePath
        self.peakDecibels = peakDecibels
        self.decibelTimeline = decibelTimeline
    }

    // MARK: - Mock Data for Previews
    static var mock: SleepSession {
        let start = Date().addingTimeInterval(-28800)
        return SleepSession(
            id: UUID(),
            startDate: start,
            endDate: Date(),
            snoreEvents: [
                SnoreEvent(offsetSeconds: 3600, confidence: 0.9, peakDecibels: 65),
                SnoreEvent(offsetSeconds: 7200, confidence: 0.85, peakDecibels: 72),
                SnoreEvent(offsetSeconds: 15000, confidence: 0.95, peakDecibels: 55)
            ],
            apneaEvents: [
                ApneaEvent(offsetSeconds: 7210, durationSeconds: 15)
            ],
            audioFilePath: nil,
            peakDecibels: 72,
            decibelTimeline: (0..<500).map { _ in Float.random(in: 10...75) }
        )
    }
}
