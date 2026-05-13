import SwiftUI

/// Updated RecordingView with guidance and "Night Mode" focus.
struct RecordingView: View {
    @ObservedObject var dashboardVM: DashboardViewModel
    @StateObject private var vm = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showStopAlert = false
    @State private var showDebugInfo = false // Option to see the waveform/stats
    @State private var localDelayMinutes: Int = 0
    
    var body: some View {
        ZStack {
            // MARK: - Premium Mesh Background
            Color.somBackground.ignoresSafeArea()
            
            ZStack {
                Circle()
                    .fill(Color.somMesh3.opacity(0.2))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Color.somAccent.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 100)
            }
            .ignoresSafeArea()
            
            if vm.isSetup {
                setupView
            } else if vm.isWaiting {
                waitingView
            } else if !vm.isCharging {
                chargerWarningView
            } else {
                nightModeView
            }
            
            // Debug Toggle
            if !vm.isSetup && !vm.isWaiting {
                VStack {
                    HStack {
                        Spacer()
                        Button { showDebugInfo.toggle() } label: {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.title3)
                                .foregroundColor(.somSurfaceHigh)
                                .padding(8)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            
            if showDebugInfo {
                debugOverlayView
            }
        }
        .alert("¿Terminar sesión?", isPresented: $showStopAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Terminar", role: .destructive) {
                Task {
                    await vm.stopSession()
                    if let finishedSession = vm.session {
                        dashboardVM.sessionToNavigate = finishedSession
                    }
                    dismiss()
                }
            }
        } message: {
            Text("Se guardará la sesión con todos los eventos detectados.")
        }
    }
    
    // MARK: - Views
    
    private var setupView: some View {
        VStack(spacing: 40) {
            HStack {
                Button("Cancelar") { dismiss() }
                    .foregroundColor(.somTextSecondary)
                Spacer()
                Text("Configuración")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Ayuda") { }
                    .opacity(0) // Balance
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.somAccent)
                
                Text("¿Cuándo empezamos?")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 25) {
                VStack(spacing: 10) {
                    Text("Retardo de inicio")
                        .font(.caption.bold())
                        .foregroundColor(.somTextSecondary)
                    
                    HStack(spacing: 20) {
                        Button { if localDelayMinutes > 0 { localDelayMinutes -= 5 } } label: {
                            Image(systemName: "minus.circle.fill").font(.title)
                        }
                        .foregroundColor(localDelayMinutes == 0 ? .somSurfaceHigh : .somAccent)
                        
                        Text(localDelayMinutes == 0 ? "Inmediato" : "\(localDelayMinutes) min")
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 160)
                        
                        Button { if localDelayMinutes < 60 { localDelayMinutes += 5 } } label: {
                            Image(systemName: "plus.circle.fill").font(.title)
                        }
                        .foregroundColor(localDelayMinutes == 60 ? .somSurfaceHigh : .somAccent)
                    }
                }
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                
                Text("Selecciona el tiempo que sueles tardar en dormir para evitar falsos positivos.")
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    vm.startWithDelay(minutes: localDelayMinutes)
                } label: {
                    Text(localDelayMinutes == 0 ? "Comenzar ahora" : "Activar sesión")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.somGradient)
                        .clipShape(Capsule())
                        .shadow(color: .somAccent.opacity(0.3), radius: 10)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
    }
    
    private var chargerWarningView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.somWarning.opacity(0.3), lineWidth: 4)
                    .frame(width: 160, height: 160)
                    .blur(radius: 8)
                
                Image(systemName: "battery.100.bolt")
                    .font(.system(size: 80))
                    .foregroundColor(.somWarning)
                    .shadow(color: .somWarning.opacity(0.5), radius: 15)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 20) {
                Text("¡Conecta el cargador!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Para asegurar que Somnera pueda monitorizar toda tu noche sin interrupciones, conecta tu iPhone a la corriente.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.somTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(30)
            .somGlassStyle(cornerRadius: 30)
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 8) {
                stopButton
                Text("Puedes minimizar la app deslizando hacia abajo.")
                    .font(.system(size: 10))
                    .foregroundColor(.somTextSecondary.opacity(0.8))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
        .transition(.opacity)
    }
    
    private var waitingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Tiempo de Calma")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.somAccent)
                    .tracking(3)
                
                Text(formattedCountdown)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 32) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundColor(.somAccent.opacity(0.8))
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(spacing: 12) {
                    Text("Prepárate para dormir")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("El monitoreo comenzará automáticamente cuando termine el contador.")
                        .font(.subheadline)
                        .foregroundColor(.somTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding(30)
            .somGlassStyle(cornerRadius: 30)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    Task { await vm.startSession() }
                } label: {
                    Text("Iniciar ahora")
                        .font(.headline)
                        .foregroundColor(.somAccent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.somAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                stopButton
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
    }
    
    private var formattedCountdown: String {
        let m = vm.countdownRemaining / 60
        let s = vm.countdownRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private var nightModeView: some View {
        VStack(spacing: 0) {
            // Live indicator
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.somAccent)
                        .frame(width: 8, height: 8)
                        .shadow(color: .somAccent, radius: 4)
                        .opacity(vm.elapsedSeconds % 2 == 0 ? 1 : 0.3)
                    Text("MONITORIZANDO SUEÑO")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(Color.somTextSecondary)
                        .tracking(2)
                }
                
                Text("Desliza hacia abajo para volver al Dashboard")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.somAccent.opacity(0.6))
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Big Clock
            Text(vm.formattedElapsed)
                .font(.system(size: 90, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 40)
            
            // Instructions
            VStack(spacing: 32) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 70))
                    .foregroundColor(.somAccent)
                    .shadow(color: .somAccent.opacity(0.5), radius: 20)
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(spacing: 12) {
                    Text("Coloca el iPhone boca abajo")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Cerca de tu almohada para una mejor detección.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.somTextSecondary)
                }
            }
            .padding(30)
            .somGlassStyle(cornerRadius: 30)
            .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 8) {
                stopButton
                Text("La sesión continuará activa aunque minimices la vista.")
                    .font(.system(size: 10))
                    .foregroundColor(.somTextSecondary.opacity(0.8))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
        .transition(.opacity)
    }
    
    private var debugOverlayView: some View {
        ZStack {
            Color.somBackground.opacity(0.9)
            VStack(spacing: 20) {
                Text("Panel Técnico").font(.headline).foregroundColor(.white)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("SUPERFICIE").font(.caption2).foregroundColor(.somTextSecondary)
                        Text(vm.currentSurface.rawValue.uppercased())
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundColor(vm.currentSurface == .bed ? .somSafe : .somWarning)
                    }
                    
                    VStack {
                        Text("DISTANCIA").font(.caption2).foregroundColor(.somTextSecondary)
                        Text(String(format: "%.1f m", vm.currentDistance))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundColor(.somAccent)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)

                WaveformView(samples: vm.latestWaveform, isApnea: vm.isApneaActive)
                    .frame(height: 80)
                
                Text("\(Int(vm.currentDecibels)) dB").font(.title.bold()).foregroundColor(.white)
                
                Button("Cerrar") { showDebugInfo = false }
                    .foregroundColor(.somAccent)
            }
            .padding()
        }
    }
    
    private var stopButton: some View {
        Button {
            showStopAlert = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "stop.circle.fill")
                    .font(.title3)
                Text("Terminar Sesión")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .foregroundColor(.somApnea)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.somApnea.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .somApnea.opacity(0.3), radius: 15)
        }
    }
}
