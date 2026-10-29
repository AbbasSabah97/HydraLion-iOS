import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: HydrationStore
    @State private var selected: BottomTabBar.Tab = .home
    @State private var showAdd = false
    @State private var showStats = false
    @State private var showHistory = false
    @State private var showGoal = false
    @State private var newGoal = "3000"

    var body: some View {
        VStack(spacing: 0) {
            if selected == .home {
                if showHistory {
                    HistoryView(onBack: { showHistory = false }, onGoal: showGoalSheet)
                } else if showStats {
                    StatisticsView(onBack: { showStats = false }, onGoal: showGoalSheet)
                } else if showAdd {
                    AddDrinkView(onBack: { showAdd = false }, onGoal: showGoalSheet)
                } else {
                    HomeView(onAdd: { showAdd = true }, onStats: { showStats = true },
                             onHistory: { showHistory = true }, onGoal: showGoalSheet)
                }
            } else {
                RemindersView(onBack: { selected = .home }, onGoal: showGoalSheet)
            }
            if !showAdd {
                BottomTabBar(selection: $selected)
                    .padding(.horizontal, 2)
            }
        }
        .background(.white)
        .sheet(isPresented: $showGoal) {
            NavigationStack {
                Form {
                    TextField("Daily goal (ml)", text: $newGoal)
                        .keyboardType(.numberPad)
                }
                .navigationTitle("Daily water goal")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showGoal = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let value = Int(newGoal), (250...10000).contains(value) { store.dailyGoal = value }
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
