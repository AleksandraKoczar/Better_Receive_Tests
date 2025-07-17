import DeepLinkKit

public enum AccountDetailsFlowInvocationContext {
    case intentPicker
    case requestMoney
    case deeplink(DeepLinkAccountDetailsRoute)
    case accountEducationViewDetails
    case accountEducationGetDetails
    case receiveSpace
    case accountService
    case accountBarButton
    case wisetag
}
