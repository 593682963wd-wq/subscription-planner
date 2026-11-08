// 作者 Wangyuan，2026-10-29。离线核心输入校验与独立复核返修。
import Foundation
import AppFoundation

public enum BillingCycle: String, CaseIterable, Codable, Identifiable, Sendable {
    case weekly
    case monthly
    case quarterly
    case yearly
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        case .custom: "Custom"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .weekly: String(localized: "cycle.weekly")
        case .monthly: String(localized: "cycle.monthly")
        case .quarterly: String(localized: "cycle.quarterly")
        case .yearly: String(localized: "cycle.yearly")
        case .custom: String(localized: "cycle.custom")
        }
    }
}

public enum BillingValidationError: Error { case invalidPrice, invalidCycle, invalidDate }
public enum BillingMath {
    /// 完整解析十进制非负金额，拒绝尾部垃圾、指数和超出精度契约的输入。
    public static func parsePrice(_ text: String) throws -> Decimal {
        guard text.range(of: "\\A[0-9]+(?:\\.[0-9]+)?\\z", options: .regularExpression) != nil,
              text.filter({ $0.isNumber }).count <= 38,
              let price = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")), !price.isNaN, price >= 0 else { throw BillingValidationError.invalidPrice }
        return price
    }
    public static func validateCycle(_ cycle: BillingCycle, days: Int?) throws {
        if let days, days <= 0 { throw BillingValidationError.invalidCycle }
        if cycle == .custom && days == nil { throw BillingValidationError.invalidCycle }
    }
    public static func validatePrice(_ price: Decimal) throws {
        guard !price.isNaN, price >= 0 else { throw BillingValidationError.invalidPrice }
    }

    public static func nextBillDate(firstBillDate: Date, cycle: BillingCycle, customCycleDays: Int? = nil, after date: Date, calendar: Calendar = DateMath.gregorian) throws -> Date {
        try validateCycle(cycle, days: customCycleDays)
        let first = DateMath.dayStart(firstBillDate, calendar: calendar)
        let after = DateMath.dayStart(date, calendar: calendar)
        if first > after { return first }

        switch cycle {
        case .weekly:
            return try nextDateByDays(first: first, interval: 7, after: after, calendar: calendar)
        case .monthly:
            return nextDateByMonths(first: first, months: 1, after: after, calendar: calendar)
        case .quarterly:
            return nextDateByMonths(first: first, months: 3, after: after, calendar: calendar)
        case .yearly:
            return nextDateByMonths(first: first, months: 12, after: after, calendar: calendar)
        case .custom:
            return try nextDateByDays(first: first, interval: customCycleDays!, after: after, calendar: calendar)
        }
    }

    public static func monthlyEquivalent(price: Decimal, cycle: BillingCycle, customCycleDays: Int? = nil) throws -> Decimal {
        try validateCycle(cycle, days: customCycleDays)
        try validatePrice(price)
        switch cycle {
        case .weekly:
            return price * Decimal(52) / Decimal(12)
        case .monthly:
            return price
        case .quarterly:
            return price / Decimal(3)
        case .yearly:
            return price / Decimal(12)
        case .custom:
            let days = Decimal(customCycleDays!)
            return price * Decimal(365) / days / Decimal(12)
        }
    }

    public static func yearlyEquivalent(price: Decimal, cycle: BillingCycle, customCycleDays: Int? = nil) throws -> Decimal {
        try validateCycle(cycle, days: customCycleDays)
        try validatePrice(price)
        return try monthlyEquivalent(price: price, cycle: cycle, customCycleDays: customCycleDays) * Decimal(12)
    }

    /// today只定位自然月；月初至下月月初（不含）全部到期次数均计入，不推断支付状态。
    public static func amountDueThisMonth(subscriptions: [Subscription], today: Date = Date(), calendar: Calendar = DateMath.gregorian) throws -> [String: Decimal] {
        guard let month = calendar.dateInterval(of: .month, for: today),
              let previousDay = calendar.date(byAdding: .day, value: -1, to: month.start) else { throw BillingValidationError.invalidDate }
        var totals: [String: Decimal] = [:]
        for item in subscriptions where !item.isArchived {
            try validatePrice(item.price)
            var occurrence = try item.nextBillDate(after: previousDay, calendar: calendar)
            while occurrence < month.end {
                totals[item.currencyCode, default: 0] += item.price
                let next = try item.nextBillDate(after: occurrence, calendar: calendar)
                guard next > occurrence else { throw BillingValidationError.invalidDate }
                occurrence = next
            }
        }
        return totals
    }

    public static func savedAmountThisYear(subscription: Subscription, today: Date = Date(), calendar: Calendar = DateMath.gregorian) throws -> Decimal {
        guard subscription.isArchived, let archivedDate = subscription.archivedDate else { return 0 }
        let year = calendar.component(.year, from: today)
        guard calendar.component(.year, from: archivedDate) == year else { return 0 }
        let archiveMonth = calendar.component(.month, from: archivedDate)
        let remainingMonths = max(12 - archiveMonth + 1, 0)
        return try monthlyEquivalent(price: subscription.price, cycle: subscription.cycle, customCycleDays: subscription.customCycleDays) * Decimal(remainingMonths)
    }

    private static func nextDateByDays(first: Date, interval: Int, after: Date, calendar: Calendar) throws -> Date {
        let days = DateMath.daysBetween(first, after, calendar: calendar)
        let steps = max(days / interval + 1, 1)
        let (offset, overflow) = steps.multipliedReportingOverflow(by: interval)
        guard !overflow, let result = calendar.date(byAdding: .day, value: offset, to: first), result > after else { throw BillingValidationError.invalidDate }
        return result
    }

    private static func nextDateByMonths(first: Date, months: Int, after: Date, calendar: Calendar) -> Date {
        let firstComponents = calendar.dateComponents([.year, .month, .day], from: first)
        let afterComponents = calendar.dateComponents([.year, .month], from: after)
        let firstMonthIndex = (firstComponents.year ?? 1970) * 12 + ((firstComponents.month ?? 1) - 1)
        let afterMonthIndex = (afterComponents.year ?? 1970) * 12 + ((afterComponents.month ?? 1) - 1)
        var offset = max(((afterMonthIndex - firstMonthIndex) / months) * months, 0)
        var candidate = anchoredMonthDate(first: first, monthOffset: offset, calendar: calendar)
        while candidate <= after {
            offset += months
            candidate = anchoredMonthDate(first: first, monthOffset: offset, calendar: calendar)
        }
        return candidate
    }

    private static func anchoredMonthDate(first: Date, monthOffset: Int, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: first)
        let baseMonthIndex = (components.year ?? 1970) * 12 + ((components.month ?? 1) - 1) + monthOffset
        let year = baseMonthIndex / 12
        let month = baseMonthIndex % 12 + 1
        let originalDay = components.day ?? 1
        let day = min(originalDay, DateMath.lastDayOfMonth(year: year, month: month, calendar: calendar))
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? first
    }
}
