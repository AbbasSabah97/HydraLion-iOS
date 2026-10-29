import SwiftUI

struct BottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.28, y: 0))
        p.addCurve(to: CGPoint(x: w * 0.04, y: h * 0.26),
                   control1: CGPoint(x: w * 0.10, y: h * 0.04), control2: CGPoint(x: w * 0.04, y: h * 0.12))
        p.addLine(to: CGPoint(x: w * 0.04, y: h * 0.83))
        p.addQuadCurve(to: CGPoint(x: w * 0.21, y: h), control: CGPoint(x: w * 0.04, y: h))
        p.addLine(to: CGPoint(x: w * 0.79, y: h))
        p.addQuadCurve(to: CGPoint(x: w * 0.96, y: h * 0.83), control: CGPoint(x: w * 0.96, y: h))
        p.addLine(to: CGPoint(x: w * 0.96, y: h * 0.26))
        p.addCurve(to: CGPoint(x: w * 0.72, y: 0),
                   control1: CGPoint(x: w * 0.96, y: h * 0.12), control2: CGPoint(x: w * 0.90, y: h * 0.04))
        p.closeSubpath()
        return p
    }
}

struct WaterWave: Shape {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height * 0.08))
        let height = rect.height * 0.08
        for x in stride(from: CGFloat(0), through: rect.width, by: 5) {
            let y = height + sin((x / max(rect.width, 1)) * .pi * 2 + phase) * 13
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
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
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .top) {
                    BottleShape()
                        .fill(Palette.bottleGradient)
                        .overlay(alignment: .bottom) {
                            GeometryReader { bottle in
                                let fillHeight = max(0, bottle.size.height * CGFloat(store.progressToday))
                                if fillHeight > 0 {
                                    WaterWave(phase: phase)
                                        .fill(LinearGradient(colors: [Palette.blueBright, Palette.blue],
                                                             startPoint: .top, endPoint: .bottom))
                                        .frame(height: fillHeight)
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                }
                            }
                            .clipShape(BottleShape())
                        }
                        .overlay {
                            BottleShape().stroke(Palette.bottleStroke, lineWidth: 2.5)
                        }
                        .shadow(color: Palette.navy.opacity(0.08), radius: 14, y: 6)
                    // These are the original transparent mascot assets supplied by the user.
                    MascotView(pose: "MascotIdle")
                        .frame(width: w * 0.66, height: h * 0.38)
                        .position(x: w / 2, y: h * 0.54)
                        .accessibilityHidden(true)
                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(store.consumedToday.formatted(.number))
                                .font(.system(size: 43, weight: .bold, design: .rounded))
                            Text("ml").font(.system(size: 22, weight: .medium))
                        }
                        Text("Remaining \(store.remainingToday.formatted()) ml")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Palette.muted)
                    }
                    .foregroundStyle(Palette.navy)
                    .padding(.top, h * 0.14)
                    VStack {
                        Spacer()
                        Button(action: onAdd) {
                            Image(systemName: "plus")
                                .font(.system(size: 37, weight: .light))
                                .foregroundStyle(Palette.blue)
                                .frame(width: 94, height: 94)
                                .background(.white.opacity(0.96), in: Circle())
                                .overlay(Circle().strokeBorder(Palette.lavender, lineWidth: 2))
                                .shadow(color: Palette.navy.opacity(0.10), radius: 18)
                        }
                        .accessibilityLabel("Add a drink")
                        .padding(.bottom, h * 0.09)
                    }
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
            .padding(.bottom, 9)

        }
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { phase = .pi * 2 }
        }
    }
}
