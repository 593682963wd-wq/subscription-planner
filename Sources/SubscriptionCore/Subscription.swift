// 作者 Wangyuan，2026-10-29。离线核心输入校验与独立复核返修。
import Foundation
import AppFoundation

public enum SubscriptionCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case video
    case music
    case cloud
    case productivity
    case game
    case health
    case reading
    case other

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .video: String(localized: "category.video")
        case .music: String(localized: "category.music")
        case .cloud: String(localized: "category.cloud")
        case .productivity: String(localized: "category.productivity")
        case .game: String(localized: "category.game")
        case .health: String(localized: "category.health")
        case .reading: String(localized: "category.reading")
        case .other: String(localized: "category.other")
        }
    }

    public var symbol: String {
        switch self {
        case .video: "play.rectangle.fill"
        case .music: "music.note"
        case .cloud: "icloud.fill"
        case .productivity: "hammer.fill"
        case .game: "gamecontroller.fill"
        case .health: "heart.fill"
        case .reading: "newspaper.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}

public final class Subscription {
    public var id: UUID
    public var name: String
    public var templateKey: String?
    public var colorHex: String
    public var price: Decimal
    public var currencyCode: String
    public var cycleRawValue: String
    public var customCycleDays: Int?
    public var firstBillDate: Date
    public var categoryRawValue: String
    public var isTrial: Bool
    public var trialEndDate: Date?
    public var reminderOffsets: [Int]
    public var isArchived: Bool
    public var archivedDate: Date?
    public var note: String
    public var createdAt: Date
    public var nextBillDateCache: Date

    public init(
        id: UUID = UUID(),
        name: String,
        templateKey: String? = nil,
        colorHex: String = "#0EA5E9",
        price: Decimal,
        currencyCode: String = "CNY",
        cycle: BillingCycle = .monthly,
        customCycleDays: Int? = nil,
        firstBillDate: Date,
        category: SubscriptionCategory = .other,
        isTrial: Bool = false,
        trialEndDate: Date? = nil,
        reminderOffsets: [Int] = [3],
        isArchived: Bool = false,
        archivedDate: Date? = nil,
        note: String = "",
        createdAt: Date = Date()
    ) throws {
        try BillingMath.validatePrice(price)
        try BillingMath.validateCycle(cycle, days: customCycleDays)
        self.id = id
        self.name = name
        self.templateKey = templateKey
        self.colorHex = colorHex
        self.price = price
        self.currencyCode = currencyCode
        self.cycleRawValue = cycle.rawValue
        self.customCycleDays = customCycleDays
        self.firstBillDate = DateMath.dayStart(firstBillDate)
        self.categoryRawValue = category.rawValue
        self.isTrial = isTrial
        self.trialEndDate = trialEndDate.map { DateMath.dayStart($0) }
        self.reminderOffsets = reminderOffsets
        self.isArchived = isArchived
        self.archivedDate = archivedDate
        self.note = note
        self.createdAt = createdAt
        self.nextBillDateCache = try BillingMath.nextBillDate(firstBillDate: firstBillDate, cycle: cycle, customCycleDays: customCycleDays, after: Date())
    }

    public var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRawValue) ?? .monthly }
        set { cycleRawValue = newValue.rawValue }
    }

    public var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    public func nextBillDate(after date: Date = Date(), calendar: Calendar = DateMath.gregorian) throws -> Date {
        try BillingMath.nextBillDate(firstBillDate: firstBillDate, cycle: cycle, customCycleDays: customCycleDays, after: date, calendar: calendar)
    }

    public func refreshNextBillDateCache(today: Date = Date()) throws {
        nextBillDateCache = try nextBillDate(after: today)
    }

    public var monthlyEquivalent: Decimal {
        get throws { try BillingMath.monthlyEquivalent(price: price, cycle: cycle, customCycleDays: customCycleDays) }
    }

    public var yearlyEquivalent: Decimal {
        get throws { try BillingMath.yearlyEquivalent(price: price, cycle: cycle, customCycleDays: customCycleDays) }
    }

    public var reminderPlanInput: ReminderPlanInput {
        ReminderPlanInput(id: id, name: name, nextBillDate: nextBillDateCache, trialEndDate: isTrial ? trialEndDate : nil, reminderOffsets: reminderOffsets, isArchived: isArchived)
    }
}
