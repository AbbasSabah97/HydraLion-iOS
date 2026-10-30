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

// A single animated volume. Color zones blend together inside one continuous liquid
// shape; there are no independent rectangular bands or horizontal separators.
private struct FluidVolume: View {
    let progress: CGFloat
    let phase: CGFloat
    let time: TimeInterval

    private let bubblePositions: [CGFloat] = [0.12, 0.22, 0.33, 0.45, 0.57, 0.67, 0.78, 0.86, 0.29, 0.51, 0.73, 0.39, 0.18, 0.61, 0.83, 0.49]

    private var level: CGFloat { min(1, max(0, progress)) }

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            drawFluid(context: context, size: size)
        }
        .accessibilityHidden(true)
    }

    private func drawFluid(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let fillHeight = level * h
        guard fillHeight > 2 else { return }

        let surfaceY = h - fillHeight
        let fillShape = fluidPath(width: w, height: h, surfaceY: surfaceY, phase: phase)

        var liquidContext = context
        liquidContext.clip(to: fillShape)

        let baseGradient = Gradient(stops: liquidStops())
        let baseShading = GraphicsContext.Shading.linearGradient(
            baseGradient,
            startPoint: CGPoint(x: w / 2, y: surfaceY),
            endPoint: CGPoint(x: w / 2, y: h)
        )
        liquidContext.fill(Path(CGRect(origin: .zero, size: size)), with: baseShading)

        drawColorClouds(context: liquidContext, size: size)
        drawCaustics(context: liquidContext, size: size, surfaceY: surfaceY, fillHeight: fillHeight)
        drawSurface(context: liquidContext, width: w, surfaceY: surfaceY)
        drawBubbles(context: liquidContext, size: size, fillHeight: fillHeight)
    }

    private func drawColorClouds(context: GraphicsContext, size: CGSize) {
        // Natural subsurface light scattering, with only clear blue water.
        let w = size.width
        let h = size.height
        let filledHeight = h * level
        for index in 0..<5 {
            let t = CGFloat(index) / 5
            let cloudWidth = w * (0.56 + t * 0.26)
            let cloudHeight = max(40, filledHeight * 0.38)
            let cx = w * (index.isMultiple(of: 2) ? 0.39 : 0.64)
                   + sin(phase * 0.34 + CGFloat(index)) * w * 0.06
            let cy = h - filledHeight * (0.18 + t * 0.73)
                   + cos(phase * 0.46 + CGFloat(index)) * 9
            let center = CGPoint(x: cx, y: cy)
            let region = CGRect(x: cx - cloudWidth / 2, y: cy - cloudHeight / 2,
                                width: cloudWidth, height: cloudHeight)
            var blurred = context
            blurred.addFilter(.blur(radius: max(13, w * 0.062)))
            let cloudTint = index.isMultiple(of: 2)
                ? Color.white.opacity(0.26)
                : Color(red: 0.52, green: 0.83, blue: 1.0).opacity(0.23)
            let shader = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [cloudTint, cloudTint.opacity(0.28), .clear]),
                center: center, startRadius: 0, endRadius: cloudWidth * 0.65)
            blurred.fill(Path(ellipseIn: region), with: shader)
        }
    }

    private func drawCaustics(context: GraphicsContext, size: CGSize,
                              surfaceY: CGFloat, fillHeight: CGFloat) {
        let w = size.width
        for index in 0..<16 {
            let normalized = CGFloat(index + 1) / 17
            let baseY = surfaceY + fillHeight * normalized
            var wave = Path()
            for x in stride(from: CGFloat(0), through: w + 5, by: 7) {
                let one = sin(x / w * .pi * 2.2 + phase * 0.56 + CGFloat(index) * 0.71)
                let two = sin(x / w * .pi * 4.2 - phase * 0.3 + CGFloat(index))
                let y = baseY + one * (8 + normalized * 12) + two * 4
                if x == 0 { wave.move(to: CGPoint(x: x, y: y)) }
                else { wave.addLine(to: CGPoint(x: x, y: y)) }
            }
            let highlight = index.isMultiple(of: 3)
            context.stroke(
                wave,
                with: .color(.white.opacity(highlight ? 0.28 : 0.11)),
                style: StrokeStyle(lineWidth: highlight ? 2.6 : 1.2, lineCap: .round)
            )
        }
    }

    private func drawSurface(context: GraphicsContext, width: CGFloat, surfaceY: CGFloat) {
        var crest = Path()
        for x in stride(from: CGFloat(0), through: width + 5, by: 5) {
            let large = sin(x / width * .pi * 2 + phase * 0.67) * 9
            let small = sin(x / width * .pi * 4 - phase * 0.30) * 3
            let y = surfaceY + 10 + large + small
            if x == 0 { crest.move(to: CGPoint(x: x, y: y)) }
            else { crest.addLine(to: CGPoint(x: x, y: y)) }
        }
        context.stroke(
            crest,
            with: .color(.white.opacity(0.80)),
            style: StrokeStyle(lineWidth: 3.1, lineCap: .round)
        )
    }

    private func drawBubbles(context: GraphicsContext, size: CGSize, fillHeight: CGFloat) {
        let w = size.width
        let h = size.height
        for index in bubblePositions.indices {
            let radius = CGFloat(3 + (index % 5) * 2)
            let velocity = 0.09 + Double(index % 5) * 0.024
            let distance = (time * velocity + Double(index) * 0.237).truncatingRemainder(dividingBy: 1)
            let x = w * bubblePositions[index] + sin(phase + CGFloat(index) * 2) * 7
            let y = h - CGFloat(distance) * fillHeight
            let rect = CGRect(x: x - radius, y: y - radius,
                              width: radius * 2, height: radius * 2)
            let bubble = Path(ellipseIn: rect)
            context.fill(bubble, with: .color(.white.opacity(0.11)))
            context.stroke(bubble, with: .color(.white.opacity(0.68)), lineWidth: 1.2)
            let tiny = CGRect(x: x - radius * 0.42, y: y - radius * 0.56,
                              width: max(1, radius * 0.34), height: max(1, radius * 0.24))
            context.fill(Path(ellipseIn: tiny), with: .color(.white.opacity(0.86)))
        }
    }

    private func fluidPath(width: CGFloat, height: CGFloat, surfaceY: CGFloat, phase: CGFloat) -> Path {
        var path = Path()
        let travel: CGFloat = 10
        for x in stride(from: CGFloat(0), through: width + 5, by: 5) {
            let y = surfaceY + travel
                + sin(x / width * .pi * 2 + phase * 0.67) * 9
                + sin(x / width * .pi * 4 - phase * 0.30) * 3
            if x == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }

    private func liquidStops() -> [Gradient.Stop] {
        // One continuous, translucent, water-blue liquid regardless of drink type.
        // Brighter near the wave crest, with gentle depth as volume increases.
        [
            .init(color: Color(red: 0.84, green: 0.95, blue: 1.0).opacity(0.37), location: 0.00),
            .init(color: Color(red: 0.56, green: 0.84, blue: 1.0).opacity(0.54), location: 0.28),
            .init(color: Color(red: 0.35, green: 0.70, blue: 0.99).opacity(0.61), location: 0.69),
            .init(color: Color(red: 0.26, green: 0.59, blue: 0.96).opacity(0.67), location: 1.00)
        ]
    }
}

