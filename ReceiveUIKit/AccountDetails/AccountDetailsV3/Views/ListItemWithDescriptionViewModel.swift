import Foundation
import Neptune

struct ListItemWithDescriptionViewModel {
    let title: String
    let subtitle: String
    let description: MarkupTextModel?
    let action: Neptune.Action?
}
