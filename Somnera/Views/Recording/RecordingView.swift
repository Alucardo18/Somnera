import SwiftUI

/// Updated RecordingView with guidance and "Night Mode" focus.
struct RecordingView: View {
    @StateObject private var vm = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showStopAlert = false
    @State private var showDebugInfo = false // Option to see the waveform/stats
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            if !vm.isCharging {
                // Phase 1: Charger Warning
                chargerWarningView
            } else {
                // Phase 2: Night Mode
                nightModeView
            }
            
            // Debug Toggle (Hidden button in top corner)
            VStack {
                HStack {
                    Spacer()
                    Button { showDebugInfo.toggle() } label: {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.caption)
                            .foregroundColor(.somSurfaceHigh)
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
                    .stroke(Color.somWarning.opacity(0.2), lineWidth: 2)
                    .frame(width: 160, height: 160)
                
                Image(systemName: "battery.100.bolt")
                    .font(.system(size: 80))
                    .foregroundColor(.somWarning)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 16) {
                Text("¡Conecta el cargador!")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.somTextPrimary)
                
                Text("Para asegurar que Somnera pueda monitorizar toda tu noche sin interrupciones, conecta tu iPhone a la corriente.")
                    .font(.body)
                    .foregroundColor(.somTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            stopButton
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
        }
        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .top)))
    }
    
    private var nightModeView: some View {
        VStack(spacing: 0) {
            // Live indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.somAccent)
                    .frame(width: 8, height: 8)
                    .opacity(vm.elapsedSeconds % 2 == 0 ? 1 : 0.3)
                Text("MONITORIZANDO SUEÑO")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundColor(.somTextSecondary)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Big Clock
            Text(vm.formattedElapsed)
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.somTextPrimary)
                .padding(.bottom, 40)
            
            // Instructions
            VStack(spacing: 24) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 80))
                    .foregroundColor(.somAccent)
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(spacing: 8) {
                    Text("Coloca el iPhone boca abajo")
                        .font(.title3.bold())
                        .foregroundColor(.somTextPrimary)
                    Text("Cerca de tu almohada para una mejor detección.")
                        .font(.subheadline)
                        .foregroundColor(.somTextSecondary)
                }
            }
            
            Spacer()
            
            stopButton
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
                Text("Terminar Sesión")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.somSurface)
            .foregroundColor(.somApnea)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.somApnea.opacity(0.3), lineWidth: 1))
        }
    }
}
