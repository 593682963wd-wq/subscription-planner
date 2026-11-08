import XCTest
import AppFoundation

final class ReminderExportTests:XCTestCase {
    func testRemindersAreCappedAndArchivedExcluded() throws {
        let today=DateMath.date(2026,1,1)
        let items=(0..<80).map{index in ReminderPlanInput(id:UUID(),name:"Synthetic",nextBillDate:DateMath.addDays(index+10,to:today),trialEndDate:nil,reminderOffsets:[3,3],isArchived:false)}
        let planned=NotificationScheduler.planNotifications(for:items,today:today)
        XCTAssertEqual(planned.count,64)
        XCTAssertLessThan(planned[0].fireDate,planned[63].fireDate)
        let archived=ReminderPlanInput(id:UUID(),name:"Archived",nextBillDate:today,trialEndDate:today,reminderOffsets:[0],isArchived:true)
        XCTAssertTrue(NotificationScheduler.planNotifications(for:[archived],today:today).isEmpty)
    }
    func testCsvQuotesAndFormulaPrefix() throws {
        let rows=[ExportRow(name:"=SUM(1,2)",price:1,currencyCode:"USD",cycle:"monthly",nextBillDate:"2026-01-01",category:"other",isArchived:false,note:"line\nquote\"")]
        let csv=ExportService.csv(rows:rows)
        XCTAssertTrue(csv.contains("'SUM") == false)
        XCTAssertTrue(csv.contains("'=SUM(1,2)"))
        XCTAssertTrue(csv.contains("quote\"\""))
    }
}
