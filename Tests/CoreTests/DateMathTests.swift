import XCTest
@testable import AppFoundation

final class DateMathTests: XCTestCase {
    func testDaysBetweenUsesCalendarDays() throws {
        let start = DateMath.date(year: 2026, month: 3, day: 28)
        let end = DateMath.date(year: 2026, month: 4, day: 2)
        XCTAssertEqual(DateMath.daysBetween(start, end), 5)
    }

    func testPositiveModuloHandlesDatesBeforeAnchor() throws {
        XCTAssertEqual(DateMath.positiveModulo(-1, 4), 3)
        XCTAssertEqual(DateMath.positiveModulo(-5, 4), 3)
        XCTAssertEqual(DateMath.positiveModulo(6, 4), 2)
    }

    func testYMDKeyIsStable() throws {
        XCTAssertEqual(DateMath.ymdKey(DateMath.date(year: 2026, month: 6, day: 12)), "2026-06-12")
    }
}

