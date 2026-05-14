import Foundation
import SwiftData

/// In-memory model representing a completed sleep session.
@Model
final class SleepSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \SnoreEvent.session) 
    var snoreEvents: [SnoreEvent] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ApneaEvent.session) 
    var apneaEvents: [ApneaEvent] = []
    
    var audioFilePath: String?        // Relative path inside Documents/
    var peakDecibels: Float
    var decibelTimeline: [Float]      // Average dB sampled every 5 seconds
    var surfaceType: String?          // "bed" or "nightstand"
    
    // MARK: - Sentinel V2 Telemetry
    var snrTimeline: [Double] = []
    var stabilityTimeline: [Double] = []
    var tiltTimeline: [Double] = []
    var motionTimeline: [Double] = []
    
    // MARK: - Spectral Analysis (Digital Twin)
    var nasalIntensity: Double = 0.0
    var palatalIntensity: Double = 0.0
    var lingualIntensity: Double = 0.0

    // MARK: - Init
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date = Date(),
        snoreEvents: [SnoreEvent] = [],
        apneaEvents: [ApneaEvent] = [],
        audioFilePath: String? = nil,
        peakDecibels: Float = 0,
        decibelTimeline: [Float] = [],
        surfaceType: String? = nil,
        nasalIntensity: Double = 0.0,
        palatalIntensity: Double = 0.0,
        lingualIntensity: Double = 0.0,
        snrTimeline: [Double] = [],
        stabilityTimeline: [Double] = [],
        tiltTimeline: [Double] = [],
        motionTimeline: [Double] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.snoreEvents = snoreEvents
        self.apneaEvents = apneaEvents
        self.audioFilePath = audioFilePath
        self.peakDecibels = peakDecibels
        self.decibelTimeline = decibelTimeline
        self.surfaceType = surfaceType
        self.nasalIntensity = nasalIntensity
        self.palatalIntensity = palatalIntensity
        self.lingualIntensity = lingualIntensity
        self.snrTimeline = snrTimeline
        self.stabilityTimeline = stabilityTimeline
        self.tiltTimeline = tiltTimeline
        self.motionTimeline = motionTimeline
    }

    // MARK: - Computed Properties (Moved from Struct)

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var snoreDurationSeconds: Double {
        snoreEvents.reduce(0) { $0 + $1.durationSeconds }
    }

    var snorePercentage: Double {
        guard duration > 0 else { return 0 }
        let totalSnoreSeconds = snoreEvents.reduce(0.0) { $0 + $1.durationSeconds }
        return min(100, (totalSnoreSeconds / duration) * 100)
    }

    var snoreScore: Int {
        // Calculate penalties only based on validated respiratory events.
        // Ambient noise (peakDecibels) is ignored if no snores are detected.
        let maxSnoreDB = snoreEvents.map { $0.peakDecibels }.max() ?? 0
        
        let percentWeight = snoreEvents.isEmpty ? 0 : (snorePercentage * 0.5)
        let dbWeight = snoreEvents.isEmpty ? 0 : (Double(max(0, maxSnoreDB) / 90.0) * 20)
        
        let apneaRiskPoints = apneaEvents.reduce(0.0) { total, event in
            if event.durationSeconds < 15 { return total + 2.0 }
            else if event.durationSeconds < 30 { return total + 5.0 }
            else { return total + 12.0 }
        }
        
        let eventDensityPenalty = min(10.0, Double(snoreEvents.count) * 0.5)
        let totalPenalty = Int(percentWeight + dbWeight + apneaRiskPoints + eventDensityPenalty)
        return max(0, 100 - totalPenalty)
    }

    var apneaEventCount: Int { apneaEvents.count }

    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        
        if h > 0 { return "\(h)h \(m)m" }
        else if m > 0 { return "\(m)m \(s)s" }
        else { return "\(s)s" }
    }

    var highlights: [SnoreEvent] {
        snoreEvents
            .sorted { ($0.confidence * Double($0.peakDecibels)) > ($1.confidence * Double($1.peakDecibels)) }
            .prefix(5)
            .sorted { $0.offsetSeconds < $1.offsetSeconds }
    }

    var insightSummary: String {
        let seed = abs(id.hashValue)
        func pick(_ options: [String]) -> String { options[seed % options.count] }

        let baseMessage: String
        // NEW LOGIC: High score (85+) is perfect
        if apneaEvents.isEmpty && snoreScore >= 85 {
            baseMessage = pick(["¡Noche perfecta! Tu respiración fue constante y silenciosa.", "Salud respiratoria óptima. No detectamos ronquidos ni interrupciones."])
        } else if apneaEvents.contains(where: { $0.durationSeconds > 30 }) {
            baseMessage = pick(["Alerta: Detectamos pausas respiratorias prolongadas (>30s).", "Riesgo de apnea crítica detectado."])
        } else if apneaEventCount > 0 {
            baseMessage = pick(["Tu respiración tuvo interrupciones. Detectamos \(apneaEventCount) pausas respiratorias."])
        } else if snoreScore < 50 {
            baseMessage = pick(["Ronquidos intensos detectados. Tu eficiencia respiratoria fue baja anoche."])
        } else {
            baseMessage = pick(["Noche estable con algunos ronquidos aislados."])
        }
        
        var finalSummary = baseMessage
        if let surface = surfaceType {
            if surface == "nightstand" {
                finalSummary += "\n\n💡 Tip: El iPhone estaba en una superficie rígida. Colócalo sobre el colchón para mayor precisión."
            } else if surface == "bed" {
                finalSummary += "\n\n✅ Sentinel V2 activado: Precisión máxima detectada."
            }
        }
        return finalSummary
    }

    // MARK: - Mock Data
    static var mock: SleepSession {
        let start = Date().addingTimeInterval(-28800)
        return SleepSession(
            id: UUID(),
            startDate: start,
            endDate: Date(),
            snoreEvents: [],
            apneaEvents: [],
            audioFilePath: nil,
            peakDecibels: 72,
            decibelTimeline: (0..<500).map { _ in Float.random(in: 10...75) },
            surfaceType: "bed",
            nasalIntensity: 0.45,
            palatalIntensity: 0.15,
            lingualIntensity: 0.10
        )
    }
}
