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

private struct SurfaceLine: Shape {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.height / 2
        for x in stride(from: CGFloat(0), through: rect.width, by: 4) {
            let y = mid + sin(x / max(rect.width, 1) * .pi * 2 + phase) * 6
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

private struct GlassBottleBody: View {
    let layers: [BottleLiquidLayer]
    let phase: CGFloat
    let time: TimeInterval

    private let bubbleX: [CGFloat] = [0.20, 0.37, 0.53, 0.69, 0.83, 0.28, 0.47, 0.76, 0.16, 0.60, 0.88, 0.33]

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let filledFraction = layers.last?.endFraction ?? 0
            let liquidHeight = h * filledFraction

            ZStack(alignment: .bottom) {
                BottleShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.95, blue: 1).opacity(0.54),
                                Color.white.opacity(0.16),
                                Color(red: 0.79, green: 0.88, blue: 1).opacity(0.52)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Each drink occupies only its own vertical portion.
                // Previous liquids keep their colors as new drinks stack above them.
                ForEach(layers) { layer in
                    let bandHeight = h * (layer.endFraction - layer.startFraction)
                    let baseOffset = h * layer.startFraction
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: layer.kind.liquidGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: max(0, bandHeight))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(y: -baseOffset)
                }

                if liquidHeight > 2 {
                    SurfaceLine(phase: phase)
                        .stroke(.white.opacity(0.64), lineWidth: 2.0)
                        .frame(height: 24)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(y: -(liquidHeight - 12))

                    // Bubbles rise through all drink layers and wrap to the bottom.
                    ZStack {
                        ForEach(0..<bubbleX.count, id: \.self) { index in
                            let diameter = CGFloat(7 + (index % 5) * 3)
                            let speed = 0.14 + Double(index % 4) * 0.045
                            let rise = CGFloat(
                                (time * speed + Double(index) * 0.17)
                                    .truncatingRemainder(dividingBy: 1)
                            )
                            Circle()
                                .fill(.white.opacity(0.14))
                                .overlay {
                                    Circle()
                                        .stroke(.white.opacity(0.78), lineWidth: 1.4)
                                }
                                .frame(width: diameter, height: diameter)
                                .position(
                                    x: w * bubbleX[index] + sin(phase + CGFloat(index)) * 6,
                                    y: liquidHeight * (1 - rise)
                                )
                        }
                    }
                    .frame(width: w, height: liquidHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.76), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.05, height: h * 0.46)
                    .rotationEffect(.degrees(7))
                    .position(x: w * 0.14, y: h * 0.48)

                Capsule()
                    .fill(.white.opacity(0.27))
                    .frame(width: w * 0.025, height: h * 0.32)
                    .rotationEffect(.degrees(-7))
                    .position(x: w * 0.88, y: h * 0.49)
            }
            .clipShape(BottleShape())
            .overlay {
                BottleShape()
                    .stroke(Palette.bottleStroke.opacity(0.90), lineWidth: 2.6)
            }
            .shadow(color: Palette.navy.opacity(0.10), radius: 14, y: 7)
        }
    }
}

// The supplied mascot image ends across both shoe toes.
// These shoe-tip continuations soften that hard image edge without redrawing his face/body.
private struct CompletedMascot: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { index in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(red: 0.79, green: 0.82, blue: 0.90)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Ellipse().stroke(Color(red: 0.73, green: 0.77, blue: 0.86), lineWidth: 1)
                    }
                    .frame(width: size * 0.235, height: size * 0.094)
                    .position(x: size * (index == 0 ? 0.38 : 0.62), y: size * 0.958)
            }

            MascotView(pose: "MascotIdle")
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: HydrationStore
    let onAdd: () -> Void
    let onGoal: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "", onMenu: onGoal)

            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let mascotSize = min(w * 0.79, h * 0.46)

                TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let phase = CGFloat(time.truncatingRemainder(dividingBy: 3.6) / 3.6) * .pi * 2

                    ZStack {
                        GlassBottleBody(
                            layers: store.bottleLayers,
                            phase: phase,
                            time: time
                        )

                        CompletedMascot(size: mascotSize)
                            .position(x: w / 2, y: h * 0.52)
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 68)
            .padding(.bottom, 12)
        }
    }
}
