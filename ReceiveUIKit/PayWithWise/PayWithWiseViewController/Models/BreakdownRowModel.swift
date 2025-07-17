import Foundation
import Neptune

// sourcery: AutoEquatableForTest, Buildable
public struct BreakdownRowModel {
    public let accessoryType: AccessoryType
    public let primaryText: String
    public let secondaryText: String
    public let secondaryMarkupTag: MarkupTag

    // sourcery: Buildable
    public enum AccessoryType {
        case circle
        case plus
        case minus
        case equals
        case multiply
        case divide
    }
}
