import SwiftUI

// MARK: - Sponsor Registration (Post-Purchase)
// Static screen shown right after a donation unlock. Allows the user to register a sponsor name.
struct SponsorRegistrationView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("somnera_sponsor_name") private var sponsorName = "Patrocinador"
    @AppStorage("somnera_equipped_totem") private var equippedTotem = "cuarzo"
    
    @State private var animateTotem = false
    @State private var animateText = false
    @State private var nameInput = ""
    @State private var currentThanks = ""
    
    private let thanks = [
        "Has activado una capa de protección silenciosa para que Somnera siga siendo independiente.",
        "Tu apoyo es una señal limpia en medio del ruido: Somnera puede seguir evolucionando sin anuncios.",
        "Acabas de desbloquear una reliquia estética. La ciencia duerme mejor cuando alguien la cuida.",
        "Gracias por mantener este laboratorio local, privado y obsesivamente preciso."
    ]
    
    private let totems = [
        TotemInfo(id: "cuarzo", name: "Cuarzo de la Homeostasis", color: .somSafe, description: "", mathType: .crystal),
        TotemInfo(id: "piramide", name: "Pirámide Delta", color: .somAccent, description: "", mathType: .pyramid),
        TotemInfo(id: "giroscopio", name: "Giroscopio Topográfico", color: .somWarning, description: "", mathType: .gyro),
        TotemInfo(id: "tesseracto", name: "Tesseracto del Olvido", color: .somApnea, description: "", mathType: .tesseract),
        TotemInfo(id: "helice", name: "Hélice de Sinergia", color: .somSafe, description: "", mathType: .helix),
        TotemInfo(id: "astrolabio", name: "Astrolabio de Oro", color: .somWarning, description: "", mathType: .astrolabe),
        TotemInfo(id: "singularidad", name: "Singularidad Áurea", color: .somWarning, description: "", mathType: .singularity)
    ]
    
    private var currentTotem: TotemInfo {
        totems.first(where: { $0.id == equippedTotem }) ?? totems[0]
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#090B12").ignoresSafeArea()
            
            StarfieldBackground()
                .ignoresSafeArea()
                .opacity(0.65)
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("NUEVO PATRÓN UNIDO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(currentTotem.color)
                        .tracking(6)
                        .scaleEffect(animateText ? 1.0 : 0.85)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    Text("Registro de Patrocinador")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.somTextPrimary)
                        .scaleEffect(animateText ? 1.0 : 0.95)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    Text(currentThanks)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.somTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 34)
                        .opacity(animateText ? 0.95 : 0.0)
                }
                .padding(.top, 40)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(currentTotem.color.opacity(0.12))
                        .frame(width: 240, height: 240)
                        .blur(radius: 40)
                        .scaleEffect(animateTotem ? 1.15 : 0.85)
                    
                    Totem3DView(mathType: currentTotem.mathType, color: currentTotem.color, isUnlocked: true)
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateTotem ? 1.0 : 0.1)
                        .rotationEffect(.degrees(animateTotem ? 360 : 0))
                }
                .frame(height: 250)
                
                Text(currentTotem.name.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(currentTotem.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(currentTotem.color.opacity(0.08))
                    .cornerRadius(10)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("REGISTRA TU NOMBRE EN EL COLEGIO DE PATROCINADORES")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.somTextSecondary)
                        .tracking(1.5)
                    
                    TextField("Tu nombre o alias", text: $nameInput)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 40)
                }
                .opacity(animateText ? 1.0 : 0.0)
                
                Button {
                    let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        sponsorName = trimmed
                    }
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text("EMPEZAR TU VIAJE")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [currentTotem.color, currentTotem.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: currentTotem.color.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                .opacity(animateText ? 1.0 : 0.0)
            }
        }
        .onAppear {
            nameInput = sponsorName
            currentThanks = thanks.randomElement() ?? thanks[0]
            
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7, blendDuration: 0.5)) {
                animateTotem = true
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateText = true
            }
        }
    }
}

