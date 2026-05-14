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
