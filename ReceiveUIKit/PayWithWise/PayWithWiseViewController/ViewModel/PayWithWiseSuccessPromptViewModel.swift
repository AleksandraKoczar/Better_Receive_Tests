import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct PayWithWiseSuccessPromptViewModel {
    let asset: PromptAsset
    let title: String
    let message: PromptConfiguration.MessageConfiguration
    let primaryButtonTitle: String

    // sourcery: skipEquality
    let completion: () -> Void
}
