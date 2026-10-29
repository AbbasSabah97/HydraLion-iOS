import SwiftUI
import UserNotifications

@main
struct HydraLionApp: App {
    @UIApplicationDelegateAdaptor(HydraAppDelegate.self) private var appDelegate
    @StateObject private var store = HydrationStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

final class HydraAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let snooze = UNNotificationAction(identifier: "HYDRA_SNOOZE", title: "Remind me later")
        center.setNotificationCategories([UNNotificationCategory(identifier: "HYDRA_WATER", actions: [snooze], intentIdentifiers: [])])
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "HYDRA_SNOOZE" {
            let minutes = max(1, UserDefaults.standard.integer(forKey: "HydraSnoozeMinutes"))
            let content = UNMutableNotificationContent()
            content.title = "HydraLion 💧"
            content.body = "Time to drink water! 💧"
            content.sound = .default
            content.categoryIdentifier = "HYDRA_WATER"
            let request = UNNotificationRequest(identifier: "hydra-snooze-\(UUID().uuidString)",
                                                content: content,
                                                trigger: UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes * 60), repeats: false))
            center.add(request)
        }
        completionHandler()
    }
}
