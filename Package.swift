// swift-tools-version: 6.0
import PackageDescription
let package=Package(name:"extra-subscription-planner",platforms:[.macOS(.v14)],products:[.library(name:"SubscriptionCore",targets:["SubscriptionCore"]),.executable(name:"planner",targets:["PlannerCLI"])],targets:[.target(name:"AppFoundation"),.target(name:"SubscriptionCore",dependencies:["AppFoundation"]),.executableTarget(name:"PlannerCLI",dependencies:["SubscriptionCore","AppFoundation"]),.testTarget(name:"CoreTests",dependencies:["SubscriptionCore","AppFoundation"])])
