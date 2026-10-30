import SwiftUI
import UserNotifications

// Persist locally so water history works without network connectivity.
enum DrinkKind: String, Codable, CaseIterable, Identifiable {
    case water, tea, coffee, juice, milk
    var id: String { rawValue }
    var title: String {
        switch self {
        case .water: return "Water"
        case .tea: return "Tea"
        case .coffee: return "Coffee"
        case .juice: return "Juice"
        case .milk: return "Milk"
        }
    }
    var historyTitle: String {
        switch self {
        case .tea: return "Green Tea"
        case .juice: return "Orange Juice"
        default: return title
        }
    }
    var symbol: String {
        switch self {
        case .water: return "drop"
        case .tea: return "cup.and.saucer.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .juice: return "drop.fill"
        case .milk: return "water.waves"
        }
    }
    var accent: Color {
        switch self {
        case .water: return Palette.blue
        case .tea: return Color(red: 0.19, green: 0.63, blue: 0.35)
        case .coffee: return Color(red: 0.65, green: 0.40, blue: 0.26)
        case .juice: return Color(red: 1.0, green: 0.60, blue: 0.02)
        case .milk: return Color(red: 0.36, green: 0.53, blue: 0.90)
        }
    }
    var soft: Color { accent.opacity(0.09) }

    // Last drink of today determines the liquid tint shown in the glass bottle.
    var liquidGradient: [Color] {
        switch self {
        case .water:
            return [
                Color(red: 0.64, green: 0.80, blue: 1.0).opacity(0.32),
                Palette.blue.opacity(0.52),
                Palette.blueBright.opacity(0.67)
            ]
        case .juice:
            return [
                Color(red: 1.0, green: 0.88, blue: 0.52).opacity(0.34),
                Color(red: 0.99, green: 0.70, blue: 0.22).opacity(0.55),
                Color(red: 0.95, green: 0.50, blue: 0.06).opacity(0.72)
            ]
        case .tea:
            return [
                Color(red: 0.95, green: 0.89, blue: 0.77).opacity(0.31),
                Color(red: 0.87, green: 0.77, blue: 0.62).opacity(0.48),
                Color(red: 0.78, green: 0.67, blue: 0.52).opacity(0.62)
            ]
        case .milk:
            return [
                Color.white.opacity(0.80),
                Color(red: 0.97, green: 0.98, blue: 1.0).opacity(0.90),
                Color(red: 0.90, green: 0.93, blue: 0.98).opacity(0.94)
            ]
        case .coffee:
            return [
                Color(red: 0.56, green: 0.39, blue: 0.26).opacity(0.41),
                Color(red: 0.42, green: 0.27, blue: 0.15).opacity(0.61),
                Color(red: 0.26, green: 0.15, blue: 0.08).opacity(0.78)
            ]
        }
    }

}

struct DrinkEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: DrinkKind
    var milliliters: Int
    var date: Date = .now
}

struct ReminderSettings: Codable, Equatable {
    var enabled = false
    var intervalMinutes = 60
    var startMinutes = 8 * 60
    var endMinutes = 22 * 60
    var message = "Time to drink water! 💧"
    var snoozeMinutes = 5
    var soundEnabled = true
}

private struct StoredHydration: Codable {
    var dailyGoal: Int = 3000
    var entries: [DrinkEntry] = []
    var reminder: ReminderSettings = ReminderSettings()
}

@MainActor
final class HydrationStore: ObservableObject {
    @Published var entries: [DrinkEntry] { didSet { save() } }
    @Published var dailyGoal: Int { didSet { save() } }
    @Published var reminder: ReminderSettings { didSet { save() } }

    private let key = "HydraLion-State-v1"

    init() {
        let state: StoredHydration
        if let bytes = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(StoredHydration.self, from: bytes) {
            state = decoded
        } else { state = StoredHydration() }
        entries = state.entries
        dailyGoal = max(250, state.dailyGoal)
        reminder = state.reminder
    }

    private func save() {
        let state = StoredHydration(dailyGoal: dailyGoal, entries: entries, reminder: reminder)
        if let bytes = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(bytes, forKey: key)
        }
    }

    func total(on date: Date) -> Int {
        entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.milliliters }
    }

    var consumedToday: Int { total(on: .now) }
    var remainingToday: Int { max(0, dailyGoal - consumedToday) }
    var progressToday: Double { min(1, Double(consumedToday) / Double(max(dailyGoal, 1))) }
    var latestDrinkToday: DrinkKind? { entries.first(where: { Calendar.current.isDateInToday($0.date) })?.kind }
    var bottleLiquidColors: [Color] { (latestDrinkToday ?? .water).liquidGradient }

    func add(_ kind: DrinkKind, milliliters: Int) {
        entries.insert(DrinkEntry(kind: kind, milliliters: max(10, milliliters)), at: 0)
    }

    func delete(_ id: UUID) { entries.removeAll { $0.id == id } }

    func update(_ id: UUID, amount: Int) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].milliliters = max(10, amount)
    }

    func records(on date: Date) -> [DrinkEntry] {
        entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func setReminderEnabled(_ enabled: Bool) {
        var newValue = reminder
        newValue.enabled = enabled
        reminder = newValue
        Task { await updateNotifications() }
    }

    func refreshReminders() { Task { await updateNotifications() } }

    private func updateNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("hydra-daily-") })
        guard reminder.enabled else { return }
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        guard granted == true else {
            reminder.enabled = false
            return
        }
        UserDefaults.standard.set(reminder.snoozeMinutes, forKey: "HydraSnoozeMinutes")
        // iOS retains a limited number of pending notifications. At >= 15 min there are <= 64 daily slots.
        let interval = max(15, reminder.intervalMinutes)
        guard reminder.startMinutes < reminder.endMinutes else { return }
        let slots = stride(from: reminder.startMinutes, through: reminder.endMinutes, by: interval)
        for (index, minute) in slots.prefix(64).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "HydraLion 💧"
            content.body = reminder.message
            content.categoryIdentifier = "HYDRA_WATER"
            if reminder.soundEnabled { content.sound = .default }
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minute / 60, minute: minute % 60), repeats: true)
            let request = UNNotificationRequest(identifier: "hydra-daily-\(index)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}

enum Palette {
    static let blue = Color(red: 0.31, green: 0.40, blue: 0.98)
    static let blueBright = Color(red: 0.20, green: 0.39, blue: 1.0)
    static let lavender = Color(red: 0.65, green: 0.70, blue: 1.0)
    static let navy = Color(red: 0.055, green: 0.085, blue: 0.32)
    static let muted = Color(red: 0.47, green: 0.50, blue: 0.61)
    static let panel = Color(red: 0.953, green: 0.961, blue: 0.993)
    static let bottleTop = Color(red: 0.92, green: 0.95, blue: 1.0)
    static let bottleBottom = Color(red: 0.84, green: 0.89, blue: 0.98)
    static let bottleStroke = Color(red: 0.75, green: 0.82, blue: 0.96)
    static let bottleGradient = LinearGradient(colors: [bottleTop, .white, bottleBottom],
                                                startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gradient = LinearGradient(colors: [blueBright, blue], startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Int {
    var milliliterLabel: String { "\(self.formatted(.number)) ml" }
}
