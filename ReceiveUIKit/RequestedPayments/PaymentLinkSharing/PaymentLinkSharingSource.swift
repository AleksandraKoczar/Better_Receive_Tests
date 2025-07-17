import Prism

public enum PaymentLinkSharingSource {
    case billSplit

    var analyticsValue: PaymentRequestShareModalSource {
        switch self {
        case .billSplit:
            .billSplit
        }
    }
}