private struct GlassBottleBody: View {
    let progress: CGFloat
    let phase: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            BottleShape()
                .fill(
                    LinearGradient(colors: [
                        Color(red: 0.91, green: 0.96, blue: 1).opacity(0.53),
                        Color.white.opacity(0.11),
                        Color(red: 0.84, green: 0.91, blue: 1).opacity(0.46)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            FluidVolume(progress: progress, phase: phase, time: time)
                .clipShape(BottleShape())

            // Two large soft specular sweeps, stronger inner and outer glass rims.
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0.88), .white.opacity(0.09)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.056, height: h * 0.42)
                    .rotationEffect(.degrees(7))
                    .position(x: w * 0.15, y: h * 0.45)
                Capsule()
                    .fill(.white.opacity(0.26))
                    .frame(width: w * 0.023, height: h * 0.27)
                    .rotationEffect(.degrees(-7))
                    .position(x: w * 0.88, y: h * 0.48)
            }
            .clipShape(BottleShape())

            BottleShape()
                .stroke(
                    LinearGradient(colors: [
                        Color.white.opacity(0.98),
                        Color(red: 0.47, green: 0.68, blue: 0.99).opacity(0.58),
                        Color.white.opacity(0.98),
                        Color(red: 0.40, green: 0.60, blue: 0.96).opacity(0.65)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 5.0
                )

            BottleShape()
                .stroke(.white.opacity(0.78), lineWidth: 1.5)
                .scaleEffect(x: 0.984, y: 0.993)
        }
        .shadow(color: Palette.blue.opacity(0.12), radius: 15, y: 8)
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
                let mascotSize = min(w * 0.83, h * 0.48)

                TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let phase = CGFloat(time.truncatingRemainder(dividingBy: 3.6) / 3.6) * .pi * 2

                    ZStack {
                        GlassBottleBody(
                            progress: CGFloat(store.progressToday),
                            phase: phase,
                            time: time
                        )

                        MascotView(pose: "MascotIdle")
                            .frame(width: mascotSize, height: mascotSize)
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
