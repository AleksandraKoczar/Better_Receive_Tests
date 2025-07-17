import Foundation

struct AccountDetailsV3AnalyticsContext {
    let currency: String
    let type: `Type`
    let context: Context

    enum `Type` {
        case ACCOUNT_DETAILS
        case INTERAC
        case SGD_FAST
        case SGD_GIRO
        case PAY_NOW
        case PIX
    }

    enum Context {
        case DEFAULT
        case DIRECT_DEBITS
        case PAYMENT_REQUEST
    }
}
