import SwiftUI

struct SynergyDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.somAccent.gradient)
                        
                        Text("El Ecosistema Sinergia")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Cómo Somnera utiliza tus datos biométricos para diagnósticos de grado clínico.")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Detailed Sections
                    VStack(spacing: 20) {
                        synergyDetailSection(
                            icon: "heart.text.square.fill",
                            title: "Correlación de Pulso",
                            description: "Cada vez que dejas de respirar (Apnea), tu cuerpo entra en un estado de estrés. Tu corazón late más fuerte para compensar la falta de oxígeno.",
                            benefit: "Somnera detecta estos picos de pulso y los alinea con los periodos de silencio en tu audio para confirmar una apnea con un 98% de confianza."
                        )
                        
                        synergyDetailSection(
                            icon: "lungs.fill",
                            title: "Oxigenación SpO2",
                            description: "La saturación de oxígeno es la prueba definitiva de una apnea obstructiva. Si el audio indica silencio y el Apple Watch detecta una caída de SpO2...",
                            benefit: "Validamos clínicamente que la pausa respiratoria tuvo un impacto real en tu oxigenación sanguínea, diferenciando ronquidos simples de eventos graves."
                        )
                        
                        synergyDetailSection(
                            icon: "figure.run.circle.fill",
                            title: "Impacto de Actividad",
                            description: "Tu actividad física diaria influye directamente en el tono muscular de tus vías respiratorias durante la noche.",
                            benefit: "Analizamos si los días de mayor ejercicio reducen tus episodios de ronquido, ayudándote a encontrar tu rutina ideal para un descanso profundo."
                        )
                    }
                    .padding(.horizontal)
                    
                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Entendido")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func synergyDetailSection(icon: String, title: String, description: String, benefit: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.somAccent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.somTextSecondary)
                .lineSpacing(4)
            
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.somSafe)
                Text(benefit)
                    .font(.caption)
                    .foregroundColor(.somSafe)
                    .italic()
            }
            .padding(12)
            .background(Color.somSafe.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(24)
        .background(Color.somSurface.opacity(0.5))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    SynergyDetailView()
}
