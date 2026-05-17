import SwiftUI

struct SynergyIntroView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("somnera_synergy_onboarded") var onboarded = false
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            // Fondo decorativo con auroras holográficas de laboratorio
            ZStack {
                Circle()
                    .fill(Color.somAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 70)
                    .offset(x: -80, y: -220)
                
                Circle()
                    .fill(Color.cyan.opacity(0.08))
                    .frame(width: 450, height: 450)
                    .blur(radius: 90)
                    .offset(x: 140, y: 180)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header Científico
                    VStack(spacing: 16) {
                        // Badge de Laboratorio
                        HStack(spacing: 6) {
                            Image(systemName: "flask.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)
                            Text("ENTORNO DE DIAGNÓSTICO CLÍNICO")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.cyan.opacity(0.08)))
                        
                        Text("Laboratorio de Sueño")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Sinergia: Telemetría y Monitoreo Cuántico Local")
                            .font(.headline)
                            .foregroundColor(.somTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 30)
                    
                    // BANNER CRÍTICO: REQUERIMIENTO APPLE WATCH (Llamativo y elegante)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "applewatch")
                                .font(.title3)
                                .foregroundColor(.cyan)
                                .frame(width: 36, height: 36)
                                .background(Color.cyan.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("INTEGRACIÓN CON APPLE WATCH")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1)
                                    .foregroundColor(.white)
                                Text("Métricas Indispensables")
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                            }
                        }
                        
                        Text("Para que el laboratorio de Somnera despliegue su máximo potencial clínico y mapee con precisión milimétrica la Biosfera de Homeostasis 3D, **los datos de tu Apple Watch son vitales**.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("El registro nocturno de oxígeno en sangre ($SpO2$) y frecuencia cardíaca actúa como la firma biológica indispensable para confirmar apneas y descartar falsos positivos.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .lineSpacing(3)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.cyan.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Main Message Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 15) {
                            Image(systemName: "cpu")
                                .font(.title2)
                                .foregroundColor(.somAccent)
                            Text("Laboratorio Acústico (iPhone)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Tu iPhone actúa como un sensor acústico autónomo de alta resolución, procesando ronquidos y patrones respiratorios de forma 100% privada con inteligencia artificial local.")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                            .lineSpacing(4)
                        
                        Divider()
                            .background(Color.white.opacity(0.06))
                        
                        HStack(spacing: 15) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                            Text("Sinergia Cardiorrespiratoria")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Al fusionar el audio del iPhone con la biometría del Watch, el algoritmo de Sinergia correlaciona tus niveles de oxígeno y pulso cardíaco para ofrecerte una precisión de grado clínico en tu hogar.")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Features Grid
                    VStack(spacing: 16) {
                        synergyFeature(
                            icon: "lungs.fill",
                            color: .cyan,
                            title: "Saturación de Oxígeno (SpO2)",
                            desc: "Indispensable para identificar caídas súbitas durante apneas."
                        )
                        synergyFeature(
                            icon: "heart.fill",
                            color: .red,
                            title: "Frecuencia Cardíaca Activa",
                            desc: "Monitorea la taquicardia refleja que ocurre post-ahogo respiratorio."
                        )
                        synergyFeature(
                            icon: "waveform.path.ecg",
                            color: .purple,
                            title: "Carga Alostática y Sueño",
                            desc: "Analiza el estrés total que sufre tu sistema cardiovascular nocturno."
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                    
                    // Button
                    Button {
                        onboarded = true
                        dismiss()
                    } label: {
                        Text("Activar Laboratorio de Sueño")
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
    
    private func synergyFeature(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.02))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }
}

#Preview {
    SynergyIntroView()
}
