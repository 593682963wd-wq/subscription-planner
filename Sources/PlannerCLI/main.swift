// 作者 Wangyuan，2026-10-29。离线核心输入校验与独立复核返修。
import Foundation
import AppFoundation
enum InputError:Error {case invalid(String)}
func date(_ value:String)throws->Date {let parts=value.split(separator:"-").compactMap{Int($0)};guard parts.count==3 else {throw InputError.invalid("日期应为YYYY-MM-DD")};let result=DateMath.date(parts[0],parts[1],parts[2]);guard DateMath.ymdKey(result)==value else {throw InputError.invalid("无效日期")};return result}
func emit(_ value:Any)throws {let data=try JSONSerialization.data(withJSONObject:value,options:[.prettyPrinted,.sortedKeys]);FileHandle.standardOutput.write(data);print("")}
func input()throws->Data {guard CommandLine.arguments.count==2 else {throw InputError.invalid("用法: planner input.json")};return try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1]))}
import SubscriptionCore
struct Item:Decodable {let name:String;let price:String;let currency:String;let cycle:BillingCycle;let first_bill:String;let custom_days:Int?;let archived:Bool?;let archived_date:String?;let trial_end:String?;let reminders:[Int]?}
struct Input:Decodable {let today:String;let subscriptions:[Item]}
do {
 let source=try JSONDecoder().decode(Input.self,from:input());let today=try date(source.today)
 let items=try source.subscriptions.map {item->Subscription in
  let price=try BillingMath.parsePrice(item.price)
  guard !item.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else {throw InputError.invalid("名称无效")}
  try BillingMath.validateCycle(item.cycle,days:item.custom_days)
  let trial=try item.trial_end.map{try date($0)}
  let sub=try Subscription(name:item.name,price:price,currencyCode:item.currency,cycle:item.cycle,customCycleDays:item.custom_days,firstBillDate:try date(item.first_bill),isTrial:trial != nil,trialEndDate:trial,reminderOffsets:item.reminders ?? [3],isArchived:item.archived ?? false,archivedDate:try item.archived_date.map{try date($0)})
  try sub.refreshNextBillDateCache(today:today);return sub
 }
 // 提醒允许当天；next_bill展示仍保留严格晚于今天的原有口径。
 let reminderInputs=try items.map {item->ReminderPlanInput in
  let bill=try BillingMath.nextBillDate(firstBillDate:item.firstBillDate,cycle:item.cycle,customCycleDays:item.customCycleDays,after:DateMath.addDays(-1,to:today))
  return ReminderPlanInput(id:item.id,name:item.name,nextBillDate:bill,trialEndDate:item.isTrial ? item.trialEndDate : nil,reminderOffsets:item.reminderOffsets,isArchived:item.isArchived)
 }
 let schedule=NotificationScheduler.planNotifications(for:reminderInputs,today:today)
 let rows=items.map {ExportRow(name:$0.name,price:$0.price,currencyCode:$0.currencyCode,cycle:$0.cycle.rawValue,nextBillDate:DateMath.ymdKey($0.nextBillDateCache),category:$0.category.rawValue,isArchived:$0.isArchived,note:"")}
 let dues=try BillingMath.amountDueThisMonth(subscriptions:items,today:today).mapValues{NSDecimalNumber(decimal:$0).stringValue}
 try emit(["amount_due_this_month":dues,"amount_due_this_month_notice":"本月计划到期总额，含今天以前，未推断已付/待付","subscriptions":try items.map{["name":$0.name,"next_bill":DateMath.ymdKey($0.nextBillDateCache),"monthly_equivalent":NSDecimalNumber(decimal:try $0.monthlyEquivalent).stringValue,"yearly_equivalent":NSDecimalNumber(decimal:try $0.yearlyEquivalent).stringValue,"estimated_saved_this_year":NSDecimalNumber(decimal:try BillingMath.savedAmountThisYear(subscription:$0,today:today)).stringValue]},"reminder_plan":schedule.map{["title":$0.title,"date":DateMath.ymdKey($0.fireDate),"kind":$0.kind.rawValue]},"csv":ExportService.csv(rows:rows),"notice":"仅计划，未支付或发送通知"])
} catch {FileHandle.standardError.write(Data("错误: \(error)\n".utf8));exit(2)}
