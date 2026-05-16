import Foundation

struct SynergyMetrics {
    var spO2: Double?
    var heartRate: Double?
    var respiratoryRate: Double?
    var snoreScore: Double
    
    var synergyScore: Double {
        var score: Double = 0
        var totalWeight: Double = 0
        
        // SpO2 (Weight: 40%)
        if let spo2 = spO2 {
            // Un valor de 95-100 es perfecto.
            let normalizedSpO2 = spo2 > 1.0 ? spo2 : spo2 * 100.0
            let o2Score = normalizedSpO2 >= 95 ? 100 : (normalizedSpO2 >= 90 ? 80 : 50)
            score += Double(o2Score) * 0.40
            totalWeight += 0.40
        }
        
        // Snore/Apnea (Weight: 30%)
        // snoreScore ya viene penalizado por eventos de apnea en el modelo SleepSession
        score += snoreScore * 0.30
        totalWeight += 0.30
        
        // Heart Rate (Weight: 15%)
        if let hr = heartRate {
            var hrScore: Double = 0
            if hr >= 40 && hr <= 70 { hrScore = 100 }
            else if hr > 70 && hr <= 85 { hrScore = 80 }
            else { hrScore = 50 }
            score += hrScore * 0.15
            totalWeight += 0.15
        }
        
        // Respiratory Rate (Weight: 15%)
        if let rr = respiratoryRate {
            var rrScore: Double = 0
            if rr >= 12 && rr <= 20 { rrScore = 100 }
            else if rr > 20 && rr <= 25 { rrScore = 70 }
            else { rrScore = 40 }
            score += rrScore * 0.15
            totalWeight += 0.15
        }
        
        return totalWeight > 0 ? (score / totalWeight) : snoreScore
    }
}
