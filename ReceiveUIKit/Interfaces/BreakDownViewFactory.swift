import Foundation
import SwiftUI

// sourcery: AutoMockable
public protocol BreakdownViewFactory {
    func make(feeBreakdown: [BreakdownRowModel]) -> AnyView
}
