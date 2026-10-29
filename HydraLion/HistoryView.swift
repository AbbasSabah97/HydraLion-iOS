import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: HydrationStore
    let onBack: () -> Void
    let onGoal: () -> Void
    @State private var period = 0
    @State private var selectedDate = Date()
    @State private var editing: DrinkEntry?

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "History", showBack: true, onBack: onBack, onMenu: onGoal)
            Picker("Period", selection: $period) {
                Text("Day").tag(0)
                Text("Week").tag(1)
                Text("Month").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .padding(.bottom, 22)
            if period == 0 {
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        let selected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        Button { selectedDate = date } label: {
                            VStack(spacing: 9) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.system(size: 12))
                                Text(date.formatted(.dateTime.day()))
                                    .font(.system(size: 21, weight: .medium))
                            }
                            .foregroundStyle(selected ? .white : Palette.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 76)
                            .background(selected ? Palette.gradient : LinearGradient(colors: [.clear,.clear], startPoint: .top, endPoint: .bottom),
                                        in: RoundedRectangle(cornerRadius: 17))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 17)
            } else {
                Text(period == 1 ? "Last 7 days" : "Last 30 days")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            ScrollView {
                if period == 0 {
                    let records = store.records(on: selectedDate)
                    if records.isEmpty { emptyState }
                    ForEach(records) { entry in
                        historyCard(entry)
                    }
                } else {
                    periodSummary
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 18)
            .scrollIndicators(.hidden)
        }
        .sheet(item: $editing) { entry in
            EditDrinkSheet(entry: entry) { newAmount in store.update(entry.id, amount: newAmount) }
                .presentationDetents([.medium])
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image("MascotRelax").resizable().scaledToFit().frame(height: 200)
            Text("No drinks recorded for this day")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 42)
    }

    private func historyCard(_ entry: DrinkEntry) -> some View {
        HStack(spacing: 15) {
            Image(systemName: entry.kind.symbol)
                .font(.system(size: 26))
                .foregroundStyle(entry.kind.accent)
                .frame(width: 62, height: 62)
                .background(entry.kind.soft, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.kind.historyTitle).font(.system(size: 17, weight: .medium))
                Text(entry.milliliters.milliliterLabel).font(.system(size: 17))
            }
            .foregroundStyle(Palette.navy)
            Spacer(minLength: 0)
            Text(entry.date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
            Menu {
                Button("Edit") { editing = entry }
                Button("Delete", role: .destructive) { store.delete(entry.id) }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.navy)
                    .frame(width: 30, height: 45)
            }
            .accessibilityLabel("Entry actions")
        }
        .padding(.horizontal, 12)
        .frame(height: 85)
        .frame(maxWidth: .infinity)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 21))
        .padding(.bottom, 9)
    }

    private var periodSummary: some View {
        let days = period == 1 ? 7 : 30
        let dates = (0..<days).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }.reversed()
        return VStack(spacing: 10) {
            ForEach(Array(dates), id: \.self) { date in
                HStack {
                    Text(date.formatted(.dateTime.month(.abbreviated).day()))
                        .foregroundStyle(Palette.navy)
                        .frame(width: 64, alignment: .leading)
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Palette.blue.opacity(0.85))
                            .frame(width: max(0, geometry.size.width * min(1, Double(store.total(on: date)) / Double(max(store.dailyGoal, 1)))), height: 16)
                    }
                    .frame(height: 16)
                    Text("\(store.total(on: date)) ml")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .frame(width: 67, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct EditDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: DrinkEntry
    let onSave: (Int) -> Void
    @State private var amount: String

    init(entry: DrinkEntry, onSave: @escaping (Int) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _amount = State(initialValue: String(entry.milliliters))
    }

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Drink", value: entry.kind.historyTitle)
                TextField("Amount in ml", text: $amount).keyboardType(.numberPad)
            }
            .navigationTitle("Edit Drink")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let ml = Int(amount), (10...3000).contains(ml) { onSave(ml) }
                        dismiss()
                    }
                }
            }
        }
    }
}
