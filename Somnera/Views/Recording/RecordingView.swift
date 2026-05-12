import SwiftUI

/// Updated RecordingView with guidance and "Night Mode" focus.
struct RecordingView: View {
    @StateObject private var vm = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showStopAlert = false
    @State private var showDebugInfo = false // Option to see the waveform/stats
    
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
            
            if !vm.isCharging {
                chargerWarningView
            } else {
                nightModeView
            }
            
            // Debug Toggle
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
            
            if showDebugInfo {
                debugOverlayView
            }
        }
        .task { await vm.startSession() }
        .alert("¿Terminar sesión?", isPresented: $showStopAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Terminar", role: .destructive) {
                Task {
                    await vm.stopSession()
                    dismiss()
                }
            }
        } message: {
            Text("Se guardará la sesión con todos los eventos detectados.")
        }
    }
    
    // MARK: - Views
    
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
                Text("Panel Técnico").font(.headline)
                WaveformView(samples: vm.latestWaveform, isApnea: vm.isApneaActive)
                    .frame(height: 80)
                Text("\(Int(vm.currentDecibels)) dB").font(.title.bold())
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
