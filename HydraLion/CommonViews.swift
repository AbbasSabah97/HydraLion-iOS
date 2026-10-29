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

    var body: some View {
        // Exactly one original transparent asset is rendered; overlapping poses are disabled.
        Image(pose)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .accessibilityLabel("HydraLion mascot")
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
                .shadow(color: Palette.blue.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct BottomTabBar: View {
    @Binding var selection: Tab
    enum Tab { case home, reminders }

    var body: some View {
        HStack {
            Spacer()
            tabButton("drop", selected: selection == .home) { selection = .home }
            Spacer()
            tabButton("power", selected: selection == .reminders) { selection = .reminders }
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 7)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.panel).frame(height: 1)
        }
    }

    private func tabButton(_ symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 29, weight: .regular))
                .foregroundStyle(selected ? Color.white : Palette.navy.opacity(0.82))
                .frame(width: 66, height: 66)
                .background(selected ? Palette.navy.opacity(0.78) : Color.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "drop" ? "Home" : "Reminders")
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
                .shadow(color: Palette.blue.opacity(0.24), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
    }
}

struct HomeShortcutButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.navy)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }
}
