import XCTest
import AppFoundation
@testable import SubscriptionCore

final class BillingMathTests: XCTestCase {
    func testMonthlyFromJanuary31NonLeapYear() throws {
        let first = DateMath.date(2026, 1, 31)
        let next = try BillingMath.nextBillDate(firstBillDate: first, cycle: .monthly, after: DateMath.date(2026, 1, 31))
        XCTAssertEqual(next, DateMath.date(2026, 2, 28))
    }

    func testMonthlyFromJanuary31LeapYear() throws {
        let first = DateMath.date(2028, 1, 31)
        let next = try BillingMath.nextBillDate(firstBillDate: first, cycle: .monthly, after: DateMath.date(2028, 1, 31))
        XCTAssertEqual(next, DateMath.date(2028, 2, 29))
    }

    func testYearlyCrossesDecember() throws {
        let first = DateMath.date(2025, 12, 15)
        let next = try BillingMath.nextBillDate(firstBillDate: first, cycle: .yearly, after: DateMath.date(2026, 1, 1))
        XCTAssertEqual(next, DateMath.date(2026, 12, 15))
    }

    func testCustomCycleDays() throws {
        let first = DateMath.date(2026, 1, 1)
        let next = try BillingMath.nextBillDate(firstBillDate: first, cycle: .custom, customCycleDays: 10, after: DateMath.date(2026, 1, 12))
        XCTAssertEqual(next, DateMath.date(2026, 1, 21))
    }

    func testEquivalents() throws {
        XCTAssertEqual(try BillingMath.monthlyEquivalent(price: 120, cycle: .yearly), 10)
        XCTAssertEqual(try BillingMath.yearlyEquivalent(price: 30, cycle: .quarterly), 120)
    }

    func testSavedAmountThisYear() throws {
        let sub = try Subscription(name: "Video", price: 12, cycle: .monthly, firstBillDate: DateMath.date(2026, 1, 1), isArchived: true, archivedDate: DateMath.date(2026, 6, 12))
        XCTAssertEqual(try BillingMath.savedAmountThisYear(subscription: sub, today: DateMath.date(2026, 8, 1)), 84)
    }

    func testAllWeeklyOccurrencesInCalendarMonth() throws {
        let sub = try Subscription(name:"Synthetic",price:10,currencyCode:"USD",cycle:.weekly,firstBillDate:DateMath.date(2030,1,2))
        for day in [1,15,31] { XCTAssertEqual(try BillingMath.amountDueThisMonth(subscriptions:[sub],today:DateMath.date(2030,1,day))["USD"],50) }
    }
    func testDailyMonthBoundaryCurrenciesAndArchive() throws {
        let daily = try Subscription(name:"Daily",price:2,currencyCode:"USD",cycle:.custom,customCycleDays:1,firstBillDate:DateMath.date(2030,1,1))
        let monthly = try Subscription(name:"Monthly",price:5,currencyCode:"EUR",cycle:.monthly,firstBillDate:DateMath.date(2029,12,31))
        let archived = try Subscription(name:"Archived",price:99,currencyCode:"USD",firstBillDate:DateMath.date(2030,1,1),isArchived:true)
        let totals = try BillingMath.amountDueThisMonth(subscriptions:[daily,monthly,archived],today:DateMath.date(2030,1,20))
        XCTAssertEqual(totals["USD"],62);XCTAssertEqual(totals["EUR"],5)
        XCTAssertEqual(try BillingMath.amountDueThisMonth(subscriptions:[monthly],today:DateMath.date(2030,2,28))["EUR"],5)
    }
    func testNoDueBeforeFirstBillAndIncludesMonthStart() throws {
        let future = try Subscription(name:"Future",price:10,firstBillDate:DateMath.date(2030,2,1))
        XCTAssertTrue(try BillingMath.amountDueThisMonth(subscriptions:[future],today:DateMath.date(2030,1,1)).isEmpty)
        XCTAssertEqual(try BillingMath.amountDueThisMonth(subscriptions:[future],today:DateMath.date(2030,2,1))["CNY"],10)
    }
    func testCompleteDecimalPrice() throws {
        XCTAssertEqual(try BillingMath.parsePrice("12.50"),Decimal(string:"12.5"))
        for raw in ["12junk","12\n"," 12","12 ","1e2","nan","-1","","1.2.3",String(repeating:"9",count:39)] { XCTAssertThrowsError(try BillingMath.parsePrice(raw)) }
    }
    func testInvalidCustomCycleRejectedInCore() throws {
        for days in [nil,0,-1] as [Int?] {
            XCTAssertThrowsError(try BillingMath.monthlyEquivalent(price:12,cycle:.custom,customCycleDays:days))
            XCTAssertThrowsError(try BillingMath.nextBillDate(firstBillDate:DateMath.date(2030,1,1),cycle:.custom,customCycleDays:days,after:DateMath.date(2029,1,1)))
            XCTAssertThrowsError(try Subscription(name:"Bad",price:12,cycle:.custom,customCycleDays:days,firstBillDate:DateMath.date(2030,1,1)))
        }
    }
    func testMutationStillValidated() throws {
        let sub = try Subscription(name:"Synthetic",price:10,cycle:.custom,customCycleDays:7,firstBillDate:DateMath.date(2030,1,1))
        sub.customCycleDays=0
        XCTAssertThrowsError(try sub.nextBillDate(after:DateMath.date(2030,1,1)))
        XCTAssertThrowsError(try sub.monthlyEquivalent)
        XCTAssertThrowsError(try BillingMath.amountDueThisMonth(subscriptions:[sub],today:DateMath.date(2030,1,1)))
    }
}
