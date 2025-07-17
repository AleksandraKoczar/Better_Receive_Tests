import AnalyticsKit

class BooleanStringAnalyticsProperty: AnalyticsProperty {
    let name: String
    let value: AnalyticsPropertyValue

    init(name: String, value: Bool) {
        self.name = name
        self.value = value ? "Yes" : "No"
    }
}