// MARK: - Sponsor Welcome (App Open)
struct SponsorWelcomeView: View {
    @Binding var isPresented: Bool
    var autoDismissAfter: Double? = nil
    
    @AppStorage("somnera_sponsor_name") private var sponsorName = "Patrocinador"
    @AppStorage("somnera_equipped_totem") private var equippedTotem = "cuarzo"
    @AppStorage("somnera_unlocked_totems") private var unlockedTotems = ""
    
    @State private var animateTotem = false
    @State private var animateText = false
    @State private var currentQuote = ""
    @State private var currentThanks = ""
    
    let quotes = [
        "La homeostasis no es un destino, es la danza silenciosa de tu cuerpo en la penumbra.",
        "Que tu sueño sea tan profundo y ordenado como la geometría del cosmos.",
        "En la calma de la noche, cada latido busca el equilibrio absoluto.",
        "La noche cobija a los valientes que cuidan de su salud en el silencio.",
        "Respira con calma, la inteligencia de Somnera vela por tu tranquilidad.",
        "Tu descanso es el combustible sagrado de tu mente para el mañana.",
        "El día ha terminado. Deja que la gravedad haga su trabajo, relaja los hombros y permite que Somnera cuide de tus frecuencias estelares. Estás a salvo.",
        "Cada latido de tu corazón es una sincronía perfecta con el universo. Apaga tus pensamientos de hoy; tu gemelo digital vigila el descanso.",
        "La homeostasis perfecta no se busca con prisa, se permite en calma. Suelta el aire, apaga la mente y sintoniza con el silencio de la noche.",
        "Dormir no es perder el tiempo, es la alquimia que consolida tus memorias y tu alma. Buenas noches, que tus ondas delta fluyan en perfecta armonía.",
        "Tu Tótem está activo y la Biosfera en perfecto equilibrio. Has hecho suficiente por hoy; entrégate al infinito y descansa.",
        "El descanso es la cuna de toda tu fuerza de mañana. Relaja la mandíbula, inhala paz y deja que la noche te cubra.",
        "La noche limpia el ruido del mundo; permite que la quietud repare tus células y resetee tu conciencia.",
        "El cerebro no duerme; esculpe tus recuerdos en el lienzo de la noche, creando la mejor versión de ti mismo.",
        "Sintoniza la frecuencia de la respiración: una inhalación lenta de serenidad, una exhalación profunda de entrega.",
        "En el laboratorio del sueño, la oscuridad es el reactivo más puro para restaurar tu homeostasis vital.",
        "Deja que tus párpados pesen tanto como las galaxias lejanas. La gravedad te sostiene con amor y seguridad.",
        "Tu respiración es el oleaje de un mar en calma. Déjate mecer por su ritmo constante, libre de tensiones.",
        "El silencio no es la ausencia de sonido, es la presencia del descanso absoluto. Habita este instante.",
        "Cada ciclo de sueño es un viaje de retorno a tu esencia biológica más pura. Viaja ligero, viaja en paz.",
        "Las estrellas brillan afuera para recordarte que la luz siempre espera al final de la noche. Duerme tranquilo.",
        "Tu mente ha corrido maratones hoy; es justo y necesario que ahora repose bajo el manto de la noche.",
        "La temperatura desciende, el ritmo cardíaco se estabiliza. Tu cuerpo sabe exactamente cómo sanar en la penumbra.",
        "Abandona el control del tiempo. En el espacio del sueño, no hay agendas ni tareas, solo reparación infinita.",
        "Eres parte de la Biosfera; la naturaleza apaga sus luces y te invita a sincronizarte con el pulso de la Tierra.",
        "La homeostasis es la sabiduría silenciosa de tu cuerpo. Confía en su capacidad para restaurar tu equilibrio nocturno.",
        "Permite que las ondas delta acunen tus pensamientos, transformando la prisa diurna en paz nocturna.",
        "Tu descanso es un santuario privado. Cierra las puertas al ruido y dale la bienvenida a la regeneración celular.",
        "El latido nocturno es pausado, limpio y rítmico. Somnera acompaña cada vibración hacia tu homeostasis perfecta.",
        "El mañana se construye esta noche. Regálate el descanso más profundo y reparador como un acto de amor propio.",
        "Apaga la última luz del pensamiento. Duerme con la certeza de que todo está bien, y la mañana traerá nueva energía."
    ]
    
