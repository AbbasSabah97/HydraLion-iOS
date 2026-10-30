import SwiftUI

struct BottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.28, y: 0))
        path.addCurve(to: CGPoint(x: w * 0.04, y: h * 0.26),
                      control1: CGPoint(x: w * 0.10, y: h * 0.04),
                      control2: CGPoint(x: w * 0.04, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.04, y: h * 0.83))
        path.addQuadCurve(to: CGPoint(x: w * 0.21, y: h),
                          control: CGPoint(x: w * 0.04, y: h))
        path.addLine(to: CGPoint(x: w * 0.79, y: h))
        path.addQuadCurve(to: CGPoint(x: w * 0.96, y: h * 0.83),
                          control: CGPoint(x: w * 0.96, y: h))
        path.addLine(to: CGPoint(x: w * 0.96, y: h * 0.26))
        path.addCurve(to: CGPoint(x: w * 0.72, y: 0),
                      control1: CGPoint(x: w * 0.96, y: h * 0.12),
                      control2: CGPoint(x: w * 0.90, y: h * 0.04))
        path.closeSubpath()
        return path
    }
}

struct WaterWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat = 12

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top: CGFloat = 18
        path.move(to: CGPoint(x: 0, y: top + sin(phase) * amplitude))
        for x in stride(from: CGFloat(0), through: rect.width, by: 5) {
            let y = top + sin((x / max(rect.width, 1)) * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct GlassBottleBody: View {
    var progress: CGFloat
    var phase: CGFloat

    private let bubbleX: [CGFloat] = [0.22, 0.42, 0.72, 0.60, 0.84, 0.32, 0.53, 0.77, 0.18, 0.66, 0.40, 0.90]
    private let bubbleY: [CGFloat] = [0.24, 0.60, 0.44, 0.16, 0.73, 0.83, 0.35, 0.90, 0.46, 0.68, 0.12, 0.57]

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let fraction = min(1, max(0, progress))
            let waterHeight = h * fraction

            ZStack(alignment: .bottom) {
                // Transparent cool glass, instead of a solid pale-blue bottle.
                BottleShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.91, green: 0.95, blue: 1).opacity(0.55),
                                .white.opacity(0.18),
                                Color(red: 0.81, green: 0.88, blue: 1).opacity(0.50)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if fraction > 0.001 {
                    WaterWave(phase: phase, amplitude: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Palette.blueBright.opacity(0.29),
                                    Palette.blue.opacity(0.43),
                                    Palette.blue.opacity(0.62)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: waterHeight + 24)

                    WaterWave(phase: phase + 1.4, amplitude: 6)
                        .fill(Color.white.opacity(0.14))
                        .frame(height: waterHeight + 15)

                    // Bubbles are positioned only inside the current water level.
                    ForEach(0..<12, id: \.self) { index in
                        let diameter = CGFloat(7 + (index % 5) * 3)
                        Circle()
                            .fill(Color.white.opacity(0.17))
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.80), lineWidth: 1.5)
                            }
                            .frame(width: diameter, height: diameter)
                            .position(
                                x: w * bubbleX[index],
                                y: h - max(8, waterHeight * bubbleY[index])
                                    + sin(phase + CGFloat(index)) * 5
                            )
                    }
                }

                // Thin reflections along the inner glass walls.
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.82), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.055, height: h * 0.47)
                    .rotationEffect(.degrees(7))
                    .position(x: w * 0.14, y: h * 0.48)

                Capsule()
                    .fill(Color.white.opacity(0.34))
                    .frame(width: w * 0.025, height: h * 0.33)
                    .rotationEffect(.degrees(-7))
                    .position(x: w * 0.88, y: h * 0.49)
            }
            .clipShape(BottleShape())
            .overlay {
                BottleShape()
                    .stroke(Palette.bottleStroke.opacity(0.90), lineWidth: 2.6)
            }
            .shadow(color: Palette.navy.opacity(0.11), radius: 16, y: 9)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: HydrationStore
    let onAdd: () -> Void
    let onGoal: () -> Void
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "", onMenu: onGoal)

            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let mascotSize = min(w * 0.85, h * 0.52)

                ZStack {
                    GlassBottleBody(
                        progress: CGFloat(store.progressToday),
                        phase: phase
                    )

                    // Show the ENTIRE seated character, including both sneakers.
                    // The sprite is never cropped and no second pose is overlaid.
                    MascotView(pose: "MascotIdle")
                        .frame(width: mascotSize, height: mascotSize)
                        .position(x: w / 2, y: h * 0.57)
                        .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(store.consumedToday.formatted(.number))
                                .font(.system(size: 41, weight: .bold, design: .rounded))
                            Text("ml")
                                .font(.system(size: 22, weight: .medium))
                        }
                        Text("Remaining \(store.remainingToday.formatted()) ml")
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.muted)
                    }
                    .foregroundStyle(Palette.navy)
                    .position(x: w / 2, y: h * 0.20)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(Palette.blue)
                            .frame(width: 94, height: 94)
                            .background(.white.opacity(0.97), in: Circle())
                            .overlay {
                                Circle().strokeBorder(Palette.lavender, lineWidth: 2)
                            }
                            .shadow(color: Palette.navy.opacity(0.14), radius: 15, y: 7)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a drink")
                    .position(x: w / 2, y: h * 0.89)
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Palette.blue)
                            .frame(width: w * 0.54, height: 66)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Palette.lavender)
                            .frame(width: w * 0.48, height: 14)
                    }
                    .offset(y: -64)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 68)
            .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
