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
                                title: "Digital Twin Anatómico",
                                icon: "person.fill.viewfinder",
                                color: .somAccent,
                                description: "Nuestra IA mapea en tiempo real el origen físico del ronquido (Nasal, Palatal o Lingual) mediante análisis espectral avanzado, creando un gemelo digital de tu vía aérea para un diagnóstico preciso."
                            )
                            
                            TechCard(
                                title: "Sentinel V2 & Crest Factor",
                                icon: "shield.checkered",
                                color: .somSafe,
                                description: "Algoritmo de vanguardia que aísla la energía percusiva del ronquido humano. Ignoramos inteligentemente ruidos constantes como ventiladores o aire acondicionado mediante el cálculo dinámico del factor de cresta."
                            )
                            
                            TechCard(
                                title: "Neural Snore Detection",
                                icon: "brain.head.profile",
                                color: .somWarning,
                                description: "Modelos de Machine Learning optimizados para el chip Apple Silicon. Clasificamos eventos respiratorios con precisión clínica, ejecutando redes neuronales convolucionales 100% offline."
                            )
                            
                            TechCard(
                                title: "Pipeline DSP Médico",
                                icon: "waveform.path.ecg",
                                color: .somInfo,
                                description: "Procesamiento de señal estandarizado en una escala de 0-90 dB. Generamos un hipnograma de respiración de alta resolución (1s) para visualizar la profundidad y el esfuerzo de cada ciclo respiratorio."
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