    let thanks = [
        "Gracias por apoyar a Somnera. Tu patrocinio mantiene este laboratorio libre de anuncios.",
        "Gracias por sostener el proyecto. Todo lo que ves aquí corre localmente gracias a ti.",
        "Tu apoyo es una promesa de privacidad: Somnera puede seguir siendo independiente."
    ]
    
    let totems = [
        TotemInfo(id: "cuarzo", name: "Cuarzo de la Homeostasis", color: .somSafe, description: "", mathType: .crystal),
        TotemInfo(id: "piramide", name: "Pirámide Delta", color: .somAccent, description: "", mathType: .pyramid),
        TotemInfo(id: "giroscopio", name: "Giroscopio Topográfico", color: .somWarning, description: "", mathType: .gyro),
        TotemInfo(id: "tesseracto", name: "Tesseracto del Olvido", color: .somApnea, description: "", mathType: .tesseract),
        TotemInfo(id: "helice", name: "Hélice de Sinergia", color: .somSafe, description: "", mathType: .helix),
        TotemInfo(id: "astrolabio", name: "Astrolabio de Oro", color: .somWarning, description: "", mathType: .astrolabe),
        TotemInfo(id: "singularidad", name: "Singularidad Áurea", color: .somWarning, description: "", mathType: .singularity)
    ]
    
    var currentTotem: TotemInfo {
        totems.first(where: { $0.id == equippedTotem }) ?? totems[0]
    }
    
    var body: some View {
        ZStack {
            // Dark elegant velvet background
            Color(hex: "#090B12").ignoresSafeArea()
            
            // Constellations glowing in the background
            StarfieldBackground()
                .ignoresSafeArea()
                .opacity(0.6)
            
            VStack(spacing: 24) {
                // Top header
                VStack(spacing: 12) {
                    Text("PATROCINADOR DETECTADO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(currentTotem.color)
                        .tracking(6)
                        .scaleEffect(animateText ? 1.0 : 0.8)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    Text("Buenas noches, \(sponsorName)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.somTextPrimary)
                        .scaleEffect(animateText ? 1.0 : 0.9)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    Text(currentThanks)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.somTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 40)
                        .opacity(animateText ? 0.9 : 0.0)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Giant rotating Totem
                ZStack {
                    // Outer glow aura
                    Circle()
                        .fill(currentTotem.color.opacity(0.12))
                        .frame(width: 240, height: 240)
                        .blur(radius: 40)
                        .scaleEffect(animateTotem ? 1.15 : 0.85)
                    
                    // The 3D canvas totem
                    Totem3DView(mathType: currentTotem.mathType, color: currentTotem.color, isUnlocked: true)
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateTotem ? 1.0 : 0.1)
                        .rotationEffect(.degrees(animateTotem ? 360 : 0))
                }
                .frame(height: 250)
                
                Text(currentTotem.name.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(currentTotem.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(currentTotem.color.opacity(0.08))
                    .cornerRadius(10)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Spacer()
                
                // Clinically calming sleep quote
                Text("“\(currentQuote)”")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(.somTextSecondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                    .opacity(animateText ? 0.9 : 0.0)
                
                Spacer()
                
                // Start / Dismiss button
                Button {
                    // Dismiss with animation
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text("CONTINUAR")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [currentTotem.color, currentTotem.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: currentTotem.color.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                .opacity(animateText ? 1.0 : 0.0)
            }
        }
        .onAppear {
            currentThanks = thanks.randomElement() ?? thanks[0]
            currentQuote = quotes.randomElement() ?? quotes[0]
            
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7, blendDuration: 0.5)) {
                animateTotem = true
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateText = true
            }

            if let autoDismissAfter {
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    SponsorWelcomeView(isPresented: .constant(true))
}
