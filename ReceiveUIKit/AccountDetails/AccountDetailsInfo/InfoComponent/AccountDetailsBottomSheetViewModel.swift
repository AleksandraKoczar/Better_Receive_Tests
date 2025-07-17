import AnalyticsKit
import Foundation
import Neptune
import TransferResources

public struct AccountDetailsBottomSheetViewModel {
    public struct CopyConfig {
        public enum FooterType {
            case revealed
            case plainText
        }

        let type: FooterType
        let title: String
        let value: String
        let copyAction: () -> Void

        public init(type: FooterType, title: String, value: String, copyAction: @escaping () -> Void) {
            self.type = type
            self.title = title
            self.value = value
            self.copyAction = copyAction
        }
    }

    let title: String?
    let description: String?
    let action: ((URL) -> Void)?
    let footerConfig: CopyConfig?

    public init(title: String?, description: String?, footerConfig: CopyConfig?) {
        self.title = title
        self.description = description
        self.footerConfig = footerConfig
        action = nil
    }

    public init(title: String?, description: String?, action: ((URL) -> Void)?) {
        self.title = title
        self.description = description
        self.action = action
        footerConfig = nil
    }
}
