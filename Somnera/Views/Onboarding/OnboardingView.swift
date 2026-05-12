import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, body: String, color: Color)] = [
        ("brain.head.profile",
         "IA que Aprende de Ti",
         "Nuestra red neuronal se personaliza con tus patrones de ronquido. Dale feedback a tus grabaciones y Somnera será cada vez más precisa.",
         .somAccent),
        ("shield.checkerboard",
         "Privacidad Blindada",
         "Tu audio nunca sale de este iPhone. Todo el procesamiento ocurre localmente en el Apple Neural Engine.",
         .somSafe),
        ("waveform.path",
         "Denoising Inteligente",
         "Filtramos ventiladores y aire acondicionado automáticamente para que solo escuches lo que importa.",
         .somWarning),
        ("chart.xyaxis.line",
         "Análisis Clínico",
         "Visualiza tu noche con mapas de calor de alta resolución y detecta posibles apneas antes de que sea tarde.",
         .somApnea)
    ]

    var body: some View {
        ZStack {
            // Fondo Dinámico Premium
            Color.somBackground.ignoresSafeArea()
            
            // Luces de fondo animadas (Efecto Aurora)
            ZStack {
                Circle()
                    .fill(pages[currentPage].color.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(Color.somAccent.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 200)
            }
            .animation(.easeInOut(duration: 1.0), value: currentPage)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image("somnera_logo") // Asumiendo que existe o usando texto
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .opacity(0.8)
                    
                    Text("SOMNERA")
                        .font(.system(size: 14, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Button("SALTAR") {
                        appState.completeOnboarding()
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.somTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        onboardingPage(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Footer Glassmorphic
                VStack(spacing: 32) {
                    // Page indicator
                    HStack(spacing: 12) {
                        ForEach(pages.indices, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? pages[i].color : Color.white.opacity(0.1))
                                .frame(width: i == currentPage ? 12 : 8, height: 8)
                                .overlay(
                                    Circle().stroke(i == currentPage ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        }
                    }

                    // Main Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            appState.completeOnboarding()
                        }
                    } label: {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "CONTINUAR" : "COMENZAR AHORA")
                                .font(.system(size: 14, weight: .black))
                                .tracking(1)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            ZStack {
                                Color.white.opacity(0.1)
                                LinearGradient(colors: [pages[currentPage].color.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 20, x: 0, y: 10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }

    private func onboardingPage(_ page: (icon: String, title: String, body: String, color: Color)) -> some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon Display con Glassmorphism
            ZStack {
                // Glow de fondo
                Circle()
                    .fill(page.color.opacity(0.3))
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)
                
                // Capa de cristal
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 220, height: 220)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                
                Image(systemName: page.icon)
                    .font(.system(size: 90))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, page.color], 
                                       startPoint: .topLeading, 
                                       endPoint: .bottomTrailing)
                    )
                    .shadow(color: page.color.opacity(0.8), radius: 30)
            }

            // Text Display
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(page.body)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
