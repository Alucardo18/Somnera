import SwiftUI

struct SynergyIntroView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("somnera_synergy_onboarded") var onboarded = false
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            // Fondo decorativo con luces
            ZStack {
                Circle()
                    .fill(Color.somAccent.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(Color.somMesh3.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 150, y: 200)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 35) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.somAccent.gradient)
                            .shadow(color: Color.somAccent.opacity(0.5), radius: 20)
                        
                        Text("Sinergia")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Potencia tu análisis con datos biométricos.")
                            .font(.headline)
                            .foregroundColor(.somTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    // Main Message Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 15) {
                            Image(systemName: "cpu")
                                .font(.title2)
                                .foregroundColor(.somAccent)
                            Text("Poder Autónomo")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Somnera es una herramienta avanzada capaz de detectar ronquidos y apneas con alta precisión usando únicamente IA y modelos matemáticos ejecutados localmente en tu iPhone.")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                            .lineSpacing(4)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        HStack(spacing: 15) {
                            Image(systemName: "applewatch")
                                .font(.title2)
                                .foregroundColor(.somSafe)
                            Text("El Multiplicador")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Al conectar tu Apple Watch, Somnera deja de 'estimar' y comienza a 'validar'. La frecuencia cardíaca y el oxígeno en sangre actúan como una firma biológica que confirma cada evento respiratorio.")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Features Grid
                    VStack(spacing: 16) {
                        synergyFeature(icon: "heart.fill", title: "Estrés Cardíaco", desc: "Correlación de taquicardia post-apnea.")
                        synergyFeature(icon: "lungs.fill", title: "Validación SpO2", desc: "Confirma pausas con caídas de oxígeno.")
                        synergyFeature(icon: "waveform.path.ecg", title: "Higiene del Sueño", desc: "Analiza cómo tu actividad diaria afecta tu noche.")
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                    
                    // Button
                    Button {
                        onboarded = true
                        dismiss()
                    } label: {
                        Text("Comenzar con Sinergia")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.somAccent.gradient)
                            .cornerRadius(16)
                            .shadow(color: Color.somAccent.opacity(0.4), radius: 15, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func synergyFeature(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.somAccent)
                .frame(width: 40, height: 40)
                .background(Color.somAccent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
}

#Preview {
    SynergyIntroView()
}
