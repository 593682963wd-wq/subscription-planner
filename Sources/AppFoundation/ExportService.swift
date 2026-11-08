import Foundation

public struct ExportRow: Codable, Sendable {
    public let name: String
    public let price: Decimal
    public let currencyCode: String
    public let cycle: String
    public let nextBillDate: String
    public let category: String
    public let isArchived: Bool
    public let note: String

    public init(name: String, price: Decimal, currencyCode: String, cycle: String, nextBillDate: String, category: String, isArchived: Bool, note: String) {
        self.name = name
        self.price = price
        self.currencyCode = currencyCode
        self.cycle = cycle
        self.nextBillDate = nextBillDate
        self.category = category
        self.isArchived = isArchived
        self.note = note
    }
}

public enum ExportService {
    public static func csv(rows: [ExportRow]) -> String {
        let header = "name,price,currency,cycle,next_bill_date,category,is_archived,note"
        let body = rows.map { row in
            [row.name, NSDecimalNumber(decimal: row.price).stringValue, row.currencyCode, row.cycle, row.nextBillDate, row.category, row.isArchived ? "true" : "false", row.note]
                .map(escapeCSV)
                .joined(separator: ",")
        }
        return ([header] + body).joined(separator: "\n")
    }

    public static func jsonData(rows: [ExportRow]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(rows)
    }





    public static func icsDate(_ date: Date) -> String {
        let components = DateMath.calendar.dateComponents([.year, .month, .day], from: DateMath.startOfDay(date))
        return String(format: "%04d%02d%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func escapeCSV(_ input: String) -> String {
        let first=input.trimmingCharacters(in:.whitespacesAndNewlines).first
        let value=(first.map { "=+-@".contains($0) } ?? false) ? "'"+input : input
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
