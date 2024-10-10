//
//  NotificationManager.swift
//  CentralSandbox
//
//  Created by Lidiomar Machado on 10/10/24.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject {
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification authorization granted.")
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }
    
    static func sendNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = message
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
