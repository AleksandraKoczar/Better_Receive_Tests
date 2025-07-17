import Neptune
import UIKit

enum PayWithWiseViewModel {
    case loaded(Loaded)
    case empty(Empty)

    // sourcery: Buildable
    struct Loaded {
        let shouldHideDetailsButton: Bool
        let header: PayWithWiseHeaderView.ViewModel
        let paymentSection: Section?
        let breakdownItems: [BreakdownRowModel]
        let inlineAlert: Alert?
        let footer: PayWithWiseFooterViewModel?
    }

    // sourcery: Buildable
    struct Alert {
        let viewModel: InlineAlertViewModel
        let style: InlineAlertStyle
    }

    // sourcery: Buildable
    struct Empty {
        let image: UIImage
        let title: String
        let message: String
        let buttonAction: Action
    }

    // sourcery: Buildable
    struct Section {
        let header: SectionHeaderViewModel
        let sectionOptions: [SectionOption]

        // sourcery: Buildable
        struct SectionOption {
            let option: OptionViewModel
            let action: (() -> Void)?
        }
    }

    // sourcery: Buildable
    struct BreakDownItem {
        let accessoryType: AccessoryType
        let title: String
        let description: String

        // sourcery: Buildable
        enum AccessoryType: CaseIterable {
            case circle
            case plus
            case minus
            case equals
            case multiply
            case divide
            case avatar
        }
    }
}
