import Neptune

// sourcery: AutoEquatableForTest
public struct PWWAlert {
    let message: String
    let type: AlertType
    // sourcery: skipEquality
    let action: Action?

    enum AlertType {
        case neutral
        case warning
    }
}
