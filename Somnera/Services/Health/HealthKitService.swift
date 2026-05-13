import HealthKit

/// Manages all HealthKit read/write operations for Somnera.
final class HealthKitService {

    private let store = HKHealthStore()

    private var sleepType: HKCategoryType {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    }

    // MARK: - Authorization

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        let share: Set<HKSampleType> = [sleepType]
        let read:  Set<HKObjectType> = [sleepType]
        try await store.requestAuthorization(toShare: share, read: read)
    }

    // MARK: - Write Sleep Session

    /// Writes an inBed + asleepUnspecified sample for the session duration.
    func saveSleepSession(start: Date, end: Date, apneaEventCount: Int, avgStability: Double) async throws {
        guard isAvailable else { return }

        let tz = TimeZone.current.identifier
        let metadata: [String: Any] = [
            HKMetadataKeyTimeZone: tz,
            "SomneraApneaCount": apneaEventCount,
            "SomneraAvgStability": String(format: "%.2f", avgStability)
        ]

        let inBed = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: start, end: end,
            metadata: metadata
        )

        let asleep = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: start, end: end,
            metadata: metadata
        )

        try await store.save([inBed, asleep])
    }

    /// Records a specific apnea event as a momentary sleep interruption.
    func saveApneaEvent(at timestamp: Date, duration: TimeInterval) async throws {
        guard isAvailable else { return }
        
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.awake.rawValue,
            start: timestamp,
            end: timestamp.addingTimeInterval(duration),
            metadata: ["SomneraEventNote": "Potential Apnea Detected"]
        )
        
        try await store.save(sample)
    }

    // MARK: - Read Recent Sessions

    /// Returns HK sleep samples for the last 7 days.
    func fetchRecentSleepSamples() async throws -> [HKCategorySample] {
        guard isAvailable else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
                }
            }
            store.execute(query)
        }
    }
}
