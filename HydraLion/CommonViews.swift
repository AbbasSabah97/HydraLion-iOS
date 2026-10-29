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

    enum Tab: CaseIterable {
        case home, history, progress, reminders

        var symbol: String {
            switch self {
            case .home: return "drop"
            case .history: return "clock.arrow.circlepath"
            case .progress: return "chart.bar"
            case .reminders: return "bell"
            }
        }

        var selectedSymbol: String {
            switch self {
            case .home: return "drop.fill"
            case .history: return "clock.arrow.circlepath"
            case .progress: return "chart.bar.fill"
            case .reminders: return "bell.fill"
            }
        }

        var title: String {
            switch self {
            case .home: return "Home"
            case .history: return "History"
            case .progress: return "Progress"
            case .reminders: return "Reminders"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        selection = tab
                    }
                } label: {
                    Image(systemName: selection == tab ? tab.selectedSymbol : tab.symbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(selection == tab ? Color.white : Palette.navy.opacity(0.76))
                        .frame(width: 44, height: 44)
                        .background {
                            if selection == tab {
                                Circle().fill(Palette.gradient)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.panel)
                .frame(height: 1)
        }
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
