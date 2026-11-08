import Foundation

public struct LocalNotificationRequest: Hashable, Sendable {
    public var id: String
    public var title: String
    public var body: String
    public var dateComponents: DateComponents

    public init(id: String, title: String, body: String, dateComponents: DateComponents) {
        self.id = id
        self.title = title
        self.body = body
        self.dateComponents = dateComponents
    }
}

public struct ReminderPlanInput: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let nextBillDate: Date
    public let trialEndDate: Date?
    public let reminderOffsets: [Int]
    public let isArchived: Bool

    public init(id: UUID, name: String, nextBillDate: Date, trialEndDate: Date?, reminderOffsets: [Int], isArchived: Bool) {
        self.id = id
        self.name = name
        self.nextBillDate = nextBillDate
        self.trialEndDate = trialEndDate
        self.reminderOffsets = reminderOffsets
        self.isArchived = isArchived
    }
}

public struct PlannedNotification: Sendable, Equatable {
    public enum Kind: String, Sendable { case renewal, trial }
    public let identifier: String
    public let title: String
    public let body: String
    public let fireDate: Date
    public let kind: Kind
}

public final class NotificationScheduler: Sendable {
    public static let shared = NotificationScheduler()

    private init() {}

    /// iOS keeps only the next 64 pending local notifications per app. SubKeeper recalculates
    /// all reminders after startup or data changes, sorts by fire date, then schedules the nearest 64.
    public static func planNotifications(for items: [ReminderPlanInput], today: Date, calendar: Calendar = DateMath.calendar, limit: Int = 64) -> [PlannedNotification] {
        guard limit > 0 else {return []}
        let todayStart = DateMath.dayStart(today, calendar: calendar)
        var planned: [PlannedNotification] = []

        for item in items where !item.isArchived {
            for offset in Set(item.reminderOffsets).filter{$0 >= 0}.sorted() {
                guard let fireDate = calendar.date(byAdding: .day, value: -offset, to: DateMath.dayStart(item.nextBillDate, calendar: calendar)), fireDate >= todayStart else { continue }
                planned.append(PlannedNotification(
                    identifier: "subkeeper.renewal.\(item.id.uuidString).\(offset)",
                    title: "\(item.name) will renew soon",
                    body: offset == 0 ? "Payment is due today." : "Payment is due in \(offset) day(s).",
                    fireDate: fireDate,
                    kind: .renewal
                ))
            }
            if let trialEndDate = item.trialEndDate {
                for offset in [3, 1] {
                    guard let fireDate = calendar.date(byAdding: .day, value: -offset, to: DateMath.dayStart(trialEndDate, calendar: calendar)), fireDate >= todayStart else { continue }
                    planned.append(PlannedNotification(
                        identifier: "subkeeper.trial.\(item.id.uuidString).\(offset)",
                        title: "\(item.name) trial ends soon",
                        body: "Remember to cancel or continue before the trial ends.",
                        fireDate: fireDate,
                        kind: .trial
                    ))
                }
            }
        }

        return Array(planned.sorted { lhs, rhs in
            if lhs.fireDate == rhs.fireDate { lhs.identifier < rhs.identifier } else { lhs.fireDate < rhs.fireDate }
        }.prefix(limit))
    }

}
