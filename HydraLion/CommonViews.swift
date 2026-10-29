import SwiftUI

struct SectionHeader: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil
    var onMenu: (() -> Void)? = nil
    var body: some View {
        ZStack {
            Text(title).font(.system(size: 21, weight: .semibold, design: .rounded)).foregroundStyle(Palette.navy)
            HStack {
                if showBack {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left").font(.system(size: 23, weight: .medium))
                    }
                    .accessibilityLabel("Back")
                } else {
                    Color.clear.frame(width: 24, height: 24)
                }
                Spacer()
                Menu {
                    Button("Daily goal") { onMenu?() }
                } label: {
                    Image(systemName: "ellipsis").rotationEffect(.degrees(90)).font(.system(size: 23, weight: .bold))
                }
                .accessibilityLabel("Options")
            }
            .foregroundStyle(Palette.blue)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }
}

struct MascotView: View {
    var pose: String = "MascotIdle"
    var animateBlink = false
    @State private var blinking = false

    var body: some View {
        Image(blinking ? "MascotBlink" : pose)
            .resizable()
            .scaledToFit()
            .accessibilityLabel("HydraLion mascot")
            .task(id: animateBlink) {
                guard animateBlink else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if Task.isCancelled { break }
                    blinking = true
                    try? await Task.sleep(nanoseconds: 220_000_000)
                    blinking = false
                }
            }
    }
}

struct RoundPrimaryButton: View {
    let symbol: String
    var size: CGFloat = 58
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.39, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Palette.gradient, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct BottomTabBar: View {
    @Binding var selection: Tab
    enum Tab { case home, reminders }
    var body: some View {
        HStack {
            Button { selection = .home } label: {
                Image(systemName: "drop")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(selection == .home ? Color.white : Palette.navy.opacity(0.8))
                    .frame(width: 66, height: 66)
                    .background(selection == .home ? Palette.navy.opacity(0.75) : Color.clear, in: Circle())
            }
            Spacer()
            Button { selection = .reminders } label: {
                Image(systemName: "power")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(selection == .reminders ? Color.white : Palette.navy.opacity(0.8))
                    .frame(width: 66, height: 66)
                    .background(selection == .reminders ? Palette.navy.opacity(0.75) : Color.clear, in: Circle())
            }
        }
        .padding(.horizontal, 62)
        .padding(.bottom, 4)
        .background(.white)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 66)
                .background(Palette.gradient, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
