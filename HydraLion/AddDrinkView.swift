import SwiftUI

struct AddDrinkView: View {
    @EnvironmentObject private var store: HydrationStore
    let onBack: () -> Void
    let onGoal: () -> Void
    @State private var kind: DrinkKind = .water
    @State private var amount: Int = 250
    @State private var didAdd = false

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Add Drink", showBack: true, onBack: onBack, onMenu: onGoal)
            Spacer(minLength: 12)
            HStack(alignment: .top, spacing: 0) {
                ForEach(DrinkKind.allCases) { drink in
                    Button { withAnimation(.easeInOut(duration: 0.18)) { kind = drink } } label: {
                        VStack(spacing: 9) {
                            Image(systemName: drink.symbol)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(kind == drink ? .white : drink.accent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(kind == drink ? Palette.gradient : LinearGradient(colors: [drink.soft, drink.soft], startPoint: .top, endPoint: .bottom),
                                            in: Circle())
                            Text(drink.title)
                                .font(.system(size: 13, weight: kind == drink ? .semibold : .regular))
                                .foregroundStyle(kind == drink ? Palette.blue : Palette.navy)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(drink.title)
                }
            }
            .padding(.horizontal, 12)
            Spacer(minLength: 20)
            HStack {
                amountButton("minus") { amount = max(50, amount - 50) }
                Spacer()
                Text("\(amount) ml")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.navy)
                    .contentTransition(.numericText())
                Spacer()
                amountButton("plus") { amount = min(3000, amount + 50) }
            }
            .padding(.horizontal, 45)
            .padding(.bottom, 20)
            HStack(spacing: 10) {
                ForEach([150, 250, 330, 500], id: \.self) { preset in
                    Button {
                        withAnimation { amount = preset }
                    } label: {
                        Text("\(preset) ml")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(amount == preset ? .white : Palette.navy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 61)
                            .background(amount == preset ? Palette.gradient : LinearGradient(colors: [Palette.panel, Palette.panel], startPoint: .top, endPoint: .bottom),
                                        in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 5)
            MascotView(pose: didAdd ? "MascotCheers" : "MascotDrink")
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 340)
            PrimaryButton(title: didAdd ? "Drink Added!" : "Add Drink") {
                store.add(kind, milliliters: amount)
                didAdd = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onBack() }
            }
            .disabled(didAdd)
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    private func amountButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(Palette.blue)
                .frame(width: 55, height: 55)
                .background(Palette.panel, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
