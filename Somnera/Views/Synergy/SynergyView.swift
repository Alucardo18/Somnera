import SwiftUI

struct SynergyView: View {
    @AppStorage("somnera_synergy_onboarded") var onboarded = false
    @AppStorage("somnera_healthkit_enabled") var healthKitEnabled = false
    @State private var showIntro = false
    @State private var showDetails = false
    @State private var showGuide = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
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
            .fullScreenCover(isPresented: $showGuide) {
                SynergyGuideView()
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
            VStack(spacing: 30) {
                // Header Interactivo
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Análisis de Bio-Arquitectura")
                            .font(.caption.bold())
                            .foregroundColor(.somTextSecondary)
                            .tracking(1)
                    }
                    Spacer()
                    
                    Button {
                        showGuide = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "book.fill")
                            Text("Guía de Lectura")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.somAccent.opacity(0.1))
                        .foregroundColor(.somAccent)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                
                // Estado de Conexión
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
                
                // Topografía de la Conciencia
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Topografía de la Conciencia")
                                .font(.headline)
                            Button {
                                alertTitle = "Topografía de la Conciencia"
                                alertMessage = "Mapea las fases del sueño y la actividad cerebral para cuantificar la consolidación de la memoria y la intensidad de los sueños, transformando los ciclos REM en métricas de recuperación cognitiva."
                                showAlert = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.somAccent)
                            }
                        }
                        Text("Simulación bio-estocástica de consolidación de memoria y actividad neuronal.")
                            .font(.caption)
                            .foregroundColor(.somTextSecondary)
                    }
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    
                    SleepTopographyView(session: viewModel.lastSession)
                }
                
                // Hélice de Sinergia
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Hélice de Sinergia")
                            .font(.headline)
                        Button {
                            alertTitle = "Hélice de Sinergia"
                            alertMessage = "Coteja y sincroniza los registros de audio con las métricas de HealthKit, validando eventos respiratorios mediante el cruce de datos biométricos precisos."
                            showAlert = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.somAccent)
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    
                    SynergyHelixView(session: viewModel.lastSession)
                }
                
                // Biosfera de Homeostasis (NUEVO)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Biosfera de Homeostasis")
                            .font(.headline)
                        Button {
                            alertTitle = "Biosfera de Homeostasis"
                            alertMessage = "Representación holográfica de tu balance fisiológico nocturno. El volumen de la esfera indica la carga de sueño, la simetría refleja la estabilidad respiratoria y la pulsación corresponde a tu frecuencia cardíaca real."
                            showAlert = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.somAccent)
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    
                    VitalityCrucibleView(session: viewModel.lastSession)
                }
                
                // Info Card (Entry point to details)
                Button {
                    showDetails = true
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Sinergia Somnera", systemImage: "info.circle.fill")
                                .font(.headline)
                                .foregroundColor(.somAccent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.somAccent.opacity(0.5))
                        }
                        
                        Text("Descubre cómo tu Apple Watch transforma los datos de audio en diagnósticos biológicos precisos.")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(24)
                    .background(Color.somSurface)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.somAccent.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
            .padding(.top)
            .animation(.spring(), value: healthKitEnabled)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showDetails) {
            SynergyDetailView()
        }
    }
}

struct SynergyEcosystemGraphic: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.somAccent.opacity(0.1), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // Icons orbiting
                Group {
                    SynergyIconCircle(icon: "heart.fill", color: .somAccent, angle: -45)
                    SynergyIconCircle(icon: "lungs.fill", color: .somSafe, angle: 180)
                    SynergyIconCircle(icon: "applewatch", color: .white, angle: 90)
                }
                
                // Central Somnera Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.somAccent)
                    .padding(25)
                    .background(Circle().fill(Color.somSurface))
                    .shadow(color: .somAccent.opacity(0.3), radius: 20)
            }
            .frame(height: 220)
            
            Text("Tu ecosistema está listo.")
                .font(.caption.bold())
                .foregroundColor(.somTextSecondary)
                .tracking(2)
                .textCase(.uppercase)
        }
        .padding(.vertical)
    }
}

struct SynergyIconCircle: View {
    let icon: String
    let color: Color
    let angle: Double
    
    var body: some View {
        Image(systemName: icon)
            .font(.caption)
            .foregroundColor(color)
            .padding(10)
            .background(Circle().fill(Color.somSurface))
            .offset(x: 100 * cos(angle * .pi / 180), y: 100 * sin(angle * .pi / 180))
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
