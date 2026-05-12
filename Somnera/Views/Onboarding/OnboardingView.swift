import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, body: String, color: Color, isCustomIcon: Bool)] = [
        ("moon.stars.fill",
         "Bienvenido a Somnera",
         "La próxima generación en monitorización del sueño, diseñada para ofrecerte un análisis de grado clínico en casa.",
         .somAccent, false),
        ("cpu.fill",
         "Machine Learning Local",
         "Privacidad absoluta. Tus datos se procesan en el Apple Neural Engine de tu iPhone. Nada sale nunca de tu dispositivo.",
         .somSafe, false),
        ("waveform.and.mic",
         "Fusión de Sensores",
         "Combinamos audio de alta fidelidad con micro-vibraciones del colchón para una precisión diagnóstica sin precedentes.",
         .somWarning, false),
        ("lock.shield.fill",
         "Tus Datos, Tu Control",
         "Sincronización segura con Apple Health y total anonimato. Tu salud es solo tuya.",
         .somApnea, false)
    ]

    var body: some View {
        ZStack {
            // Background with subtle gradient
            Color.somBackground.ignoresSafeArea()
            
            // Starry sky background effect
            Circle()
                .fill(Color.somAccent.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 100, y: -200)

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    Button("Saltar") {
                        appState.completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundColor(.somTextSecondary)
                    .padding()
                }

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        onboardingPage(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Footer
                VStack(spacing: 24) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.somAccent : Color.somTextSecondary.opacity(0.3))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            appState.completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continuar" : "Comenzar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.somGradient)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.somAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private func onboardingPage(_ page: (icon: String, title: String, body: String, color: Color, isCustomIcon: Bool)) -> some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon Display
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(colors: [page.color, page.color.opacity(0.6)], 
                                       startPoint: .topLeading, 
                                       endPoint: .bottomTrailing)
                    )
                    .shadow(color: page.color.opacity(0.5), radius: 20)
            }

            // Text Display
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.somTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundColor(.somTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
