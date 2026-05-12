import SwiftUI

struct SettingsView: View {
    @AppStorage("somnera_healthkit_enabled") private var healthKitEnabled = false
    @AppStorage("somnera_notifications_enabled") private var notificationsEnabled = true
    @AppStorage("somnera_sensitivity") private var sensitivity: Double = 0.75

    @State private var showHealthKitSheet = false
    @State private var showDeleteAlert = false
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
                            Slider(value: $sensitivity, in: 0.60...0.95, step: 0.05)
                                .tint(.somAccent)
                            Text("Valores más altos reducen falsos positivos pero pueden perder ronquidos suaves.")
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
                        HStack {
                            Label("Sesiones guardadas", systemImage: "internaldrive.fill")
                                .foregroundColor(.somTextPrimary)
                            Spacer()
                            Text("Máx. 7")
                                .font(.caption)
                                .foregroundColor(.somTextSecondary)
                        }
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
                        HStack {
                            Label("Versión", systemImage: "info.circle.fill")
                                .foregroundColor(.somTextPrimary)
                            Spacer()
                            Text("1.0.0")
                                .font(.caption)
                                .foregroundColor(.somTextSecondary)
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
        case ..<0.65: return "Muy Alta"
        case ..<0.75: return "Alta"
        case ..<0.85: return "Media"
        default:      return "Baja"
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.somTextSecondary)
            .textCase(nil)
    }
}
