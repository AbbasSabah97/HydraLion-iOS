import SwiftUI

struct RemindersView: View {
    @EnvironmentObject private var store: HydrationStore
    let onBack: () -> Void
    let onGoal: () -> Void

    private var startBinding: Binding<Date> {
        Binding(
            get: { date(fromMinutes: store.reminder.startMinutes) },
            set: { date in
                let minute = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
                store.reminder.startMinutes = minute
                if minute >= store.reminder.endMinutes { store.reminder.endMinutes = min(1439, minute + 60) }
                store.refreshReminders()
            }
        )
    }
    private var endBinding: Binding<Date> {
        Binding(
            get: { date(fromMinutes: store.reminder.endMinutes) },
            set: { date in
                let minute = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
                guard minute > store.reminder.startMinutes else { return }
                store.reminder.endMinutes = minute
                store.refreshReminders()
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Reminder").font(.system(size: 18, weight: .semibold))
                            Text("Get notified to drink water")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Toggle("Reminder", isOn: Binding(get: { store.reminder.enabled }, set: { store.setReminderEnabled($0) }))
                            .labelsHidden()
                            .tint(Palette.blue)
                    }
                    .padding(.horizontal, 20)
                     .frame(height: 96)
                    Divider().opacity(0.5)
                    HStack {
                        Text("Interval")
                        Spacer()
                        Menu {
                            ForEach([15, 30, 45, 60, 90, 120, 180], id: \.self) { minutes in
                                Button("\(minutes) minutes") {
                                    store.reminder.intervalMinutes = minutes
                                    store.refreshReminders()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(store.reminder.intervalMinutes) minutes").foregroundStyle(Palette.muted)
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    .padding(.horizontal, 20).frame(height: 68)
                    Divider().opacity(0.5)
                    HStack {
                        Text("Start Time")
                        Spacer()
                        DatePicker("Start Time", selection: startBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Palette.blue)
                    }
                    .padding(.horizontal, 20).frame(height: 68)
                    Divider().opacity(0.5)
                    HStack {
                        Text("End Time")
                        Spacer()
                        DatePicker("End Time", selection: endBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Palette.blue)
                    }
                    .padding(.horizontal, 20).frame(height: 68)
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.navy)
                .background(.white, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.panel, lineWidth: 2))

                VStack(spacing: 0) {
                    Text("Notifications")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20).frame(height: 66)
                    Divider().opacity(0.5)
                    Toggle("Sound", isOn: Binding(get: { store.reminder.soundEnabled }, set: {
                        store.reminder.soundEnabled = $0
                        store.refreshReminders()
                    }))
                    .tint(Palette.blue)
                    .padding(.horizontal, 20).frame(height: 68)
                    Divider().opacity(0.5)
                    HStack {
                        Text("Message")
                        Spacer()
                        TextField("Notification message", text: Binding(get: { store.reminder.message }, set: {
                            store.reminder.message = $0
                            store.refreshReminders()
                        }))
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                    }
                    .padding(.horizontal, 20).frame(height: 68)
                    Divider().opacity(0.5)
                    HStack {
                        Text("Snooze")
                        Spacer()
                        Menu {
                            ForEach([5, 10, 15, 30], id: \.self) { minutes in
                                Button("\(minutes) minutes") {
                                    store.reminder.snoozeMinutes = minutes
                                    store.refreshReminders()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(store.reminder.snoozeMinutes) minutes").foregroundStyle(Palette.muted)
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    .padding(.horizontal, 20).frame(height: 68)
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.navy)
                .background(.white, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.panel, lineWidth: 2))
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            SectionHeader(title: "Reminders", showBack: true, onBack: onBack, onMenu: onGoal)
                .background(.white)
        }
    }

    private func date(fromMinutes minutes: Int) -> Date {
        Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(minutes * 60))
    }
}
