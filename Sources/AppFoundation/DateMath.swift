import Foundation

public enum DateMath {
    public static var gregorian: Calendar { calendar }

    public static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    public static func startOfDay(_ date: Date, calendar inputCalendar: Calendar = DateMath.calendar) -> Date {
        var calendar = inputCalendar
        calendar.timeZone = DateMath.calendar.timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }

    public static func dayStart(_ date: Date, calendar inputCalendar: Calendar = DateMath.calendar) -> Date {
        startOfDay(date, calendar: inputCalendar)
    }

    public static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = DateMath.calendar
        components.year = year
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    public static func date(_ year: Int, _ month: Int, _ day: Int, calendar inputCalendar: Calendar = DateMath.calendar) -> Date {
        var components = DateComponents()
        components.calendar = inputCalendar
        components.year = year
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    public static func daysBetween(_ start: Date, _ end: Date) -> Int {
        let lhs = startOfDay(start)
        let rhs = startOfDay(end)
        return calendar.dateComponents([.day], from: lhs, to: rhs).day ?? 0
    }

    public static func daysBetween(_ start: Date, _ end: Date, calendar inputCalendar: Calendar) -> Int {
        let lhs = startOfDay(start, calendar: inputCalendar)
        let rhs = startOfDay(end, calendar: inputCalendar)
        return inputCalendar.dateComponents([.day], from: lhs, to: rhs).day ?? 0
    }

    public static func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: startOfDay(date)) ?? date
    }

    public static func monthInterval(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .month, for: startOfDay(date)) ?? DateInterval(start: date, duration: 0)
    }

    public static func monthDates(year: Int, month: Int) -> [Date] {
        let start = date(year: year, month: month, day: 1)
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        return range.compactMap { day in
            DateMath.date(year: year, month: month, day: day)
        }
    }

    public static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    public static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(startOfDay(lhs), inSameDayAs: startOfDay(rhs))
    }

    public static func isSameYear(_ lhs: Date, _ rhs: Date, calendar inputCalendar: Calendar = DateMath.calendar) -> Bool {
        inputCalendar.component(.year, from: lhs) == inputCalendar.component(.year, from: rhs)
    }

    public static func lastDayOfMonth(year: Int, month: Int, calendar inputCalendar: Calendar = DateMath.calendar) -> Int {
        let start = inputCalendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return inputCalendar.range(of: .day, in: .month, for: start)?.count ?? 28
    }

    public static func ymdKey(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: startOfDay(date))
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
