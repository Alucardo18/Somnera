import SwiftUI

/// A full-screen view shown during an active recording session.
/// Provides guidance on charging and placement, plus a night-mode timer.
struct RecordingActiveView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Status Header
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(viewModel.elapsedSeconds % 2 == 0 ? 1 : 0.3)
                    Text("GRABANDO EN VIVO")
                        .font(.caption.bold())
                        .foregroundColor(.somTextSecondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                if !viewModel.isCharging {
                    // Warning: Not Charging
                    VStack(spacing: 24) {
                        Image(systemName: "battery.100.bolt")
                            .font(.system(size: 80))
                            .foregroundColor(.somWarning)
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Text("¡Conecta el cargador!")
                            .font(.title2.bold())
                            .foregroundColor(.somTextPrimary)
                        
                        Text("Para asegurar que Somnera pueda monitorizar toda tu noche, es necesario que el iPhone esté conectado a la corriente.")
                            .font(.body)
                            .foregroundColor(.somTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Success: Charging + Night Mode
                    VStack(spacing: 30) {
                        Text(viewModel.formattedElapsed)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.somTextPrimary)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "iphone.gen3.arrow.left.and.right.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.somAccent)
                            
                            Text("Coloca el iPhone boca abajo")
                                .font(.headline)
                                .foregroundColor(.somTextPrimary)
                            
                            Text("Cerca de tu almohada para una mejor detección de ronquidos.")
                                .font(.subheadline)
                                .foregroundColor(.somTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Stop Button
                Button {
                    Task {
                        await viewModel.stopSession()
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Detener Sesión")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 56)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 60)
            }
        }
        .animation(.spring(), value: viewModel.isCharging)
        .interactiveDismissDisabled() // Prevent accidental swipe down
    }
}
