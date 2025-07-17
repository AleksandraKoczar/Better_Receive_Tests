import AnalyticsKit
import Foundation

protocol ReceiveErrorAnalyticsModel {
    var type: String { get }
    var message: String { get }
    var identifier: String { get }
}

struct AnyReceiveErrorAnalyticsModel: ReceiveErrorAnalyticsModel {
    let type: String
    let message: String
    let identifier: String
}

class ReceiveErrorAnalyticsViewAction<V: AnalyticsView>: AnalyticsViewAction {
    typealias View = V

    let name: String
    let properties: [AnalyticsProperty]

    static func makeInnerProperties(model: ReceiveErrorAnalyticsModel) -> [AnalyticsProperty] {
        let prefix = "Inner-"
        return [
            AnyAnalyticsProperty(
                prefix + Keys.type,
                model.type
            ),
            AnyAnalyticsProperty(
                prefix + Keys.identifier,
                model.identifier
            ),
            AnyAnalyticsProperty(
                prefix + Keys.message,
                model.message
            ),
        ]
    }

    init(
        name: String,
        model: ReceiveErrorAnalyticsModel,
        additionalProperties: [AnalyticsProperty] = []
    ) {
        self.name = name
        properties = additionalProperties.appending(
            contentsOf: [
                AnyAnalyticsProperty(
                    Keys.type,
                    model.type
                ),
                AnyAnalyticsProperty(
                    Keys.identifier,
                    model.identifier
                ),
                AnyAnalyticsProperty(
                    Keys.message,
                    model.message
                ),
            ]
        )
    }
}

private enum Keys {
    static let type = "Type"
    static let message = "Message"
    static let identifier = "Identifier"
}
