import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws -> Bool {
        guard isAvailable else {
            throw HKError(.errorHealthDataUnavailable)
        }
        
        // Tipos de datos que queremos LEER (Read)
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]
        
        // Tipos de datos que queremos ESCRIBIR (Write)
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            return true
        } catch {
            print("[Somnera] ❌ Error solicitando autorización de HealthKit: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAuthorizationStatus() -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
    }
    
    // MARK: - Writing Data
    
    func saveSleepSession(start: Date, end: Date, apneaEventCount: Int, avgStability: Double) async throws {
        guard getAuthorizationStatus() == .sharingAuthorized else { return }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let metadata: [String: Any] = [
            "SomneraApneaEvents": apneaEventCount,
            "SomneraBreathingStability": avgStability
        ]
        
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleep.rawValue,
            start: start,
            end: end,
            metadata: metadata
        )
        
        try await healthStore.save(sample)
        print("[Somnera] ✅ Sesión de sueño guardada en HealthKit (\(apneaEventCount) apneas)")
    }
    
    func saveApneaEvent(at date: Date, duration: Double) async throws {
        guard getAuthorizationStatus() == .sharingAuthorized else { return }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let start = date.addingTimeInterval(-duration)
        
        // Guardamos la apnea como un periodo de "despierto" o interrupción del sueño
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.awake.rawValue,
            start: start,
            end: date,
            metadata: ["Notes": "Evento de Apnea detectado por Somnera"]
        )
        
        try await healthStore.save(sample)
        print("[Somnera] ✅ Evento de apnea guardado en HealthKit")
    }
}
