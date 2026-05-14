import Foundation

/// Local AI service that analyzes sleep patterns to provide human-readable insights.
/// This acts as the "brain" of Somnera, interpreting raw data into actionable reports.
final class SessionAnalyticsService {
    static let shared = SessionAnalyticsService()
    
    struct DiagnosticReport {
        let snoreInsight: String
        let apneaInsight: String
        let overallHealth: String
    }
    
    struct WeeklyReport {
        let averageScore: Int
        let scoreTrend: Int // Difference from previous period
        let mainInsight: String
        let trendDescription: String
        let recommendation: String
        let isImproving: Bool
    }
    
    func generateReport(for session: SleepSession) -> DiagnosticReport {
        let snoreMsg = analyzeSnores(session)
        let apneaMsg = analyzeApneas(session)
        let healthMsg = summarizeOverall(session)
        
        return DiagnosticReport(
            snoreInsight: snoreMsg,
            apneaInsight: apneaMsg,
            overallHealth: healthMsg
        )
    }
    
    func generateWeeklyReport(sessions: [SleepSession]) -> WeeklyReport {
        guard !sessions.isEmpty else {
            return WeeklyReport(
                averageScore: 0,
                scoreTrend: 0,
                mainInsight: "Sin Datos",
                trendDescription: "Aún no hay suficientes sesiones para generar un análisis.",
                recommendation: "Comienza tu primera grabación esta noche.",
                isImproving: true
            )
        }
        
        // Split sessions into current week and previous week
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now)!
        
        let currentWeekSessions = sessions.filter { $0.startDate >= sevenDaysAgo }
        let previousWeekSessions = sessions.filter { $0.startDate >= fourteenDaysAgo && $0.startDate < sevenDaysAgo }
        
        let currentAvg = currentWeekSessions.isEmpty ? 0 : 
            currentWeekSessions.map { $0.snoreScore }.reduce(0, +) / currentWeekSessions.count
            
        let previousAvg = previousWeekSessions.isEmpty ? currentAvg : 
            previousWeekSessions.map { $0.snoreScore }.reduce(0, +) / previousWeekSessions.count
            
        let trend = currentAvg - previousAvg
        
        // 1. Analyze Anatomical Predominance
        let n = Double(currentWeekSessions.count)
        let avgNasal = currentWeekSessions.map { $0.nasalIntensity }.reduce(0, +) / (n > 0 ? n : 1.0)
        let avgPalatal = currentWeekSessions.map { $0.palatalIntensity }.reduce(0, +) / (n > 0 ? n : 1.0)
        let avgLingual = currentWeekSessions.map { $0.lingualIntensity }.reduce(0, +) / (n > 0 ? n : 1.0)
        
        var anatomicalMsg = ""
        if avgNasal > 0.3 { anatomicalMsg = "Tu patrón es predominantemente nasal, lo que sugiere congestión." }
        else if avgLingual > 0.3 { anatomicalMsg = "Detectamos obstrucción lingual, común al dormir boca arriba." }
        else { anatomicalMsg = "Tu respiración es mayormente palatal y estable." }
        
        // 2. Postural Analysis (Sentinel V2)
        let sessionsWithTilt = currentWeekSessions.filter { !$0.tiltTimeline.isEmpty }
        var posturalTip = "Mantén tu iPhone en el colchón para análisis postural."
        
        if !sessionsWithTilt.isEmpty {
            // Check if snore events happen more at low tilt (< 25 degrees = boca arriba)
            let flatSnores = sessionsWithTilt.reduce(0) { count, session in
                // Simplified heuristic: if avg tilt is low, assume supine
                let avgTilt = session.tiltTimeline.reduce(0, +) / Double(session.tiltTimeline.count)
                return count + (avgTilt < 25.0 ? session.snoreEvents.count : 0)
            }
            if flatSnores > 10 {
                posturalTip = "Evita dormir boca arriba; tus ronquidos aumentan en esa posición."
            } else {
                posturalTip = "Tu posición lateral está ayudando a mantener tus vías abiertas."
            }
        }
        
        let isImproving = trend >= 0
        let trendText = trend == 0 ? "Estable" : "\(abs(trend))% \(isImproving ? "mejor" : "menor") que la semana pasada"
        
        return WeeklyReport(
            averageScore: currentAvg,
            scoreTrend: trend,
            mainInsight: isImproving ? "Tendencia de Mejora" : "Atención Necesaria",
            trendDescription: "Tu puntuación promedio es de \(currentAvg) pts. \(trendText).",
            recommendation: "\(anatomicalMsg) \(posturalTip)",
            isImproving: isImproving
        )
    }
    
    // MARK: - Snore Analysis
    
    private func analyzeSnores(_ session: SleepSession) -> String {
        let count = session.snoreEvents.count
        let score = session.snoreScore
        
        if count == 0 {
            return "Tu noche fue silenciosa. No se detectaron patrones de ronquido significativos."
        }
        
        if score >= 70 {
            return "Eficiencia respiratoria alta. Ronquidos mínimos detectados, lo cual es ideal para un descanso reparador."
        } else if score >= 40 {
            return "Patrón de ronquido moderado. Se observan ráfagas rítmicas que podrían estar relacionadas con tu posición al dormir."
        } else {
            return "Salud respiratoria comprometida. Ronquido persistente de alta intensidad que sugiere un descanso de baja calidad."
        }
    }
    
    // MARK: - Apnea Analysis
    
    private func analyzeApneas(_ session: SleepSession) -> String {
        let count = session.apneaEvents.count
        let severes = session.apneaEvents.filter { $0.severity == .severe }.count
        
        if count == 0 {
            return "Respiración excelente. No se detectaron interrupciones en tu flujo de aire."
        }
        
        if count < 5 {
            return "Se detectaron pausas respiratorias mínimas. Son eventos aislados comunes que no suelen representar un riesgo."
        } else if severes > 0 {
            return "Patrón respiratorio irregular detectado con eventos de larga duración. Se recomienda compartir este reporte con un especialista."
        } else {
            return "Se observaron múltiples pausas breves. Somnera monitoreará si esto se convierte en una tendencia constante."
        }
    }
    
    // MARK: - Overall Summary
    
    private func summarizeOverall(_ session: SleepSession) -> String {
        if session.snoreScore >= 80 && session.apneaEvents.isEmpty {
            return "Salud Respiratoria Óptima"
        } else if session.snoreScore < 40 || !session.apneaEvents.isEmpty {
            return "Atención Sugerida"
        } else {
            return "Calidad de Sueño Media"
        }
    }
}
