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
        drawSurface(context: liquidContext, width: w, surfaceY: surfaceY)
        drawBubbles(context: liquidContext, size: size, fillHeight: fillHeight)
    }

    private func drawColorClouds(context: GraphicsContext, size: CGSize) {
        // Low-contrast refraction regions instead of drawn parallel stripes.
        let width = size.width
        let waterHeight = size.height * level
        for index in 0..<3 {
            let drift = sin(phase * (0.14 + CGFloat(index) * 0.07) + CGFloat(index))
            let cx = width * (index == 1 ? 0.68 : 0.37) + drift * width * 0.07
            let cy = size.height - waterHeight * (0.27 + CGFloat(index) * 0.24)
            let spread = width * (index == 0 ? 0.75 : 0.58)
            let center = CGPoint(x: cx, y: cy)
            let region = CGRect(x: cx-spread/2,y: cy-waterHeight*0.21,
                                width: spread,height: max(28, waterHeight*0.42))
            var mist = context
            mist.addFilter(.blur(radius: 27))
            let light = index.isMultiple(of: 2)
                ? Color(red: 0.70, green: 0.89, blue: 1.0).opacity(0.09)
                : Color(red: 0.25, green: 0.66, blue: 0.95).opacity(0.11)
            mist.fill(Path(ellipseIn: region),
                      with: .radialGradient(Gradient(colors: [light,.clear]),
                                            center: center,startRadius: 0,endRadius: spread*0.58))
        }
    }

    private func drawSurface(context: GraphicsContext, width: CGFloat, surfaceY: CGFloat) {
        // One soft crest is the only illuminated contour. No parallel line art.
        var crest = Path()
        for x in stride(from: CGFloat(-4), through: width + 5, by: 5) {
            let waveA = sin((x / width) * .pi * 2 + phase * 0.49) * 9
            let waveB = sin((x / width) * .pi * 3.7 - phase * 0.32 + 0.8) * 4
            let y = surfaceY + 8 + waveA + waveB
            if x <= -4 { crest.move(to: CGPoint(x: x, y: y)) }
            else { crest.addLine(to: CGPoint(x: x, y: y)) }
        }
        var diffuse = context
        diffuse.addFilter(.blur(radius: 6))
        diffuse.stroke(crest, with: .color(.white.opacity(0.52)),
                       style: StrokeStyle(lineWidth: 10, lineCap: .round))
        context.stroke(crest, with: .color(.white.opacity(0.53)),
                       style: StrokeStyle(lineWidth: 1.15, lineCap: .round))
    }

    private func drawBubbles(context: GraphicsContext, size: CGSize, fillHeight: CGFloat) {
        let w = size.width
        let h = size.height
        for index in bubblePositions.indices {
            let radius: CGFloat = 2.8 + CGFloat(index % 5) * 1.55
            // Each bubble rises at a slightly different speed and wraps below the
            // surface; it never reverses or resets the animation timeline.
            let velocity = 0.075 + Double(index % 6) * 0.019
            let distance = (time * velocity + Double(index) * 0.217)
                .truncatingRemainder(dividingBy: 1)
            let x = w * bubblePositions[index]
                + sin(phase * 0.62 + CGFloat(index) * 1.81) * 5
            let y = h - CGFloat(distance) * fillHeight
            // Fade bubbles while crossing the surface.
            let fade = min(1, max(0, (h - fillHeight - y + radius + 15) * -1 / 15))
            let alpha = Double(max(0.12, fade))
            let bubble = Path(ellipseIn: CGRect(x:x-radius,y:y-radius,
                                                 width:radius*2,height:radius*2))
            context.fill(bubble, with: .color(.white.opacity(0.07*alpha)))
            context.stroke(bubble, with: .color(.white.opacity(0.65*alpha)), lineWidth: 1.2)
            let specular = CGRect(x:x-radius*0.35,y:y-radius*0.62,
                                  width:max(1,radius*0.30),height:max(1,radius*0.24))
            context.fill(Path(ellipseIn: specular),
                         with: .color(.white.opacity(0.69*alpha)))
        }
    }

    private func fluidPath(width: CGFloat, height: CGFloat, surfaceY: CGFloat, phase: CGFloat) -> Path {
        var path = Path()
        for x in stride(from: CGFloat(0), through: width + 5, by: 5) {
            let y = surfaceY + 8
                + sin((x / width) * .pi * 2 + phase * 0.49) * 9
                + sin((x / width) * .pi * 3.7 - phase * 0.32 + 0.8) * 4
            if x == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }

    private func liquidStops() -> [Gradient.Stop] {
        // Physically softer transparent blue: depth increases smoothly toward
        // the bottle floor; the water is never an opaque painted shape.
        [
            .init(color: Color(red: 0.34, green: 0.73, blue: 0.98).opacity(0.80), location: 0.00),
            .init(color: Color(red: 0.24, green: 0.65, blue: 0.96).opacity(0.85), location: 0.24),
            .init(color: Color(red: 0.13, green: 0.52, blue: 0.89).opacity(0.91), location: 0.63),
            .init(color: Color(red: 0.05, green: 0.35, blue: 0.74).opacity(0.98), location: 1.00)
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
                let mascotSize = min(w * 0.82, h * 0.49)

                TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let phase = CGFloat(time)

                    ZStack {
                        GlassBottleBody(
                            progress: CGFloat(store.progressToday),
                            phase: phase,
                            time: time
                        )

                        MascotView(pose: "MascotIdle")
                            .frame(width: mascotSize, height: mascotSize)
                            .position(x: w / 2, y: h * 0.49)
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
