import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var store: HydrationStore
    var onBack: () -> Void
    var onGoal: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Water Reminder", showBack: true, onBack: onBack, onMenu: onGoal)
            Spacer(minLength: 24)
            ZStack {
                Circle()
                    .trim(from: 0.02, to: 0.98)
                    .stroke(Palette.panel, style: StrokeStyle(lineWidth: 19, lineCap: .round))
                Circle()
                    .trim(from: 0, to: max(0.001, CGFloat(store.progressToday) * 0.93))
                    .stroke(
                        AngularGradient(
                            colors: [Palette.lavender, Palette.blueBright],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 19, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-88))
                VStack(spacing: 15) {
                    Text(String(format: "%.2f %%", store.progressToday * 100))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text(store.consumedToday.milliliterLabel)
                        .font(.system(size: 29, weight: .semibold, design: .rounded))
                    Text("Remaining \(store.remainingToday) ml")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                }
                .foregroundStyle(Palette.navy)
            }
            .frame(width: 276, height: 276)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 26)
        .background(.white)
    }
}
