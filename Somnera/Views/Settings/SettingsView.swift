import SwiftUI

struct SettingsView: View {
    @AppStorage("somnera_healthkit_enabled") private var healthKitEnabled = false
    @AppStorage("somnera_notifications_enabled") private var notificationsEnabled = true
    @AppStorage("somnera_sensitivity") private var sensitivity: Double = 1.0
    @AppStorage(SomneraConstants.Storage.maxSessionsKey) private var maxSessions: Int = 7

    @State private var showHealthKitSheet = false
    @State private var showDeleteAlert = false
    @State private var showTechSheet = false
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.somBackground.ignoresSafeArea()

                List {
                    // Detection
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Sensibilidad del detector", systemImage: "slider.horizontal.3")
                                    .foregroundColor(.somTextPrimary)
                                Spacer()
                                Text(sensitivityLabel)
                                    .font(.caption.bold())
                                    .foregroundColor(.somAccent)
                            }
                            Slider(value: $sensitivity, in: 0.7...1.3, step: 0.1)
                                .tint(.somAccent)
                            Text("Ajusta la reactividad de la IA. Usa una sensibilidad mayor en habitaciones muy silenciosas o menor si hay ruido de fondo (ventiladores, AC).")
                                .font(.caption2)
                                .foregroundColor(.somTextSecondary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        sectionHeader("Detección")
                    }
                    .listRowBackground(Color.somSurface)

                    // Integrations
                    Section {
                        Toggle(isOn: $healthKitEnabled) {
                            Label("Apple Health", systemImage: "heart.fill")
                                .foregroundColor(.somTextPrimary)
                        }
                        .tint(.somAccent)
                        .onChange(of: healthKitEnabled) { _, enabled in
                            if enabled { showHealthKitSheet = true }
                        }

                        Toggle(isOn: $notificationsEnabled) {
                            Label("Resumen al despertar", systemImage: "bell.badge.fill")
                                .foregroundColor(.somTextPrimary)
                        }
                        .tint(.somAccent)

                    } header: {
                        sectionHeader("Integraciones")
                    }
                    .listRowBackground(Color.somSurface)

                    // Storage
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Límite de Historial", systemImage: "internaldrive.fill")
                                    .foregroundColor(.somTextPrimary)
                                Spacer()
                                Text("\(maxSessions) sesiones")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(.somAccent)
                            }
                            
                            Slider(value: Binding(
                                get: { Double(maxSessions) },
                                set: { maxSessions = Int($0) }
                            ), in: 1...31, step: 1)
                            .tint(.somAccent)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(maxSessions > 20 ? .somApnea : .somTextSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(storageEstimateText)
                                        .font(.caption2.bold())
                                        .foregroundColor(maxSessions > 20 ? .somApnea : .somTextPrimary)
                                    
                                    Text("Somnera eliminará automáticamente la sesión más antigua al superar este límite para proteger tu espacio.")
                                        .font(.system(size: 10))
                                        .foregroundColor(.somTextSecondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)

                        HStack {
                            Label("Formato de audio", systemImage: "waveform")
                                .foregroundColor(.somTextPrimary)
                            Spacer()
                            Text("AAC 32kbps · 16kHz")
                                .font(.caption)
                                .foregroundColor(.somTextSecondary)
                        }
                        
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Borrar todas las sesiones", systemImage: "trash.fill")
                        }
                    } header: {
                        sectionHeader("Almacenamiento")
                    }
                    .listRowBackground(Color.somSurface)

                    // About
                    Section {
                        Button {
                            showTechSheet = true
                        } label: {
                            HStack {
                                Label("Versión", systemImage: "info.circle.fill")
                                    .foregroundColor(.somTextPrimary)
                                Spacer()
                                Text("2.0.1")
                                    .font(.caption)
                                    .foregroundColor(.somAccent)
                            }
                        }
                        
                        Link(destination: URL(string: "https://somnera.app/privacy")!) {
                            Label("Política de privacidad", systemImage: "lock.shield.fill")
                                .foregroundColor(.somAccent)
                        }
                    } header: {
                        sectionHeader("Acerca de Somnera")
                    }
                    .listRowBackground(Color.somSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTechSheet) {
                TechInsightsView()
            }
            .toolbarBackground(Color.somBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("¿Borrar todas las sesiones?", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Borrar Todo", role: .destructive) {
                    viewModel.deleteAllSessions()
                }
            } message: {
                Text("Esta acción eliminará permanentemente todas tus grabaciones y datos de sueño. No se puede deshacer.")
            }
        }
    }

    private var sensitivityLabel: String {
        switch sensitivity {
        case ..<0.85: return "Baja"
        case ..<1.15: return "Media (Recomendado)"
        case ..<1.25: return "Alta"
        default:      return "Muy Alta"
        }
    }

    private var storageEstimateText: String {
        let mbPerSession = 120 // Estimado para 8h en AAC 32kbps
        let totalMB = maxSessions * mbPerSession
        if totalMB >= 1024 {
            let gb = Double(totalMB) / 1024.0
            return "Espacio estimado: \(String(format: "%.1f", gb)) GB"
        } else {
            return "Espacio estimado: \(totalMB) MB"
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.somTextSecondary)
            .textCase(nil)
    }
}
