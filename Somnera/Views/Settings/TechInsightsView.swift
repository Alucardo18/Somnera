import SwiftUI

struct TechInsightsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.somBackground.ignoresSafeArea()
                
                // Fondo decorativo
                Circle()
                    .fill(Color.somAccent.opacity(0.1))
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerSection
                        
                        VStack(spacing: 20) {
                            TechCard(
                                title: "Sentinel V2",
                                icon: "sensor.tag.radiowaves.forward.fill",
                                color: .somSafe,
                                description: "Fusión de sensores que combina el acelerómetro con el micrófono. Detecta micro-vibraciones en el colchón para confirmar eventos respiratorios y filtrar ruidos ambientales externos."
                            )
                            
                            TechCard(
                                title: "Echo-Location Pasivo",
                                icon: "waveform.and.mic",
                                color: .somAccent,
                                description: "Analiza el 'Crest Factor' y la reverberación de la habitación. Somnera estima la distancia entre tú y el iPhone para calibrar la sensibilidad del análisis de sonido automáticamente."
                            )
                            
                            TechCard(
                                title: "Core ML & SoundAnalysis",
                                icon: "brain.head.profile",
                                color: .somWarning,
                                description: "Redes neuronales convolucionales ejecutándose 100% en el dispositivo. Identificamos patrones de ronquido y apnea sin enviar ni un solo bit de audio a la nube."
                            )
                            
                            TechCard(
                                title: "DSP Filter Pipeline",
                                icon: "wave.3.right",
                                color: .somInfo,
                                description: "Procesamiento Digital de Señales en tiempo real. Aplicamos filtros pasa-altos y normalización dinámica para aislar la frecuencia fundamental del ronquido humano del ruido de fondo."
                            )
                        }
                        .padding(.horizontal)
                        
                        Text("Somnera Intelligence Suite v2.0.0")
                            .font(.caption2.monospaced())
                            .foregroundColor(.somTextSecondary)
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Tecnología")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.somAccent)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 40))
                .foregroundColor(.somAccent)
                .padding()
                .background(Circle().fill(Color.somAccent.opacity(0.1)))
            
            Text("Ingeniería de Vanguardia")
                .font(.title2.bold())
                .foregroundColor(.somTextPrimary)
            
            Text("Privacidad absoluta con potencia de grado clínico.")
                .font(.subheadline)
                .foregroundColor(.somTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 30)
    }
}

struct TechCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.somTextPrimary)
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.somTextSecondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.somSurface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TechInsightsView()
}
