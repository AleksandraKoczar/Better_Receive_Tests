@testable import ReceiveUIKit
import TWFoundationTestingSupport

extension PayWithWiseViewModel {
    var loaded: PayWithWiseViewModel.Loaded {
        get throws {
            guard case let .loaded(loadedVM) = self else {
                throw MockError.dummy
            }
            return loadedVM
        }
    }

    var empty: PayWithWiseViewModel.Empty {
        get throws {
            guard case let .empty(emptyVM) = self else {
                throw MockError.dummy
            }
            return emptyVM
        }
    }
}
