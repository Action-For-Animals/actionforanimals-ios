//
//  Notification+Extension.swift
//  ActionForAnimals
//
//  Created by Christopher Selin on 9/15/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import UserNotifications
import UIKit
import RswiftResources

extension UNMutableNotificationContent {
    static func notificationContent() -> UNMutableNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = R.string.localizable.scheduledReminderAlertTitle()
        notificationContent.body = R.string.localizable.scheduledReminderAlertBody()
        notificationContent.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        return notificationContent
    }
}

extension UNCalendarNotificationTrigger {
    static func notificationTrigger(date: Date, dayIndex: Int, fromZeroBased: Bool = false) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.hour,.minute,.second], from: date)
        components.timeZone = TimeZone(identifier: "default")
        components.weekday = fromZeroBased ? dayIndex + 1 : dayIndex
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    static func oneShotTrigger(date: Date) -> UNCalendarNotificationTrigger {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}

extension UNMutableNotificationContent {
    static func streakRiskContent(streak: Int) -> UNMutableNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Don't lose your streak!"
        notificationContent.body = "Your \(streak)-week streak is at risk — call or email today to keep it going before the weekend."
        notificationContent.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        return notificationContent
    }
}

extension UNNotificationRequest {
    static func indices(from notifications: [UNNotificationRequest], zeroBased: Bool = false) -> [Int] {
        let calendar = Calendar(identifier: .gregorian)
        return notifications.compactMap({ notification in
            if let calendarTrigger = notification.trigger as? UNCalendarNotificationTrigger {
                return calendar.component(.weekday, from: (calendarTrigger.nextTriggerDate()!)) - (zeroBased ? 1 : 0)
            }
            
            return nil
        })
    }
}
