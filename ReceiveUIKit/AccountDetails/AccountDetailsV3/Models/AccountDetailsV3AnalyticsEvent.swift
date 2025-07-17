import Foundation

enum AccountDetailsV3AnalyticsEvent {
    enum Event {
        case pageLoaded

        case chipSelected(_ chip: KeyInformationType)
        case containerSelected(_ container: KeyInformationType)

        case feedbackFormSelected

        case modalButtonSelected(value: String?)

        case currencyHeaderMarkupClicked(value: String?)

        case markupLinkClicked(detailType: DetailType, value: String?)
        case detailCopied(detailType: DetailType)

        case shareButtonSelected
        case shareDetailsSelected
        case copyDetailsSelected
        case downloadDetailsSelected
    }

    enum DetailType: String {
        case ACCOUNT_HOLDER
        case ACCOUNT_NUMBER
        case BANK_CODE
        case BANK_NAME_ADDRESS
        case BIC
        case IBAN
        case other
    }
}
