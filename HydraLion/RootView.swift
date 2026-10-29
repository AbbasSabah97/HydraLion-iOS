import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: HydrationStore
    @State private var selected: BottomTabBar.Tab = .home
    @State private var showAdd = false
    @State private var showGoal = false
    @State private var newGoal = "3000"

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if showAdd {
                    AddDrinkView(onBack: { showAdd = false }, onGoal: showGoalSheet)
                } else {
                    switch selected {
                    case .home:
                        HomeView(onAdd: { showAdd = true }, onGoal: showGoalSheet)
                    case .history:
                        HistoryView(onBack: { selected = .home }, onGoal: showGoalSheet)
                    case .progress:
                        StatisticsView(onBack: { selected = .home }, onGoal: showGoalSheet)
                    case .reminders:
                        RemindersView(onBack: { selected = .home }, onGoal: showGoalSheet)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !showAdd {
                BottomTabBar(selection: $selected)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showGoal) {
            NavigationStack {
                Form {
                    TextField("Daily goal (ml)", text: $newGoal)
                        .keyboardType(.numberPad)
                }
                .navigationTitle("Daily water goal")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showGoal = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let value = Int(newGoal), (250...10000).contains(value) {
                                store.dailyGoal = value
                            }
                            showGoal = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func showGoalSheet() {
        newGoal = String(store.dailyGoal)
        showGoal = true
    }
}
