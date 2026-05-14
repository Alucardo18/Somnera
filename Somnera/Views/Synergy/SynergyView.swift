import SwiftUI

struct SynergyView: View {
    @AppStorage("somnera_synergy_onboarded") var onboarded = false
    @AppStorage("somnera_healthkit_enabled") var healthKitEnabled = false
    @State private var showIntro = false
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.somBackground.ignoresSafeArea()
                
                if !onboarded {
                    emptyState
                } else {
                    activeState
                }
            }
            .navigationTitle("Sinergia")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !onboarded {
                    showIntro = true
                }
            }
            .fullScreenCover(isPresented: $showIntro) {
                SynergyIntroView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 25) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(Color.somAccent.gradient)
            
            VStack(spacing: 12) {
                Text("Desbloquea el Potencial")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Conecta tus dispositivos de salud para un análisis de grado clínico.")
                    .font(.subheadline)
                    .foregroundColor(.somTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Ver Introducción") {
                showIntro = true
            }
            .font(.headline)
            .foregroundColor(.somAccent)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.somAccent.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var activeState: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Estado de Conexión (Convertido en Botón de Navegación)
                if !healthKitEnabled {
                    Button {
                        appState.highlightHealthSetting = true
                        appState.currentTab = .settings
                    } label: {
                        ConnectionStatusCard()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Próximamente: Análisis Bio-Informáticos
                VStack(alignment: .leading, spacing: 16) {
                    Text("Análisis Biométrico")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        SynergyFeatureRow(
                            icon: "heart.text.square",
                            title: "Correlación de Pulso",
                            status: "Pendiente de Sesión",
                            description: "Visualiza picos de estrés cardíaco alineados con tus ronquidos."
                        )
                        
                        SynergyFeatureRow(
                            icon: "lungs",
                            title: "Oxigenación SpO2",
                            status: "Configurar HealthKit",
                            description: "Importa caídas de oxígeno para validar eventos de apnea."
                        )
                        
                        SynergyFeatureRow(
                            icon: "figure.run",
                            title: "Impacto de Actividad",
                            status: "Listo",
                            description: "Analiza cómo tu ejercicio diario mejora tu respiración nocturna."
                        )
                    }
                }
                .padding(.horizontal)
                
                // Info Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Sinergia Somnera", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.somAccent)
                    
                    Text("Los algoritmos de Somnera se vuelven un 40% más confiables cuando se combinan con la frecuencia cardíaca en reposo.")
                        .font(.caption)
                        .foregroundColor(.somTextSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.somSurface.opacity(0.5))
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .padding(.top)
            .animation(.spring(), value: healthKitEnabled)
        }
    }
}

struct ConnectionStatusCard: View {
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estado del Ecosistema")
                    .font(.caption.bold())
                    .foregroundColor(.somTextSecondary)
                Text("Listo para Sincronizar")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Spacer()
            
            Image(systemName: "applewatch")
                .font(.title)
                .foregroundColor(.somAccent)
                .padding(12)
                .background(Circle().fill(Color.somAccent.opacity(0.1)))
        }
        .padding(20)
        .background(Color.somSurface)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

struct SynergyFeatureRow: View {
    let icon: String
    let title: String
    let status: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text(status)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.somAccent.opacity(0.2))
                    .foregroundColor(.somAccent)
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.somTextSecondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    SynergyView(viewModel: DashboardViewModel())
}
