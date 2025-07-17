import AnalyticsKit
import BalanceKit
import Combine
import ContactsKit
import DeepLinkKit
import Neptune
import NeptuneTestingSupport
import PreloadKit
import ReceiveKit
@testable import ReceiveUIKit
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// swiftlint:disable line_length
// swiftlint:disable variable_name

internal final class AccountDetailListPresenterMock: AccountDetailListPresenter {
    // MARK: - viewDidAppear

    internal private(set) var viewDidAppearCallsCount = 0
    internal var viewDidAppearClosure: (() -> Void)?
    internal var viewDidAppearCalled: Bool {
        viewDidAppearCallsCount > 0
    }

    internal func viewDidAppear() {
        viewDidAppearCallsCount += 1
        viewDidAppearClosure?()
    }

    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsListView?
    internal private(set) var startReceivedInvocations: [AccountDetailsListView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsListView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(withView view: AccountDetailsListView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - cellTapped

    internal private(set) var cellTappedReceivedIndexPath: IndexPath?
    internal private(set) var cellTappedReceivedInvocations: [IndexPath] = []
    internal private(set) var cellTappedCallsCount = 0
    internal var cellTappedClosure: ((IndexPath) -> Void)?
    internal var cellTappedCalled: Bool {
        cellTappedCallsCount > 0
    }

    internal func cellTapped(indexPath: IndexPath) {
        cellTappedCallsCount += 1
        cellTappedReceivedIndexPath = indexPath
        cellTappedReceivedInvocations.append(indexPath)
        cellTappedClosure?(indexPath)
    }

    // MARK: - updateSearchQuery

    internal private(set) var updateSearchQueryReceivedSearchText: String?
    internal private(set) var updateSearchQueryReceivedInvocations: [String] = []
    internal private(set) var updateSearchQueryCallsCount = 0
    internal var updateSearchQueryClosure: ((String) -> Void)?
    internal var updateSearchQueryCalled: Bool {
        updateSearchQueryCallsCount > 0
    }

    internal func updateSearchQuery(_ searchText: String) {
        updateSearchQueryCallsCount += 1
        updateSearchQueryReceivedSearchText = searchText
        updateSearchQueryReceivedInvocations.append(searchText)
        updateSearchQueryClosure?(searchText)
    }

    // MARK: - footerTapped

    internal private(set) var footerTappedCallsCount = 0
    internal var footerTappedClosure: (() -> Void)?
    internal var footerTappedCalled: Bool {
        footerTappedCallsCount > 0
    }

    internal func footerTapped() {
        footerTappedCallsCount += 1
        footerTappedClosure?()
    }

    // MARK: - dismissed

    internal private(set) var dismissedCallsCount = 0
    internal var dismissedClosure: (() -> Void)?
    internal var dismissedCalled: Bool {
        dismissedCallsCount > 0
    }

    internal func dismissed() {
        dismissedCallsCount += 1
        dismissedClosure?()
    }
}

internal final class AccountDetailsInfoIntroPresenterMock: AccountDetailsInfoIntroPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsInfoIntroView?
    internal private(set) var startReceivedInvocations: [AccountDetailsInfoIntroView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsInfoIntroView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(view: AccountDetailsInfoIntroView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class AccountDetailsInfoIntroRouterMock: AccountDetailsInfoIntroRouter {
    // MARK: - showAccountDetailsInfo

    internal private(set) var showAccountDetailsInfoReceivedArguments: (profile: Profile, accountDetails: ActiveAccountDetails)?
    internal private(set) var showAccountDetailsInfoReceivedInvocations: [(
        profile: Profile,
        accountDetails: ActiveAccountDetails
    )] = []
    internal private(set) var showAccountDetailsInfoCallsCount = 0
    internal var showAccountDetailsInfoClosure: ((Profile, ActiveAccountDetails) -> Void)?
    internal var showAccountDetailsInfoCalled: Bool {
        showAccountDetailsInfoCallsCount > 0
    }

    internal func showAccountDetailsInfo(profile: Profile, accountDetails: ActiveAccountDetails) {
        showAccountDetailsInfoCallsCount += 1
        showAccountDetailsInfoReceivedArguments = (profile: profile, accountDetails: accountDetails)
        showAccountDetailsInfoReceivedInvocations.append((profile: profile, accountDetails: accountDetails))
        showAccountDetailsInfoClosure?(profile, accountDetails)
    }

    // MARK: - showSalarySwitch

    internal private(set) var showSalarySwitchReceivedArguments: (
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profile: Profile
    )?
    internal private(set) var showSalarySwitchReceivedInvocations: [(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profile: Profile
    )] = []
    internal private(set) var showSalarySwitchCallsCount = 0
    internal var showSalarySwitchClosure: ((BalanceId, CurrencyCode, Profile) -> Void)?
    internal var showSalarySwitchCalled: Bool {
        showSalarySwitchCallsCount > 0
    }

    internal func showSalarySwitch(balanceId: BalanceId, currencyCode: CurrencyCode, profile: Profile) {
        showSalarySwitchCallsCount += 1
        showSalarySwitchReceivedArguments = (balanceId: balanceId, currencyCode: currencyCode, profile: profile)
        showSalarySwitchReceivedInvocations.append((balanceId: balanceId, currencyCode: currencyCode, profile: profile))
        showSalarySwitchClosure?(balanceId, currencyCode, profile)
    }

    // MARK: - showReceiveMoney

    internal private(set) var showReceiveMoneyCallsCount = 0
    internal var showReceiveMoneyClosure: (() -> Void)?
    internal var showReceiveMoneyCalled: Bool {
        showReceiveMoneyCallsCount > 0
    }

    internal func showReceiveMoney() {
        showReceiveMoneyCallsCount += 1
        showReceiveMoneyClosure?()
    }
}

internal final class AccountDetailsInfoModalDelegateMock: AccountDetailsInfoModalDelegate {
    // MARK: - copyAccountDetails

    internal private(set) var copyAccountDetailsReceivedArguments: (
        copyText: String,
        fieldName: String,
        analyticsType: String?
    )?
    internal private(set) var copyAccountDetailsReceivedInvocations: [(
        copyText: String,
        fieldName: String,
        analyticsType: String?
    )] = []
    internal private(set) var copyAccountDetailsCallsCount = 0
    internal var copyAccountDetailsClosure: ((String, String, String?) -> Void)?
    internal var copyAccountDetailsCalled: Bool {
        copyAccountDetailsCallsCount > 0
    }

    internal func copyAccountDetails(_ copyText: String, for fieldName: String, analyticsType: String?) {
        copyAccountDetailsCallsCount += 1
        copyAccountDetailsReceivedArguments = (copyText: copyText, fieldName: fieldName, analyticsType: analyticsType)
        copyAccountDetailsReceivedInvocations.append((copyText: copyText, fieldName: fieldName, analyticsType: analyticsType))
        copyAccountDetailsClosure?(copyText, fieldName, analyticsType)
    }

    // MARK: - showInformationModal

    internal private(set) var showInformationModalReceivedArguments: (
        title: String?,
        description: String?,
        analyticsType: String?
    )?
    internal private(set) var showInformationModalReceivedInvocations: [(
        title: String?,
        description: String?,
        analyticsType: String?
    )] = []
    internal private(set) var showInformationModalCallsCount = 0
    internal var showInformationModalClosure: ((String?, String?, String?) -> Void)?
    internal var showInformationModalCalled: Bool {
        showInformationModalCallsCount > 0
    }

    internal func showInformationModal(title: String?, description: String?, analyticsType: String?) {
        showInformationModalCallsCount += 1
        showInformationModalReceivedArguments = (title: title, description: description, analyticsType: analyticsType)
        showInformationModalReceivedInvocations.append((title: title, description: description, analyticsType: analyticsType))
        showInformationModalClosure?(title, description, analyticsType)
    }

    // MARK: - showCopyableModal

    internal private(set) var showCopyableModalReceivedAccountDetailItem: AccountDetailsDetailItem?
    internal private(set) var showCopyableModalReceivedInvocations: [AccountDetailsDetailItem] = []
    internal private(set) var showCopyableModalCallsCount = 0
    internal var showCopyableModalClosure: ((AccountDetailsDetailItem) -> Void)?
    internal var showCopyableModalCalled: Bool {
        showCopyableModalCallsCount > 0
    }

    internal func showCopyableModal(accountDetailItem: AccountDetailsDetailItem) {
        showCopyableModalCallsCount += 1
        showCopyableModalReceivedAccountDetailItem = accountDetailItem
        showCopyableModalReceivedInvocations.append(accountDetailItem)
        showCopyableModalClosure?(accountDetailItem)
    }

    // MARK: - shareAccountDetails

    internal private(set) var shareAccountDetailsReceivedArguments: (shareText: String, sender: UIView?)?
    internal private(set) var shareAccountDetailsReceivedInvocations: [(shareText: String, sender: UIView?)] = []
    internal private(set) var shareAccountDetailsCallsCount = 0
    internal var shareAccountDetailsClosure: ((String, UIView?) -> Void)?
    internal var shareAccountDetailsCalled: Bool {
        shareAccountDetailsCallsCount > 0
    }

    internal func shareAccountDetails(shareText: String, sender: UIView?) {
        shareAccountDetailsCallsCount += 1
        shareAccountDetailsReceivedArguments = (shareText: shareText, sender: sender)
        shareAccountDetailsReceivedInvocations.append((shareText: shareText, sender: sender))
        shareAccountDetailsClosure?(shareText, sender)
    }
}

internal final class AccountDetailsInfoRouterMock: AccountDetailsInfoRouter {
    // MARK: - showBottomSheet

    internal private(set) var showBottomSheetReceivedViewModel: AccountDetailsBottomSheetViewModel?
    internal private(set) var showBottomSheetReceivedInvocations: [AccountDetailsBottomSheetViewModel] = []
    internal private(set) var showBottomSheetCallsCount = 0
    internal var showBottomSheetClosure: ((AccountDetailsBottomSheetViewModel) -> Void)?
    internal var showBottomSheetCalled: Bool {
        showBottomSheetCallsCount > 0
    }

    internal func showBottomSheet(viewModel: AccountDetailsBottomSheetViewModel) {
        showBottomSheetCallsCount += 1
        showBottomSheetReceivedViewModel = viewModel
        showBottomSheetReceivedInvocations.append(viewModel)
        showBottomSheetClosure?(viewModel)
    }

    // MARK: - showShareSheet

    internal private(set) var showShareSheetReceivedArguments: (
        text: String,
        sender: UIView,
        completion: (UIActivity.ActivityType?, Bool) -> Void
    )?
    internal private(set) var showShareSheetReceivedInvocations: [(
        text: String,
        sender: UIView,
        completion: (UIActivity.ActivityType?, Bool) -> Void
    )] = []
    internal private(set) var showShareSheetCallsCount = 0
    internal var showShareSheetClosure: ((String, UIView, @escaping (UIActivity.ActivityType?, Bool) -> Void) -> Void)?
    internal var showShareSheetCalled: Bool {
        showShareSheetCallsCount > 0
    }

    internal func showShareSheet(with text: String, sender: UIView, completion: @escaping (UIActivity.ActivityType?, Bool) -> Void) {
        showShareSheetCallsCount += 1
        showShareSheetReceivedArguments = (text: text, sender: sender, completion: completion)
        showShareSheetReceivedInvocations.append((text: text, sender: sender, completion: completion))
        showShareSheetClosure?(text, sender, completion)
    }

    // MARK: - showShareActions

    internal private(set) var showShareActionsReceivedArguments: (title: String, actions: [AccountDetailsShareAction])?
    internal private(set) var showShareActionsReceivedInvocations: [(title: String, actions: [AccountDetailsShareAction])] = []
    internal private(set) var showShareActionsCallsCount = 0
    internal var showShareActionsClosure: ((String, [AccountDetailsShareAction]) -> Void)?
    internal var showShareActionsCalled: Bool {
        showShareActionsCallsCount > 0
    }

    internal func showShareActions(title: String, actions: [AccountDetailsShareAction]) {
        showShareActionsCallsCount += 1
        showShareActionsReceivedArguments = (title: title, actions: actions)
        showShareActionsReceivedInvocations.append((title: title, actions: actions))
        showShareActionsClosure?(title, actions)
    }

    // MARK: - showShareActionsAccountDetailsV3

    internal private(set) var showShareActionsAccountDetailsV3ReceivedArguments: (
        title: String,
        currencyCode: CurrencyCode,
        actions: [AccountDetailsShareAction]
    )?
    internal private(set) var showShareActionsAccountDetailsV3ReceivedInvocations: [(
        title: String,
        currencyCode: CurrencyCode,
        actions: [AccountDetailsShareAction]
    )] = []
    internal private(set) var showShareActionsAccountDetailsV3CallsCount = 0
    internal var showShareActionsAccountDetailsV3Closure: ((String, CurrencyCode, [AccountDetailsShareAction]) -> Void)?
    internal var showShareActionsAccountDetailsV3Called: Bool {
        showShareActionsAccountDetailsV3CallsCount > 0
    }

    internal func showShareActionsAccountDetailsV3(title: String, currencyCode: CurrencyCode, actions: [AccountDetailsShareAction]) {
        showShareActionsAccountDetailsV3CallsCount += 1
        showShareActionsAccountDetailsV3ReceivedArguments = (title: title, currencyCode: currencyCode, actions: actions)
        showShareActionsAccountDetailsV3ReceivedInvocations.append((title: title, currencyCode: currencyCode, actions: actions))
        showShareActionsAccountDetailsV3Closure?(title, currencyCode, actions)
    }

    // MARK: - showDownloadPDFSheet

    internal private(set) var showDownloadPDFSheetReceivedActions: [AccountDetailsV3ShareAction]?
    internal private(set) var showDownloadPDFSheetReceivedInvocations: [[AccountDetailsV3ShareAction]] = []
    internal private(set) var showDownloadPDFSheetCallsCount = 0
    internal var showDownloadPDFSheetClosure: (([AccountDetailsV3ShareAction]) -> Void)?
    internal var showDownloadPDFSheetCalled: Bool {
        showDownloadPDFSheetCallsCount > 0
    }

    internal func showDownloadPDFSheet(actions: [AccountDetailsV3ShareAction]) {
        showDownloadPDFSheetCallsCount += 1
        showDownloadPDFSheetReceivedActions = actions
        showDownloadPDFSheetReceivedInvocations.append(actions)
        showDownloadPDFSheetClosure?(actions)
    }

    // MARK: - showDetails

    internal private(set) var showDetailsReceivedModel: DetailedSummaryViewModel?
    internal private(set) var showDetailsReceivedInvocations: [DetailedSummaryViewModel] = []
    internal private(set) var showDetailsCallsCount = 0
    internal var showDetailsClosure: ((DetailedSummaryViewModel) -> Void)?
    internal var showDetailsCalled: Bool {
        showDetailsCallsCount > 0
    }

    internal func showDetails(model: DetailedSummaryViewModel) {
        showDetailsCallsCount += 1
        showDetailsReceivedModel = model
        showDetailsReceivedInvocations.append(model)
        showDetailsClosure?(model)
    }

    // MARK: - showBottomsheetAccountDetailsV3

    internal private(set) var showBottomsheetAccountDetailsV3ReceivedModal: AccountDetailsV3Modal?
    internal private(set) var showBottomsheetAccountDetailsV3ReceivedInvocations: [AccountDetailsV3Modal] = []
    internal private(set) var showBottomsheetAccountDetailsV3CallsCount = 0
    internal var showBottomsheetAccountDetailsV3Closure: ((AccountDetailsV3Modal) -> Void)?
    internal var showBottomsheetAccountDetailsV3Called: Bool {
        showBottomsheetAccountDetailsV3CallsCount > 0
    }

    internal func showBottomsheetAccountDetailsV3(modal: AccountDetailsV3Modal) {
        showBottomsheetAccountDetailsV3CallsCount += 1
        showBottomsheetAccountDetailsV3ReceivedModal = modal
        showBottomsheetAccountDetailsV3ReceivedInvocations.append(modal)
        showBottomsheetAccountDetailsV3Closure?(modal)
    }

    // MARK: - showSwitcher

    internal private(set) var showSwitcherReceivedViewController: UIViewController?
    internal private(set) var showSwitcherReceivedInvocations: [UIViewController] = []
    internal private(set) var showSwitcherCallsCount = 0
    internal var showSwitcherClosure: ((UIViewController) -> Void)?
    internal var showSwitcherCalled: Bool {
        showSwitcherCallsCount > 0
    }

    internal func showSwitcher(viewController: UIViewController) {
        showSwitcherCallsCount += 1
        showSwitcherReceivedViewController = viewController
        showSwitcherReceivedInvocations.append(viewController)
        showSwitcherClosure?(viewController)
    }

    // MARK: - orderReceiveMethod

    internal private(set) var orderReceiveMethodReceivedArguments: (currency: CurrencyCode?, profile: Profile)?
    internal private(set) var orderReceiveMethodReceivedInvocations: [(currency: CurrencyCode?, profile: Profile)] = []
    internal private(set) var orderReceiveMethodCallsCount = 0
    internal var orderReceiveMethodClosure: ((CurrencyCode?, Profile) -> Void)?
    internal var orderReceiveMethodCalled: Bool {
        orderReceiveMethodCallsCount > 0
    }

    internal func orderReceiveMethod(currency: CurrencyCode?, profile: Profile) {
        orderReceiveMethodCallsCount += 1
        orderReceiveMethodReceivedArguments = (currency: currency, profile: profile)
        orderReceiveMethodReceivedInvocations.append((currency: currency, profile: profile))
        orderReceiveMethodClosure?(currency, profile)
    }

    // MARK: - queryReceiveMethod

    internal private(set) var queryReceiveMethodReceivedArguments: (currency: CurrencyCode?, profile: Profile)?
    internal private(set) var queryReceiveMethodReceivedInvocations: [(currency: CurrencyCode?, profile: Profile)] = []
    internal private(set) var queryReceiveMethodCallsCount = 0
    internal var queryReceiveMethodClosure: ((CurrencyCode?, Profile) -> Void)?
    internal var queryReceiveMethodCalled: Bool {
        queryReceiveMethodCallsCount > 0
    }

    internal func queryReceiveMethod(currency: CurrencyCode?, profile: Profile) {
        queryReceiveMethodCallsCount += 1
        queryReceiveMethodReceivedArguments = (currency: currency, profile: profile)
        queryReceiveMethodReceivedInvocations.append((currency: currency, profile: profile))
        queryReceiveMethodClosure?(currency, profile)
    }

    // MARK: - cleanViewMethodNavigation

    internal private(set) var cleanViewMethodNavigationCallsCount = 0
    internal var cleanViewMethodNavigationClosure: (() -> Void)?
    internal var cleanViewMethodNavigationCalled: Bool {
        cleanViewMethodNavigationCallsCount > 0
    }

    internal func cleanViewMethodNavigation() {
        cleanViewMethodNavigationCallsCount += 1
        cleanViewMethodNavigationClosure?()
    }

    // MARK: - showFeedback

    internal private(set) var showFeedbackReceivedArguments: (
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: () -> Void
    )?
    internal private(set) var showFeedbackReceivedInvocations: [(
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: () -> Void
    )] = []
    internal private(set) var showFeedbackCallsCount = 0
    internal var showFeedbackClosure: ((FeedbackViewModel, FeedbackContext, @escaping () -> Void) -> Void)?
    internal var showFeedbackCalled: Bool {
        showFeedbackCallsCount > 0
    }

    internal func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping () -> Void) {
        showFeedbackCallsCount += 1
        showFeedbackReceivedArguments = (model: model, context: context, onSuccess: onSuccess)
        showFeedbackReceivedInvocations.append((model: model, context: context, onSuccess: onSuccess))
        showFeedbackClosure?(model, context, onSuccess)
    }

    // MARK: - showFile

    internal private(set) var showFileReceivedArguments: (url: URL, delegate: UIDocumentInteractionControllerDelegate)?
    internal private(set) var showFileReceivedInvocations: [(url: URL, delegate: UIDocumentInteractionControllerDelegate)] = []
    internal private(set) var showFileCallsCount = 0
    internal var showFileClosure: ((URL, UIDocumentInteractionControllerDelegate) -> Void)?
    internal var showFileCalled: Bool {
        showFileCallsCount > 0
    }

    internal func showFile(url: URL, delegate: UIDocumentInteractionControllerDelegate) {
        showFileCallsCount += 1
        showFileReceivedArguments = (url: url, delegate: delegate)
        showFileReceivedInvocations.append((url: url, delegate: delegate))
        showFileClosure?(url, delegate)
    }

    // MARK: - showExplore

    internal private(set) var showExploreReceivedArguments: (currencyCode: CurrencyCode, profile: Profile)?
    internal private(set) var showExploreReceivedInvocations: [(currencyCode: CurrencyCode, profile: Profile)] = []
    internal private(set) var showExploreCallsCount = 0
    internal var showExploreClosure: ((CurrencyCode, Profile) -> Void)?
    internal var showExploreCalled: Bool {
        showExploreCallsCount > 0
    }

    internal func showExplore(currencyCode: CurrencyCode, profile: Profile) {
        showExploreCallsCount += 1
        showExploreReceivedArguments = (currencyCode: currencyCode, profile: profile)
        showExploreReceivedInvocations.append((currencyCode: currencyCode, profile: profile))
        showExploreClosure?(currencyCode, profile)
    }

    // MARK: - showTips

    internal private(set) var showTipsReceivedArguments: (
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode
    )?
    internal private(set) var showTipsReceivedInvocations: [(
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode
    )] = []
    internal private(set) var showTipsCallsCount = 0
    internal var showTipsClosure: ((ProfileId, AccountDetailsId, CurrencyCode) -> Void)?
    internal var showTipsCalled: Bool {
        showTipsCallsCount > 0
    }

    internal func showTips(profileId: ProfileId, accountDetailsId: AccountDetailsId, currencyCode: CurrencyCode) {
        showTipsCallsCount += 1
        showTipsReceivedArguments = (profileId: profileId, accountDetailsId: accountDetailsId, currencyCode: currencyCode)
        showTipsReceivedInvocations.append((profileId: profileId, accountDetailsId: accountDetailsId, currencyCode: currencyCode))
        showTipsClosure?(profileId, accountDetailsId, currencyCode)
    }

    // MARK: - showDirectDebitsFAQ

    internal private(set) var showDirectDebitsFAQCallsCount = 0
    internal var showDirectDebitsFAQClosure: (() -> Void)?
    internal var showDirectDebitsFAQCalled: Bool {
        showDirectDebitsFAQCallsCount > 0
    }

    internal func showDirectDebitsFAQ() {
        showDirectDebitsFAQCallsCount += 1
        showDirectDebitsFAQClosure?()
    }

    // MARK: - dismissBottomSheet

    internal private(set) var dismissBottomSheetReceivedCompletion: (() -> Void)?
    internal private(set) var dismissBottomSheetReceivedInvocations: [(() -> Void)?] = []
    internal private(set) var dismissBottomSheetCallsCount = 0
    internal var dismissBottomSheetClosure: (((() -> Void)?) -> Void)?
    internal var dismissBottomSheetCalled: Bool {
        dismissBottomSheetCallsCount > 0
    }

    internal func dismissBottomSheet(completion: (() -> Void)?) {
        dismissBottomSheetCallsCount += 1
        dismissBottomSheetReceivedCompletion = completion
        dismissBottomSheetReceivedInvocations.append(completion)
        dismissBottomSheetClosure?(completion)
    }

    // MARK: - showArticle

    internal private(set) var showArticleReceivedUrl: URL?
    internal private(set) var showArticleReceivedInvocations: [URL] = []
    internal private(set) var showArticleCallsCount = 0
    internal var showArticleClosure: ((URL) -> Void)?
    internal var showArticleCalled: Bool {
        showArticleCallsCount > 0
    }

    internal func showArticle(url: URL) {
        showArticleCallsCount += 1
        showArticleReceivedUrl = url
        showArticleReceivedInvocations.append(url)
        showArticleClosure?(url)
    }

    // MARK: - handleURI

    internal private(set) var handleURIReceivedUri: URI?
    internal private(set) var handleURIReceivedInvocations: [URI] = []
    internal private(set) var handleURICallsCount = 0
    internal var handleURIClosure: ((URI) -> Void)?
    internal var handleURICalled: Bool {
        handleURICallsCount > 0
    }

    internal func handleURI(_ uri: URI) {
        handleURICallsCount += 1
        handleURIReceivedUri = uri
        handleURIReceivedInvocations.append(uri)
        handleURIClosure?(uri)
    }

    // MARK: - showReceiveMethodAliasRegistration

    internal private(set) var showReceiveMethodAliasRegistrationReceivedArguments: (
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    )?
    internal private(set) var showReceiveMethodAliasRegistrationReceivedInvocations: [(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    )] = []
    internal private(set) var showReceiveMethodAliasRegistrationCallsCount = 0
    internal var showReceiveMethodAliasRegistrationClosure: ((AccountDetailsId, ProfileId) -> Void)?
    internal var showReceiveMethodAliasRegistrationCalled: Bool {
        showReceiveMethodAliasRegistrationCallsCount > 0
    }

    internal func showReceiveMethodAliasRegistration(accountDetailsId: AccountDetailsId, profileId: ProfileId) {
        showReceiveMethodAliasRegistrationCallsCount += 1
        showReceiveMethodAliasRegistrationReceivedArguments = (accountDetailsId: accountDetailsId, profileId: profileId)
        showReceiveMethodAliasRegistrationReceivedInvocations.append((accountDetailsId: accountDetailsId, profileId: profileId))
        showReceiveMethodAliasRegistrationClosure?(accountDetailsId, profileId)
    }

    // MARK: - present

    internal private(set) var presentReceivedViewController: UIViewController?
    internal private(set) var presentReceivedInvocations: [UIViewController] = []
    internal private(set) var presentCallsCount = 0
    internal var presentClosure: ((UIViewController) -> Void)?
    internal var presentCalled: Bool {
        presentCallsCount > 0
    }

    internal func present(viewController: UIViewController) {
        presentCallsCount += 1
        presentReceivedViewController = viewController
        presentReceivedInvocations.append(viewController)
        presentClosure?(viewController)
    }
}

internal final class AccountDetailsInfoV2ViewMock: AccountDetailsInfoV2View {
    internal var activeView: UIView {
        get { underlyingActiveView }
        set(value) { underlyingActiveView = value }
    }

    private var underlyingActiveView: UIView!
    internal var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate {
        get { underlyingDocumentInteractionControllerDelegate }
        set(value) { underlyingDocumentInteractionControllerDelegate = value }
    }

    private var underlyingDocumentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate!

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - configure

    internal private(set) var configureReceivedModel: AccountDetailsV2ViewModel?
    internal private(set) var configureReceivedInvocations: [AccountDetailsV2ViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((AccountDetailsV2ViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with model: AccountDetailsV2ViewModel) {
        configureCallsCount += 1
        configureReceivedModel = model
        configureReceivedInvocations.append(model)
        configureClosure?(model)
    }

    // MARK: - showConfirmation

    internal private(set) var showConfirmationReceivedMessage: String?
    internal private(set) var showConfirmationReceivedInvocations: [String] = []
    internal private(set) var showConfirmationCallsCount = 0
    internal var showConfirmationClosure: ((String) -> Void)?
    internal var showConfirmationCalled: Bool {
        showConfirmationCallsCount > 0
    }

    internal func showConfirmation(message: String) {
        showConfirmationCallsCount += 1
        showConfirmationReceivedMessage = message
        showConfirmationReceivedInvocations.append(message)
        showConfirmationClosure?(message)
    }

    // MARK: - generateHapticFeedback

    internal private(set) var generateHapticFeedbackCallsCount = 0
    internal var generateHapticFeedbackClosure: (() -> Void)?
    internal var generateHapticFeedbackCalled: Bool {
        generateHapticFeedbackCallsCount > 0
    }

    internal func generateHapticFeedback() {
        generateHapticFeedbackCallsCount += 1
        generateHapticFeedbackClosure?()
    }

    // MARK: - showErrorAlert

    internal private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorAlertCallsCount = 0
    internal var showErrorAlertClosure: ((String, String) -> Void)?
    internal var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    internal func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }

    // MARK: - showError

    internal private(set) var showErrorReceivedArguments: (
        title: String,
        message: String,
        leftAction: AlertAction,
        rightActionTitle: String
    )?
    internal private(set) var showErrorReceivedInvocations: [(
        title: String,
        message: String,
        leftAction: AlertAction,
        rightActionTitle: String
    )] = []
    internal private(set) var showErrorCallsCount = 0
    internal var showErrorClosure: ((String, String, AlertAction, String) -> Void)?
    internal var showErrorCalled: Bool {
        showErrorCallsCount > 0
    }

    internal func showError(title: String, message: String, leftAction: AlertAction, rightActionTitle: String) {
        showErrorCallsCount += 1
        showErrorReceivedArguments = (title: title, message: message, leftAction: leftAction, rightActionTitle: rightActionTitle)
        showErrorReceivedInvocations.append((
            title: title,
            message: message,
            leftAction: leftAction,
            rightActionTitle: rightActionTitle
        ))
        showErrorClosure?(title, message, leftAction, rightActionTitle)
    }
}

internal final class AccountDetailsListRouterMock: AccountDetailsListRouter {
    // MARK: - showSingleAccountDetails

    internal private(set) var showSingleAccountDetailsReceivedArguments: (
        accountDetails: ActiveAccountDetails,
        profile: Profile
    )?
    internal private(set) var showSingleAccountDetailsReceivedInvocations: [(
        accountDetails: ActiveAccountDetails,
        profile: Profile
    )] = []
    internal private(set) var showSingleAccountDetailsCallsCount = 0
    internal var showSingleAccountDetailsClosure: ((ActiveAccountDetails, Profile) -> Void)?
    internal var showSingleAccountDetailsCalled: Bool {
        showSingleAccountDetailsCallsCount > 0
    }

    internal func showSingleAccountDetails(_ accountDetails: ActiveAccountDetails, profile: Profile) {
        showSingleAccountDetailsCallsCount += 1
        showSingleAccountDetailsReceivedArguments = (accountDetails: accountDetails, profile: profile)
        showSingleAccountDetailsReceivedInvocations.append((accountDetails: accountDetails, profile: profile))
        showSingleAccountDetailsClosure?(accountDetails, profile)
    }

    // MARK: - showMultipleAccountDetails

    internal private(set) var showMultipleAccountDetailsReceivedArguments: (
        accountDetails: [ActiveAccountDetails],
        profile: Profile
    )?
    internal private(set) var showMultipleAccountDetailsReceivedInvocations: [(
        accountDetails: [ActiveAccountDetails],
        profile: Profile
    )] = []
    internal private(set) var showMultipleAccountDetailsCallsCount = 0
    internal var showMultipleAccountDetailsClosure: (([ActiveAccountDetails], Profile) -> Void)?
    internal var showMultipleAccountDetailsCalled: Bool {
        showMultipleAccountDetailsCallsCount > 0
    }

    internal func showMultipleAccountDetails(_ accountDetails: [ActiveAccountDetails], profile: Profile) {
        showMultipleAccountDetailsCallsCount += 1
        showMultipleAccountDetailsReceivedArguments = (accountDetails: accountDetails, profile: profile)
        showMultipleAccountDetailsReceivedInvocations.append((accountDetails: accountDetails, profile: profile))
        showMultipleAccountDetailsClosure?(accountDetails, profile)
    }

    // MARK: - requestAccountDetails

    internal private(set) var requestAccountDetailsReceivedArguments: (country: Country?, completion: () -> Void)?
    internal private(set) var requestAccountDetailsReceivedInvocations: [(country: Country?, completion: () -> Void)] = []
    internal private(set) var requestAccountDetailsCallsCount = 0
    internal var requestAccountDetailsClosure: ((Country?, @escaping () -> Void) -> Void)?
    internal var requestAccountDetailsCalled: Bool {
        requestAccountDetailsCallsCount > 0
    }

    internal func requestAccountDetails(country: Country?, completion: @escaping () -> Void) {
        requestAccountDetailsCallsCount += 1
        requestAccountDetailsReceivedArguments = (country: country, completion: completion)
        requestAccountDetailsReceivedInvocations.append((country: country, completion: completion))
        requestAccountDetailsClosure?(country, completion)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class AccountDetailsListViewMock: AccountDetailsListView {
    // MARK: - configureHeader

    internal private(set) var configureHeaderReceivedViewModel: LargeTitleViewModel?
    internal private(set) var configureHeaderReceivedInvocations: [LargeTitleViewModel] = []
    internal private(set) var configureHeaderCallsCount = 0
    internal var configureHeaderClosure: ((LargeTitleViewModel) -> Void)?
    internal var configureHeaderCalled: Bool {
        configureHeaderCallsCount > 0
    }

    internal func configureHeader(viewModel: LargeTitleViewModel) {
        configureHeaderCallsCount += 1
        configureHeaderReceivedViewModel = viewModel
        configureHeaderReceivedInvocations.append(viewModel)
        configureHeaderClosure?(viewModel)
    }

    // MARK: - setupNavigationLeftButton

    internal private(set) var setupNavigationLeftButtonReceivedArguments: (
        buttonStyle: UIBarButtonItem.BackButtonType,
        buttonAction: () -> Void
    )?
    internal private(set) var setupNavigationLeftButtonReceivedInvocations: [(
        buttonStyle: UIBarButtonItem.BackButtonType,
        buttonAction: () -> Void
    )] = []
    internal private(set) var setupNavigationLeftButtonCallsCount = 0
    internal var setupNavigationLeftButtonClosure: ((UIBarButtonItem.BackButtonType, @escaping () -> Void) -> Void)?
    internal var setupNavigationLeftButtonCalled: Bool {
        setupNavigationLeftButtonCallsCount > 0
    }

    internal func setupNavigationLeftButton(buttonStyle: UIBarButtonItem.BackButtonType, buttonAction: @escaping () -> Void) {
        setupNavigationLeftButtonCallsCount += 1
        setupNavigationLeftButtonReceivedArguments = (buttonStyle: buttonStyle, buttonAction: buttonAction)
        setupNavigationLeftButtonReceivedInvocations.append((buttonStyle: buttonStyle, buttonAction: buttonAction))
        setupNavigationLeftButtonClosure?(buttonStyle, buttonAction)
    }

    // MARK: - updateList

    internal private(set) var updateListReceivedSections: [AccountDetailListSectionModel]?
    internal private(set) var updateListReceivedInvocations: [[AccountDetailListSectionModel]] = []
    internal private(set) var updateListCallsCount = 0
    internal var updateListClosure: (([AccountDetailListSectionModel]) -> Void)?
    internal var updateListCalled: Bool {
        updateListCallsCount > 0
    }

    internal func updateList(sections: [AccountDetailListSectionModel]) {
        updateListCallsCount += 1
        updateListReceivedSections = sections
        updateListReceivedInvocations.append(sections)
        updateListClosure?(sections)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showInfoModal

    internal private(set) var showInfoModalReceivedArguments: (title: String, message: String)?
    internal private(set) var showInfoModalReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showInfoModalCallsCount = 0
    internal var showInfoModalClosure: ((String, String) -> Void)?
    internal var showInfoModalCalled: Bool {
        showInfoModalCallsCount > 0
    }

    internal func showInfoModal(title: String, message: String) {
        showInfoModalCallsCount += 1
        showInfoModalReceivedArguments = (title: title, message: message)
        showInfoModalReceivedInvocations.append((title: title, message: message))
        showInfoModalClosure?(title, message)
    }

    // MARK: - presentAlert

    internal private(set) var presentAlertReceivedArguments: (message: String, backAction: () -> Void)?
    internal private(set) var presentAlertReceivedInvocations: [(message: String, backAction: () -> Void)] = []
    internal private(set) var presentAlertCallsCount = 0
    internal var presentAlertClosure: ((String, @escaping () -> Void) -> Void)?
    internal var presentAlertCalled: Bool {
        presentAlertCallsCount > 0
    }

    internal func presentAlert(message: String, backAction: @escaping () -> Void) {
        presentAlertCallsCount += 1
        presentAlertReceivedArguments = (message: message, backAction: backAction)
        presentAlertReceivedInvocations.append((message: message, backAction: backAction))
        presentAlertClosure?(message, backAction)
    }

    // MARK: - presentSnackBar

    internal private(set) var presentSnackBarReceivedMessage: String?
    internal private(set) var presentSnackBarReceivedInvocations: [String] = []
    internal private(set) var presentSnackBarCallsCount = 0
    internal var presentSnackBarClosure: ((String) -> Void)?
    internal var presentSnackBarCalled: Bool {
        presentSnackBarCallsCount > 0
    }

    internal func presentSnackBar(message: String) {
        presentSnackBarCallsCount += 1
        presentSnackBarReceivedMessage = message
        presentSnackBarReceivedInvocations.append(message)
        presentSnackBarClosure?(message)
    }
}

internal final class AccountDetailsSplitterScreenViewControllerFactoryMock: AccountDetailsSplitterScreenViewControllerFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        profile: Profile,
        currency: CurrencyCode,
        source: AccountDetailsInfoInvocationSource,
        host: UINavigationController
    )?
    internal private(set) var makeReceivedInvocations: [(
        profile: Profile,
        currency: CurrencyCode,
        source: AccountDetailsInfoInvocationSource,
        host: UINavigationController
    )] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((Profile, CurrencyCode, AccountDetailsInfoInvocationSource, UINavigationController) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        profile: Profile,
        currency: CurrencyCode,
        source: AccountDetailsInfoInvocationSource,
        host: UINavigationController
    ) -> UIViewController {
        makeCallsCount += 1
        makeReceivedArguments = (profile: profile, currency: currency, source: source, host: host)
        makeReceivedInvocations.append((profile: profile, currency: currency, source: source, host: host))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(profile, currency, source, host)
    }
}

internal final class AccountDetailsStatusInteractorMock: AccountDetailsStatusInteractor {
    // MARK: - status

    internal private(set) var statusReceivedArguments: (profileId: ProfileId, currencyCode: CurrencyCode)?
    internal private(set) var statusReceivedInvocations: [(profileId: ProfileId, currencyCode: CurrencyCode)] = []
    internal var statusReturnValue: AnyPublisher<AccountDetailsStatus, Error>!
    internal private(set) var statusCallsCount = 0
    internal var statusClosure: ((ProfileId, CurrencyCode) -> AnyPublisher<AccountDetailsStatus, Error>)?
    internal var statusCalled: Bool {
        statusCallsCount > 0
    }

    internal func status(profileId: ProfileId, currencyCode: CurrencyCode) -> AnyPublisher<AccountDetailsStatus, Error> {
        statusCallsCount += 1
        statusReceivedArguments = (profileId: profileId, currencyCode: currencyCode)
        statusReceivedInvocations.append((profileId: profileId, currencyCode: currencyCode))
        guard let statusClosure else {
            return statusReturnValue
        }
        return statusClosure(profileId, currencyCode)
    }
}

internal final class AccountDetailsStatusPresenterMock: AccountDetailsStatusPresenter {
    // MARK: - configure

    internal private(set) var configureReceivedView: AccountDetailsStatusView?
    internal private(set) var configureReceivedInvocations: [AccountDetailsStatusView] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((AccountDetailsStatusView) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(view: AccountDetailsStatusView) {
        configureCallsCount += 1
        configureReceivedView = view
        configureReceivedInvocations.append(view)
        configureClosure?(view)
    }

    // MARK: - refresh

    internal private(set) var refreshCallsCount = 0
    internal var refreshClosure: (() -> Void)?
    internal var refreshCalled: Bool {
        refreshCallsCount > 0
    }

    internal func refresh() {
        refreshCallsCount += 1
        refreshClosure?()
    }

    // MARK: - infoSelected

    internal private(set) var infoSelectedReceivedInfo: AccountDetailsStatus.Section.Summary.Info?
    internal private(set) var infoSelectedReceivedInvocations: [AccountDetailsStatus.Section.Summary.Info] = []
    internal private(set) var infoSelectedCallsCount = 0
    internal var infoSelectedClosure: ((AccountDetailsStatus.Section.Summary.Info) -> Void)?
    internal var infoSelectedCalled: Bool {
        infoSelectedCallsCount > 0
    }

    internal func infoSelected(info: AccountDetailsStatus.Section.Summary.Info) {
        infoSelectedCallsCount += 1
        infoSelectedReceivedInfo = info
        infoSelectedReceivedInvocations.append(info)
        infoSelectedClosure?(info)
    }

    // MARK: - dismissSelected

    internal private(set) var dismissSelectedCallsCount = 0
    internal var dismissSelectedClosure: (() -> Void)?
    internal var dismissSelectedCalled: Bool {
        dismissSelectedCallsCount > 0
    }

    internal func dismissSelected() {
        dismissSelectedCallsCount += 1
        dismissSelectedClosure?()
    }

    // MARK: - buttonSelected

    internal private(set) var buttonSelectedReceivedAction: AccountDetailsStatus.Button.Action?
    internal private(set) var buttonSelectedReceivedInvocations: [AccountDetailsStatus.Button.Action] = []
    internal private(set) var buttonSelectedCallsCount = 0
    internal var buttonSelectedClosure: ((AccountDetailsStatus.Button.Action) -> Void)?
    internal var buttonSelectedCalled: Bool {
        buttonSelectedCallsCount > 0
    }

    internal func buttonSelected(action: AccountDetailsStatus.Button.Action) {
        buttonSelectedCallsCount += 1
        buttonSelectedReceivedAction = action
        buttonSelectedReceivedInvocations.append(action)
        buttonSelectedClosure?(action)
    }
}

internal final class AccountDetailsStatusViewMock: AccountDetailsStatusView {
    // MARK: - configure

    internal private(set) var configureReceivedState: AccountDetailsStatusViewState?
    internal private(set) var configureReceivedInvocations: [AccountDetailsStatusViewState] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((AccountDetailsStatusViewState) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with state: AccountDetailsStatusViewState) {
        configureCallsCount += 1
        configureReceivedState = state
        configureReceivedInvocations.append(state)
        configureClosure?(state)
    }
}

internal final class AccountDetailsTipsPresenterMock: AccountDetailsTipsPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsTipsView?
    internal private(set) var startReceivedInvocations: [AccountDetailsTipsView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsTipsView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: AccountDetailsTipsView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - closeButtonTapped

    internal private(set) var closeButtonTappedCallsCount = 0
    internal var closeButtonTappedClosure: (() -> Void)?
    internal var closeButtonTappedCalled: Bool {
        closeButtonTappedCallsCount > 0
    }

    internal func closeButtonTapped() {
        closeButtonTappedCallsCount += 1
        closeButtonTappedClosure?()
    }
}

internal final class AccountDetailsTipsRouterMock: AccountDetailsTipsRouter {
    // MARK: - open

    internal private(set) var openReceivedUrl: URL?
    internal private(set) var openReceivedInvocations: [URL] = []
    internal private(set) var openCallsCount = 0
    internal var openClosure: ((URL) -> Void)?
    internal var openCalled: Bool {
        openCallsCount > 0
    }

    internal func open(url: URL) {
        openCallsCount += 1
        openReceivedUrl = url
        openReceivedInvocations.append(url)
        openClosure?(url)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class AccountDetailsTipsViewMock: AccountDetailsTipsView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: UpsellViewModel?
    internal private(set) var configureReceivedInvocations: [UpsellViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((UpsellViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: UpsellViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showErrorAlert

    internal private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorAlertCallsCount = 0
    internal var showErrorAlertClosure: ((String, String) -> Void)?
    internal var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    internal func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }
}

internal final class AccountDetailsV3ListPresenterMock: AccountDetailsV3ListPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsV3ListView?
    internal private(set) var startReceivedInvocations: [AccountDetailsV3ListView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsV3ListView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: AccountDetailsV3ListView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - refresh

    internal private(set) var refreshCallsCount = 0
    internal var refreshClosure: (() -> Void)?
    internal var refreshCalled: Bool {
        refreshCallsCount > 0
    }

    internal func refresh() {
        refreshCallsCount += 1
        refreshClosure?()
    }
}

internal final class AccountDetailsV3ListViewMock: AccountDetailsV3ListView {
    // MARK: - configure

    internal private(set) var configureReceivedWith: AccountDetailsV3ListViewModel?
    internal private(set) var configureReceivedInvocations: [AccountDetailsV3ListViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((AccountDetailsV3ListViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with: AccountDetailsV3ListViewModel) {
        configureCallsCount += 1
        configureReceivedWith = with
        configureReceivedInvocations.append(with)
        configureClosure?(with)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedErrorViewModel: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with errorViewModel: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedErrorViewModel = errorViewModel
        configureWithErrorReceivedInvocations.append(errorViewModel)
        configureWithErrorClosure?(errorViewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - hideLoading

    internal private(set) var hideLoadingCallsCount = 0
    internal var hideLoadingClosure: (() -> Void)?
    internal var hideLoadingCalled: Bool {
        hideLoadingCallsCount > 0
    }

    internal func hideLoading() {
        hideLoadingCallsCount += 1
        hideLoadingClosure?()
    }
}

internal final class AccountDetailsV3PresenterMock: AccountDetailsV3Presenter {
    internal var viewActionDelegate: AccountDetailsV3ViewActionDelegate {
        get { underlyingViewActionDelegate }
        set(value) { underlyingViewActionDelegate = value }
    }

    private var underlyingViewActionDelegate: AccountDetailsV3ViewActionDelegate!
    internal var isCurrencySwitcherEnabled: Bool {
        get { underlyingIsCurrencySwitcherEnabled }
        set(value) { underlyingIsCurrencySwitcherEnabled = value }
    }

    private var underlyingIsCurrencySwitcherEnabled: Bool!

    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsV3View?
    internal private(set) var startReceivedInvocations: [AccountDetailsV3View] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsV3View) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: AccountDetailsV3View) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - refresh

    internal private(set) var refreshCallsCount = 0
    internal var refreshClosure: (() -> Void)?
    internal var refreshCalled: Bool {
        refreshCallsCount > 0
    }

    internal func refresh() {
        refreshCallsCount += 1
        refreshClosure?()
    }
}

internal final class AccountDetailsV3SplitterScreenListViewMock: AccountDetailsV3SplitterScreenListView {
    // MARK: - configure

    internal private(set) var configureReceivedWith: AccountDetailsV3SplitterScreenViewModel?
    internal private(set) var configureReceivedInvocations: [AccountDetailsV3SplitterScreenViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((AccountDetailsV3SplitterScreenViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with: AccountDetailsV3SplitterScreenViewModel) {
        configureCallsCount += 1
        configureReceivedWith = with
        configureReceivedInvocations.append(with)
        configureClosure?(with)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedErrorViewModel: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with errorViewModel: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedErrorViewModel = errorViewModel
        configureWithErrorReceivedInvocations.append(errorViewModel)
        configureWithErrorClosure?(errorViewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class AccountDetailsV3SplitterScreenPresenterMock: AccountDetailsV3SplitterScreenPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsV3SplitterScreenListView?
    internal private(set) var startReceivedInvocations: [AccountDetailsV3SplitterScreenListView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsV3SplitterScreenListView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: AccountDetailsV3SplitterScreenListView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class AccountDetailsV3ViewMock: LoadingPresentableMock, AccountDetailsV3View {
    internal var activeView: UIView {
        get { underlyingActiveView }
        set(value) { underlyingActiveView = value }
    }

    private var underlyingActiveView: UIView!
    internal var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate {
        get { underlyingDocumentInteractionControllerDelegate }
        set(value) { underlyingDocumentInteractionControllerDelegate = value }
    }

    private var underlyingDocumentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate!

    // MARK: - configure

    internal private(set) var configureReceivedModel: AccountDetailsV3?
    internal private(set) var configureReceivedInvocations: [AccountDetailsV3] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((AccountDetailsV3) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with model: AccountDetailsV3) {
        configureCallsCount += 1
        configureReceivedModel = model
        configureReceivedInvocations.append(model)
        configureClosure?(model)
    }

    // MARK: - configureNavigationBar

    internal private(set) var configureNavigationBarReceivedModel: AccountDetailsV3CurrencySelectorViewModel?
    internal private(set) var configureNavigationBarReceivedInvocations: [AccountDetailsV3CurrencySelectorViewModel] = []
    internal private(set) var configureNavigationBarCallsCount = 0
    internal var configureNavigationBarClosure: ((AccountDetailsV3CurrencySelectorViewModel) -> Void)?
    internal var configureNavigationBarCalled: Bool {
        configureNavigationBarCallsCount > 0
    }

    internal func configureNavigationBar(with model: AccountDetailsV3CurrencySelectorViewModel) {
        configureNavigationBarCallsCount += 1
        configureNavigationBarReceivedModel = model
        configureNavigationBarReceivedInvocations.append(model)
        configureNavigationBarClosure?(model)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedErrorViewModel: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with errorViewModel: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedErrorViewModel = errorViewModel
        configureWithErrorReceivedInvocations.append(errorViewModel)
        configureWithErrorClosure?(errorViewModel)
    }

    // MARK: - showErrorAlert

    internal private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorAlertCallsCount = 0
    internal var showErrorAlertClosure: ((String, String) -> Void)?
    internal var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    internal func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }

    // MARK: - showConfirmation

    internal private(set) var showConfirmationReceivedMessage: String?
    internal private(set) var showConfirmationReceivedInvocations: [String] = []
    internal private(set) var showConfirmationCallsCount = 0
    internal var showConfirmationClosure: ((String) -> Void)?
    internal var showConfirmationCalled: Bool {
        showConfirmationCallsCount > 0
    }

    internal func showConfirmation(message: String) {
        showConfirmationCallsCount += 1
        showConfirmationReceivedMessage = message
        showConfirmationReceivedInvocations.append(message)
        showConfirmationClosure?(message)
    }

    // MARK: - generateHapticFeedback

    internal private(set) var generateHapticFeedbackCallsCount = 0
    internal var generateHapticFeedbackClosure: (() -> Void)?
    internal var generateHapticFeedbackCalled: Bool {
        generateHapticFeedbackCallsCount > 0
    }

    internal func generateHapticFeedback() {
        generateHapticFeedbackCallsCount += 1
        generateHapticFeedbackClosure?()
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class AccountDetailsV3ViewActionDelegateMock: AccountDetailsV3ViewActionDelegate {
    // MARK: - containerTapped

    internal private(set) var containerTappedReceivedContent: AccountDetailsV3Information.InformationItem.DetailedSummary?
    internal private(set) var containerTappedReceivedInvocations: [AccountDetailsV3Information.InformationItem.DetailedSummary] = []
    internal private(set) var containerTappedCallsCount = 0
    internal var containerTappedClosure: ((AccountDetailsV3Information.InformationItem.DetailedSummary) -> Void)?
    internal var containerTappedCalled: Bool {
        containerTappedCallsCount > 0
    }

    internal func containerTapped(content: AccountDetailsV3Information.InformationItem.DetailedSummary) {
        containerTappedCallsCount += 1
        containerTappedReceivedContent = content
        containerTappedReceivedInvocations.append(content)
        containerTappedClosure?(content)
    }

    // MARK: - handleExternalAction

    internal private(set) var handleExternalActionReceivedAction: AccountDetailsExternalAction?
    internal private(set) var handleExternalActionReceivedInvocations: [AccountDetailsExternalAction?] = []
    internal private(set) var handleExternalActionCallsCount = 0
    internal var handleExternalActionClosure: ((AccountDetailsExternalAction?) -> Void)?
    internal var handleExternalActionCalled: Bool {
        handleExternalActionCallsCount > 0
    }

    internal func handleExternalAction(action: AccountDetailsExternalAction?) {
        handleExternalActionCallsCount += 1
        handleExternalActionReceivedAction = action
        handleExternalActionReceivedInvocations.append(action)
        handleExternalActionClosure?(action)
    }

    // MARK: - handleCopyAction

    internal private(set) var handleCopyActionReceivedArguments: (copyText: String, feedbackText: String)?
    internal private(set) var handleCopyActionReceivedInvocations: [(copyText: String, feedbackText: String)] = []
    internal private(set) var handleCopyActionCallsCount = 0
    internal var handleCopyActionClosure: ((String, String) -> Void)?
    internal var handleCopyActionCalled: Bool {
        handleCopyActionCallsCount > 0
    }

    internal func handleCopyAction(copyText: String, feedbackText: String) {
        handleCopyActionCallsCount += 1
        handleCopyActionReceivedArguments = (copyText: copyText, feedbackText: feedbackText)
        handleCopyActionReceivedInvocations.append((copyText: copyText, feedbackText: feedbackText))
        handleCopyActionClosure?(copyText, feedbackText)
    }

    // MARK: - handleHeaderAction

    internal private(set) var handleHeaderActionReceivedAction: AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction?
    internal private(set) var handleHeaderActionReceivedInvocations: [AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction] = []
    internal private(set) var handleHeaderActionCallsCount = 0
    internal var handleHeaderActionClosure: ((AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction) -> Void)?
    internal var handleHeaderActionCalled: Bool {
        handleHeaderActionCallsCount > 0
    }

    internal func handleHeaderAction(_ action: AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction) {
        handleHeaderActionCallsCount += 1
        handleHeaderActionReceivedAction = action
        handleHeaderActionReceivedInvocations.append(action)
        handleHeaderActionClosure?(action)
    }

    // MARK: - handleFeedbackAction

    internal private(set) var handleFeedbackActionCallsCount = 0
    internal var handleFeedbackActionClosure: (() -> Void)?
    internal var handleFeedbackActionCalled: Bool {
        handleFeedbackActionCallsCount > 0
    }

    internal func handleFeedbackAction() {
        handleFeedbackActionCallsCount += 1
        handleFeedbackActionClosure?()
    }

    // MARK: - handleAlertAction

    internal private(set) var handleAlertActionReceivedUri: URI?
    internal private(set) var handleAlertActionReceivedInvocations: [URI] = []
    internal private(set) var handleAlertActionCallsCount = 0
    internal var handleAlertActionClosure: ((URI) -> Void)?
    internal var handleAlertActionCalled: Bool {
        handleAlertActionCallsCount > 0
    }

    internal func handleAlertAction(uri: URI) {
        handleAlertActionCallsCount += 1
        handleAlertActionReceivedUri = uri
        handleAlertActionReceivedInvocations.append(uri)
        handleAlertActionClosure?(uri)
    }

    // MARK: - trackEvent

    internal private(set) var trackEventReceivedEvent: AccountDetailsV3AnalyticsEvent.Event?
    internal private(set) var trackEventReceivedInvocations: [AccountDetailsV3AnalyticsEvent.Event] = []
    internal private(set) var trackEventCallsCount = 0
    internal var trackEventClosure: ((AccountDetailsV3AnalyticsEvent.Event) -> Void)?
    internal var trackEventCalled: Bool {
        trackEventCallsCount > 0
    }

    internal func trackEvent(event: AccountDetailsV3AnalyticsEvent.Event) {
        trackEventCallsCount += 1
        trackEventReceivedEvent = event
        trackEventReceivedInvocations.append(event)
        trackEventClosure?(event)
    }
}

internal final class AccountDetailsWishListPresenterMock: AccountDetailsWishListPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: AccountDetailsWishView?
    internal private(set) var startReceivedInvocations: [AccountDetailsWishView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((AccountDetailsWishView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: AccountDetailsWishView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - toggleSelection

    internal private(set) var toggleSelectionReceivedIndex: Int?
    internal private(set) var toggleSelectionReceivedInvocations: [Int] = []
    internal private(set) var toggleSelectionCallsCount = 0
    internal var toggleSelectionClosure: ((Int) -> Void)?
    internal var toggleSelectionCalled: Bool {
        toggleSelectionCallsCount > 0
    }

    internal func toggleSelection(at index: Int) {
        toggleSelectionCallsCount += 1
        toggleSelectionReceivedIndex = index
        toggleSelectionReceivedInvocations.append(index)
        toggleSelectionClosure?(index)
    }

    // MARK: - updateSearchQuery

    internal private(set) var updateSearchQueryReceivedQuery: String?
    internal private(set) var updateSearchQueryReceivedInvocations: [String] = []
    internal private(set) var updateSearchQueryCallsCount = 0
    internal var updateSearchQueryClosure: ((String) -> Void)?
    internal var updateSearchQueryCalled: Bool {
        updateSearchQueryCallsCount > 0
    }

    internal func updateSearchQuery(_ query: String) {
        updateSearchQueryCallsCount += 1
        updateSearchQueryReceivedQuery = query
        updateSearchQueryReceivedInvocations.append(query)
        updateSearchQueryClosure?(query)
    }

    // MARK: - reload

    internal private(set) var reloadCallsCount = 0
    internal var reloadClosure: (() -> Void)?
    internal var reloadCalled: Bool {
        reloadCallsCount > 0
    }

    internal func reload() {
        reloadCallsCount += 1
        reloadClosure?()
    }
}

internal final class AvatarLoadableNavigationOptionTableViewCellMock: AvatarLoadableNavigationOptionTableViewCell {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: OptionViewModel?
    internal private(set) var configureReceivedInvocations: [OptionViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((OptionViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: OptionViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class AvatarLoadableNavigationOptionTableViewCellPresenterMock: AvatarLoadableNavigationOptionTableViewCellPresenter {
    // MARK: - start

    internal private(set) var startReceivedArguments: (
        title: String,
        subtitle: String,
        avatarPublisher: AvatarPublisher,
        cell: AvatarLoadableNavigationOptionTableViewCell
    )?
    internal private(set) var startReceivedInvocations: [(
        title: String,
        subtitle: String,
        avatarPublisher: AvatarPublisher,
        cell: AvatarLoadableNavigationOptionTableViewCell
    )] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((String, String, AvatarPublisher, AvatarLoadableNavigationOptionTableViewCell) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(
        title: String,
        subtitle: String,
        avatarPublisher: AvatarPublisher,
        cell: AvatarLoadableNavigationOptionTableViewCell
    ) {
        startCallsCount += 1
        startReceivedArguments = (title: title, subtitle: subtitle, avatarPublisher: avatarPublisher, cell: cell)
        startReceivedInvocations.append((title: title, subtitle: subtitle, avatarPublisher: avatarPublisher, cell: cell))
        startClosure?(title, subtitle, avatarPublisher, cell)
    }

    // MARK: - prepareForReuse

    internal private(set) var prepareForReuseCallsCount = 0
    internal var prepareForReuseClosure: (() -> Void)?
    internal var prepareForReuseCalled: Bool {
        prepareForReuseCallsCount > 0
    }

    internal func prepareForReuse() {
        prepareForReuseCallsCount += 1
        prepareForReuseClosure?()
    }
}

internal final class CameraRollPermissionFlowFactoryMock: CameraRollPermissionFlowFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (image: UIImage, navigationHost: UIViewController)?
    internal private(set) var makeReceivedInvocations: [(image: UIImage, navigationHost: UIViewController)] = []
    internal var makeReturnValue: (any Flow<CameraRollPermissionFlowResult>)!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((UIImage, UIViewController) -> any Flow<CameraRollPermissionFlowResult>)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(image: UIImage, navigationHost: UIViewController) -> any Flow<CameraRollPermissionFlowResult> {
        makeCallsCount += 1
        makeReceivedArguments = (image: image, navigationHost: navigationHost)
        makeReceivedInvocations.append((image: image, navigationHost: navigationHost))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(image, navigationHost)
    }
}

internal final class CameraRollPermissionProviderMock: CameraRollPermissionProvider {
    // MARK: - getCameraRollPermissionState

    internal var getCameraRollPermissionStateReturnValue: CameraRollPermissionState!
    internal private(set) var getCameraRollPermissionStateCallsCount = 0
    internal var getCameraRollPermissionStateClosure: (() -> CameraRollPermissionState)?
    internal var getCameraRollPermissionStateCalled: Bool {
        getCameraRollPermissionStateCallsCount > 0
    }

    internal func getCameraRollPermissionState() -> CameraRollPermissionState {
        getCameraRollPermissionStateCallsCount += 1
        guard let getCameraRollPermissionStateClosure else {
            return getCameraRollPermissionStateReturnValue
        }
        return getCameraRollPermissionStateClosure()
    }

    // MARK: - requestAccess

    internal private(set) var requestAccessReceivedCompletion: ((Bool) -> Void)?
    internal private(set) var requestAccessReceivedInvocations: [(Bool) -> Void] = []
    internal private(set) var requestAccessCallsCount = 0
    internal var requestAccessClosure: ((@escaping (Bool) -> Void) -> Void)?
    internal var requestAccessCalled: Bool {
        requestAccessCallsCount > 0
    }

    internal func requestAccess(_ completion: @escaping (Bool) -> Void) {
        requestAccessCallsCount += 1
        requestAccessReceivedCompletion = completion
        requestAccessReceivedInvocations.append(completion)
        requestAccessClosure?(completion)
    }

    // MARK: - saveImage

    internal private(set) var saveImageReceivedArguments: (image: UIImage, completion: (Bool) -> Void)?
    internal private(set) var saveImageReceivedInvocations: [(image: UIImage, completion: (Bool) -> Void)] = []
    internal private(set) var saveImageCallsCount = 0
    internal var saveImageClosure: ((UIImage, @escaping (Bool) -> Void) -> Void)?
    internal var saveImageCalled: Bool {
        saveImageCallsCount > 0
    }

    internal func saveImage(image: UIImage, _ completion: @escaping (Bool) -> Void) {
        saveImageCallsCount += 1
        saveImageReceivedArguments = (image: image, completion: completion)
        saveImageReceivedInvocations.append((image: image, completion: completion))
        saveImageClosure?(image, completion)
    }
}

internal final class CameraRollPermissionSheetFactoryMock: CameraRollPermissionSheetFactory {
    // MARK: - makeCustomAlertBottomSheet

    internal private(set) var makeCustomAlertBottomSheetReceivedArguments: (
        title: String,
        message: String,
        primaryAction: Action
    )?
    internal private(set) var makeCustomAlertBottomSheetReceivedInvocations: [(
        title: String,
        message: String,
        primaryAction: Action
    )] = []
    internal var makeCustomAlertBottomSheetReturnValue: UIViewController!
    internal private(set) var makeCustomAlertBottomSheetCallsCount = 0
    internal var makeCustomAlertBottomSheetClosure: ((String, String, Action) -> UIViewController)?
    internal var makeCustomAlertBottomSheetCalled: Bool {
        makeCustomAlertBottomSheetCallsCount > 0
    }

    internal func makeCustomAlertBottomSheet(title: String, message: String, primaryAction: Action) -> UIViewController {
        makeCustomAlertBottomSheetCallsCount += 1
        makeCustomAlertBottomSheetReceivedArguments = (title: title, message: message, primaryAction: primaryAction)
        makeCustomAlertBottomSheetReceivedInvocations.append((title: title, message: message, primaryAction: primaryAction))
        guard let makeCustomAlertBottomSheetClosure else {
            return makeCustomAlertBottomSheetReturnValue
        }
        return makeCustomAlertBottomSheetClosure(title, message, primaryAction)
    }
}

internal final class CancellableAvatarFetcherMock: CancellableAvatarFetcher {
    // MARK: - fetch

    internal private(set) var fetchReceivedArguments: (
        publisher: AvatarPublisher,
        completion: (ContactsKit.AvatarModel) -> Void
    )?
    internal private(set) var fetchReceivedInvocations: [(
        publisher: AvatarPublisher,
        completion: (ContactsKit.AvatarModel) -> Void
    )] = []
    internal private(set) var fetchCallsCount = 0
    internal var fetchClosure: ((AvatarPublisher, @escaping (ContactsKit.AvatarModel) -> Void) -> Void)?
    internal var fetchCalled: Bool {
        fetchCallsCount > 0
    }

    internal func fetch(publisher: AvatarPublisher, completion: @escaping (ContactsKit.AvatarModel) -> Void) {
        fetchCallsCount += 1
        fetchReceivedArguments = (publisher: publisher, completion: completion)
        fetchReceivedInvocations.append((publisher: publisher, completion: completion))
        fetchClosure?(publisher, completion)
    }

    // MARK: - cancel

    internal private(set) var cancelCallsCount = 0
    internal var cancelClosure: (() -> Void)?
    internal var cancelCalled: Bool {
        cancelCallsCount > 0
    }

    internal func cancel() {
        cancelCallsCount += 1
        cancelClosure?()
    }
}

internal final class ContactPickerInviteFriendsPreferenceStorageMock: ContactPickerInviteFriendsPreferenceStorage {
    // MARK: - inviteFriendsPreference

    internal private(set) var inviteFriendsPreferenceReceivedUserId: UserId?
    internal private(set) var inviteFriendsPreferenceReceivedInvocations: [UserId] = []
    internal var inviteFriendsPreferenceReturnValue: Bool!
    internal private(set) var inviteFriendsPreferenceCallsCount = 0
    internal var inviteFriendsPreferenceClosure: ((UserId) -> Bool)?
    internal var inviteFriendsPreferenceCalled: Bool {
        inviteFriendsPreferenceCallsCount > 0
    }

    internal func inviteFriendsPreference(for userId: UserId) -> Bool {
        inviteFriendsPreferenceCallsCount += 1
        inviteFriendsPreferenceReceivedUserId = userId
        inviteFriendsPreferenceReceivedInvocations.append(userId)
        guard let inviteFriendsPreferenceClosure else {
            return inviteFriendsPreferenceReturnValue
        }
        return inviteFriendsPreferenceClosure(userId)
    }

    // MARK: - setInviteFriendsPreference

    internal private(set) var setInviteFriendsPreferenceReceivedArguments: (preference: Bool, userId: UserId)?
    internal private(set) var setInviteFriendsPreferenceReceivedInvocations: [(preference: Bool, userId: UserId)] = []
    internal private(set) var setInviteFriendsPreferenceCallsCount = 0
    internal var setInviteFriendsPreferenceClosure: ((Bool, UserId) -> Void)?
    internal var setInviteFriendsPreferenceCalled: Bool {
        setInviteFriendsPreferenceCallsCount > 0
    }

    internal func setInviteFriendsPreference(_ preference: Bool, for userId: UserId) {
        setInviteFriendsPreferenceCallsCount += 1
        setInviteFriendsPreferenceReceivedArguments = (preference: preference, userId: userId)
        setInviteFriendsPreferenceReceivedInvocations.append((preference: preference, userId: userId))
        setInviteFriendsPreferenceClosure?(preference, userId)
    }
}

internal final class ContactPickerNudgeProviderMock: ContactPickerNudgeProvider {
    internal var nudge: AnyPublisher<ContactPickerNudgeType?, Never> {
        get { underlyingNudge }
        set(value) { underlyingNudge = value }
    }

    private var underlyingNudge: AnyPublisher<ContactPickerNudgeType?, Never>!

    // MARK: - nudgeDismissed

    internal private(set) var nudgeDismissedReceivedNudge: ContactPickerNudgeType?
    internal private(set) var nudgeDismissedReceivedInvocations: [ContactPickerNudgeType] = []
    internal private(set) var nudgeDismissedCallsCount = 0
    internal var nudgeDismissedClosure: ((ContactPickerNudgeType) -> Void)?
    internal var nudgeDismissedCalled: Bool {
        nudgeDismissedCallsCount > 0
    }

    internal func nudgeDismissed(_ nudge: ContactPickerNudgeType) {
        nudgeDismissedCallsCount += 1
        nudgeDismissedReceivedNudge = nudge
        nudgeDismissedReceivedInvocations.append(nudge)
        nudgeDismissedClosure?(nudge)
    }

    // MARK: - getContentForNudge

    internal private(set) var getContentForNudgeReceivedNudge: ContactPickerNudgeType?
    internal private(set) var getContentForNudgeReceivedInvocations: [ContactPickerNudgeType] = []
    internal var getContentForNudgeReturnValue: AnyPublisher<ContactPickerNudgeModel, Error>!
    internal private(set) var getContentForNudgeCallsCount = 0
    internal var getContentForNudgeClosure: ((ContactPickerNudgeType) -> AnyPublisher<ContactPickerNudgeModel, Error>)?
    internal var getContentForNudgeCalled: Bool {
        getContentForNudgeCallsCount > 0
    }

    internal func getContentForNudge(_ nudge: ContactPickerNudgeType) -> AnyPublisher<ContactPickerNudgeModel, Error> {
        getContentForNudgeCallsCount += 1
        getContentForNudgeReceivedNudge = nudge
        getContentForNudgeReceivedInvocations.append(nudge)
        guard let getContentForNudgeClosure else {
            return getContentForNudgeReturnValue
        }
        return getContentForNudgeClosure(nudge)
    }
}

internal final class CreatePaymentRequestConfirmationPresenterMock: CreatePaymentRequestConfirmationPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: CreatePaymentRequestConfirmationView?
    internal private(set) var startReceivedInvocations: [CreatePaymentRequestConfirmationView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((CreatePaymentRequestConfirmationView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: CreatePaymentRequestConfirmationView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - privacyPolicyTapped

    internal private(set) var privacyPolicyTappedCallsCount = 0
    internal var privacyPolicyTappedClosure: (() -> Void)?
    internal var privacyPolicyTappedCalled: Bool {
        privacyPolicyTappedCallsCount > 0
    }

    internal func privacyPolicyTapped() {
        privacyPolicyTappedCallsCount += 1
        privacyPolicyTappedClosure?()
    }

    // MARK: - giveFeedbackTapped

    internal private(set) var giveFeedbackTappedCallsCount = 0
    internal var giveFeedbackTappedClosure: (() -> Void)?
    internal var giveFeedbackTappedCalled: Bool {
        giveFeedbackTappedCallsCount > 0
    }

    internal func giveFeedbackTapped() {
        giveFeedbackTappedCallsCount += 1
        giveFeedbackTappedClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - doneTapped

    internal private(set) var doneTappedCallsCount = 0
    internal var doneTappedClosure: (() -> Void)?
    internal var doneTappedCalled: Bool {
        doneTappedCallsCount > 0
    }

    internal func doneTapped() {
        doneTappedCallsCount += 1
        doneTappedClosure?()
    }
}

internal final class CreatePaymentRequestConfirmationRouterMock: CreatePaymentRequestConfirmationRouter {
    // MARK: - showPrivacyPolicy

    internal private(set) var showPrivacyPolicyCallsCount = 0
    internal var showPrivacyPolicyClosure: (() -> Void)?
    internal var showPrivacyPolicyCalled: Bool {
        showPrivacyPolicyCallsCount > 0
    }

    internal func showPrivacyPolicy() {
        showPrivacyPolicyCallsCount += 1
        showPrivacyPolicyClosure?()
    }

    // MARK: - showQRCode

    internal private(set) var showQRCodeCallsCount = 0
    internal var showQRCodeClosure: (() -> Void)?
    internal var showQRCodeCalled: Bool {
        showQRCodeCallsCount > 0
    }

    internal func showQRCode() {
        showQRCodeCallsCount += 1
        showQRCodeClosure?()
    }

    // MARK: - showFeedback

    internal private(set) var showFeedbackReceivedArguments: (
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: () -> Void
    )?
    internal private(set) var showFeedbackReceivedInvocations: [(
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: () -> Void
    )] = []
    internal private(set) var showFeedbackCallsCount = 0
    internal var showFeedbackClosure: ((FeedbackViewModel, FeedbackContext, @escaping () -> Void) -> Void)?
    internal var showFeedbackCalled: Bool {
        showFeedbackCallsCount > 0
    }

    internal func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping () -> Void) {
        showFeedbackCallsCount += 1
        showFeedbackReceivedArguments = (model: model, context: context, onSuccess: onSuccess)
        showFeedbackReceivedInvocations.append((model: model, context: context, onSuccess: onSuccess))
        showFeedbackClosure?(model, context, onSuccess)
    }
}

internal final class CreatePaymentRequestConfirmationViewMock: CreatePaymentRequestConfirmationView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: CreatePaymentRequestConfirmationViewModel?
    internal private(set) var configureReceivedInvocations: [CreatePaymentRequestConfirmationViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((CreatePaymentRequestConfirmationViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: CreatePaymentRequestConfirmationViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }

    // MARK: - showSnackbar

    internal private(set) var showSnackbarReceivedMessage: String?
    internal private(set) var showSnackbarReceivedInvocations: [String] = []
    internal private(set) var showSnackbarCallsCount = 0
    internal var showSnackbarClosure: ((String) -> Void)?
    internal var showSnackbarCalled: Bool {
        showSnackbarCallsCount > 0
    }

    internal func showSnackbar(message: String) {
        showSnackbarCallsCount += 1
        showSnackbarReceivedMessage = message
        showSnackbarReceivedInvocations.append(message)
        showSnackbarClosure?(message)
    }

    // MARK: - generateHapticFeedback

    internal private(set) var generateHapticFeedbackCallsCount = 0
    internal var generateHapticFeedbackClosure: (() -> Void)?
    internal var generateHapticFeedbackCalled: Bool {
        generateHapticFeedbackCallsCount > 0
    }

    internal func generateHapticFeedback() {
        generateHapticFeedbackCallsCount += 1
        generateHapticFeedbackClosure?()
    }

    // MARK: - showShareSheet

    internal private(set) var showShareSheetReceivedText: String?
    internal private(set) var showShareSheetReceivedInvocations: [String] = []
    internal private(set) var showShareSheetCallsCount = 0
    internal var showShareSheetClosure: ((String) -> Void)?
    internal var showShareSheetCalled: Bool {
        showShareSheetCallsCount > 0
    }

    internal func showShareSheet(with text: String) {
        showShareSheetCallsCount += 1
        showShareSheetReceivedText = text
        showShareSheetReceivedInvocations.append(text)
        showShareSheetClosure?(text)
    }

    // MARK: - showPrivacyNotice

    internal private(set) var showPrivacyNoticeReceivedViewModel: CreatePaymentRequestConfirmationPrivacyNoticeViewModel?
    internal private(set) var showPrivacyNoticeReceivedInvocations: [CreatePaymentRequestConfirmationPrivacyNoticeViewModel] = []
    internal private(set) var showPrivacyNoticeCallsCount = 0
    internal var showPrivacyNoticeClosure: ((CreatePaymentRequestConfirmationPrivacyNoticeViewModel) -> Void)?
    internal var showPrivacyNoticeCalled: Bool {
        showPrivacyNoticeCallsCount > 0
    }

    internal func showPrivacyNotice(with viewModel: CreatePaymentRequestConfirmationPrivacyNoticeViewModel) {
        showPrivacyNoticeCallsCount += 1
        showPrivacyNoticeReceivedViewModel = viewModel
        showPrivacyNoticeReceivedInvocations.append(viewModel)
        showPrivacyNoticeClosure?(viewModel)
    }
}

internal final class CreatePaymentRequestFlowFactoryMock: CreatePaymentRequestFlowFactory {
    // MARK: - makeForRequestMoneyFlow

    internal private(set) var makeForRequestMoneyFlowReceivedArguments: (
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        navigationController: UINavigationController
    )?
    internal private(set) var makeForRequestMoneyFlowReceivedInvocations: [(
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        navigationController: UINavigationController
    )] = []
    internal var makeForRequestMoneyFlowReturnValue: (any Flow<CreatePaymentRequestFlowResult>)!
    internal private(set) var makeForRequestMoneyFlowCallsCount = 0
    internal var makeForRequestMoneyFlowClosure: ((
        RequestMoneyFlow.EntryPoint,
        Profile,
        RequestMoneyContact?,
        CurrencyCode?,
        PaymentRequestEligibleBalances.Balance,
        PaymentRequestEligibleBalances,
        ReceiveContactSearchViewControllerFactory,
        UINavigationController
    ) -> any Flow<CreatePaymentRequestFlowResult>)?
    internal var makeForRequestMoneyFlowCalled: Bool {
        makeForRequestMoneyFlowCallsCount > 0
    }

    internal func makeForRequestMoneyFlow(
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        navigationController: UINavigationController
    ) -> any Flow<CreatePaymentRequestFlowResult> {
        makeForRequestMoneyFlowCallsCount += 1
        makeForRequestMoneyFlowReceivedArguments = (
            entryPoint: entryPoint,
            profile: profile,
            contact: contact,
            preSelectedBalanceCurrencyCode: preSelectedBalanceCurrencyCode,
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            navigationController: navigationController
        )
        makeForRequestMoneyFlowReceivedInvocations.append((
            entryPoint: entryPoint,
            profile: profile,
            contact: contact,
            preSelectedBalanceCurrencyCode: preSelectedBalanceCurrencyCode,
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            navigationController: navigationController
        ))
        guard let makeForRequestMoneyFlowClosure else {
            return makeForRequestMoneyFlowReturnValue
        }
        return makeForRequestMoneyFlowClosure(
            entryPoint,
            profile,
            contact,
            preSelectedBalanceCurrencyCode,
            defaultBalance,
            eligibleBalances,
            contactSearchViewControllerFactory,
            navigationController
        )
    }
}

internal final class CreatePaymentRequestInteractorMock: CreatePaymentRequestInteractor {
    // MARK: - shouldShowNudge

    internal private(set) var shouldShowNudgeReceivedArguments: (profileId: ProfileId, nudgeType: CardNudgeType)?
    internal private(set) var shouldShowNudgeReceivedInvocations: [(profileId: ProfileId, nudgeType: CardNudgeType)] = []
    internal var shouldShowNudgeReturnValue: Bool!
    internal private(set) var shouldShowNudgeCallsCount = 0
    internal var shouldShowNudgeClosure: ((ProfileId, CardNudgeType) -> Bool)?
    internal var shouldShowNudgeCalled: Bool {
        shouldShowNudgeCallsCount > 0
    }

    internal func shouldShowNudge(profileId: ProfileId, nudgeType: CardNudgeType) -> Bool {
        shouldShowNudgeCallsCount += 1
        shouldShowNudgeReceivedArguments = (profileId: profileId, nudgeType: nudgeType)
        shouldShowNudgeReceivedInvocations.append((profileId: profileId, nudgeType: nudgeType))
        guard let shouldShowNudgeClosure else {
            return shouldShowNudgeReturnValue
        }
        return shouldShowNudgeClosure(profileId, nudgeType)
    }

    // MARK: - setShouldShowNudge

    internal private(set) var setShouldShowNudgeReceivedArguments: (
        shouldShow: Bool,
        profileId: ProfileId,
        nudgeType: CardNudgeType
    )?
    internal private(set) var setShouldShowNudgeReceivedInvocations: [(
        shouldShow: Bool,
        profileId: ProfileId,
        nudgeType: CardNudgeType
    )] = []
    internal private(set) var setShouldShowNudgeCallsCount = 0
    internal var setShouldShowNudgeClosure: ((Bool, ProfileId, CardNudgeType) -> Void)?
    internal var setShouldShowNudgeCalled: Bool {
        setShouldShowNudgeCallsCount > 0
    }

    internal func setShouldShowNudge(_ shouldShow: Bool, profileId: ProfileId, nudgeType: CardNudgeType) {
        setShouldShowNudgeCallsCount += 1
        setShouldShowNudgeReceivedArguments = (shouldShow: shouldShow, profileId: profileId, nudgeType: nudgeType)
        setShouldShowNudgeReceivedInvocations.append((shouldShow: shouldShow, profileId: profileId, nudgeType: nudgeType))
        setShouldShowNudgeClosure?(shouldShow, profileId, nudgeType)
    }

    // MARK: - fetchEligibilityAndDefaultRequestType

    internal var fetchEligibilityAndDefaultRequestTypeReturnValue: AnyPublisher<
        (RequestMoneyProductEligibility, RequestType),
        Error
    >!
    internal private(set) var fetchEligibilityAndDefaultRequestTypeCallsCount = 0
    internal var fetchEligibilityAndDefaultRequestTypeClosure: (() -> AnyPublisher<
        (RequestMoneyProductEligibility, RequestType),
        Error
    >)?
    internal var fetchEligibilityAndDefaultRequestTypeCalled: Bool {
        fetchEligibilityAndDefaultRequestTypeCallsCount > 0
    }

    internal func fetchEligibilityAndDefaultRequestType() -> AnyPublisher<(RequestMoneyProductEligibility, RequestType), Error> {
        fetchEligibilityAndDefaultRequestTypeCallsCount += 1
        guard let fetchEligibilityAndDefaultRequestTypeClosure else {
            return fetchEligibilityAndDefaultRequestTypeReturnValue
        }
        return fetchEligibilityAndDefaultRequestTypeClosure()
    }

    // MARK: - fetchEligibleBalances

    internal var fetchEligibleBalancesReturnValue: AnyPublisher<PaymentRequestEligibleBalances, Error>!
    internal private(set) var fetchEligibleBalancesCallsCount = 0
    internal var fetchEligibleBalancesClosure: (() -> AnyPublisher<PaymentRequestEligibleBalances, Error>)?
    internal var fetchEligibleBalancesCalled: Bool {
        fetchEligibleBalancesCallsCount > 0
    }

    internal func fetchEligibleBalances() -> AnyPublisher<PaymentRequestEligibleBalances, Error> {
        fetchEligibleBalancesCallsCount += 1
        guard let fetchEligibleBalancesClosure else {
            return fetchEligibleBalancesReturnValue
        }
        return fetchEligibleBalancesClosure()
    }

    // MARK: - createPaymentRequest

    internal private(set) var createPaymentRequestReceivedBody: PaymentRequestBodyV2?
    internal private(set) var createPaymentRequestReceivedInvocations: [PaymentRequestBodyV2] = []
    internal var createPaymentRequestReturnValue: AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError>!
    internal private(set) var createPaymentRequestCallsCount = 0
    internal var createPaymentRequestClosure: ((PaymentRequestBodyV2) -> AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError>)?
    internal var createPaymentRequestCalled: Bool {
        createPaymentRequestCallsCount > 0
    }

    internal func createPaymentRequest(body: PaymentRequestBodyV2) -> AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError> {
        createPaymentRequestCallsCount += 1
        createPaymentRequestReceivedBody = body
        createPaymentRequestReceivedInvocations.append(body)
        guard let createPaymentRequestClosure else {
            return createPaymentRequestReturnValue
        }
        return createPaymentRequestClosure(body)
    }

    // MARK: - fetchReceiverCurrencyAvailability

    internal private(set) var fetchReceiverCurrencyAvailabilityReceivedArguments: (
        amount: Decimal,
        currencies: [CurrencyCode],
        paymentMethods: [PaymentRequestV2PaymentMethods],
        onlyPreferredPaymentMethods: Bool
    )?
    internal private(set) var fetchReceiverCurrencyAvailabilityReceivedInvocations: [(
        amount: Decimal,
        currencies: [CurrencyCode],
        paymentMethods: [PaymentRequestV2PaymentMethods],
        onlyPreferredPaymentMethods: Bool
    )] = []
    internal var fetchReceiverCurrencyAvailabilityReturnValue: AnyPublisher<PaymentRequestV2ReceiverAvailability, Error>!
    internal private(set) var fetchReceiverCurrencyAvailabilityCallsCount = 0
    internal var fetchReceiverCurrencyAvailabilityClosure: ((Decimal, [CurrencyCode], [PaymentRequestV2PaymentMethods], Bool) -> AnyPublisher<
        PaymentRequestV2ReceiverAvailability,
        Error
    >)?
    internal var fetchReceiverCurrencyAvailabilityCalled: Bool {
        fetchReceiverCurrencyAvailabilityCallsCount > 0
    }

    internal func fetchReceiverCurrencyAvailability(
        amount: Decimal,
        currencies: [CurrencyCode],
        paymentMethods: [PaymentRequestV2PaymentMethods],
        onlyPreferredPaymentMethods: Bool
    ) -> AnyPublisher<PaymentRequestV2ReceiverAvailability, Error> {
        fetchReceiverCurrencyAvailabilityCallsCount += 1
        fetchReceiverCurrencyAvailabilityReceivedArguments = (
            amount: amount,
            currencies: currencies,
            paymentMethods: paymentMethods,
            onlyPreferredPaymentMethods: onlyPreferredPaymentMethods
        )
        fetchReceiverCurrencyAvailabilityReceivedInvocations.append((
            amount: amount,
            currencies: currencies,
            paymentMethods: paymentMethods,
            onlyPreferredPaymentMethods: onlyPreferredPaymentMethods
        ))
        guard let fetchReceiverCurrencyAvailabilityClosure else {
            return fetchReceiverCurrencyAvailabilityReturnValue
        }
        return fetchReceiverCurrencyAvailabilityClosure(amount, currencies, paymentMethods, onlyPreferredPaymentMethods)
    }
}

internal final class CreatePaymentRequestPaymentMethodManagementPresenterMock: CreatePaymentRequestPaymentMethodManagementPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: CreatePaymentRequestPaymentMethodManagementView?
    internal private(set) var startReceivedInvocations: [CreatePaymentRequestPaymentMethodManagementView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((CreatePaymentRequestPaymentMethodManagementView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: CreatePaymentRequestPaymentMethodManagementView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - footerButtonTapped

    internal private(set) var footerButtonTappedCallsCount = 0
    internal var footerButtonTappedClosure: (() -> Void)?
    internal var footerButtonTappedCalled: Bool {
        footerButtonTappedCallsCount > 0
    }

    internal func footerButtonTapped() {
        footerButtonTappedCallsCount += 1
        footerButtonTappedClosure?()
    }

    // MARK: - secondaryFooterButtonTapped

    internal private(set) var secondaryFooterButtonTappedCallsCount = 0
    internal var secondaryFooterButtonTappedClosure: (() -> Void)?
    internal var secondaryFooterButtonTappedCalled: Bool {
        secondaryFooterButtonTappedCallsCount > 0
    }

    internal func secondaryFooterButtonTapped() {
        secondaryFooterButtonTappedCallsCount += 1
        secondaryFooterButtonTappedClosure?()
    }
}

internal final class CreatePaymentRequestPaymentMethodManagementViewMock: CreatePaymentRequestPaymentMethodManagementView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: CreatePaymentRequestMethodManagementViewModel?
    internal private(set) var configureReceivedInvocations: [CreatePaymentRequestMethodManagementViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((CreatePaymentRequestMethodManagementViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: CreatePaymentRequestMethodManagementViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class CreatePaymentRequestPersonalPresenterMock: CreatePaymentRequestPersonalPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: CreatePaymentRequestPersonalView?
    internal private(set) var startReceivedInvocations: [CreatePaymentRequestPersonalView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((CreatePaymentRequestPersonalView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: CreatePaymentRequestPersonalView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - moneyValueUpdated

    internal private(set) var moneyValueUpdatedReceivedValue: String?
    internal private(set) var moneyValueUpdatedReceivedInvocations: [String?] = []
    internal private(set) var moneyValueUpdatedCallsCount = 0
    internal var moneyValueUpdatedClosure: ((String?) -> Void)?
    internal var moneyValueUpdatedCalled: Bool {
        moneyValueUpdatedCallsCount > 0
    }

    internal func moneyValueUpdated(_ value: String?) {
        moneyValueUpdatedCallsCount += 1
        moneyValueUpdatedReceivedValue = value
        moneyValueUpdatedReceivedInvocations.append(value)
        moneyValueUpdatedClosure?(value)
    }

    // MARK: - moneyInputCurrencyTapped

    internal private(set) var moneyInputCurrencyTappedCallsCount = 0
    internal var moneyInputCurrencyTappedClosure: (() -> Void)?
    internal var moneyInputCurrencyTappedCalled: Bool {
        moneyInputCurrencyTappedCallsCount > 0
    }

    internal func moneyInputCurrencyTapped() {
        moneyInputCurrencyTappedCallsCount += 1
        moneyInputCurrencyTappedClosure?()
    }

    // MARK: - nudgeSelected

    internal private(set) var nudgeSelectedCallsCount = 0
    internal var nudgeSelectedClosure: (() -> Void)?
    internal var nudgeSelectedCalled: Bool {
        nudgeSelectedCallsCount > 0
    }

    internal func nudgeSelected() {
        nudgeSelectedCallsCount += 1
        nudgeSelectedClosure?()
    }

    // MARK: - nudgeCloseTapped

    internal private(set) var nudgeCloseTappedCallsCount = 0
    internal var nudgeCloseTappedClosure: (() -> Void)?
    internal var nudgeCloseTappedCalled: Bool {
        nudgeCloseTappedCallsCount > 0
    }

    internal func nudgeCloseTapped() {
        nudgeCloseTappedCallsCount += 1
        nudgeCloseTappedClosure?()
    }

    // MARK: - sendRequestTapped

    internal private(set) var sendRequestTappedReceivedNote: String?
    internal private(set) var sendRequestTappedReceivedInvocations: [String] = []
    internal private(set) var sendRequestTappedCallsCount = 0
    internal var sendRequestTappedClosure: ((String) -> Void)?
    internal var sendRequestTappedCalled: Bool {
        sendRequestTappedCallsCount > 0
    }

    internal func sendRequestTapped(note: String) {
        sendRequestTappedCallsCount += 1
        sendRequestTappedReceivedNote = note
        sendRequestTappedReceivedInvocations.append(note)
        sendRequestTappedClosure?(note)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - isValidPersonalMessage

    internal private(set) var isValidPersonalMessageReceivedMessage: String?
    internal private(set) var isValidPersonalMessageReceivedInvocations: [String] = []
    internal var isValidPersonalMessageReturnValue: Bool!
    internal private(set) var isValidPersonalMessageCallsCount = 0
    internal var isValidPersonalMessageClosure: ((String) -> Bool)?
    internal var isValidPersonalMessageCalled: Bool {
        isValidPersonalMessageCallsCount > 0
    }

    internal func isValidPersonalMessage(_ message: String) -> Bool {
        isValidPersonalMessageCallsCount += 1
        isValidPersonalMessageReceivedMessage = message
        isValidPersonalMessageReceivedInvocations.append(message)
        guard let isValidPersonalMessageClosure else {
            return isValidPersonalMessageReturnValue
        }
        return isValidPersonalMessageClosure(message)
    }
}

internal final class CreatePaymentRequestPersonalRoutingDelegateMock: CreatePaymentRequestPersonalRoutingDelegate {
    // MARK: - showCurrencySelector

    internal private(set) var showCurrencySelectorReceivedArguments: (
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: (CurrencyCode) -> Void
    )?
    internal private(set) var showCurrencySelectorReceivedInvocations: [(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: (CurrencyCode) -> Void
    )] = []
    internal private(set) var showCurrencySelectorCallsCount = 0
    internal var showCurrencySelectorClosure: (([CurrencyCode], [CurrencyCode], CurrencyCode?, @escaping (CurrencyCode) -> Void) -> Void)?
    internal var showCurrencySelectorCalled: Bool {
        showCurrencySelectorCallsCount > 0
    }

    internal func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    ) {
        showCurrencySelectorCallsCount += 1
        showCurrencySelectorReceivedArguments = (
            activeCurrencies: activeCurrencies,
            eligibleCurrencies: eligibleCurrencies,
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected
        )
        showCurrencySelectorReceivedInvocations.append((
            activeCurrencies: activeCurrencies,
            eligibleCurrencies: eligibleCurrencies,
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected
        ))
        showCurrencySelectorClosure?(activeCurrencies, eligibleCurrencies, selectedCurrency, onCurrencySelected)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - showConfirmation

    internal private(set) var showConfirmationReceivedPaymentRequest: PaymentRequestV2?
    internal private(set) var showConfirmationReceivedInvocations: [PaymentRequestV2] = []
    internal private(set) var showConfirmationCallsCount = 0
    internal var showConfirmationClosure: ((PaymentRequestV2) -> Void)?
    internal var showConfirmationCalled: Bool {
        showConfirmationCallsCount > 0
    }

    internal func showConfirmation(paymentRequest: PaymentRequestV2) {
        showConfirmationCallsCount += 1
        showConfirmationReceivedPaymentRequest = paymentRequest
        showConfirmationReceivedInvocations.append(paymentRequest)
        showConfirmationClosure?(paymentRequest)
    }

    // MARK: - showRequestFromContactsSuccess

    internal private(set) var showRequestFromContactsSuccessReceivedArguments: (
        contact: RequestMoneyContact,
        paymentRequest: PaymentRequestV2
    )?
    internal private(set) var showRequestFromContactsSuccessReceivedInvocations: [(
        contact: RequestMoneyContact,
        paymentRequest: PaymentRequestV2
    )] = []
    internal private(set) var showRequestFromContactsSuccessCallsCount = 0
    internal var showRequestFromContactsSuccessClosure: ((RequestMoneyContact, PaymentRequestV2) -> Void)?
    internal var showRequestFromContactsSuccessCalled: Bool {
        showRequestFromContactsSuccessCallsCount > 0
    }

    internal func showRequestFromContactsSuccess(contact: RequestMoneyContact, paymentRequest: PaymentRequestV2) {
        showRequestFromContactsSuccessCallsCount += 1
        showRequestFromContactsSuccessReceivedArguments = (contact: contact, paymentRequest: paymentRequest)
        showRequestFromContactsSuccessReceivedInvocations.append((contact: contact, paymentRequest: paymentRequest))
        showRequestFromContactsSuccessClosure?(contact, paymentRequest)
    }

    // MARK: - showPayWithWiseEducation

    internal private(set) var showPayWithWiseEducationCallsCount = 0
    internal var showPayWithWiseEducationClosure: (() -> Void)?
    internal var showPayWithWiseEducationCalled: Bool {
        showPayWithWiseEducationCallsCount > 0
    }

    internal func showPayWithWiseEducation() {
        showPayWithWiseEducationCallsCount += 1
        showPayWithWiseEducationClosure?()
    }

    // MARK: - showAccountDetailsFlow

    internal private(set) var showAccountDetailsFlowReceivedCurrencyCode: CurrencyCode?
    internal private(set) var showAccountDetailsFlowReceivedInvocations: [CurrencyCode] = []
    internal var showAccountDetailsFlowReturnValue: AnyPublisher<Void, Never>!
    internal private(set) var showAccountDetailsFlowCallsCount = 0
    internal var showAccountDetailsFlowClosure: ((CurrencyCode) -> AnyPublisher<Void, Never>)?
    internal var showAccountDetailsFlowCalled: Bool {
        showAccountDetailsFlowCallsCount > 0
    }

    internal func showAccountDetailsFlow(currencyCode: CurrencyCode) -> AnyPublisher<Void, Never> {
        showAccountDetailsFlowCallsCount += 1
        showAccountDetailsFlowReceivedCurrencyCode = currencyCode
        showAccountDetailsFlowReceivedInvocations.append(currencyCode)
        guard let showAccountDetailsFlowClosure else {
            return showAccountDetailsFlowReturnValue
        }
        return showAccountDetailsFlowClosure(currencyCode)
    }

    // MARK: - handleDynamicForms

    internal private(set) var handleDynamicFormsReceivedArguments: (
        forms: [PaymentMethodAvailability.DynamicForm],
        completionHandler: () -> Void
    )?
    internal private(set) var handleDynamicFormsReceivedInvocations: [(
        forms: [PaymentMethodAvailability.DynamicForm],
        completionHandler: () -> Void
    )] = []
    internal private(set) var handleDynamicFormsCallsCount = 0
    internal var handleDynamicFormsClosure: (([PaymentMethodAvailability.DynamicForm], @escaping () -> Void) -> Void)?
    internal var handleDynamicFormsCalled: Bool {
        handleDynamicFormsCallsCount > 0
    }

    internal func handleDynamicForms(forms: [PaymentMethodAvailability.DynamicForm], completionHandler: @escaping () -> Void) {
        handleDynamicFormsCallsCount += 1
        handleDynamicFormsReceivedArguments = (forms: forms, completionHandler: completionHandler)
        handleDynamicFormsReceivedInvocations.append((forms: forms, completionHandler: completionHandler))
        handleDynamicFormsClosure?(forms, completionHandler)
    }
}

internal final class CreatePaymentRequestPersonalViewMock: LoadingPresentableMock, CreatePaymentRequestPersonalView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: CreatePaymentRequestPersonalViewModel?
    internal private(set) var configureReceivedInvocations: [CreatePaymentRequestPersonalViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((CreatePaymentRequestPersonalViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: CreatePaymentRequestPersonalViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedErrorViewModel: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with errorViewModel: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedErrorViewModel = errorViewModel
        configureWithErrorReceivedInvocations.append(errorViewModel)
        configureWithErrorClosure?(errorViewModel)
    }

    // MARK: - configureContact

    internal private(set) var configureContactReceivedViewModel: OptionViewModel?
    internal private(set) var configureContactReceivedInvocations: [OptionViewModel?] = []
    internal private(set) var configureContactCallsCount = 0
    internal var configureContactClosure: ((OptionViewModel?) -> Void)?
    internal var configureContactCalled: Bool {
        configureContactCallsCount > 0
    }

    internal func configureContact(with viewModel: OptionViewModel?) {
        configureContactCallsCount += 1
        configureContactReceivedViewModel = viewModel
        configureContactReceivedInvocations.append(viewModel)
        configureContactClosure?(viewModel)
    }

    // MARK: - updateSelectedCurrency

    internal private(set) var updateSelectedCurrencyReceivedCurrency: CurrencyCode?
    internal private(set) var updateSelectedCurrencyReceivedInvocations: [CurrencyCode] = []
    internal private(set) var updateSelectedCurrencyCallsCount = 0
    internal var updateSelectedCurrencyClosure: ((CurrencyCode) -> Void)?
    internal var updateSelectedCurrencyCalled: Bool {
        updateSelectedCurrencyCallsCount > 0
    }

    internal func updateSelectedCurrency(currency: CurrencyCode) {
        updateSelectedCurrencyCallsCount += 1
        updateSelectedCurrencyReceivedCurrency = currency
        updateSelectedCurrencyReceivedInvocations.append(currency)
        updateSelectedCurrencyClosure?(currency)
    }

    // MARK: - calculatorError

    internal private(set) var calculatorErrorReceivedErrorMsg: String?
    internal private(set) var calculatorErrorReceivedInvocations: [String] = []
    internal private(set) var calculatorErrorCallsCount = 0
    internal var calculatorErrorClosure: ((String) -> Void)?
    internal var calculatorErrorCalled: Bool {
        calculatorErrorCallsCount > 0
    }

    internal func calculatorError(_ errorMsg: String) {
        calculatorErrorCallsCount += 1
        calculatorErrorReceivedErrorMsg = errorMsg
        calculatorErrorReceivedInvocations.append(errorMsg)
        calculatorErrorClosure?(errorMsg)
    }

    // MARK: - showMessageInputError

    internal private(set) var showMessageInputErrorReceivedErrorMessage: String?
    internal private(set) var showMessageInputErrorReceivedInvocations: [String] = []
    internal private(set) var showMessageInputErrorCallsCount = 0
    internal var showMessageInputErrorClosure: ((String) -> Void)?
    internal var showMessageInputErrorCalled: Bool {
        showMessageInputErrorCallsCount > 0
    }

    internal func showMessageInputError(_ errorMessage: String) {
        showMessageInputErrorCallsCount += 1
        showMessageInputErrorReceivedErrorMessage = errorMessage
        showMessageInputErrorReceivedInvocations.append(errorMessage)
        showMessageInputErrorClosure?(errorMessage)
    }

    // MARK: - dismissMessageInputError

    internal private(set) var dismissMessageInputErrorCallsCount = 0
    internal var dismissMessageInputErrorClosure: (() -> Void)?
    internal var dismissMessageInputErrorCalled: Bool {
        dismissMessageInputErrorCallsCount > 0
    }

    internal func dismissMessageInputError() {
        dismissMessageInputErrorCallsCount += 1
        dismissMessageInputErrorClosure?()
    }

    // MARK: - footerButtonState

    internal private(set) var footerButtonStateReceivedEnabled: Bool?
    internal private(set) var footerButtonStateReceivedInvocations: [Bool] = []
    internal private(set) var footerButtonStateCallsCount = 0
    internal var footerButtonStateClosure: ((Bool) -> Void)?
    internal var footerButtonStateCalled: Bool {
        footerButtonStateCallsCount > 0
    }

    internal func footerButtonState(enabled: Bool) {
        footerButtonStateCallsCount += 1
        footerButtonStateReceivedEnabled = enabled
        footerButtonStateReceivedInvocations.append(enabled)
        footerButtonStateClosure?(enabled)
    }

    // MARK: - hideNudge

    internal private(set) var hideNudgeCallsCount = 0
    internal var hideNudgeClosure: (() -> Void)?
    internal var hideNudgeCalled: Bool {
        hideNudgeCallsCount > 0
    }

    internal func hideNudge() {
        hideNudgeCallsCount += 1
        hideNudgeClosure?()
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class CreatePaymentRequestPersonalViewModelMapperMock: CreatePaymentRequestPersonalViewModelMapper {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        contactName: String?,
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        shouldShowNudge: Bool
    )?
    internal private(set) var makeReceivedInvocations: [(
        contactName: String?,
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        shouldShowNudge: Bool
    )] = []
    internal var makeReturnValue: CreatePaymentRequestPersonalViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((String?, CreatePaymentRequestPersonalPresenterInfo, Bool) -> CreatePaymentRequestPersonalViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(contactName: String?, paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo, shouldShowNudge: Bool) -> CreatePaymentRequestPersonalViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (
            contactName: contactName,
            paymentRequestInfo: paymentRequestInfo,
            shouldShowNudge: shouldShowNudge
        )
        makeReceivedInvocations.append((
            contactName: contactName,
            paymentRequestInfo: paymentRequestInfo,
            shouldShowNudge: shouldShowNudge
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(contactName, paymentRequestInfo, shouldShowNudge)
    }
}

internal final class CreatePaymentRequestPresenterMock: CreatePaymentRequestPresenter {
    internal var isReusableLinksEnabled: Bool {
        get { underlyingIsReusableLinksEnabled }
        set(value) { underlyingIsReusableLinksEnabled = value }
    }

    private var underlyingIsReusableLinksEnabled: Bool!

    // MARK: - start

    internal private(set) var startReceivedView: CreatePaymentRequestView?
    internal private(set) var startReceivedInvocations: [CreatePaymentRequestView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((CreatePaymentRequestView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: CreatePaymentRequestView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - togglePaymentLimit

    internal private(set) var togglePaymentLimitCallsCount = 0
    internal var togglePaymentLimitClosure: (() -> Void)?
    internal var togglePaymentLimitCalled: Bool {
        togglePaymentLimitCallsCount > 0
    }

    internal func togglePaymentLimit() {
        togglePaymentLimitCallsCount += 1
        togglePaymentLimitClosure?()
    }

    // MARK: - moneyValueUpdated

    internal private(set) var moneyValueUpdatedReceivedValue: String?
    internal private(set) var moneyValueUpdatedReceivedInvocations: [String?] = []
    internal private(set) var moneyValueUpdatedCallsCount = 0
    internal var moneyValueUpdatedClosure: ((String?) -> Void)?
    internal var moneyValueUpdatedCalled: Bool {
        moneyValueUpdatedCallsCount > 0
    }

    internal func moneyValueUpdated(_ value: String?) {
        moneyValueUpdatedCallsCount += 1
        moneyValueUpdatedReceivedValue = value
        moneyValueUpdatedReceivedInvocations.append(value)
        moneyValueUpdatedClosure?(value)
    }

    // MARK: - moneyInputCurrencyTapped

    internal private(set) var moneyInputCurrencyTappedCallsCount = 0
    internal var moneyInputCurrencyTappedClosure: (() -> Void)?
    internal var moneyInputCurrencyTappedCalled: Bool {
        moneyInputCurrencyTappedCallsCount > 0
    }

    internal func moneyInputCurrencyTapped() {
        moneyInputCurrencyTappedCallsCount += 1
        moneyInputCurrencyTappedClosure?()
    }

    // MARK: - continueTapped

    internal private(set) var continueTappedReceivedInputs: CreatePaymentRequestInputs?
    internal private(set) var continueTappedReceivedInvocations: [CreatePaymentRequestInputs] = []
    internal private(set) var continueTappedCallsCount = 0
    internal var continueTappedClosure: ((CreatePaymentRequestInputs) -> Void)?
    internal var continueTappedCalled: Bool {
        continueTappedCallsCount > 0
    }

    internal func continueTapped(inputs: CreatePaymentRequestInputs) {
        continueTappedCallsCount += 1
        continueTappedReceivedInputs = inputs
        continueTappedReceivedInvocations.append(inputs)
        continueTappedClosure?(inputs)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class CreatePaymentRequestRoutingDelegateMock: CreatePaymentRequestRoutingDelegate {
    // MARK: - showCurrencySelector

    internal private(set) var showCurrencySelectorReceivedArguments: (
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: (CurrencyCode) -> Void
    )?
    internal private(set) var showCurrencySelectorReceivedInvocations: [(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: (CurrencyCode) -> Void
    )] = []
    internal private(set) var showCurrencySelectorCallsCount = 0
    internal var showCurrencySelectorClosure: (([CurrencyCode], [CurrencyCode], CurrencyCode?, @escaping (CurrencyCode) -> Void) -> Void)?
    internal var showCurrencySelectorCalled: Bool {
        showCurrencySelectorCallsCount > 0
    }

    internal func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    ) {
        showCurrencySelectorCallsCount += 1
        showCurrencySelectorReceivedArguments = (
            activeCurrencies: activeCurrencies,
            eligibleCurrencies: eligibleCurrencies,
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected
        )
        showCurrencySelectorReceivedInvocations.append((
            activeCurrencies: activeCurrencies,
            eligibleCurrencies: eligibleCurrencies,
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected
        ))
        showCurrencySelectorClosure?(activeCurrencies, eligibleCurrencies, selectedCurrency, onCurrencySelected)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - showConfirmation

    internal private(set) var showConfirmationReceivedPaymentRequest: PaymentRequestV2?
    internal private(set) var showConfirmationReceivedInvocations: [PaymentRequestV2] = []
    internal private(set) var showConfirmationCallsCount = 0
    internal var showConfirmationClosure: ((PaymentRequestV2) -> Void)?
    internal var showConfirmationCalled: Bool {
        showConfirmationCallsCount > 0
    }

    internal func showConfirmation(paymentRequest: PaymentRequestV2) {
        showConfirmationCallsCount += 1
        showConfirmationReceivedPaymentRequest = paymentRequest
        showConfirmationReceivedInvocations.append(paymentRequest)
        showConfirmationClosure?(paymentRequest)
    }

    // MARK: - showPayWithWiseEducation

    internal private(set) var showPayWithWiseEducationCallsCount = 0
    internal var showPayWithWiseEducationClosure: (() -> Void)?
    internal var showPayWithWiseEducationCalled: Bool {
        showPayWithWiseEducationCallsCount > 0
    }

    internal func showPayWithWiseEducation() {
        showPayWithWiseEducationCallsCount += 1
        showPayWithWiseEducationClosure?()
    }

    // MARK: - showPaymentMethodsSheet

    internal private(set) var showPaymentMethodsSheetReceivedArguments: (
        delegate: PaymentMethodsDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        methods: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        completion: ([PaymentRequestV2PaymentMethods]) -> Void
    )?
    internal private(set) var showPaymentMethodsSheetReceivedInvocations: [(
        delegate: PaymentMethodsDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        methods: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        completion: ([PaymentRequestV2PaymentMethods]) -> Void
    )] = []
    internal private(set) var showPaymentMethodsSheetCallsCount = 0
    internal var showPaymentMethodsSheetClosure: ((
        PaymentMethodsDelegate,
        [PaymentRequestV2PaymentMethods],
        PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        @escaping ([PaymentRequestV2PaymentMethods]) -> Void
    ) -> Void)?
    internal var showPaymentMethodsSheetCalled: Bool {
        showPaymentMethodsSheetCallsCount > 0
    }

    internal func showPaymentMethodsSheet(
        delegate: PaymentMethodsDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        methods: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        completion: @escaping ([PaymentRequestV2PaymentMethods]) -> Void
    ) {
        showPaymentMethodsSheetCallsCount += 1
        showPaymentMethodsSheetReceivedArguments = (
            delegate: delegate,
            localPreferences: localPreferences,
            methods: methods,
            completion: completion
        )
        showPaymentMethodsSheetReceivedInvocations.append((
            delegate: delegate,
            localPreferences: localPreferences,
            methods: methods,
            completion: completion
        ))
        showPaymentMethodsSheetClosure?(delegate, localPreferences, methods, completion)
    }

    // MARK: - showAccountDetailsFlow

    internal private(set) var showAccountDetailsFlowReceivedCurrencyCode: CurrencyCode?
    internal private(set) var showAccountDetailsFlowReceivedInvocations: [CurrencyCode] = []
    internal var showAccountDetailsFlowReturnValue: AnyPublisher<Void, Never>!
    internal private(set) var showAccountDetailsFlowCallsCount = 0
    internal var showAccountDetailsFlowClosure: ((CurrencyCode) -> AnyPublisher<Void, Never>)?
    internal var showAccountDetailsFlowCalled: Bool {
        showAccountDetailsFlowCallsCount > 0
    }

    internal func showAccountDetailsFlow(currencyCode: CurrencyCode) -> AnyPublisher<Void, Never> {
        showAccountDetailsFlowCallsCount += 1
        showAccountDetailsFlowReceivedCurrencyCode = currencyCode
        showAccountDetailsFlowReceivedInvocations.append(currencyCode)
        guard let showAccountDetailsFlowClosure else {
            return showAccountDetailsFlowReturnValue
        }
        return showAccountDetailsFlowClosure(currencyCode)
    }

    // MARK: - showDynamicFormsMethodManagement

    internal private(set) var showDynamicFormsMethodManagementReceivedArguments: (
        dynamicForms: [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm],
        delegate: PaymentMethodsDelegate?
    )?
    internal private(set) var showDynamicFormsMethodManagementReceivedInvocations: [(
        dynamicForms: [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm],
        delegate: PaymentMethodsDelegate?
    )] = []
    internal private(set) var showDynamicFormsMethodManagementCallsCount = 0
    internal var showDynamicFormsMethodManagementClosure: ((
        [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm],
        PaymentMethodsDelegate?
    ) -> Void)?
    internal var showDynamicFormsMethodManagementCalled: Bool {
        showDynamicFormsMethodManagementCallsCount > 0
    }

    internal func showDynamicFormsMethodManagement(
        _ dynamicForms: [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm],
        delegate: PaymentMethodsDelegate?
    ) {
        showDynamicFormsMethodManagementCallsCount += 1
        showDynamicFormsMethodManagementReceivedArguments = (dynamicForms: dynamicForms, delegate: delegate)
        showDynamicFormsMethodManagementReceivedInvocations.append((dynamicForms: dynamicForms, delegate: delegate))
        showDynamicFormsMethodManagementClosure?(dynamicForms, delegate)
    }

    // MARK: - showPaymentMethodManagementOnWeb

    internal private(set) var showPaymentMethodManagementOnWebReceivedDelegate: PaymentMethodsDelegate?
    internal private(set) var showPaymentMethodManagementOnWebReceivedInvocations: [PaymentMethodsDelegate?] = []
    internal private(set) var showPaymentMethodManagementOnWebCallsCount = 0
    internal var showPaymentMethodManagementOnWebClosure: ((PaymentMethodsDelegate?) -> Void)?
    internal var showPaymentMethodManagementOnWebCalled: Bool {
        showPaymentMethodManagementOnWebCallsCount > 0
    }

    internal func showPaymentMethodManagementOnWeb(delegate: PaymentMethodsDelegate?) {
        showPaymentMethodManagementOnWebCallsCount += 1
        showPaymentMethodManagementOnWebReceivedDelegate = delegate
        showPaymentMethodManagementOnWebReceivedInvocations.append(delegate)
        showPaymentMethodManagementOnWebClosure?(delegate)
    }
}

internal final class CreatePaymentRequestViewMock: CreatePaymentRequestView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: CreatePaymentRequestViewModel?
    internal private(set) var configureReceivedInvocations: [CreatePaymentRequestViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((CreatePaymentRequestViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: CreatePaymentRequestViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - updateSelectedCurrency

    internal private(set) var updateSelectedCurrencyReceivedCurrency: CurrencyCode?
    internal private(set) var updateSelectedCurrencyReceivedInvocations: [CurrencyCode] = []
    internal private(set) var updateSelectedCurrencyCallsCount = 0
    internal var updateSelectedCurrencyClosure: ((CurrencyCode) -> Void)?
    internal var updateSelectedCurrencyCalled: Bool {
        updateSelectedCurrencyCallsCount > 0
    }

    internal func updateSelectedCurrency(currency: CurrencyCode) {
        updateSelectedCurrencyCallsCount += 1
        updateSelectedCurrencyReceivedCurrency = currency
        updateSelectedCurrencyReceivedInvocations.append(currency)
        updateSelectedCurrencyClosure?(currency)
    }

    // MARK: - calculatorError

    internal private(set) var calculatorErrorReceivedErrorMsg: String?
    internal private(set) var calculatorErrorReceivedInvocations: [String] = []
    internal private(set) var calculatorErrorCallsCount = 0
    internal var calculatorErrorClosure: ((String) -> Void)?
    internal var calculatorErrorCalled: Bool {
        calculatorErrorCallsCount > 0
    }

    internal func calculatorError(_ errorMsg: String) {
        calculatorErrorCallsCount += 1
        calculatorErrorReceivedErrorMsg = errorMsg
        calculatorErrorReceivedInvocations.append(errorMsg)
        calculatorErrorClosure?(errorMsg)
    }

    // MARK: - footerButtonState

    internal private(set) var footerButtonStateReceivedEnabled: Bool?
    internal private(set) var footerButtonStateReceivedInvocations: [Bool] = []
    internal private(set) var footerButtonStateCallsCount = 0
    internal var footerButtonStateClosure: ((Bool) -> Void)?
    internal var footerButtonStateCalled: Bool {
        footerButtonStateCallsCount > 0
    }

    internal func footerButtonState(enabled: Bool) {
        footerButtonStateCallsCount += 1
        footerButtonStateReceivedEnabled = enabled
        footerButtonStateReceivedInvocations.append(enabled)
        footerButtonStateClosure?(enabled)
    }

    // MARK: - updatePaymentMethodOption

    internal private(set) var updatePaymentMethodOptionReceivedOption: CreatePaymentRequestViewModel.PaymentMethodsOption?
    internal private(set) var updatePaymentMethodOptionReceivedInvocations: [CreatePaymentRequestViewModel.PaymentMethodsOption] = []
    internal private(set) var updatePaymentMethodOptionCallsCount = 0
    internal var updatePaymentMethodOptionClosure: ((CreatePaymentRequestViewModel.PaymentMethodsOption) -> Void)?
    internal var updatePaymentMethodOptionCalled: Bool {
        updatePaymentMethodOptionCallsCount > 0
    }

    internal func updatePaymentMethodOption(option: CreatePaymentRequestViewModel.PaymentMethodsOption) {
        updatePaymentMethodOptionCallsCount += 1
        updatePaymentMethodOptionReceivedOption = option
        updatePaymentMethodOptionReceivedInvocations.append(option)
        updatePaymentMethodOptionClosure?(option)
    }

    // MARK: - updateNudge

    internal private(set) var updateNudgeReceivedNudge: NudgeViewModel?
    internal private(set) var updateNudgeReceivedInvocations: [NudgeViewModel?] = []
    internal private(set) var updateNudgeCallsCount = 0
    internal var updateNudgeClosure: ((NudgeViewModel?) -> Void)?
    internal var updateNudgeCalled: Bool {
        updateNudgeCallsCount > 0
    }

    internal func updateNudge(_ nudge: NudgeViewModel?) {
        updateNudgeCallsCount += 1
        updateNudgeReceivedNudge = nudge
        updateNudgeReceivedInvocations.append(nudge)
        updateNudgeClosure?(nudge)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedErrorViewModel: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with errorViewModel: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedErrorViewModel = errorViewModel
        configureWithErrorReceivedInvocations.append(errorViewModel)
        configureWithErrorClosure?(errorViewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class CreatePaymentRequestViewControllerFactoryMock: CreatePaymentRequestViewControllerFactory {
    // MARK: - makeCreatePaymentRequestFromContactSuccess

    internal private(set) var makeCreatePaymentRequestFromContactSuccessReceivedViewModel: CreatePaymentRequestFromContactSuccessViewModel?
    internal private(set) var makeCreatePaymentRequestFromContactSuccessReceivedInvocations: [CreatePaymentRequestFromContactSuccessViewModel] = []
    internal var makeCreatePaymentRequestFromContactSuccessReturnValue: UIViewController!
    internal private(set) var makeCreatePaymentRequestFromContactSuccessCallsCount = 0
    internal var makeCreatePaymentRequestFromContactSuccessClosure: ((CreatePaymentRequestFromContactSuccessViewModel) -> UIViewController)?
    internal var makeCreatePaymentRequestFromContactSuccessCalled: Bool {
        makeCreatePaymentRequestFromContactSuccessCallsCount > 0
    }

    internal func makeCreatePaymentRequestFromContactSuccess(with viewModel: CreatePaymentRequestFromContactSuccessViewModel) -> UIViewController {
        makeCreatePaymentRequestFromContactSuccessCallsCount += 1
        makeCreatePaymentRequestFromContactSuccessReceivedViewModel = viewModel
        makeCreatePaymentRequestFromContactSuccessReceivedInvocations.append(viewModel)
        guard let makeCreatePaymentRequestFromContactSuccessClosure else {
            return makeCreatePaymentRequestFromContactSuccessReturnValue
        }
        return makeCreatePaymentRequestFromContactSuccessClosure(viewModel)
    }

    // MARK: - makeContactPicker

    internal private(set) var makeContactPickerReceivedArguments: (
        profile: Profile,
        router: RequestMoneyContactPickerRouter,
        navigationController: UINavigationController
    )?
    internal private(set) var makeContactPickerReceivedInvocations: [(
        profile: Profile,
        router: RequestMoneyContactPickerRouter,
        navigationController: UINavigationController
    )] = []
    internal var makeContactPickerReturnValue: UIViewController!
    internal private(set) var makeContactPickerCallsCount = 0
    internal var makeContactPickerClosure: ((Profile, RequestMoneyContactPickerRouter, UINavigationController) -> UIViewController)?
    internal var makeContactPickerCalled: Bool {
        makeContactPickerCallsCount > 0
    }

    internal func makeContactPicker(
        profile: Profile,
        router: RequestMoneyContactPickerRouter,
        navigationController: UINavigationController
    ) -> UIViewController {
        makeContactPickerCallsCount += 1
        makeContactPickerReceivedArguments = (profile: profile, router: router, navigationController: navigationController)
        makeContactPickerReceivedInvocations.append((profile: profile, router: router, navigationController: navigationController))
        guard let makeContactPickerClosure else {
            return makeContactPickerReturnValue
        }
        return makeContactPickerClosure(profile, router, navigationController)
    }

    // MARK: - makeOnboardingViewController

    internal private(set) var makeOnboardingViewControllerReceivedArguments: (
        profile: Profile,
        routingDelegate: PaymentRequestOnboardingRoutingDelegate
    )?
    internal private(set) var makeOnboardingViewControllerReceivedInvocations: [(
        profile: Profile,
        routingDelegate: PaymentRequestOnboardingRoutingDelegate
    )] = []
    internal var makeOnboardingViewControllerReturnValue: UIViewController!
    internal private(set) var makeOnboardingViewControllerCallsCount = 0
    internal var makeOnboardingViewControllerClosure: ((Profile, PaymentRequestOnboardingRoutingDelegate) -> UIViewController)?
    internal var makeOnboardingViewControllerCalled: Bool {
        makeOnboardingViewControllerCallsCount > 0
    }

    internal func makeOnboardingViewController(profile: Profile, routingDelegate: PaymentRequestOnboardingRoutingDelegate) -> UIViewController {
        makeOnboardingViewControllerCallsCount += 1
        makeOnboardingViewControllerReceivedArguments = (profile: profile, routingDelegate: routingDelegate)
        makeOnboardingViewControllerReceivedInvocations.append((profile: profile, routingDelegate: routingDelegate))
        guard let makeOnboardingViewControllerClosure else {
            return makeOnboardingViewControllerReturnValue
        }
        return makeOnboardingViewControllerClosure(profile, routingDelegate)
    }

    // MARK: - makeCreatePaymentRequestBusiness

    internal private(set) var makeCreatePaymentRequestBusinessReceivedArguments: (
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestRoutingDelegate
    )?
    internal private(set) var makeCreatePaymentRequestBusinessReceivedInvocations: [(
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestRoutingDelegate
    )] = []
    internal var makeCreatePaymentRequestBusinessReturnValue: UIViewController!
    internal private(set) var makeCreatePaymentRequestBusinessCallsCount = 0
    internal var makeCreatePaymentRequestBusinessClosure: ((
        CreatePaymentRequestPresenterInfo,
        Profile,
        CreatePaymentRequestRoutingDelegate
    ) -> UIViewController)?
    internal var makeCreatePaymentRequestBusinessCalled: Bool {
        makeCreatePaymentRequestBusinessCallsCount > 0
    }

    internal func makeCreatePaymentRequestBusiness(
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestRoutingDelegate
    ) -> UIViewController {
        makeCreatePaymentRequestBusinessCallsCount += 1
        makeCreatePaymentRequestBusinessReceivedArguments = (
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: routingDelegate
        )
        makeCreatePaymentRequestBusinessReceivedInvocations.append((
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: routingDelegate
        ))
        guard let makeCreatePaymentRequestBusinessClosure else {
            return makeCreatePaymentRequestBusinessReturnValue
        }
        return makeCreatePaymentRequestBusinessClosure(paymentRequestInfo, profile, routingDelegate)
    }

    // MARK: - makeCreatePaymentRequestPersonal

    internal private(set) var makeCreatePaymentRequestPersonalReceivedArguments: (
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    )?
    internal private(set) var makeCreatePaymentRequestPersonalReceivedInvocations: [(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    )] = []
    internal var makeCreatePaymentRequestPersonalReturnValue: UIViewController!
    internal private(set) var makeCreatePaymentRequestPersonalCallsCount = 0
    internal var makeCreatePaymentRequestPersonalClosure: ((
        CreatePaymentRequestPersonalPresenterInfo,
        Profile,
        CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController)?
    internal var makeCreatePaymentRequestPersonalCalled: Bool {
        makeCreatePaymentRequestPersonalCallsCount > 0
    }

    internal func makeCreatePaymentRequestPersonal(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController {
        makeCreatePaymentRequestPersonalCallsCount += 1
        makeCreatePaymentRequestPersonalReceivedArguments = (
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: routingDelegate
        )
        makeCreatePaymentRequestPersonalReceivedInvocations.append((
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: routingDelegate
        ))
        guard let makeCreatePaymentRequestPersonalClosure else {
            return makeCreatePaymentRequestPersonalReturnValue
        }
        return makeCreatePaymentRequestPersonalClosure(paymentRequestInfo, profile, routingDelegate)
    }

    // MARK: - makeCreatePaymentRequestPersonalBottomSheet

    internal private(set) var makeCreatePaymentRequestPersonalBottomSheetReceivedArguments: (
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    )?
    internal private(set) var makeCreatePaymentRequestPersonalBottomSheetReceivedInvocations: [(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    )] = []
    internal var makeCreatePaymentRequestPersonalBottomSheetReturnValue: UIViewController!
    internal private(set) var makeCreatePaymentRequestPersonalBottomSheetCallsCount = 0
    internal var makeCreatePaymentRequestPersonalBottomSheetClosure: ((
        CreatePaymentRequestPersonalPresenterInfo,
        Profile,
        CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController)?
    internal var makeCreatePaymentRequestPersonalBottomSheetCalled: Bool {
        makeCreatePaymentRequestPersonalBottomSheetCallsCount > 0
    }

    internal func makeCreatePaymentRequestPersonalBottomSheet(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController {
        makeCreatePaymentRequestPersonalBottomSheetCallsCount += 1
        makeCreatePaymentRequestPersonalBottomSheetReceivedArguments = (
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: routingDelegate
        )
        makeCreatePaymentRequestPersonalBottomSheetReceivedInvocations.append((
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: routingDelegate
        ))
        guard let makeCreatePaymentRequestPersonalBottomSheetClosure else {
            return makeCreatePaymentRequestPersonalBottomSheetReturnValue
        }
        return makeCreatePaymentRequestPersonalBottomSheetClosure(paymentRequestInfo, profile, routingDelegate)
    }

    // MARK: - makeRequestFromAnyoneViewController

    internal private(set) var makeRequestFromAnyoneViewControllerReceivedArguments: (
        profile: Profile,
        routingDelegate: RequestFromAnyoneRoutingDelegate
    )?
    internal private(set) var makeRequestFromAnyoneViewControllerReceivedInvocations: [(
        profile: Profile,
        routingDelegate: RequestFromAnyoneRoutingDelegate
    )] = []
    internal var makeRequestFromAnyoneViewControllerReturnValue: UIViewController!
    internal private(set) var makeRequestFromAnyoneViewControllerCallsCount = 0
    internal var makeRequestFromAnyoneViewControllerClosure: ((Profile, RequestFromAnyoneRoutingDelegate) -> UIViewController)?
    internal var makeRequestFromAnyoneViewControllerCalled: Bool {
        makeRequestFromAnyoneViewControllerCallsCount > 0
    }

    internal func makeRequestFromAnyoneViewController(profile: Profile, routingDelegate: RequestFromAnyoneRoutingDelegate) -> UIViewController {
        makeRequestFromAnyoneViewControllerCallsCount += 1
        makeRequestFromAnyoneViewControllerReceivedArguments = (profile: profile, routingDelegate: routingDelegate)
        makeRequestFromAnyoneViewControllerReceivedInvocations.append((profile: profile, routingDelegate: routingDelegate))
        guard let makeRequestFromAnyoneViewControllerClosure else {
            return makeRequestFromAnyoneViewControllerReturnValue
        }
        return makeRequestFromAnyoneViewControllerClosure(profile, routingDelegate)
    }

    // MARK: - makeConfirmation

    internal private(set) var makeConfirmationReceivedArguments: (
        paymentRequest: PaymentRequestV2,
        profile: Profile,
        onSuccess: (CreatePaymentRequestFlowResult) -> Void
    )?
    internal private(set) var makeConfirmationReceivedInvocations: [(
        paymentRequest: PaymentRequestV2,
        profile: Profile,
        onSuccess: (CreatePaymentRequestFlowResult) -> Void
    )] = []
    internal var makeConfirmationReturnValue: UIViewController!
    internal private(set) var makeConfirmationCallsCount = 0
    internal var makeConfirmationClosure: ((PaymentRequestV2, Profile, @escaping (CreatePaymentRequestFlowResult) -> Void) -> UIViewController)?
    internal var makeConfirmationCalled: Bool {
        makeConfirmationCallsCount > 0
    }

    internal func makeConfirmation(
        paymentRequest: PaymentRequestV2,
        profile: Profile,
        onSuccess: @escaping (CreatePaymentRequestFlowResult) -> Void
    ) -> UIViewController {
        makeConfirmationCallsCount += 1
        makeConfirmationReceivedArguments = (paymentRequest: paymentRequest, profile: profile, onSuccess: onSuccess)
        makeConfirmationReceivedInvocations.append((paymentRequest: paymentRequest, profile: profile, onSuccess: onSuccess))
        guard let makeConfirmationClosure else {
            return makeConfirmationReturnValue
        }
        return makeConfirmationClosure(paymentRequest, profile, onSuccess)
    }

    // MARK: - makeCardTerms

    internal private(set) var makeCardTermsReceivedUrl: URL?
    internal private(set) var makeCardTermsReceivedInvocations: [URL] = []
    internal var makeCardTermsReturnValue: UIViewController!
    internal private(set) var makeCardTermsCallsCount = 0
    internal var makeCardTermsClosure: ((URL) -> UIViewController)?
    internal var makeCardTermsCalled: Bool {
        makeCardTermsCallsCount > 0
    }

    internal func makeCardTerms(url: URL) -> UIViewController {
        makeCardTermsCallsCount += 1
        makeCardTermsReceivedUrl = url
        makeCardTermsReceivedInvocations.append(url)
        guard let makeCardTermsClosure else {
            return makeCardTermsReturnValue
        }
        return makeCardTermsClosure(url)
    }

    // MARK: - makePaymentMethodsSelection

    internal private(set) var makePaymentMethodsSelectionReceivedArguments: (
        delegate: PaymentMethodsDelegate,
        routingDelegate: CreatePaymentRequestRoutingDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        onPaymentMethodsSelected: ([PaymentRequestV2PaymentMethods]) -> Void
    )?
    internal private(set) var makePaymentMethodsSelectionReceivedInvocations: [(
        delegate: PaymentMethodsDelegate,
        routingDelegate: CreatePaymentRequestRoutingDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        onPaymentMethodsSelected: ([PaymentRequestV2PaymentMethods]) -> Void
    )] = []
    internal var makePaymentMethodsSelectionReturnValue: UIViewController!
    internal private(set) var makePaymentMethodsSelectionCallsCount = 0
    internal var makePaymentMethodsSelectionClosure: ((
        PaymentMethodsDelegate,
        CreatePaymentRequestRoutingDelegate,
        [PaymentRequestV2PaymentMethods],
        PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        @escaping ([PaymentRequestV2PaymentMethods]) -> Void
    ) -> UIViewController)?
    internal var makePaymentMethodsSelectionCalled: Bool {
        makePaymentMethodsSelectionCallsCount > 0
    }

    internal func makePaymentMethodsSelection(
        delegate: PaymentMethodsDelegate,
        routingDelegate: CreatePaymentRequestRoutingDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        onPaymentMethodsSelected: @escaping ([PaymentRequestV2PaymentMethods]) -> Void
    ) -> UIViewController {
        makePaymentMethodsSelectionCallsCount += 1
        makePaymentMethodsSelectionReceivedArguments = (
            delegate: delegate,
            routingDelegate: routingDelegate,
            localPreferences: localPreferences,
            paymentMethodsAvailability: paymentMethodsAvailability,
            onPaymentMethodsSelected: onPaymentMethodsSelected
        )
        makePaymentMethodsSelectionReceivedInvocations.append((
            delegate: delegate,
            routingDelegate: routingDelegate,
            localPreferences: localPreferences,
            paymentMethodsAvailability: paymentMethodsAvailability,
            onPaymentMethodsSelected: onPaymentMethodsSelected
        ))
        guard let makePaymentMethodsSelectionClosure else {
            return makePaymentMethodsSelectionReturnValue
        }
        return makePaymentMethodsSelectionClosure(
            delegate,
            routingDelegate,
            localPreferences,
            paymentMethodsAvailability,
            onPaymentMethodsSelected
        )
    }
}

internal final class CreatePaymentRequestViewModelMapperMock: CreatePaymentRequestViewModelMapper {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        shouldShowPaymentLimitsCheckbox: Bool,
        isLimitPaymentsSelected: Bool,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        paymentMethodsOption: CreatePaymentRequestViewModel.PaymentMethodsOption,
        nudge: NudgeViewModel?
    )?
    internal private(set) var makeReceivedInvocations: [(
        shouldShowPaymentLimitsCheckbox: Bool,
        isLimitPaymentsSelected: Bool,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        paymentMethodsOption: CreatePaymentRequestViewModel.PaymentMethodsOption,
        nudge: NudgeViewModel?
    )] = []
    internal var makeReturnValue: CreatePaymentRequestViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((
        Bool,
        Bool,
        CreatePaymentRequestPresenterInfo,
        CreatePaymentRequestViewModel.PaymentMethodsOption,
        NudgeViewModel?
    ) -> CreatePaymentRequestViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        shouldShowPaymentLimitsCheckbox: Bool,
        isLimitPaymentsSelected: Bool,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        paymentMethodsOption: CreatePaymentRequestViewModel.PaymentMethodsOption,
        nudge: NudgeViewModel?
    ) -> CreatePaymentRequestViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (
            shouldShowPaymentLimitsCheckbox: shouldShowPaymentLimitsCheckbox,
            isLimitPaymentsSelected: isLimitPaymentsSelected,
            paymentRequestInfo: paymentRequestInfo,
            paymentMethodsOption: paymentMethodsOption,
            nudge: nudge
        )
        makeReceivedInvocations.append((
            shouldShowPaymentLimitsCheckbox: shouldShowPaymentLimitsCheckbox,
            isLimitPaymentsSelected: isLimitPaymentsSelected,
            paymentRequestInfo: paymentRequestInfo,
            paymentMethodsOption: paymentMethodsOption,
            nudge: nudge
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(
            shouldShowPaymentLimitsCheckbox,
            isLimitPaymentsSelected,
            paymentRequestInfo,
            paymentMethodsOption,
            nudge
        )
    }
}

internal final class FindFriendsActionDelegateMock: FindFriendsActionDelegate {
    // MARK: - enableContactSync

    internal private(set) var enableContactSyncCallsCount = 0
    internal var enableContactSyncClosure: (() -> Void)?
    internal var enableContactSyncCalled: Bool {
        enableContactSyncCallsCount > 0
    }

    internal func enableContactSync() {
        enableContactSyncCallsCount += 1
        enableContactSyncClosure?()
    }

    // MARK: - learnMoreButtonTapped

    internal private(set) var learnMoreButtonTappedCallsCount = 0
    internal var learnMoreButtonTappedClosure: (() -> Void)?
    internal var learnMoreButtonTappedCalled: Bool {
        learnMoreButtonTappedCallsCount > 0
    }

    internal func learnMoreButtonTapped() {
        learnMoreButtonTappedCallsCount += 1
        learnMoreButtonTappedClosure?()
    }
}

internal final class FindFriendsFlowFactoryMock: FindFriendsFlowFactory {
    // MARK: - makeFlow

    internal private(set) var makeFlowReceivedNavigationController: UINavigationController?
    internal private(set) var makeFlowReceivedInvocations: [UINavigationController] = []
    internal var makeFlowReturnValue: (any Flow<Void>)!
    internal private(set) var makeFlowCallsCount = 0
    internal var makeFlowClosure: ((UINavigationController) -> any Flow<Void>)?
    internal var makeFlowCalled: Bool {
        makeFlowCallsCount > 0
    }

    internal func makeFlow(navigationController: UINavigationController) -> any Flow<Void> {
        makeFlowCallsCount += 1
        makeFlowReceivedNavigationController = navigationController
        makeFlowReceivedInvocations.append(navigationController)
        guard let makeFlowClosure else {
            return makeFlowReturnValue
        }
        return makeFlowClosure(navigationController)
    }
}

internal final class GetPaidOptionsRoutingDelegateMock: GetPaidOptionsRoutingDelegate {
    // MARK: - didSelectGetPaidOption

    internal private(set) var didSelectGetPaidOptionReceivedOption: GetPaidOption?
    internal private(set) var didSelectGetPaidOptionReceivedInvocations: [GetPaidOption] = []
    internal private(set) var didSelectGetPaidOptionCallsCount = 0
    internal var didSelectGetPaidOptionClosure: ((GetPaidOption) -> Void)?
    internal var didSelectGetPaidOptionCalled: Bool {
        didSelectGetPaidOptionCallsCount > 0
    }

    internal func didSelectGetPaidOption(_ option: GetPaidOption) {
        didSelectGetPaidOptionCallsCount += 1
        didSelectGetPaidOptionReceivedOption = option
        didSelectGetPaidOptionReceivedInvocations.append(option)
        didSelectGetPaidOptionClosure?(option)
    }
}

internal final class LoadAccountDetailsEligibilityFactoryMock: LoadAccountDetailsEligibilityFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (router: LoadAccountDetailsEligibilityRouter, profile: Profile)?
    internal private(set) var makeReceivedInvocations: [(router: LoadAccountDetailsEligibilityRouter, profile: Profile)] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((LoadAccountDetailsEligibilityRouter, Profile) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(router: LoadAccountDetailsEligibilityRouter, profile: Profile) -> UIViewController {
        makeCallsCount += 1
        makeReceivedArguments = (router: router, profile: profile)
        makeReceivedInvocations.append((router: router, profile: profile))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(router, profile)
    }
}

internal final class LoadAccountDetailsEligibilityInteractorMock: LoadAccountDetailsEligibilityInteractor {
    // MARK: - eligibility

    internal private(set) var eligibilityReceivedProfile: Profile?
    internal private(set) var eligibilityReceivedInvocations: [Profile] = []
    internal var eligibilityReturnValue: AnyPublisher<MultipleAccountDetailsEligibility, Error>!
    internal private(set) var eligibilityCallsCount = 0
    internal var eligibilityClosure: ((Profile) -> AnyPublisher<MultipleAccountDetailsEligibility, Error>)?
    internal var eligibilityCalled: Bool {
        eligibilityCallsCount > 0
    }

    internal func eligibility(for profile: Profile) -> AnyPublisher<MultipleAccountDetailsEligibility, Error> {
        eligibilityCallsCount += 1
        eligibilityReceivedProfile = profile
        eligibilityReceivedInvocations.append(profile)
        guard let eligibilityClosure else {
            return eligibilityReturnValue
        }
        return eligibilityClosure(profile)
    }
}

internal final class LoadAccountDetailsStatusFactoryMock: LoadAccountDetailsStatusFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (router: LoadAccountDetailsStatusRouter, profile: Profile)?
    internal private(set) var makeReceivedInvocations: [(router: LoadAccountDetailsStatusRouter, profile: Profile)] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((LoadAccountDetailsStatusRouter, Profile) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(router: LoadAccountDetailsStatusRouter, profile: Profile) -> UIViewController {
        makeCallsCount += 1
        makeReceivedArguments = (router: router, profile: profile)
        makeReceivedInvocations.append((router: router, profile: profile))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(router, profile)
    }
}

internal final class LoadAccountDetailsStatusInteractorMock: LoadAccountDetailsStatusInteractor {
    internal var accountDetails: AnyPublisher<[AccountDetails], Error> {
        get { underlyingAccountDetails }
        set(value) { underlyingAccountDetails = value }
    }

    private var underlyingAccountDetails: AnyPublisher<[AccountDetails], Error>!
}

internal final class ManagePaymentRequestViewControllerFactoryMock: ManagePaymentRequestViewControllerFactory {
    // MARK: - makePaymentRquestList

    internal private(set) var makePaymentRquestListReceivedArguments: (
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State,
        profile: Profile,
        navigationController: UINavigationController,
        flowDismissed: () -> Void
    )?
    internal private(set) var makePaymentRquestListReceivedInvocations: [(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State,
        profile: Profile,
        navigationController: UINavigationController,
        flowDismissed: () -> Void
    )] = []
    internal var makePaymentRquestListReturnValue: UIViewController!
    internal private(set) var makePaymentRquestListCallsCount = 0
    internal var makePaymentRquestListClosure: ((
        SupportedPaymentRequestType,
        PaymentRequestSummaryList.State,
        Profile,
        UINavigationController,
        @escaping () -> Void
    ) -> UIViewController)?
    internal var makePaymentRquestListCalled: Bool {
        makePaymentRquestListCallsCount > 0
    }

    internal func makePaymentRquestList(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State,
        profile: Profile,
        navigationController: UINavigationController,
        flowDismissed: @escaping () -> Void
    ) -> UIViewController {
        makePaymentRquestListCallsCount += 1
        makePaymentRquestListReceivedArguments = (
            supportedPaymentRequestType: supportedPaymentRequestType,
            visibleState: visibleState,
            profile: profile,
            navigationController: navigationController,
            flowDismissed: flowDismissed
        )
        makePaymentRquestListReceivedInvocations.append((
            supportedPaymentRequestType: supportedPaymentRequestType,
            visibleState: visibleState,
            profile: profile,
            navigationController: navigationController,
            flowDismissed: flowDismissed
        ))
        guard let makePaymentRquestListClosure else {
            return makePaymentRquestListReturnValue
        }
        return makePaymentRquestListClosure(
            supportedPaymentRequestType,
            visibleState,
            profile,
            navigationController,
            flowDismissed
        )
    }
}

internal final class PayWithWiseAnalyticsTrackerMock: PayWithWiseAnalyticsTracker {
    // MARK: - trackEvent

    internal private(set) var trackEventReceivedEvent: PayWithWiseAnalyticsEvent?
    internal private(set) var trackEventReceivedInvocations: [PayWithWiseAnalyticsEvent] = []
    internal private(set) var trackEventCallsCount = 0
    internal var trackEventClosure: ((PayWithWiseAnalyticsEvent) -> Void)?
    internal var trackEventCalled: Bool {
        trackEventCallsCount > 0
    }

    internal func trackEvent(_ event: PayWithWiseAnalyticsEvent) {
        trackEventCallsCount += 1
        trackEventReceivedEvent = event
        trackEventReceivedInvocations.append(event)
        trackEventClosure?(event)
    }

    // MARK: - trackPayerScreenEvent

    internal private(set) var trackPayerScreenEventReceivedEvent: PayerScreenAnalyticsEvent?
    internal private(set) var trackPayerScreenEventReceivedInvocations: [PayerScreenAnalyticsEvent] = []
    internal private(set) var trackPayerScreenEventCallsCount = 0
    internal var trackPayerScreenEventClosure: ((PayerScreenAnalyticsEvent) -> Void)?
    internal var trackPayerScreenEventCalled: Bool {
        trackPayerScreenEventCallsCount > 0
    }

    internal func trackPayerScreenEvent(_ event: PayerScreenAnalyticsEvent) {
        trackPayerScreenEventCallsCount += 1
        trackPayerScreenEventReceivedEvent = event
        trackPayerScreenEventReceivedInvocations.append(event)
        trackPayerScreenEventClosure?(event)
    }
}

internal final class PayWithWiseFlowNavigationDelegateMock: PayWithWiseFlowNavigationDelegate {
    // MARK: - startRequestMoneyFlow

    internal private(set) var startRequestMoneyFlowReceivedProfile: Profile?
    internal private(set) var startRequestMoneyFlowReceivedInvocations: [Profile] = []
    internal private(set) var startRequestMoneyFlowCallsCount = 0
    internal var startRequestMoneyFlowClosure: ((Profile) -> Void)?
    internal var startRequestMoneyFlowCalled: Bool {
        startRequestMoneyFlowCallsCount > 0
    }

    internal func startRequestMoneyFlow(profile: Profile) {
        startRequestMoneyFlowCallsCount += 1
        startRequestMoneyFlowReceivedProfile = profile
        startRequestMoneyFlowReceivedInvocations.append(profile)
        startRequestMoneyFlowClosure?(profile)
    }

    // MARK: - dismissed

    internal private(set) var dismissedReceivedAt: PayWithWiseFlowNavigationStep?
    internal private(set) var dismissedReceivedInvocations: [PayWithWiseFlowNavigationStep] = []
    internal private(set) var dismissedCallsCount = 0
    internal var dismissedClosure: ((PayWithWiseFlowNavigationStep) -> Void)?
    internal var dismissedCalled: Bool {
        dismissedCallsCount > 0
    }

    internal func dismissed(at: PayWithWiseFlowNavigationStep) {
        dismissedCallsCount += 1
        dismissedReceivedAt = at
        dismissedReceivedInvocations.append(at)
        dismissedClosure?(at)
    }
}

internal final class PayWithWiseInteractorMock: PayWithWiseInteractor {
    // MARK: - gatherPaymentKey

    internal private(set) var gatherPaymentKeyReceivedProfileId: ProfileId?
    internal private(set) var gatherPaymentKeyReceivedInvocations: [ProfileId] = []
    internal var gatherPaymentKeyReturnValue: AnyPublisher<String, PayWithWiseV2Error>!
    internal private(set) var gatherPaymentKeyCallsCount = 0
    internal var gatherPaymentKeyClosure: ((ProfileId) -> AnyPublisher<String, PayWithWiseV2Error>)?
    internal var gatherPaymentKeyCalled: Bool {
        gatherPaymentKeyCallsCount > 0
    }

    internal func gatherPaymentKey(profileId: ProfileId) -> AnyPublisher<String, PayWithWiseV2Error> {
        gatherPaymentKeyCallsCount += 1
        gatherPaymentKeyReceivedProfileId = profileId
        gatherPaymentKeyReceivedInvocations.append(profileId)
        guard let gatherPaymentKeyClosure else {
            return gatherPaymentKeyReturnValue
        }
        return gatherPaymentKeyClosure(profileId)
    }

    // MARK: - paymentRequestLookup

    internal private(set) var paymentRequestLookupReceivedPaymentKey: String?
    internal private(set) var paymentRequestLookupReceivedInvocations: [String] = []
    internal var paymentRequestLookupReturnValue: AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error>!
    internal private(set) var paymentRequestLookupCallsCount = 0
    internal var paymentRequestLookupClosure: ((String) -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error>)?
    internal var paymentRequestLookupCalled: Bool {
        paymentRequestLookupCallsCount > 0
    }

    internal func paymentRequestLookup(paymentKey: String) -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error> {
        paymentRequestLookupCallsCount += 1
        paymentRequestLookupReceivedPaymentKey = paymentKey
        paymentRequestLookupReceivedInvocations.append(paymentKey)
        guard let paymentRequestLookupClosure else {
            return paymentRequestLookupReturnValue
        }
        return paymentRequestLookupClosure(paymentKey)
    }

    // MARK: - balances

    internal private(set) var balancesReceivedArguments: (amount: Money, profileId: ProfileId, needsRefresh: Bool)?
    internal private(set) var balancesReceivedInvocations: [(amount: Money, profileId: ProfileId, needsRefresh: Bool)] = []
    internal var balancesReturnValue: AnyPublisher<PayWithWiseInteractorImpl.BalanceFetchingResult, PayWithWiseV2Error>!
    internal private(set) var balancesCallsCount = 0
    internal var balancesClosure: ((Money, ProfileId, Bool) -> AnyPublisher<
        PayWithWiseInteractorImpl.BalanceFetchingResult,
        PayWithWiseV2Error
    >)?
    internal var balancesCalled: Bool {
        balancesCallsCount > 0
    }

    internal func balances(amount: Money, profileId: ProfileId, needsRefresh: Bool) -> AnyPublisher<
        PayWithWiseInteractorImpl.BalanceFetchingResult,
        PayWithWiseV2Error
    > {
        balancesCallsCount += 1
        balancesReceivedArguments = (amount: amount, profileId: profileId, needsRefresh: needsRefresh)
        balancesReceivedInvocations.append((amount: amount, profileId: profileId, needsRefresh: needsRefresh))
        guard let balancesClosure else {
            return balancesReturnValue
        }
        return balancesClosure(amount, profileId, needsRefresh)
    }

    // MARK: - createPayment

    internal private(set) var createPaymentReceivedArguments: (
        paymentKey: String,
        paymentRequestId: PaymentRequestId,
        balanceId: BalanceId,
        profileId: ProfileId
    )?
    internal private(set) var createPaymentReceivedInvocations: [(
        paymentKey: String,
        paymentRequestId: PaymentRequestId,
        balanceId: BalanceId,
        profileId: ProfileId
    )] = []
    internal var createPaymentReturnValue: AnyPublisher<(PaymentRequestSession, PayWithWiseQuote), PayWithWiseV2Error>!
    internal private(set) var createPaymentCallsCount = 0
    internal var createPaymentClosure: ((String, PaymentRequestId, BalanceId, ProfileId) -> AnyPublisher<
        (PaymentRequestSession, PayWithWiseQuote),
        PayWithWiseV2Error
    >)?
    internal var createPaymentCalled: Bool {
        createPaymentCallsCount > 0
    }

    internal func createPayment(paymentKey: String, paymentRequestId: PaymentRequestId, balanceId: BalanceId, profileId: ProfileId) -> AnyPublisher<
        (PaymentRequestSession, PayWithWiseQuote),
        PayWithWiseV2Error
    > {
        createPaymentCallsCount += 1
        createPaymentReceivedArguments = (
            paymentKey: paymentKey,
            paymentRequestId: paymentRequestId,
            balanceId: balanceId,
            profileId: profileId
        )
        createPaymentReceivedInvocations.append((
            paymentKey: paymentKey,
            paymentRequestId: paymentRequestId,
            balanceId: balanceId,
            profileId: profileId
        ))
        guard let createPaymentClosure else {
            return createPaymentReturnValue
        }
        return createPaymentClosure(paymentKey, paymentRequestId, balanceId, profileId)
    }

    // MARK: - acquiringPaymentLookup

    internal private(set) var acquiringPaymentLookupReceivedArguments: (
        paymentSession: QuickpayAcquiringPaymentSession,
        acquiringPaymentId: AcquiringPaymentId
    )?
    internal private(set) var acquiringPaymentLookupReceivedInvocations: [(
        paymentSession: QuickpayAcquiringPaymentSession,
        acquiringPaymentId: AcquiringPaymentId
    )] = []
    internal var acquiringPaymentLookupReturnValue: AnyPublisher<QuickpayAcquiringPayment, PayWithWiseV2Error>!
    internal private(set) var acquiringPaymentLookupCallsCount = 0
    internal var acquiringPaymentLookupClosure: ((QuickpayAcquiringPaymentSession, AcquiringPaymentId) -> AnyPublisher<
        QuickpayAcquiringPayment,
        PayWithWiseV2Error
    >)?
    internal var acquiringPaymentLookupCalled: Bool {
        acquiringPaymentLookupCallsCount > 0
    }

    internal func acquiringPaymentLookup(paymentSession: QuickpayAcquiringPaymentSession, acquiringPaymentId: AcquiringPaymentId) -> AnyPublisher<
        QuickpayAcquiringPayment,
        PayWithWiseV2Error
    > {
        acquiringPaymentLookupCallsCount += 1
        acquiringPaymentLookupReceivedArguments = (paymentSession: paymentSession, acquiringPaymentId: acquiringPaymentId)
        acquiringPaymentLookupReceivedInvocations.append((paymentSession: paymentSession, acquiringPaymentId: acquiringPaymentId))
        guard let acquiringPaymentLookupClosure else {
            return acquiringPaymentLookupReturnValue
        }
        return acquiringPaymentLookupClosure(paymentSession, acquiringPaymentId)
    }

    // MARK: - createQuickpayQuote

    internal private(set) var createQuickpayQuoteReceivedArguments: (
        session: PaymentRequestSession,
        balanceId: BalanceId,
        profileId: ProfileId
    )?
    internal private(set) var createQuickpayQuoteReceivedInvocations: [(
        session: PaymentRequestSession,
        balanceId: BalanceId,
        profileId: ProfileId
    )] = []
    internal var createQuickpayQuoteReturnValue: AnyPublisher<PayWithWiseQuote, PayWithWiseV2Error>!
    internal private(set) var createQuickpayQuoteCallsCount = 0
    internal var createQuickpayQuoteClosure: ((PaymentRequestSession, BalanceId, ProfileId) -> AnyPublisher<
        PayWithWiseQuote,
        PayWithWiseV2Error
    >)?
    internal var createQuickpayQuoteCalled: Bool {
        createQuickpayQuoteCallsCount > 0
    }

    internal func createQuickpayQuote(session: PaymentRequestSession, balanceId: BalanceId, profileId: ProfileId) -> AnyPublisher<
        PayWithWiseQuote,
        PayWithWiseV2Error
    > {
        createQuickpayQuoteCallsCount += 1
        createQuickpayQuoteReceivedArguments = (session: session, balanceId: balanceId, profileId: profileId)
        createQuickpayQuoteReceivedInvocations.append((session: session, balanceId: balanceId, profileId: profileId))
        guard let createQuickpayQuoteClosure else {
            return createQuickpayQuoteReturnValue
        }
        return createQuickpayQuoteClosure(session, balanceId, profileId)
    }

    // MARK: - loadAttachment

    internal private(set) var loadAttachmentReceivedArguments: (
        paymentKey: String,
        attachmentFile: PayerAttachmentFile,
        paymentRequestId: PaymentRequestId
    )?
    internal private(set) var loadAttachmentReceivedInvocations: [(
        paymentKey: String,
        attachmentFile: PayerAttachmentFile,
        paymentRequestId: PaymentRequestId
    )] = []
    internal var loadAttachmentReturnValue: AnyPublisher<URL, PayWithWiseV2Error>!
    internal private(set) var loadAttachmentCallsCount = 0
    internal var loadAttachmentClosure: ((String, PayerAttachmentFile, PaymentRequestId) -> AnyPublisher<URL, PayWithWiseV2Error>)?
    internal var loadAttachmentCalled: Bool {
        loadAttachmentCallsCount > 0
    }

    internal func loadAttachment(paymentKey: String, attachmentFile: PayerAttachmentFile, paymentRequestId: PaymentRequestId) -> AnyPublisher<
        URL,
        PayWithWiseV2Error
    > {
        loadAttachmentCallsCount += 1
        loadAttachmentReceivedArguments = (
            paymentKey: paymentKey,
            attachmentFile: attachmentFile,
            paymentRequestId: paymentRequestId
        )
        loadAttachmentReceivedInvocations.append((
            paymentKey: paymentKey,
            attachmentFile: attachmentFile,
            paymentRequestId: paymentRequestId
        ))
        guard let loadAttachmentClosure else {
            return loadAttachmentReturnValue
        }
        return loadAttachmentClosure(paymentKey, attachmentFile, paymentRequestId)
    }

    // MARK: - rejectRequest

    internal private(set) var rejectRequestReceivedArguments: (paymentRequestId: PaymentRequestId, profileId: ProfileId)?
    internal private(set) var rejectRequestReceivedInvocations: [(paymentRequestId: PaymentRequestId, profileId: ProfileId)] = []
    internal var rejectRequestReturnValue: AnyPublisher<OwedPaymentRequestStatusUpdate, PayWithWiseV2Error>!
    internal private(set) var rejectRequestCallsCount = 0
    internal var rejectRequestClosure: ((PaymentRequestId, ProfileId) -> AnyPublisher<
        OwedPaymentRequestStatusUpdate,
        PayWithWiseV2Error
    >)?
    internal var rejectRequestCalled: Bool {
        rejectRequestCallsCount > 0
    }

    internal func rejectRequest(paymentRequestId: PaymentRequestId, profileId: ProfileId) -> AnyPublisher<
        OwedPaymentRequestStatusUpdate,
        PayWithWiseV2Error
    > {
        rejectRequestCallsCount += 1
        rejectRequestReceivedArguments = (paymentRequestId: paymentRequestId, profileId: profileId)
        rejectRequestReceivedInvocations.append((paymentRequestId: paymentRequestId, profileId: profileId))
        guard let rejectRequestClosure else {
            return rejectRequestReturnValue
        }
        return rejectRequestClosure(paymentRequestId, profileId)
    }

    // MARK: - pay

    internal private(set) var payReceivedArguments: (
        session: PaymentRequestSession,
        profileId: ProfileId,
        balanceId: BalanceId
    )?
    internal private(set) var payReceivedInvocations: [(
        session: PaymentRequestSession,
        profileId: ProfileId,
        balanceId: BalanceId
    )] = []
    internal var payReturnValue: AnyPublisher<PayWithWisePayment, PayWithWiseV2Error>!
    internal private(set) var payCallsCount = 0
    internal var payClosure: ((PaymentRequestSession, ProfileId, BalanceId) -> AnyPublisher<PayWithWisePayment, PayWithWiseV2Error>)?
    internal var payCalled: Bool {
        payCallsCount > 0
    }

    internal func pay(session: PaymentRequestSession, profileId: ProfileId, balanceId: BalanceId) -> AnyPublisher<
        PayWithWisePayment,
        PayWithWiseV2Error
    > {
        payCallsCount += 1
        payReceivedArguments = (session: session, profileId: profileId, balanceId: balanceId)
        payReceivedInvocations.append((session: session, profileId: profileId, balanceId: balanceId))
        guard let payClosure else {
            return payReturnValue
        }
        return payClosure(session, profileId, balanceId)
    }

    // MARK: - loadImage

    internal private(set) var loadImageReceivedUrl: URL?
    internal private(set) var loadImageReceivedInvocations: [URL] = []
    internal var loadImageReturnValue: AnyPublisher<UIImage?, Never>!
    internal private(set) var loadImageCallsCount = 0
    internal var loadImageClosure: ((URL) -> AnyPublisher<UIImage?, Never>)?
    internal var loadImageCalled: Bool {
        loadImageCallsCount > 0
    }

    internal func loadImage(url: URL) -> AnyPublisher<UIImage?, Never> {
        loadImageCallsCount += 1
        loadImageReceivedUrl = url
        loadImageReceivedInvocations.append(url)
        guard let loadImageClosure else {
            return loadImageReturnValue
        }
        return loadImageClosure(url)
    }
}

internal final class PayWithWisePresenterMock: PayWithWisePresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PayWithWiseView?
    internal private(set) var startReceivedInvocations: [PayWithWiseView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PayWithWiseView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PayWithWiseView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - showDetails

    internal private(set) var showDetailsCallsCount = 0
    internal var showDetailsClosure: (() -> Void)?
    internal var showDetailsCalled: Bool {
        showDetailsCallsCount > 0
    }

    internal func showDetails() {
        showDetailsCallsCount += 1
        showDetailsClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PayWithWiseRouterMock: PayWithWiseRouter {
    // MARK: - showSuccess

    internal private(set) var showSuccessReceivedViewModel: PayWithWiseSuccessPromptViewModel?
    internal private(set) var showSuccessReceivedInvocations: [PayWithWiseSuccessPromptViewModel] = []
    internal private(set) var showSuccessCallsCount = 0
    internal var showSuccessClosure: ((PayWithWiseSuccessPromptViewModel) -> Void)?
    internal var showSuccessCalled: Bool {
        showSuccessCallsCount > 0
    }

    internal func showSuccess(viewModel: PayWithWiseSuccessPromptViewModel) {
        showSuccessCallsCount += 1
        showSuccessReceivedViewModel = viewModel
        showSuccessReceivedInvocations.append(viewModel)
        showSuccessClosure?(viewModel)
    }

    // MARK: - showRejectConfirmation

    internal private(set) var showRejectConfirmationReceivedViewModel: InfoSheetViewModel?
    internal private(set) var showRejectConfirmationReceivedInvocations: [InfoSheetViewModel] = []
    internal private(set) var showRejectConfirmationCallsCount = 0
    internal var showRejectConfirmationClosure: ((InfoSheetViewModel) -> Void)?
    internal var showRejectConfirmationCalled: Bool {
        showRejectConfirmationCallsCount > 0
    }

    internal func showRejectConfirmation(viewModel: InfoSheetViewModel) {
        showRejectConfirmationCallsCount += 1
        showRejectConfirmationReceivedViewModel = viewModel
        showRejectConfirmationReceivedInvocations.append(viewModel)
        showRejectConfirmationClosure?(viewModel)
    }

    // MARK: - showRejectSuccess

    internal private(set) var showRejectSuccessReceivedProfileId: ProfileId?
    internal private(set) var showRejectSuccessReceivedInvocations: [ProfileId] = []
    internal private(set) var showRejectSuccessCallsCount = 0
    internal var showRejectSuccessClosure: ((ProfileId) -> Void)?
    internal var showRejectSuccessCalled: Bool {
        showRejectSuccessCallsCount > 0
    }

    internal func showRejectSuccess(profileId: ProfileId) {
        showRejectSuccessCallsCount += 1
        showRejectSuccessReceivedProfileId = profileId
        showRejectSuccessReceivedInvocations.append(profileId)
        showRejectSuccessClosure?(profileId)
    }

    // MARK: - showPaymentMethodsBottomSheet

    internal private(set) var showPaymentMethodsBottomSheetReceivedArguments: (
        paymentMethods: [PayerAcquiringPaymentMethod],
        requesterName: String,
        completion: (PayerAcquiringPaymentMethod) -> Void
    )?
    internal private(set) var showPaymentMethodsBottomSheetReceivedInvocations: [(
        paymentMethods: [PayerAcquiringPaymentMethod],
        requesterName: String,
        completion: (PayerAcquiringPaymentMethod) -> Void
    )] = []
    internal private(set) var showPaymentMethodsBottomSheetCallsCount = 0
    internal var showPaymentMethodsBottomSheetClosure: ((
        [PayerAcquiringPaymentMethod],
        String,
        @escaping (PayerAcquiringPaymentMethod) -> Void
    ) -> Void)?
    internal var showPaymentMethodsBottomSheetCalled: Bool {
        showPaymentMethodsBottomSheetCallsCount > 0
    }

    internal func showPaymentMethodsBottomSheet(
        paymentMethods: [PayerAcquiringPaymentMethod],
        requesterName: String,
        completion: @escaping (PayerAcquiringPaymentMethod) -> Void
    ) {
        showPaymentMethodsBottomSheetCallsCount += 1
        showPaymentMethodsBottomSheetReceivedArguments = (
            paymentMethods: paymentMethods,
            requesterName: requesterName,
            completion: completion
        )
        showPaymentMethodsBottomSheetReceivedInvocations.append((
            paymentMethods: paymentMethods,
            requesterName: requesterName,
            completion: completion
        ))
        showPaymentMethodsBottomSheetClosure?(paymentMethods, requesterName, completion)
    }

    // MARK: - showPaymentMethodsBottomSheetQuickpay

    internal private(set) var showPaymentMethodsBottomSheetQuickpayReceivedArguments: (
        paymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        businessName: String,
        completion: (QuickpayAcquiringPayment.PaymentMethodAvailability) -> Void
    )?
    internal private(set) var showPaymentMethodsBottomSheetQuickpayReceivedInvocations: [(
        paymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        businessName: String,
        completion: (QuickpayAcquiringPayment.PaymentMethodAvailability) -> Void
    )] = []
    internal private(set) var showPaymentMethodsBottomSheetQuickpayCallsCount = 0
    internal var showPaymentMethodsBottomSheetQuickpayClosure: ((
        [QuickpayAcquiringPayment.PaymentMethodAvailability],
        String,
        @escaping (QuickpayAcquiringPayment.PaymentMethodAvailability) -> Void
    ) -> Void)?
    internal var showPaymentMethodsBottomSheetQuickpayCalled: Bool {
        showPaymentMethodsBottomSheetQuickpayCallsCount > 0
    }

    internal func showPaymentMethodsBottomSheetQuickpay(
        paymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        businessName: String,
        completion: @escaping (QuickpayAcquiringPayment.PaymentMethodAvailability) -> Void
    ) {
        showPaymentMethodsBottomSheetQuickpayCallsCount += 1
        showPaymentMethodsBottomSheetQuickpayReceivedArguments = (
            paymentMethods: paymentMethods,
            businessName: businessName,
            completion: completion
        )
        showPaymentMethodsBottomSheetQuickpayReceivedInvocations.append((
            paymentMethods: paymentMethods,
            businessName: businessName,
            completion: completion
        ))
        showPaymentMethodsBottomSheetQuickpayClosure?(paymentMethods, businessName, completion)
    }

    // MARK: - showPaymentMethod

    internal private(set) var showPaymentMethodReceivedArguments: (
        profileId: ProfileId,
        paymentMethod: PayerAcquiringPaymentMethod,
        paymentKey: String
    )?
    internal private(set) var showPaymentMethodReceivedInvocations: [(
        profileId: ProfileId,
        paymentMethod: PayerAcquiringPaymentMethod,
        paymentKey: String
    )] = []
    internal private(set) var showPaymentMethodCallsCount = 0
    internal var showPaymentMethodClosure: ((ProfileId, PayerAcquiringPaymentMethod, String) -> Void)?
    internal var showPaymentMethodCalled: Bool {
        showPaymentMethodCallsCount > 0
    }

    internal func showPaymentMethod(profileId: ProfileId, paymentMethod: PayerAcquiringPaymentMethod, paymentKey: String) {
        showPaymentMethodCallsCount += 1
        showPaymentMethodReceivedArguments = (profileId: profileId, paymentMethod: paymentMethod, paymentKey: paymentKey)
        showPaymentMethodReceivedInvocations.append((profileId: profileId, paymentMethod: paymentMethod, paymentKey: paymentKey))
        showPaymentMethodClosure?(profileId, paymentMethod, paymentKey)
    }

    // MARK: - showPaymentMethodQuickpay

    internal private(set) var showPaymentMethodQuickpayReceivedArguments: (
        profileId: ProfileId,
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability,
        quickpayLookup: QuickpayAcquiringPayment,
        quickpay: String
    )?
    internal private(set) var showPaymentMethodQuickpayReceivedInvocations: [(
        profileId: ProfileId,
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability,
        quickpayLookup: QuickpayAcquiringPayment,
        quickpay: String
    )] = []
    internal private(set) var showPaymentMethodQuickpayCallsCount = 0
    internal var showPaymentMethodQuickpayClosure: ((
        ProfileId,
        QuickpayAcquiringPayment.PaymentMethodAvailability,
        QuickpayAcquiringPayment,
        String
    ) -> Void)?
    internal var showPaymentMethodQuickpayCalled: Bool {
        showPaymentMethodQuickpayCallsCount > 0
    }

    internal func showPaymentMethodQuickpay(
        profileId: ProfileId,
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability,
        quickpayLookup: QuickpayAcquiringPayment,
        quickpay: String
    ) {
        showPaymentMethodQuickpayCallsCount += 1
        showPaymentMethodQuickpayReceivedArguments = (
            profileId: profileId,
            paymentMethod: paymentMethod,
            quickpayLookup: quickpayLookup,
            quickpay: quickpay
        )
        showPaymentMethodQuickpayReceivedInvocations.append((
            profileId: profileId,
            paymentMethod: paymentMethod,
            quickpayLookup: quickpayLookup,
            quickpay: quickpay
        ))
        showPaymentMethodQuickpayClosure?(profileId, paymentMethod, quickpayLookup, quickpay)
    }

    // MARK: - showProfileSwitcher

    internal private(set) var showProfileSwitcherReceivedCompletion: (() -> Void)?
    internal private(set) var showProfileSwitcherReceivedInvocations: [() -> Void] = []
    internal private(set) var showProfileSwitcherCallsCount = 0
    internal var showProfileSwitcherClosure: ((@escaping () -> Void) -> Void)?
    internal var showProfileSwitcherCalled: Bool {
        showProfileSwitcherCallsCount > 0
    }

    internal func showProfileSwitcher(completion: @escaping () -> Void) {
        showProfileSwitcherCallsCount += 1
        showProfileSwitcherReceivedCompletion = completion
        showProfileSwitcherReceivedInvocations.append(completion)
        showProfileSwitcherClosure?(completion)
    }

    // MARK: - showBalanceSelector

    internal private(set) var showBalanceSelectorReceivedViewModel: PayWithWiseBalanceSelectorViewModel?
    internal private(set) var showBalanceSelectorReceivedInvocations: [PayWithWiseBalanceSelectorViewModel] = []
    internal private(set) var showBalanceSelectorCallsCount = 0
    internal var showBalanceSelectorClosure: ((PayWithWiseBalanceSelectorViewModel) -> Void)?
    internal var showBalanceSelectorCalled: Bool {
        showBalanceSelectorCallsCount > 0
    }

    internal func showBalanceSelector(viewModel: PayWithWiseBalanceSelectorViewModel) {
        showBalanceSelectorCallsCount += 1
        showBalanceSelectorReceivedViewModel = viewModel
        showBalanceSelectorReceivedInvocations.append(viewModel)
        showBalanceSelectorClosure?(viewModel)
    }

    // MARK: - showTopUpFlow

    internal private(set) var showTopUpFlowReceivedArguments: (
        profile: Profile,
        targetAmount: Money?,
        rootViewController: UIViewController,
        completion: (TopUpBalanceFlowResult) -> Void
    )?
    internal private(set) var showTopUpFlowReceivedInvocations: [(
        profile: Profile,
        targetAmount: Money?,
        rootViewController: UIViewController,
        completion: (TopUpBalanceFlowResult) -> Void
    )] = []
    internal private(set) var showTopUpFlowCallsCount = 0
    internal var showTopUpFlowClosure: ((Profile, Money?, UIViewController, @escaping (TopUpBalanceFlowResult) -> Void) -> Void)?
    internal var showTopUpFlowCalled: Bool {
        showTopUpFlowCallsCount > 0
    }

    internal func showTopUpFlow(
        profile: Profile,
        targetAmount: Money?,
        rootViewController: UIViewController,
        completion: @escaping (TopUpBalanceFlowResult) -> Void
    ) {
        showTopUpFlowCallsCount += 1
        showTopUpFlowReceivedArguments = (
            profile: profile,
            targetAmount: targetAmount,
            rootViewController: rootViewController,
            completion: completion
        )
        showTopUpFlowReceivedInvocations.append((
            profile: profile,
            targetAmount: targetAmount,
            rootViewController: rootViewController,
            completion: completion
        ))
        showTopUpFlowClosure?(profile, targetAmount, rootViewController, completion)
    }

    // MARK: - showDetails

    internal private(set) var showDetailsReceivedViewModel: PayWithWiseRequestDetailsView.ViewModel?
    internal private(set) var showDetailsReceivedInvocations: [PayWithWiseRequestDetailsView.ViewModel] = []
    internal private(set) var showDetailsCallsCount = 0
    internal var showDetailsClosure: ((PayWithWiseRequestDetailsView.ViewModel) -> Void)?
    internal var showDetailsCalled: Bool {
        showDetailsCallsCount > 0
    }

    internal func showDetails(viewModel: PayWithWiseRequestDetailsView.ViewModel) {
        showDetailsCallsCount += 1
        showDetailsReceivedViewModel = viewModel
        showDetailsReceivedInvocations.append(viewModel)
        showDetailsClosure?(viewModel)
    }

    // MARK: - showAttachment

    internal private(set) var showAttachmentReceivedArguments: (url: URL, delegate: UIDocumentInteractionControllerDelegate)?
    internal private(set) var showAttachmentReceivedInvocations: [(url: URL, delegate: UIDocumentInteractionControllerDelegate)] = []
    internal private(set) var showAttachmentCallsCount = 0
    internal var showAttachmentClosure: ((URL, UIDocumentInteractionControllerDelegate) -> Void)?
    internal var showAttachmentCalled: Bool {
        showAttachmentCallsCount > 0
    }

    internal func showAttachment(url: URL, delegate: UIDocumentInteractionControllerDelegate) {
        showAttachmentCallsCount += 1
        showAttachmentReceivedArguments = (url: url, delegate: delegate)
        showAttachmentReceivedInvocations.append((url: url, delegate: delegate))
        showAttachmentClosure?(url, delegate)
    }

    // MARK: - showRequestMoney

    internal private(set) var showRequestMoneyReceivedProfile: Profile?
    internal private(set) var showRequestMoneyReceivedInvocations: [Profile] = []
    internal private(set) var showRequestMoneyCallsCount = 0
    internal var showRequestMoneyClosure: ((Profile) -> Void)?
    internal var showRequestMoneyCalled: Bool {
        showRequestMoneyCallsCount > 0
    }

    internal func showRequestMoney(profile: Profile) {
        showRequestMoneyCallsCount += 1
        showRequestMoneyReceivedProfile = profile
        showRequestMoneyReceivedInvocations.append(profile)
        showRequestMoneyClosure?(profile)
    }

    // MARK: - dismissBalanceSelector

    internal private(set) var dismissBalanceSelectorCallsCount = 0
    internal var dismissBalanceSelectorClosure: (() -> Void)?
    internal var dismissBalanceSelectorCalled: Bool {
        dismissBalanceSelectorCallsCount > 0
    }

    internal func dismissBalanceSelector() {
        dismissBalanceSelectorCallsCount += 1
        dismissBalanceSelectorClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PayWithWiseViewMock: PayWithWiseView {
    internal var documentDelegate: UIDocumentInteractionControllerDelegate {
        get { underlyingDocumentDelegate }
        set(value) { underlyingDocumentDelegate = value }
    }

    private var underlyingDocumentDelegate: UIDocumentInteractionControllerDelegate!
    internal var presentationRootViewController: UIViewController {
        get { underlyingPresentationRootViewController }
        set(value) { underlyingPresentationRootViewController = value }
    }

    private var underlyingPresentationRootViewController: UIViewController!

    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PayWithWiseViewModel?
    internal private(set) var configureReceivedInvocations: [PayWithWiseViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PayWithWiseViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(viewModel: PayWithWiseViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - updateTitle

    internal private(set) var updateTitleReceivedViewModel: PayWithWiseHeaderView.ViewModel?
    internal private(set) var updateTitleReceivedInvocations: [PayWithWiseHeaderView.ViewModel] = []
    internal private(set) var updateTitleCallsCount = 0
    internal var updateTitleClosure: ((PayWithWiseHeaderView.ViewModel) -> Void)?
    internal var updateTitleCalled: Bool {
        updateTitleCallsCount > 0
    }

    internal func updateTitle(viewModel: PayWithWiseHeaderView.ViewModel) {
        updateTitleCallsCount += 1
        updateTitleReceivedViewModel = viewModel
        updateTitleReceivedInvocations.append(viewModel)
        updateTitleClosure?(viewModel)
    }

    // MARK: - showErrorAlert

    internal private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorAlertCallsCount = 0
    internal var showErrorAlertClosure: ((String, String) -> Void)?
    internal var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    internal func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class PayWithWiseViewControllerFactoryMock: PayWithWiseViewControllerFactory {
    // MARK: - setFlowNavigationDelegate

    internal private(set) var setFlowNavigationDelegateReceivedDelegate: PayWithWiseFlowNavigationDelegate?
    internal private(set) var setFlowNavigationDelegateReceivedInvocations: [PayWithWiseFlowNavigationDelegate] = []
    internal private(set) var setFlowNavigationDelegateCallsCount = 0
    internal var setFlowNavigationDelegateClosure: ((PayWithWiseFlowNavigationDelegate) -> Void)?
    internal var setFlowNavigationDelegateCalled: Bool {
        setFlowNavigationDelegateCallsCount > 0
    }

    internal func setFlowNavigationDelegate(_ delegate: PayWithWiseFlowNavigationDelegate) {
        setFlowNavigationDelegateCallsCount += 1
        setFlowNavigationDelegateReceivedDelegate = delegate
        setFlowNavigationDelegateReceivedInvocations.append(delegate)
        setFlowNavigationDelegateClosure?(delegate)
    }

    // MARK: - makeViewController

    internal private(set) var makeViewControllerReceivedArguments: (profile: Profile, host: UINavigationController)?
    internal private(set) var makeViewControllerReceivedInvocations: [(profile: Profile, host: UINavigationController)] = []
    internal var makeViewControllerReturnValue: UIViewController!
    internal private(set) var makeViewControllerCallsCount = 0
    internal var makeViewControllerClosure: ((Profile, UINavigationController) -> UIViewController)?
    internal var makeViewControllerCalled: Bool {
        makeViewControllerCallsCount > 0
    }

    internal func makeViewController(profile: Profile, host: UINavigationController) -> UIViewController {
        makeViewControllerCallsCount += 1
        makeViewControllerReceivedArguments = (profile: profile, host: host)
        makeViewControllerReceivedInvocations.append((profile: profile, host: host))
        guard let makeViewControllerClosure else {
            return makeViewControllerReturnValue
        }
        return makeViewControllerClosure(profile, host)
    }
}

internal final class PayWithWiseViewModelFactoryMock: PayWithWiseViewModelFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        source: PayWithWiseFlow.PaymentInitializationSource,
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [AcquiringPaymentMethodType],
        profile: Profile,
        paymentRequestLookup: PaymentRequestLookup,
        avatar: ContactsKit.AvatarModel?,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: () -> Void,
        selectBalanceAction: () -> Void,
        firstButtonAction: () -> Void,
        secondButtonAction: () -> Void
    )?
    internal private(set) var makeReceivedInvocations: [(
        source: PayWithWiseFlow.PaymentInitializationSource,
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [AcquiringPaymentMethodType],
        profile: Profile,
        paymentRequestLookup: PaymentRequestLookup,
        avatar: ContactsKit.AvatarModel?,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: () -> Void,
        selectBalanceAction: () -> Void,
        firstButtonAction: () -> Void,
        secondButtonAction: () -> Void
    )] = []
    internal var makeReturnValue: PayWithWiseViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((
        PayWithWiseFlow.PaymentInitializationSource,
        PayWithWiseViewModel.Alert?,
        Bool,
        [AcquiringPaymentMethodType],
        Profile,
        PaymentRequestLookup,
        ContactsKit.AvatarModel?,
        PayWithWiseQuote?,
        Balance?,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void
    ) -> PayWithWiseViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        source: PayWithWiseFlow.PaymentInitializationSource,
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [AcquiringPaymentMethodType],
        profile: Profile,
        paymentRequestLookup: PaymentRequestLookup,
        avatar: ContactsKit.AvatarModel?,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: @escaping () -> Void,
        selectBalanceAction: @escaping () -> Void,
        firstButtonAction: @escaping () -> Void,
        secondButtonAction: @escaping () -> Void
    ) -> PayWithWiseViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (
            source: source,
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: supportedPaymentMethods,
            profile: profile,
            paymentRequestLookup: paymentRequestLookup,
            avatar: avatar,
            quote: quote,
            selectedBalance: selectedBalance,
            selectProfileAction: selectProfileAction,
            selectBalanceAction: selectBalanceAction,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        )
        makeReceivedInvocations.append((
            source: source,
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: supportedPaymentMethods,
            profile: profile,
            paymentRequestLookup: paymentRequestLookup,
            avatar: avatar,
            quote: quote,
            selectedBalance: selectedBalance,
            selectProfileAction: selectProfileAction,
            selectBalanceAction: selectBalanceAction,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(
            source,
            inlineAlert,
            supportsProfileChange,
            supportedPaymentMethods,
            profile,
            paymentRequestLookup,
            avatar,
            quote,
            selectedBalance,
            selectProfileAction,
            selectBalanceAction,
            firstButtonAction,
            secondButtonAction
        )
    }

    // MARK: - makeQuickpay

    internal private(set) var makeQuickpayReceivedArguments: (
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        profile: Profile,
        businessInfo: ContactSearch,
        quickpayLookup: QuickpayAcquiringPayment,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: () -> Void,
        selectBalanceAction: () -> Void,
        firstButtonAction: () -> Void,
        secondButtonAction: () -> Void
    )?
    internal private(set) var makeQuickpayReceivedInvocations: [(
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        profile: Profile,
        businessInfo: ContactSearch,
        quickpayLookup: QuickpayAcquiringPayment,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: () -> Void,
        selectBalanceAction: () -> Void,
        firstButtonAction: () -> Void,
        secondButtonAction: () -> Void
    )] = []
    internal var makeQuickpayReturnValue: PayWithWiseViewModel!
    internal private(set) var makeQuickpayCallsCount = 0
    internal var makeQuickpayClosure: ((
        PayWithWiseViewModel.Alert?,
        Bool,
        [QuickpayAcquiringPayment.PaymentMethodAvailability],
        Profile,
        ContactSearch,
        QuickpayAcquiringPayment,
        PayWithWiseQuote?,
        Balance?,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void
    ) -> PayWithWiseViewModel)?
    internal var makeQuickpayCalled: Bool {
        makeQuickpayCallsCount > 0
    }

    internal func makeQuickpay(
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        profile: Profile,
        businessInfo: ContactSearch,
        quickpayLookup: QuickpayAcquiringPayment,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: @escaping () -> Void,
        selectBalanceAction: @escaping () -> Void,
        firstButtonAction: @escaping () -> Void,
        secondButtonAction: @escaping () -> Void
    ) -> PayWithWiseViewModel {
        makeQuickpayCallsCount += 1
        makeQuickpayReceivedArguments = (
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: supportedPaymentMethods,
            profile: profile,
            businessInfo: businessInfo,
            quickpayLookup: quickpayLookup,
            quote: quote,
            selectedBalance: selectedBalance,
            selectProfileAction: selectProfileAction,
            selectBalanceAction: selectBalanceAction,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        )
        makeQuickpayReceivedInvocations.append((
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: supportedPaymentMethods,
            profile: profile,
            businessInfo: businessInfo,
            quickpayLookup: quickpayLookup,
            quote: quote,
            selectedBalance: selectedBalance,
            selectProfileAction: selectProfileAction,
            selectBalanceAction: selectBalanceAction,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        ))
        guard let makeQuickpayClosure else {
            return makeQuickpayReturnValue
        }
        return makeQuickpayClosure(
            inlineAlert,
            supportsProfileChange,
            supportedPaymentMethods,
            profile,
            businessInfo,
            quickpayLookup,
            quote,
            selectedBalance,
            selectProfileAction,
            selectBalanceAction,
            firstButtonAction,
            secondButtonAction
        )
    }

    // MARK: - makeBalanceOptionsContainer

    internal private(set) var makeBalanceOptionsContainerReceivedArguments: (fundableBalances: [Balance], balances: [Balance])?
    internal private(set) var makeBalanceOptionsContainerReceivedInvocations: [(
        fundableBalances: [Balance],
        balances: [Balance]
    )] = []
    internal var makeBalanceOptionsContainerReturnValue: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer!
    internal private(set) var makeBalanceOptionsContainerCallsCount = 0
    internal var makeBalanceOptionsContainerClosure: (([Balance], [Balance]) -> PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer)?
    internal var makeBalanceOptionsContainerCalled: Bool {
        makeBalanceOptionsContainerCallsCount > 0
    }

    internal func makeBalanceOptionsContainer(fundableBalances: [Balance], balances: [Balance]) -> PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer {
        makeBalanceOptionsContainerCallsCount += 1
        makeBalanceOptionsContainerReceivedArguments = (fundableBalances: fundableBalances, balances: balances)
        makeBalanceOptionsContainerReceivedInvocations.append((fundableBalances: fundableBalances, balances: balances))
        guard let makeBalanceOptionsContainerClosure else {
            return makeBalanceOptionsContainerReturnValue
        }
        return makeBalanceOptionsContainerClosure(fundableBalances, balances)
    }

    // MARK: - makeBalanceSections

    internal private(set) var makeBalanceSectionsReceivedContainer: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer?
    internal private(set) var makeBalanceSectionsReceivedInvocations: [PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer] = []
    internal var makeBalanceSectionsReturnValue: [PayWithWiseBalanceSelectorViewModel.Section]!
    internal private(set) var makeBalanceSectionsCallsCount = 0
    internal var makeBalanceSectionsClosure: ((PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer) -> [PayWithWiseBalanceSelectorViewModel.Section])?
    internal var makeBalanceSectionsCalled: Bool {
        makeBalanceSectionsCallsCount > 0
    }

    internal func makeBalanceSections(container: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer) -> [PayWithWiseBalanceSelectorViewModel.Section] {
        makeBalanceSectionsCallsCount += 1
        makeBalanceSectionsReceivedContainer = container
        makeBalanceSectionsReceivedInvocations.append(container)
        guard let makeBalanceSectionsClosure else {
            return makeBalanceSectionsReturnValue
        }
        return makeBalanceSectionsClosure(container)
    }

    // MARK: - makeEmptyStateViewModel

    internal private(set) var makeEmptyStateViewModelReceivedArguments: (
        image: UIImage,
        title: String,
        message: String,
        buttonAction: Action
    )?
    internal private(set) var makeEmptyStateViewModelReceivedInvocations: [(
        image: UIImage,
        title: String,
        message: String,
        buttonAction: Action
    )] = []
    internal var makeEmptyStateViewModelReturnValue: PayWithWiseViewModel!
    internal private(set) var makeEmptyStateViewModelCallsCount = 0
    internal var makeEmptyStateViewModelClosure: ((UIImage, String, String, Action) -> PayWithWiseViewModel)?
    internal var makeEmptyStateViewModelCalled: Bool {
        makeEmptyStateViewModelCallsCount > 0
    }

    internal func makeEmptyStateViewModel(image: UIImage, title: String, message: String, buttonAction: Action) -> PayWithWiseViewModel {
        makeEmptyStateViewModelCallsCount += 1
        makeEmptyStateViewModelReceivedArguments = (image: image, title: title, message: message, buttonAction: buttonAction)
        makeEmptyStateViewModelReceivedInvocations.append((
            image: image,
            title: title,
            message: message,
            buttonAction: buttonAction
        ))
        guard let makeEmptyStateViewModelClosure else {
            return makeEmptyStateViewModelReturnValue
        }
        return makeEmptyStateViewModelClosure(image, title, message, buttonAction)
    }

    // MARK: - makeAlertViewModel

    internal private(set) var makeAlertViewModelReceivedArguments: (message: String, style: InlineAlertStyle, action: Action?)?
    internal private(set) var makeAlertViewModelReceivedInvocations: [(
        message: String,
        style: InlineAlertStyle,
        action: Action?
    )] = []
    internal var makeAlertViewModelReturnValue: PayWithWiseViewModel.Alert!
    internal private(set) var makeAlertViewModelCallsCount = 0
    internal var makeAlertViewModelClosure: ((String, InlineAlertStyle, Action?) -> PayWithWiseViewModel.Alert)?
    internal var makeAlertViewModelCalled: Bool {
        makeAlertViewModelCallsCount > 0
    }

    internal func makeAlertViewModel(message: String, style: InlineAlertStyle, action: Action?) -> PayWithWiseViewModel.Alert {
        makeAlertViewModelCallsCount += 1
        makeAlertViewModelReceivedArguments = (message: message, style: style, action: action)
        makeAlertViewModelReceivedInvocations.append((message: message, style: style, action: action))
        guard let makeAlertViewModelClosure else {
            return makeAlertViewModelReturnValue
        }
        return makeAlertViewModelClosure(message, style, action)
    }

    // MARK: - makeItems

    internal private(set) static var makeItemsReceivedPaymentRequestLookup: PaymentRequestLookup?
    internal private(set) static var makeItemsReceivedInvocations: [PaymentRequestLookup] = []
    internal static var makeItemsReturnValue: [LegacyListItemViewModel]!
    internal private(set) static var makeItemsCallsCount = 0
    internal static var makeItemsClosure: ((PaymentRequestLookup) -> [LegacyListItemViewModel])?
    internal static var makeItemsCalled: Bool {
        makeItemsCallsCount > 0
    }

    internal static func makeItems(paymentRequestLookup: PaymentRequestLookup) -> [LegacyListItemViewModel] {
        makeItemsCallsCount += 1
        makeItemsReceivedPaymentRequestLookup = paymentRequestLookup
        makeItemsReceivedInvocations.append(paymentRequestLookup)
        guard let makeItemsClosure else {
            return makeItemsReturnValue
        }
        return makeItemsClosure(paymentRequestLookup)
    }

    // MARK: - makeItemsForQuickpay

    internal private(set) static var makeItemsForQuickpayReceivedQuickpayLookup: QuickpayAcquiringPayment?
    internal private(set) static var makeItemsForQuickpayReceivedInvocations: [QuickpayAcquiringPayment] = []
    internal static var makeItemsForQuickpayReturnValue: [LegacyListItemViewModel]!
    internal private(set) static var makeItemsForQuickpayCallsCount = 0
    internal static var makeItemsForQuickpayClosure: ((QuickpayAcquiringPayment) -> [LegacyListItemViewModel])?
    internal static var makeItemsForQuickpayCalled: Bool {
        makeItemsForQuickpayCallsCount > 0
    }

    internal static func makeItemsForQuickpay(quickpayLookup: QuickpayAcquiringPayment) -> [LegacyListItemViewModel] {
        makeItemsForQuickpayCallsCount += 1
        makeItemsForQuickpayReceivedQuickpayLookup = quickpayLookup
        makeItemsForQuickpayReceivedInvocations.append(quickpayLookup)
        guard let makeItemsForQuickpayClosure else {
            return makeItemsForQuickpayReturnValue
        }
        return makeItemsForQuickpayClosure(quickpayLookup)
    }

    // MARK: - makeRejectConfirmationModel

    internal private(set) static var makeRejectConfirmationModelReceivedArguments: (
        confirmAction: () -> Void,
        cancelAction: () -> Void
    )?
    internal private(set) static var makeRejectConfirmationModelReceivedInvocations: [(
        confirmAction: () -> Void,
        cancelAction: () -> Void
    )] = []
    internal static var makeRejectConfirmationModelReturnValue: InfoSheetViewModel!
    internal private(set) static var makeRejectConfirmationModelCallsCount = 0
    internal static var makeRejectConfirmationModelClosure: ((@escaping () -> Void, @escaping () -> Void) -> InfoSheetViewModel)?
    internal static var makeRejectConfirmationModelCalled: Bool {
        makeRejectConfirmationModelCallsCount > 0
    }

    internal static func makeRejectConfirmationModel(confirmAction: @escaping () -> Void, cancelAction: @escaping () -> Void) -> InfoSheetViewModel {
        makeRejectConfirmationModelCallsCount += 1
        makeRejectConfirmationModelReceivedArguments = (confirmAction: confirmAction, cancelAction: cancelAction)
        makeRejectConfirmationModelReceivedInvocations.append((confirmAction: confirmAction, cancelAction: cancelAction))
        guard let makeRejectConfirmationModelClosure else {
            return makeRejectConfirmationModelReturnValue
        }
        return makeRejectConfirmationModelClosure(confirmAction, cancelAction)
    }

    // MARK: - makeHeaderViewModel

    internal private(set) var makeHeaderViewModelReceivedArguments: (
        title: String,
        recipientName: String,
        description: String?,
        avatar: AnyPublisher<ContactsKit.AvatarModel, Never>
    )?
    internal private(set) var makeHeaderViewModelReceivedInvocations: [(
        title: String,
        recipientName: String,
        description: String?,
        avatar: AnyPublisher<ContactsKit.AvatarModel, Never>
    )] = []
    internal var makeHeaderViewModelReturnValue: PayWithWiseHeaderView.ViewModel!
    internal private(set) var makeHeaderViewModelCallsCount = 0
    internal var makeHeaderViewModelClosure: ((String, String, String?, AnyPublisher<ContactsKit.AvatarModel, Never>) -> PayWithWiseHeaderView.ViewModel)?
    internal var makeHeaderViewModelCalled: Bool {
        makeHeaderViewModelCallsCount > 0
    }

    internal func makeHeaderViewModel(
        title: String,
        recipientName: String,
        description: String?,
        avatar: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PayWithWiseHeaderView.ViewModel {
        makeHeaderViewModelCallsCount += 1
        makeHeaderViewModelReceivedArguments = (
            title: title,
            recipientName: recipientName,
            description: description,
            avatar: avatar
        )
        makeHeaderViewModelReceivedInvocations.append((
            title: title,
            recipientName: recipientName,
            description: description,
            avatar: avatar
        ))
        guard let makeHeaderViewModelClosure else {
            return makeHeaderViewModelReturnValue
        }
        return makeHeaderViewModelClosure(title, recipientName, description, avatar)
    }
}

internal final class PaymentDetailsInteractorMock: PaymentDetailsInteractor {
    // MARK: - paymentDetails

    internal private(set) var paymentDetailsReceivedProfileId: ProfileId?
    internal private(set) var paymentDetailsReceivedInvocations: [ProfileId] = []
    internal var paymentDetailsReturnValue: AnyPublisher<PaymentDetails, Error>!
    internal private(set) var paymentDetailsCallsCount = 0
    internal var paymentDetailsClosure: ((ProfileId) -> AnyPublisher<PaymentDetails, Error>)?
    internal var paymentDetailsCalled: Bool {
        paymentDetailsCallsCount > 0
    }

    internal func paymentDetails(profileId: ProfileId) -> AnyPublisher<PaymentDetails, Error> {
        paymentDetailsCallsCount += 1
        paymentDetailsReceivedProfileId = profileId
        paymentDetailsReceivedInvocations.append(profileId)
        guard let paymentDetailsClosure else {
            return paymentDetailsReturnValue
        }
        return paymentDetailsClosure(profileId)
    }
}

internal final class PaymentDetailsPresenterMock: PaymentDetailsPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentDetailsView?
    internal private(set) var startReceivedInvocations: [PaymentDetailsView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentDetailsView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentDetailsView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class PaymentDetailsRefundFlowDelegateMock: PaymentDetailsRefundFlowDelegate {
    // MARK: - didRefundFlowCompleted

    internal private(set) var didRefundFlowCompletedCallsCount = 0
    internal var didRefundFlowCompletedClosure: (() -> Void)?
    internal var didRefundFlowCompletedCalled: Bool {
        didRefundFlowCompletedCallsCount > 0
    }

    internal func didRefundFlowCompleted() {
        didRefundFlowCompletedCallsCount += 1
        didRefundFlowCompletedClosure?()
    }

    // MARK: - goBackToAllPayments

    internal private(set) var goBackToAllPaymentsCallsCount = 0
    internal var goBackToAllPaymentsClosure: (() -> Void)?
    internal var goBackToAllPaymentsCalled: Bool {
        goBackToAllPaymentsCallsCount > 0
    }

    internal func goBackToAllPayments() {
        goBackToAllPaymentsCallsCount += 1
        goBackToAllPaymentsClosure?()
    }
}

internal final class PaymentDetailsRouterMock: PaymentDetailsRouter {
    // MARK: - showRefundFlow

    internal private(set) var showRefundFlowReceivedArguments: (paymentId: String, profileId: ProfileId)?
    internal private(set) var showRefundFlowReceivedInvocations: [(paymentId: String, profileId: ProfileId)] = []
    internal private(set) var showRefundFlowCallsCount = 0
    internal var showRefundFlowClosure: ((String, ProfileId) -> Void)?
    internal var showRefundFlowCalled: Bool {
        showRefundFlowCallsCount > 0
    }

    internal func showRefundFlow(paymentId: String, profileId: ProfileId) {
        showRefundFlowCallsCount += 1
        showRefundFlowReceivedArguments = (paymentId: paymentId, profileId: profileId)
        showRefundFlowReceivedInvocations.append((paymentId: paymentId, profileId: profileId))
        showRefundFlowClosure?(paymentId, profileId)
    }

    // MARK: - showRefundDisabledBottomSheet

    internal private(set) var showRefundDisabledBottomSheetReceivedArguments: (
        title: String,
        illustrationUrn: String?,
        message: String
    )?
    internal private(set) var showRefundDisabledBottomSheetReceivedInvocations: [(
        title: String,
        illustrationUrn: String?,
        message: String
    )] = []
    internal private(set) var showRefundDisabledBottomSheetCallsCount = 0
    internal var showRefundDisabledBottomSheetClosure: ((String, String?, String) -> Void)?
    internal var showRefundDisabledBottomSheetCalled: Bool {
        showRefundDisabledBottomSheetCallsCount > 0
    }

    internal func showRefundDisabledBottomSheet(title: String, illustrationUrn: String?, message: String) {
        showRefundDisabledBottomSheetCallsCount += 1
        showRefundDisabledBottomSheetReceivedArguments = (title: title, illustrationUrn: illustrationUrn, message: message)
        showRefundDisabledBottomSheetReceivedInvocations.append((title: title, illustrationUrn: illustrationUrn, message: message))
        showRefundDisabledBottomSheetClosure?(title, illustrationUrn, message)
    }
}

internal final class PaymentDetailsViewMock: PaymentDetailsView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentDetailsViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentDetailsViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentDetailsViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentDetailsViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }
}

internal final class PaymentDetailsViewControllerFactoryMock: PaymentDetailsViewControllerFactory {
    // MARK: - make

    internal private(set) static var makeWithTransactionIdReceivedArguments: (
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transactionId: AcquiringTransactionId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    )?
    internal private(set) static var makeWithTransactionIdReceivedInvocations: [(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transactionId: AcquiringTransactionId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    )] = []
    internal static var makeWithTransactionIdReturnValue: UIViewController!
    internal private(set) static var makeWithTransactionIdCallsCount = 0
    internal static var makeWithTransactionIdClosure: ((
        ProfileId,
        PaymentRequestId,
        AcquiringTransactionId,
        UINavigationController,
        PaymentDetailsRefundFlowDelegate,
        WebViewControllerFactory.Type
    ) -> UIViewController)?
    internal static var makeWithTransactionIdCalled: Bool {
        makeWithTransactionIdCallsCount > 0
    }

    internal static func make(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transactionId: AcquiringTransactionId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController {
        makeWithTransactionIdCallsCount += 1
        makeWithTransactionIdReceivedArguments = (
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transactionId: transactionId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory
        )
        makeWithTransactionIdReceivedInvocations.append((
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transactionId: transactionId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory
        ))
        guard let makeWithTransactionIdClosure else {
            return makeWithTransactionIdReturnValue
        }
        return makeWithTransactionIdClosure(
            profileId,
            paymentRequestId,
            transactionId,
            navigationController,
            paymentDetailsRefundFlowDelegate,
            webViewControllerFactory
        )
    }

    // MARK: - make

    internal private(set) static var makeWithTransferIdReceivedArguments: (
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transferId: ReceiveTransferId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    )?
    internal private(set) static var makeWithTransferIdReceivedInvocations: [(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transferId: ReceiveTransferId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    )] = []
    internal static var makeWithTransferIdReturnValue: UIViewController!
    internal private(set) static var makeWithTransferIdCallsCount = 0
    internal static var makeWithTransferIdClosure: ((
        ProfileId,
        PaymentRequestId,
        ReceiveTransferId,
        UINavigationController,
        PaymentDetailsRefundFlowDelegate,
        WebViewControllerFactory.Type
    ) -> UIViewController)?
    internal static var makeWithTransferIdCalled: Bool {
        makeWithTransferIdCallsCount > 0
    }

    internal static func make(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transferId: ReceiveTransferId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController {
        makeWithTransferIdCallsCount += 1
        makeWithTransferIdReceivedArguments = (
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transferId: transferId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory
        )
        makeWithTransferIdReceivedInvocations.append((
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transferId: transferId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory
        ))
        guard let makeWithTransferIdClosure else {
            return makeWithTransferIdReturnValue
        }
        return makeWithTransferIdClosure(
            profileId,
            paymentRequestId,
            transferId,
            navigationController,
            paymentDetailsRefundFlowDelegate,
            webViewControllerFactory
        )
    }
}

internal final class PaymentDetailsViewModelMapperDelegateMock: PaymentDetailsViewModelMapperDelegate {
    // MARK: - isRefundEnabled

    internal var isRefundEnabledReturnValue: Bool!
    internal private(set) var isRefundEnabledCallsCount = 0
    internal var isRefundEnabledClosure: (() -> Bool)?
    internal var isRefundEnabledCalled: Bool {
        isRefundEnabledCallsCount > 0
    }

    internal func isRefundEnabled() -> Bool {
        isRefundEnabledCallsCount += 1
        guard let isRefundEnabledClosure else {
            return isRefundEnabledReturnValue
        }
        return isRefundEnabledClosure()
    }

    // MARK: - proceedRefund

    internal private(set) var proceedRefundReceivedPaymentId: String?
    internal private(set) var proceedRefundReceivedInvocations: [String] = []
    internal private(set) var proceedRefundCallsCount = 0
    internal var proceedRefundClosure: ((String) -> Void)?
    internal var proceedRefundCalled: Bool {
        proceedRefundCallsCount > 0
    }

    internal func proceedRefund(paymentId: String) {
        proceedRefundCallsCount += 1
        proceedRefundReceivedPaymentId = paymentId
        proceedRefundReceivedInvocations.append(paymentId)
        proceedRefundClosure?(paymentId)
    }

    // MARK: - showRefundDisabled

    internal private(set) var showRefundDisabledReceivedArguments: (title: String, message: String, illustrationUrn: String?)?
    internal private(set) var showRefundDisabledReceivedInvocations: [(
        title: String,
        message: String,
        illustrationUrn: String?
    )] = []
    internal private(set) var showRefundDisabledCallsCount = 0
    internal var showRefundDisabledClosure: ((String, String, String?) -> Void)?
    internal var showRefundDisabledCalled: Bool {
        showRefundDisabledCallsCount > 0
    }

    internal func showRefundDisabled(title: String, message: String, illustrationUrn: String?) {
        showRefundDisabledCallsCount += 1
        showRefundDisabledReceivedArguments = (title: title, message: message, illustrationUrn: illustrationUrn)
        showRefundDisabledReceivedInvocations.append((title: title, message: message, illustrationUrn: illustrationUrn))
        showRefundDisabledClosure?(title, message, illustrationUrn)
    }
}

internal final class PaymentLinkAllPaymentsPresenterMock: PaymentLinkAllPaymentsPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentLinkAllPaymentsView?
    internal private(set) var startReceivedInvocations: [PaymentLinkAllPaymentsView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentLinkAllPaymentsView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentLinkAllPaymentsView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - rowTapped

    internal private(set) var rowTappedReceivedAction: PaymentLinkAllPayments.Group.Content.OptionItemAction?
    internal private(set) var rowTappedReceivedInvocations: [PaymentLinkAllPayments.Group.Content.OptionItemAction] = []
    internal private(set) var rowTappedCallsCount = 0
    internal var rowTappedClosure: ((PaymentLinkAllPayments.Group.Content.OptionItemAction) -> Void)?
    internal var rowTappedCalled: Bool {
        rowTappedCallsCount > 0
    }

    internal func rowTapped(action: PaymentLinkAllPayments.Group.Content.OptionItemAction) {
        rowTappedCallsCount += 1
        rowTappedReceivedAction = action
        rowTappedReceivedInvocations.append(action)
        rowTappedClosure?(action)
    }

    // MARK: - prefetch

    internal private(set) var prefetchReceivedId: String?
    internal private(set) var prefetchReceivedInvocations: [String] = []
    internal private(set) var prefetchCallsCount = 0
    internal var prefetchClosure: ((String) -> Void)?
    internal var prefetchCalled: Bool {
        prefetchCallsCount > 0
    }

    internal func prefetch(id: String) {
        prefetchCallsCount += 1
        prefetchReceivedId = id
        prefetchReceivedInvocations.append(id)
        prefetchClosure?(id)
    }
}

internal final class PaymentLinkAllPaymentsRouterMock: PaymentLinkAllPaymentsRouter {
    // MARK: - showPaymentLinkPaymentDetails

    internal private(set) var showPaymentLinkPaymentDetailsReceivedAcquiringPaymentId: AcquiringPaymentId?
    internal private(set) var showPaymentLinkPaymentDetailsReceivedInvocations: [AcquiringPaymentId] = []
    internal private(set) var showPaymentLinkPaymentDetailsCallsCount = 0
    internal var showPaymentLinkPaymentDetailsClosure: ((AcquiringPaymentId) -> Void)?
    internal var showPaymentLinkPaymentDetailsCalled: Bool {
        showPaymentLinkPaymentDetailsCallsCount > 0
    }

    internal func showPaymentLinkPaymentDetails(acquiringPaymentId: AcquiringPaymentId) {
        showPaymentLinkPaymentDetailsCallsCount += 1
        showPaymentLinkPaymentDetailsReceivedAcquiringPaymentId = acquiringPaymentId
        showPaymentLinkPaymentDetailsReceivedInvocations.append(acquiringPaymentId)
        showPaymentLinkPaymentDetailsClosure?(acquiringPaymentId)
    }

    // MARK: - showAcquiringTransactionPaymentDetails

    internal private(set) var showAcquiringTransactionPaymentDetailsReceivedTransactionId: AcquiringTransactionId?
    internal private(set) var showAcquiringTransactionPaymentDetailsReceivedInvocations: [AcquiringTransactionId] = []
    internal private(set) var showAcquiringTransactionPaymentDetailsCallsCount = 0
    internal var showAcquiringTransactionPaymentDetailsClosure: ((AcquiringTransactionId) -> Void)?
    internal var showAcquiringTransactionPaymentDetailsCalled: Bool {
        showAcquiringTransactionPaymentDetailsCallsCount > 0
    }

    internal func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId) {
        showAcquiringTransactionPaymentDetailsCallsCount += 1
        showAcquiringTransactionPaymentDetailsReceivedTransactionId = transactionId
        showAcquiringTransactionPaymentDetailsReceivedInvocations.append(transactionId)
        showAcquiringTransactionPaymentDetailsClosure?(transactionId)
    }

    // MARK: - showTransferPaymentDetails

    internal private(set) var showTransferPaymentDetailsReceivedTransferId: ReceiveTransferId?
    internal private(set) var showTransferPaymentDetailsReceivedInvocations: [ReceiveTransferId] = []
    internal private(set) var showTransferPaymentDetailsCallsCount = 0
    internal var showTransferPaymentDetailsClosure: ((ReceiveTransferId) -> Void)?
    internal var showTransferPaymentDetailsCalled: Bool {
        showTransferPaymentDetailsCallsCount > 0
    }

    internal func showTransferPaymentDetails(transferId: ReceiveTransferId) {
        showTransferPaymentDetailsCallsCount += 1
        showTransferPaymentDetailsReceivedTransferId = transferId
        showTransferPaymentDetailsReceivedInvocations.append(transferId)
        showTransferPaymentDetailsClosure?(transferId)
    }
}

internal final class PaymentLinkAllPaymentsViewMock: PaymentLinkAllPaymentsView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentLinkAllPaymentsViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentLinkAllPaymentsViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentLinkAllPaymentsViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentLinkAllPaymentsViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }

    // MARK: - showNewSections

    internal private(set) var showNewSectionsReceivedNewSections: [PaymentLinkAllPaymentsViewModel.Section]?
    internal private(set) var showNewSectionsReceivedInvocations: [[PaymentLinkAllPaymentsViewModel.Section]] = []
    internal private(set) var showNewSectionsCallsCount = 0
    internal var showNewSectionsClosure: (([PaymentLinkAllPaymentsViewModel.Section]) -> Void)?
    internal var showNewSectionsCalled: Bool {
        showNewSectionsCallsCount > 0
    }

    internal func showNewSections(_ newSections: [PaymentLinkAllPaymentsViewModel.Section]) {
        showNewSectionsCallsCount += 1
        showNewSectionsReceivedNewSections = newSections
        showNewSectionsReceivedInvocations.append(newSections)
        showNewSectionsClosure?(newSections)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class PaymentLinkPaymentDetailsPresenterMock: PaymentLinkPaymentDetailsPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentLinkPaymentDetailsView?
    internal private(set) var startReceivedInvocations: [PaymentLinkPaymentDetailsView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentLinkPaymentDetailsView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentLinkPaymentDetailsView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class PaymentLinkPaymentDetailsRouterMock: PaymentLinkPaymentDetailsRouter {
    // MARK: - showAcquiringTransactionPaymentDetails

    internal private(set) var showAcquiringTransactionPaymentDetailsReceivedTransactionId: AcquiringTransactionId?
    internal private(set) var showAcquiringTransactionPaymentDetailsReceivedInvocations: [AcquiringTransactionId] = []
    internal private(set) var showAcquiringTransactionPaymentDetailsCallsCount = 0
    internal var showAcquiringTransactionPaymentDetailsClosure: ((AcquiringTransactionId) -> Void)?
    internal var showAcquiringTransactionPaymentDetailsCalled: Bool {
        showAcquiringTransactionPaymentDetailsCallsCount > 0
    }

    internal func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId) {
        showAcquiringTransactionPaymentDetailsCallsCount += 1
        showAcquiringTransactionPaymentDetailsReceivedTransactionId = transactionId
        showAcquiringTransactionPaymentDetailsReceivedInvocations.append(transactionId)
        showAcquiringTransactionPaymentDetailsClosure?(transactionId)
    }

    // MARK: - showTransferPaymentDetails

    internal private(set) var showTransferPaymentDetailsReceivedTransferId: ReceiveTransferId?
    internal private(set) var showTransferPaymentDetailsReceivedInvocations: [ReceiveTransferId] = []
    internal private(set) var showTransferPaymentDetailsCallsCount = 0
    internal var showTransferPaymentDetailsClosure: ((ReceiveTransferId) -> Void)?
    internal var showTransferPaymentDetailsCalled: Bool {
        showTransferPaymentDetailsCallsCount > 0
    }

    internal func showTransferPaymentDetails(transferId: ReceiveTransferId) {
        showTransferPaymentDetailsCallsCount += 1
        showTransferPaymentDetailsReceivedTransferId = transferId
        showTransferPaymentDetailsReceivedInvocations.append(transferId)
        showTransferPaymentDetailsClosure?(transferId)
    }
}

internal final class PaymentLinkPaymentDetailsViewMock: PaymentLinkPaymentDetailsView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentLinkPaymentDetailsViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentLinkPaymentDetailsViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentLinkPaymentDetailsViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentLinkPaymentDetailsViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }
}

internal final class PaymentLinkPaymentDetailsViewModelDelegateMock: PaymentLinkPaymentDetailsViewModelDelegate {
    // MARK: - optionItemTapped

    internal private(set) var optionItemTappedReceivedAction: PaymentLinkPaymentDetails.Section.Item.OptionItemAction?
    internal private(set) var optionItemTappedReceivedInvocations: [PaymentLinkPaymentDetails.Section.Item.OptionItemAction] = []
    internal private(set) var optionItemTappedCallsCount = 0
    internal var optionItemTappedClosure: ((PaymentLinkPaymentDetails.Section.Item.OptionItemAction) -> Void)?
    internal var optionItemTappedCalled: Bool {
        optionItemTappedCallsCount > 0
    }

    internal func optionItemTapped(action: PaymentLinkPaymentDetails.Section.Item.OptionItemAction) {
        optionItemTappedCallsCount += 1
        optionItemTappedReceivedAction = action
        optionItemTappedReceivedInvocations.append(action)
        optionItemTappedClosure?(action)
    }
}

internal final class PaymentLinkPaymentDetailsViewModelFactoryMock: PaymentLinkPaymentDetailsViewModelFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        paymentLinkPaymentDetails: PaymentLinkPaymentDetails,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    )?
    internal private(set) var makeReceivedInvocations: [(
        paymentLinkPaymentDetails: PaymentLinkPaymentDetails,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    )] = []
    internal var makeReturnValue: PaymentLinkPaymentDetailsViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((PaymentLinkPaymentDetails, PaymentLinkPaymentDetailsViewModelDelegate) -> PaymentLinkPaymentDetailsViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        from paymentLinkPaymentDetails: PaymentLinkPaymentDetails,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    ) -> PaymentLinkPaymentDetailsViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (paymentLinkPaymentDetails: paymentLinkPaymentDetails, delegate: delegate)
        makeReceivedInvocations.append((paymentLinkPaymentDetails: paymentLinkPaymentDetails, delegate: delegate))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(paymentLinkPaymentDetails, delegate)
    }
}

internal final class PaymentLinkSharingInteractorMock: PaymentLinkSharingInteractor {
    // MARK: - fetchDetails

    internal var fetchDetailsReturnValue: AnyPublisher<PaymentLinkSharingDetailsModelState, Never>!
    internal private(set) var fetchDetailsCallsCount = 0
    internal var fetchDetailsClosure: (() -> AnyPublisher<PaymentLinkSharingDetailsModelState, Never>)?
    internal var fetchDetailsCalled: Bool {
        fetchDetailsCallsCount > 0
    }

    internal func fetchDetails() -> AnyPublisher<PaymentLinkSharingDetailsModelState, Never> {
        fetchDetailsCallsCount += 1
        guard let fetchDetailsClosure else {
            return fetchDetailsReturnValue
        }
        return fetchDetailsClosure()
    }
}

internal final class PaymentLinkSharingPresenterMock: PaymentLinkSharingPresenter {
    // MARK: - viewLoaded

    internal private(set) var viewLoadedReceivedView: PaymentLinkSharingView?
    internal private(set) var viewLoadedReceivedInvocations: [PaymentLinkSharingView] = []
    internal private(set) var viewLoadedCallsCount = 0
    internal var viewLoadedClosure: ((PaymentLinkSharingView) -> Void)?
    internal var viewLoadedCalled: Bool {
        viewLoadedCallsCount > 0
    }

    internal func viewLoaded(with view: PaymentLinkSharingView) {
        viewLoadedCallsCount += 1
        viewLoadedReceivedView = view
        viewLoadedReceivedInvocations.append(view)
        viewLoadedClosure?(view)
    }

    // MARK: - refresh

    internal private(set) var refreshCallsCount = 0
    internal var refreshClosure: (() -> Void)?
    internal var refreshCalled: Bool {
        refreshCallsCount > 0
    }

    internal func refresh() {
        refreshCallsCount += 1
        refreshClosure?()
    }
}

internal final class PaymentLinkSharingRouterMock: PaymentLinkSharingRouter {
    // MARK: - openLinkSharing

    internal private(set) var openLinkSharingReceivedPaymentRequest: PaymentRequestV2?
    internal private(set) var openLinkSharingReceivedInvocations: [PaymentRequestV2] = []
    internal private(set) var openLinkSharingCallsCount = 0
    internal var openLinkSharingClosure: ((PaymentRequestV2) -> Void)?
    internal var openLinkSharingCalled: Bool {
        openLinkSharingCallsCount > 0
    }

    internal func openLinkSharing(for paymentRequest: PaymentRequestV2) {
        openLinkSharingCallsCount += 1
        openLinkSharingReceivedPaymentRequest = paymentRequest
        openLinkSharingReceivedInvocations.append(paymentRequest)
        openLinkSharingClosure?(paymentRequest)
    }

    // MARK: - openPaymentRequestDetails

    internal private(set) var openPaymentRequestDetailsReceivedPaymentRequestId: PaymentRequestId?
    internal private(set) var openPaymentRequestDetailsReceivedInvocations: [PaymentRequestId] = []
    internal private(set) var openPaymentRequestDetailsCallsCount = 0
    internal var openPaymentRequestDetailsClosure: ((PaymentRequestId) -> Void)?
    internal var openPaymentRequestDetailsCalled: Bool {
        openPaymentRequestDetailsCallsCount > 0
    }

    internal func openPaymentRequestDetails(for paymentRequestId: PaymentRequestId) {
        openPaymentRequestDetailsCallsCount += 1
        openPaymentRequestDetailsReceivedPaymentRequestId = paymentRequestId
        openPaymentRequestDetailsReceivedInvocations.append(paymentRequestId)
        openPaymentRequestDetailsClosure?(paymentRequestId)
    }
}

internal final class PaymentLinkSharingViewMock: LoadingPresentableMock, PaymentLinkSharingView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentLinkSharingViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentLinkSharingViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentLinkSharingViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentLinkSharingViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class PaymentLinkSharingViewModelMapperMock: PaymentLinkSharingViewModelMapper {
    // MARK: - map

    internal private(set) var mapReceivedArguments: (
        model: PaymentLinkSharingDetails,
        actionHandler: PaymentLinkSharingActionHandler
    )?
    internal private(set) var mapReceivedInvocations: [(
        model: PaymentLinkSharingDetails,
        actionHandler: PaymentLinkSharingActionHandler
    )] = []
    internal var mapReturnValue: PaymentLinkSharingViewModel!
    internal private(set) var mapCallsCount = 0
    internal var mapClosure: ((PaymentLinkSharingDetails, @escaping PaymentLinkSharingActionHandler) -> PaymentLinkSharingViewModel)?
    internal var mapCalled: Bool {
        mapCallsCount > 0
    }

    internal func map(_ model: PaymentLinkSharingDetails, actionHandler: @escaping PaymentLinkSharingActionHandler) -> PaymentLinkSharingViewModel {
        mapCallsCount += 1
        mapReceivedArguments = (model: model, actionHandler: actionHandler)
        mapReceivedInvocations.append((model: model, actionHandler: actionHandler))
        guard let mapClosure else {
            return mapReturnValue
        }
        return mapClosure(model, actionHandler)
    }
}

internal final class PaymentLinkViewControllerFactoryMock: PaymentLinkViewControllerFactory {
    // MARK: - makePaymentDetails

    internal private(set) var makePaymentDetailsReceivedArguments: (
        paymentRequestId: PaymentRequestId,
        acquiringPaymentId: AcquiringPaymentId,
        profileId: ProfileId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type
    )?
    internal private(set) var makePaymentDetailsReceivedInvocations: [(
        paymentRequestId: PaymentRequestId,
        acquiringPaymentId: AcquiringPaymentId,
        profileId: ProfileId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type
    )] = []
    internal var makePaymentDetailsReturnValue: UIViewController!
    internal private(set) var makePaymentDetailsCallsCount = 0
    internal var makePaymentDetailsClosure: ((
        PaymentRequestId,
        AcquiringPaymentId,
        ProfileId,
        PaymentDetailsRefundFlowDelegate,
        UINavigationController,
        WebViewControllerFactory.Type
    ) -> UIViewController)?
    internal var makePaymentDetailsCalled: Bool {
        makePaymentDetailsCallsCount > 0
    }

    internal func makePaymentDetails(
        paymentRequestId: PaymentRequestId,
        acquiringPaymentId: AcquiringPaymentId,
        profileId: ProfileId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController {
        makePaymentDetailsCallsCount += 1
        makePaymentDetailsReceivedArguments = (
            paymentRequestId: paymentRequestId,
            acquiringPaymentId: acquiringPaymentId,
            profileId: profileId,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory
        )
        makePaymentDetailsReceivedInvocations.append((
            paymentRequestId: paymentRequestId,
            acquiringPaymentId: acquiringPaymentId,
            profileId: profileId,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory
        ))
        guard let makePaymentDetailsClosure else {
            return makePaymentDetailsReturnValue
        }
        return makePaymentDetailsClosure(
            paymentRequestId,
            acquiringPaymentId,
            profileId,
            paymentDetailsRefundFlowDelegate,
            navigationController,
            webViewControllerFactory
        )
    }
}

internal final class PaymentMethodsDelegateMock: PaymentMethodsDelegate {
    // MARK: - refreshPaymentMethods

    internal private(set) var refreshPaymentMethodsCallsCount = 0
    internal var refreshPaymentMethodsClosure: (() -> Void)?
    internal var refreshPaymentMethodsCalled: Bool {
        refreshPaymentMethodsCallsCount > 0
    }

    internal func refreshPaymentMethods() {
        refreshPaymentMethodsCallsCount += 1
        refreshPaymentMethodsClosure?()
    }

    // MARK: - trackDynamicFlowFailed

    internal private(set) var trackDynamicFlowFailedCallsCount = 0
    internal var trackDynamicFlowFailedClosure: (() -> Void)?
    internal var trackDynamicFlowFailedCalled: Bool {
        trackDynamicFlowFailedCallsCount > 0
    }

    internal func trackDynamicFlowFailed() {
        trackDynamicFlowFailedCallsCount += 1
        trackDynamicFlowFailedClosure?()
    }
}

internal final class PaymentMethodsDynamicFlowHandlerMock: PaymentMethodsDynamicFlowHandler {
    // MARK: - showDynamicForms

    internal private(set) var showDynamicFormsReceivedArguments: (
        dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    )?
    internal private(set) var showDynamicFormsReceivedInvocations: [(
        dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    )] = []
    internal private(set) var showDynamicFormsCallsCount = 0
    internal var showDynamicFormsClosure: (([PaymentMethodDynamicForm], PaymentMethodsDelegate?) -> Void)?
    internal var showDynamicFormsCalled: Bool {
        showDynamicFormsCallsCount > 0
    }

    internal func showDynamicForms(_ dynamicForms: [PaymentMethodDynamicForm], delegate: PaymentMethodsDelegate?) {
        showDynamicFormsCallsCount += 1
        showDynamicFormsReceivedArguments = (dynamicForms: dynamicForms, delegate: delegate)
        showDynamicFormsReceivedInvocations.append((dynamicForms: dynamicForms, delegate: delegate))
        showDynamicFormsClosure?(dynamicForms, delegate)
    }
}

internal final class PaymentRequestDetailFlowDelegateMock: PaymentRequestDetailFlowDelegate {
    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PaymentRequestDetailPresenterMock: PaymentRequestDetailPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentRequestDetailView?
    internal private(set) var startReceivedInvocations: [PaymentRequestDetailView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentRequestDetailView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentRequestDetailView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PaymentRequestDetailRouterMock: PaymentRequestDetailRouter {
    // MARK: - showPaymentLinkPaymentDetails

    internal private(set) var showPaymentLinkPaymentDetailsReceivedAcquiringPaymentId: AcquiringPaymentId?
    internal private(set) var showPaymentLinkPaymentDetailsReceivedInvocations: [AcquiringPaymentId] = []
    internal private(set) var showPaymentLinkPaymentDetailsCallsCount = 0
    internal var showPaymentLinkPaymentDetailsClosure: ((AcquiringPaymentId) -> Void)?
    internal var showPaymentLinkPaymentDetailsCalled: Bool {
        showPaymentLinkPaymentDetailsCallsCount > 0
    }

    internal func showPaymentLinkPaymentDetails(acquiringPaymentId: AcquiringPaymentId) {
        showPaymentLinkPaymentDetailsCallsCount += 1
        showPaymentLinkPaymentDetailsReceivedAcquiringPaymentId = acquiringPaymentId
        showPaymentLinkPaymentDetailsReceivedInvocations.append(acquiringPaymentId)
        showPaymentLinkPaymentDetailsClosure?(acquiringPaymentId)
    }

    // MARK: - showAcquiringTransactionPaymentDetails

    internal private(set) var showAcquiringTransactionPaymentDetailsReceivedTransactionId: AcquiringTransactionId?
    internal private(set) var showAcquiringTransactionPaymentDetailsReceivedInvocations: [AcquiringTransactionId] = []
    internal private(set) var showAcquiringTransactionPaymentDetailsCallsCount = 0
    internal var showAcquiringTransactionPaymentDetailsClosure: ((AcquiringTransactionId) -> Void)?
    internal var showAcquiringTransactionPaymentDetailsCalled: Bool {
        showAcquiringTransactionPaymentDetailsCallsCount > 0
    }

    internal func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId) {
        showAcquiringTransactionPaymentDetailsCallsCount += 1
        showAcquiringTransactionPaymentDetailsReceivedTransactionId = transactionId
        showAcquiringTransactionPaymentDetailsReceivedInvocations.append(transactionId)
        showAcquiringTransactionPaymentDetailsClosure?(transactionId)
    }

    // MARK: - showTransferPaymentDetails

    internal private(set) var showTransferPaymentDetailsReceivedTransferId: ReceiveTransferId?
    internal private(set) var showTransferPaymentDetailsReceivedInvocations: [ReceiveTransferId] = []
    internal private(set) var showTransferPaymentDetailsCallsCount = 0
    internal var showTransferPaymentDetailsClosure: ((ReceiveTransferId) -> Void)?
    internal var showTransferPaymentDetailsCalled: Bool {
        showTransferPaymentDetailsCallsCount > 0
    }

    internal func showTransferPaymentDetails(transferId: ReceiveTransferId) {
        showTransferPaymentDetailsCallsCount += 1
        showTransferPaymentDetailsReceivedTransferId = transferId
        showTransferPaymentDetailsReceivedInvocations.append(transferId)
        showTransferPaymentDetailsClosure?(transferId)
    }

    // MARK: - showDocumentPreview

    internal private(set) var showDocumentPreviewReceivedArguments: (
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    )?
    internal private(set) var showDocumentPreviewReceivedInvocations: [(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    )] = []
    internal private(set) var showDocumentPreviewCallsCount = 0
    internal var showDocumentPreviewClosure: ((URL, UIDocumentInteractionControllerDelegate) -> Void)?
    internal var showDocumentPreviewCalled: Bool {
        showDocumentPreviewCallsCount > 0
    }

    internal func showDocumentPreview(url: URL, delegate: UIDocumentInteractionControllerDelegate) {
        showDocumentPreviewCallsCount += 1
        showDocumentPreviewReceivedArguments = (url: url, delegate: delegate)
        showDocumentPreviewReceivedInvocations.append((url: url, delegate: delegate))
        showDocumentPreviewClosure?(url, delegate)
    }

    // MARK: - showActionConfirmation

    internal private(set) var showActionConfirmationReceivedViewModel: InfoSheetViewModel?
    internal private(set) var showActionConfirmationReceivedInvocations: [InfoSheetViewModel] = []
    internal private(set) var showActionConfirmationCallsCount = 0
    internal var showActionConfirmationClosure: ((InfoSheetViewModel) -> Void)?
    internal var showActionConfirmationCalled: Bool {
        showActionConfirmationCallsCount > 0
    }

    internal func showActionConfirmation(viewModel: InfoSheetViewModel) {
        showActionConfirmationCallsCount += 1
        showActionConfirmationReceivedViewModel = viewModel
        showActionConfirmationReceivedInvocations.append(viewModel)
        showActionConfirmationClosure?(viewModel)
    }

    // MARK: - showQRCode

    internal private(set) var showQRCodeReceivedPaymentRequest: PaymentRequestV2?
    internal private(set) var showQRCodeReceivedInvocations: [PaymentRequestV2] = []
    internal private(set) var showQRCodeCallsCount = 0
    internal var showQRCodeClosure: ((PaymentRequestV2) -> Void)?
    internal var showQRCodeCalled: Bool {
        showQRCodeCallsCount > 0
    }

    internal func showQRCode(paymentRequest: PaymentRequestV2) {
        showQRCodeCallsCount += 1
        showQRCodeReceivedPaymentRequest = paymentRequest
        showQRCodeReceivedInvocations.append(paymentRequest)
        showQRCodeClosure?(paymentRequest)
    }

    // MARK: - showShareSheet

    internal private(set) var showShareSheetReceivedPaymentRequest: PaymentRequestV2?
    internal private(set) var showShareSheetReceivedInvocations: [PaymentRequestV2] = []
    internal private(set) var showShareSheetCallsCount = 0
    internal var showShareSheetClosure: ((PaymentRequestV2) -> Void)?
    internal var showShareSheetCalled: Bool {
        showShareSheetCallsCount > 0
    }

    internal func showShareSheet(paymentRequest: PaymentRequestV2) {
        showShareSheetCallsCount += 1
        showShareSheetReceivedPaymentRequest = paymentRequest
        showShareSheetReceivedInvocations.append(paymentRequest)
        showShareSheetClosure?(paymentRequest)
    }

    // MARK: - goBackToPaymentRequestDetail

    internal private(set) var goBackToPaymentRequestDetailCallsCount = 0
    internal var goBackToPaymentRequestDetailClosure: (() -> Void)?
    internal var goBackToPaymentRequestDetailCalled: Bool {
        goBackToPaymentRequestDetailCallsCount > 0
    }

    internal func goBackToPaymentRequestDetail() {
        goBackToPaymentRequestDetailCallsCount += 1
        goBackToPaymentRequestDetailClosure?()
    }

    // MARK: - goToViewAllPayments

    internal private(set) var goToViewAllPaymentsCallsCount = 0
    internal var goToViewAllPaymentsClosure: (() -> Void)?
    internal var goToViewAllPaymentsCalled: Bool {
        goToViewAllPaymentsCallsCount > 0
    }

    internal func goToViewAllPayments() {
        goToViewAllPaymentsCallsCount += 1
        goToViewAllPaymentsClosure?()
    }

    // MARK: - goBackToAllPayments

    internal private(set) var goBackToAllPaymentsCallsCount = 0
    internal var goBackToAllPaymentsClosure: (() -> Void)?
    internal var goBackToAllPaymentsCalled: Bool {
        goBackToAllPaymentsCallsCount > 0
    }

    internal func goBackToAllPayments() {
        goBackToAllPaymentsCallsCount += 1
        goBackToAllPaymentsClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PaymentRequestDetailViewMock: PaymentRequestDetailView {
    internal var documentDelegate: UIDocumentInteractionControllerDelegate {
        get { underlyingDocumentDelegate }
        set(value) { underlyingDocumentDelegate = value }
    }

    private var underlyingDocumentDelegate: UIDocumentInteractionControllerDelegate!
    internal var sourceView: UIView {
        get { underlyingSourceView }
        set(value) { underlyingSourceView = value }
    }

    private var underlyingSourceView: UIView!

    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentRequestDetailViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentRequestDetailViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentRequestDetailViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentRequestDetailViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showSnackBar

    internal private(set) var showSnackBarReceivedMessage: String?
    internal private(set) var showSnackBarReceivedInvocations: [String] = []
    internal private(set) var showSnackBarCallsCount = 0
    internal var showSnackBarClosure: ((String) -> Void)?
    internal var showSnackBarCalled: Bool {
        showSnackBarCallsCount > 0
    }

    internal func showSnackBar(message: String) {
        showSnackBarCallsCount += 1
        showSnackBarReceivedMessage = message
        showSnackBarReceivedInvocations.append(message)
        showSnackBarClosure?(message)
    }

    // MARK: - showShareOptions

    internal private(set) var showShareOptionsReceivedViewModel: PaymentRequestDetailShareOptionsViewModel?
    internal private(set) var showShareOptionsReceivedInvocations: [PaymentRequestDetailShareOptionsViewModel] = []
    internal private(set) var showShareOptionsCallsCount = 0
    internal var showShareOptionsClosure: ((PaymentRequestDetailShareOptionsViewModel) -> Void)?
    internal var showShareOptionsCalled: Bool {
        showShareOptionsCallsCount > 0
    }

    internal func showShareOptions(viewModel: PaymentRequestDetailShareOptionsViewModel) {
        showShareOptionsCallsCount += 1
        showShareOptionsReceivedViewModel = viewModel
        showShareOptionsReceivedInvocations.append(viewModel)
        showShareOptionsClosure?(viewModel)
    }

    // MARK: - showPaymentMethodSummaries

    internal private(set) var showPaymentMethodSummariesReceivedViewModel: PaymentRequestDetailPaymentMethodsViewModel?
    internal private(set) var showPaymentMethodSummariesReceivedInvocations: [PaymentRequestDetailPaymentMethodsViewModel] = []
    internal private(set) var showPaymentMethodSummariesCallsCount = 0
    internal var showPaymentMethodSummariesClosure: ((PaymentRequestDetailPaymentMethodsViewModel) -> Void)?
    internal var showPaymentMethodSummariesCalled: Bool {
        showPaymentMethodSummariesCallsCount > 0
    }

    internal func showPaymentMethodSummaries(viewModel: PaymentRequestDetailPaymentMethodsViewModel) {
        showPaymentMethodSummariesCallsCount += 1
        showPaymentMethodSummariesReceivedViewModel = viewModel
        showPaymentMethodSummariesReceivedInvocations.append(viewModel)
        showPaymentMethodSummariesClosure?(viewModel)
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }

    // MARK: - showAlert

    internal private(set) var showAlertReceivedArguments: (
        title: String,
        message: String,
        leftAction: AlertAction,
        rightAction: AlertAction
    )?
    internal private(set) var showAlertReceivedInvocations: [(
        title: String,
        message: String,
        leftAction: AlertAction,
        rightAction: AlertAction
    )] = []
    internal private(set) var showAlertCallsCount = 0
    internal var showAlertClosure: ((String, String, AlertAction, AlertAction) -> Void)?
    internal var showAlertCalled: Bool {
        showAlertCallsCount > 0
    }

    internal func showAlert(title: String, message: String, leftAction: AlertAction, rightAction: AlertAction) {
        showAlertCallsCount += 1
        showAlertReceivedArguments = (title: title, message: message, leftAction: leftAction, rightAction: rightAction)
        showAlertReceivedInvocations.append((title: title, message: message, leftAction: leftAction, rightAction: rightAction))
        showAlertClosure?(title, message, leftAction, rightAction)
    }
}

internal final class PaymentRequestDetailViewModelDelegateMock: PaymentRequestDetailViewModelDelegate {
    // MARK: - copyTapped

    internal private(set) var copyTappedReceivedValue: String?
    internal private(set) var copyTappedReceivedInvocations: [String] = []
    internal private(set) var copyTappedCallsCount = 0
    internal var copyTappedClosure: ((String) -> Void)?
    internal var copyTappedCalled: Bool {
        copyTappedCallsCount > 0
    }

    internal func copyTapped(_ value: String) {
        copyTappedCallsCount += 1
        copyTappedReceivedValue = value
        copyTappedReceivedInvocations.append(value)
        copyTappedClosure?(value)
    }

    // MARK: - shareOptionsTapped

    internal private(set) var shareOptionsTappedReceivedViewModel: PaymentRequestDetailShareOptionsViewModel?
    internal private(set) var shareOptionsTappedReceivedInvocations: [PaymentRequestDetailShareOptionsViewModel] = []
    internal private(set) var shareOptionsTappedCallsCount = 0
    internal var shareOptionsTappedClosure: ((PaymentRequestDetailShareOptionsViewModel) -> Void)?
    internal var shareOptionsTappedCalled: Bool {
        shareOptionsTappedCallsCount > 0
    }

    internal func shareOptionsTapped(viewModel: PaymentRequestDetailShareOptionsViewModel) {
        shareOptionsTappedCallsCount += 1
        shareOptionsTappedReceivedViewModel = viewModel
        shareOptionsTappedReceivedInvocations.append(viewModel)
        shareOptionsTappedClosure?(viewModel)
    }

    // MARK: - paymentMethodSummariesTapped

    internal private(set) var paymentMethodSummariesTappedReceivedViewModel: PaymentRequestDetailPaymentMethodsViewModel?
    internal private(set) var paymentMethodSummariesTappedReceivedInvocations: [PaymentRequestDetailPaymentMethodsViewModel] = []
    internal private(set) var paymentMethodSummariesTappedCallsCount = 0
    internal var paymentMethodSummariesTappedClosure: ((PaymentRequestDetailPaymentMethodsViewModel) -> Void)?
    internal var paymentMethodSummariesTappedCalled: Bool {
        paymentMethodSummariesTappedCallsCount > 0
    }

    internal func paymentMethodSummariesTapped(viewModel: PaymentRequestDetailPaymentMethodsViewModel) {
        paymentMethodSummariesTappedCallsCount += 1
        paymentMethodSummariesTappedReceivedViewModel = viewModel
        paymentMethodSummariesTappedReceivedInvocations.append(viewModel)
        paymentMethodSummariesTappedClosure?(viewModel)
    }

    // MARK: - viewAttachmentFileTapped

    internal private(set) var viewAttachmentFileTappedReceivedFile: RequestorAttachmentFile?
    internal private(set) var viewAttachmentFileTappedReceivedInvocations: [RequestorAttachmentFile] = []
    internal private(set) var viewAttachmentFileTappedCallsCount = 0
    internal var viewAttachmentFileTappedClosure: ((RequestorAttachmentFile) -> Void)?
    internal var viewAttachmentFileTappedCalled: Bool {
        viewAttachmentFileTappedCallsCount > 0
    }

    internal func viewAttachmentFileTapped(_ file: RequestorAttachmentFile) {
        viewAttachmentFileTappedCallsCount += 1
        viewAttachmentFileTappedReceivedFile = file
        viewAttachmentFileTappedReceivedInvocations.append(file)
        viewAttachmentFileTappedClosure?(file)
    }

    // MARK: - paymentDetailsTapped

    internal private(set) var paymentDetailsTappedReceivedAction: PaymentRequestDetailsSection.Item.OptionItemAction?
    internal private(set) var paymentDetailsTappedReceivedInvocations: [PaymentRequestDetailsSection.Item.OptionItemAction] = []
    internal private(set) var paymentDetailsTappedCallsCount = 0
    internal var paymentDetailsTappedClosure: ((PaymentRequestDetailsSection.Item.OptionItemAction) -> Void)?
    internal var paymentDetailsTappedCalled: Bool {
        paymentDetailsTappedCallsCount > 0
    }

    internal func paymentDetailsTapped(action: PaymentRequestDetailsSection.Item.OptionItemAction) {
        paymentDetailsTappedCallsCount += 1
        paymentDetailsTappedReceivedAction = action
        paymentDetailsTappedReceivedInvocations.append(action)
        paymentDetailsTappedClosure?(action)
    }

    // MARK: - cancelPaymentRequestTapped

    internal private(set) var cancelPaymentRequestTappedReceivedRequestType: PaymentRequestDetails.RequestType?
    internal private(set) var cancelPaymentRequestTappedReceivedInvocations: [PaymentRequestDetails.RequestType] = []
    internal private(set) var cancelPaymentRequestTappedCallsCount = 0
    internal var cancelPaymentRequestTappedClosure: ((PaymentRequestDetails.RequestType) -> Void)?
    internal var cancelPaymentRequestTappedCalled: Bool {
        cancelPaymentRequestTappedCallsCount > 0
    }

    internal func cancelPaymentRequestTapped(requestType: PaymentRequestDetails.RequestType) {
        cancelPaymentRequestTappedCallsCount += 1
        cancelPaymentRequestTappedReceivedRequestType = requestType
        cancelPaymentRequestTappedReceivedInvocations.append(requestType)
        cancelPaymentRequestTappedClosure?(requestType)
    }

    // MARK: - cancelPaymentRequestConfirmed

    internal private(set) var cancelPaymentRequestConfirmedCallsCount = 0
    internal var cancelPaymentRequestConfirmedClosure: (() -> Void)?
    internal var cancelPaymentRequestConfirmedCalled: Bool {
        cancelPaymentRequestConfirmedCallsCount > 0
    }

    internal func cancelPaymentRequestConfirmed() {
        cancelPaymentRequestConfirmedCallsCount += 1
        cancelPaymentRequestConfirmedClosure?()
    }

    // MARK: - markAsPaidTapped

    internal private(set) var markAsPaidTappedReceivedRequestType: PaymentRequestDetails.RequestType?
    internal private(set) var markAsPaidTappedReceivedInvocations: [PaymentRequestDetails.RequestType] = []
    internal private(set) var markAsPaidTappedCallsCount = 0
    internal var markAsPaidTappedClosure: ((PaymentRequestDetails.RequestType) -> Void)?
    internal var markAsPaidTappedCalled: Bool {
        markAsPaidTappedCallsCount > 0
    }

    internal func markAsPaidTapped(requestType: PaymentRequestDetails.RequestType) {
        markAsPaidTappedCallsCount += 1
        markAsPaidTappedReceivedRequestType = requestType
        markAsPaidTappedReceivedInvocations.append(requestType)
        markAsPaidTappedClosure?(requestType)
    }

    // MARK: - markAsPaidConfirmed

    internal private(set) var markAsPaidConfirmedCallsCount = 0
    internal var markAsPaidConfirmedClosure: (() -> Void)?
    internal var markAsPaidConfirmedCalled: Bool {
        markAsPaidConfirmedCallsCount > 0
    }

    internal func markAsPaidConfirmed() {
        markAsPaidConfirmedCallsCount += 1
        markAsPaidConfirmedClosure?()
    }

    // MARK: - shareWithQRCodeTapped

    internal private(set) var shareWithQRCodeTappedCallsCount = 0
    internal var shareWithQRCodeTappedClosure: (() -> Void)?
    internal var shareWithQRCodeTappedCalled: Bool {
        shareWithQRCodeTappedCallsCount > 0
    }

    internal func shareWithQRCodeTapped() {
        shareWithQRCodeTappedCallsCount += 1
        shareWithQRCodeTappedClosure?()
    }

    // MARK: - shareSheetTapped

    internal private(set) var shareSheetTappedCallsCount = 0
    internal var shareSheetTappedClosure: (() -> Void)?
    internal var shareSheetTappedCalled: Bool {
        shareSheetTappedCallsCount > 0
    }

    internal func shareSheetTapped() {
        shareSheetTappedCallsCount += 1
        shareSheetTappedClosure?()
    }

    // MARK: - fetchAvatarViewModel

    internal private(set) var fetchAvatarViewModelReceivedArguments: (
        urlString: String,
        fallbackImage: UIImage,
        badge: UIImage?
    )?
    internal private(set) var fetchAvatarViewModelReceivedInvocations: [(
        urlString: String,
        fallbackImage: UIImage,
        badge: UIImage?
    )] = []
    internal var fetchAvatarViewModelReturnValue: AnyPublisher<AvatarViewModel, Never>!
    internal private(set) var fetchAvatarViewModelCallsCount = 0
    internal var fetchAvatarViewModelClosure: ((String, UIImage, UIImage?) -> AnyPublisher<AvatarViewModel, Never>)?
    internal var fetchAvatarViewModelCalled: Bool {
        fetchAvatarViewModelCallsCount > 0
    }

    internal func fetchAvatarViewModel(urlString: String, fallbackImage: UIImage, badge: UIImage?) -> AnyPublisher<
        AvatarViewModel,
        Never
    > {
        fetchAvatarViewModelCallsCount += 1
        fetchAvatarViewModelReceivedArguments = (urlString: urlString, fallbackImage: fallbackImage, badge: badge)
        fetchAvatarViewModelReceivedInvocations.append((urlString: urlString, fallbackImage: fallbackImage, badge: badge))
        guard let fetchAvatarViewModelClosure else {
            return fetchAvatarViewModelReturnValue
        }
        return fetchAvatarViewModelClosure(urlString, fallbackImage, badge)
    }

    // MARK: - sectionHeaderActionTapped

    internal private(set) var sectionHeaderActionTappedReceivedUrnString: String?
    internal private(set) var sectionHeaderActionTappedReceivedInvocations: [String] = []
    internal private(set) var sectionHeaderActionTappedCallsCount = 0
    internal var sectionHeaderActionTappedClosure: ((String) -> Void)?
    internal var sectionHeaderActionTappedCalled: Bool {
        sectionHeaderActionTappedCallsCount > 0
    }

    internal func sectionHeaderActionTapped(urnString: String) {
        sectionHeaderActionTappedCallsCount += 1
        sectionHeaderActionTappedReceivedUrnString = urnString
        sectionHeaderActionTappedReceivedInvocations.append(urnString)
        sectionHeaderActionTappedClosure?(urnString)
    }
}

internal final class PaymentRequestDetailViewModelFactoryMock: PaymentRequestDetailViewModelFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    )?
    internal private(set) var makeReceivedInvocations: [(
        paymentRequestDetails: PaymentRequestDetails,
        delegate: PaymentRequestDetailViewModelDelegate
    )] = []
    internal var makeReturnValue: AnyPublisher<PaymentRequestDetailViewModel, Never>!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((PaymentRequestDetails, PaymentRequestDetailViewModelDelegate) -> AnyPublisher<
        PaymentRequestDetailViewModel,
        Never
    >)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(from paymentRequestDetails: PaymentRequestDetails, delegate: PaymentRequestDetailViewModelDelegate) -> AnyPublisher<
        PaymentRequestDetailViewModel,
        Never
    > {
        makeCallsCount += 1
        makeReceivedArguments = (paymentRequestDetails: paymentRequestDetails, delegate: delegate)
        makeReceivedInvocations.append((paymentRequestDetails: paymentRequestDetails, delegate: delegate))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(paymentRequestDetails, delegate)
    }

    // MARK: - makeCancelConfirmation

    internal private(set) var makeCancelConfirmationReceivedArguments: (
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    )?
    internal private(set) var makeCancelConfirmationReceivedInvocations: [(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    )] = []
    internal var makeCancelConfirmationReturnValue: InfoSheetViewModel!
    internal private(set) var makeCancelConfirmationCallsCount = 0
    internal var makeCancelConfirmationClosure: ((PaymentRequestDetails.RequestType, PaymentRequestDetailViewModelDelegate) -> InfoSheetViewModel)?
    internal var makeCancelConfirmationCalled: Bool {
        makeCancelConfirmationCallsCount > 0
    }

    internal func makeCancelConfirmation(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> InfoSheetViewModel {
        makeCancelConfirmationCallsCount += 1
        makeCancelConfirmationReceivedArguments = (requestType: requestType, delegate: delegate)
        makeCancelConfirmationReceivedInvocations.append((requestType: requestType, delegate: delegate))
        guard let makeCancelConfirmationClosure else {
            return makeCancelConfirmationReturnValue
        }
        return makeCancelConfirmationClosure(requestType, delegate)
    }

    // MARK: - makeMarkAsPaidConfirmation

    internal private(set) var makeMarkAsPaidConfirmationReceivedArguments: (
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    )?
    internal private(set) var makeMarkAsPaidConfirmationReceivedInvocations: [(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    )] = []
    internal var makeMarkAsPaidConfirmationReturnValue: InfoSheetViewModel!
    internal private(set) var makeMarkAsPaidConfirmationCallsCount = 0
    internal var makeMarkAsPaidConfirmationClosure: ((PaymentRequestDetails.RequestType, PaymentRequestDetailViewModelDelegate) -> InfoSheetViewModel)?
    internal var makeMarkAsPaidConfirmationCalled: Bool {
        makeMarkAsPaidConfirmationCallsCount > 0
    }

    internal func makeMarkAsPaidConfirmation(
        requestType: PaymentRequestDetails.RequestType,
        delegate: PaymentRequestDetailViewModelDelegate
    ) -> InfoSheetViewModel {
        makeMarkAsPaidConfirmationCallsCount += 1
        makeMarkAsPaidConfirmationReceivedArguments = (requestType: requestType, delegate: delegate)
        makeMarkAsPaidConfirmationReceivedInvocations.append((requestType: requestType, delegate: delegate))
        guard let makeMarkAsPaidConfirmationClosure else {
            return makeMarkAsPaidConfirmationReturnValue
        }
        return makeMarkAsPaidConfirmationClosure(requestType, delegate)
    }
}

internal final class PaymentRequestListUpdaterMock: PaymentRequestListUpdater {
    // MARK: - requestStatusUpdated

    internal private(set) var requestStatusUpdatedCallsCount = 0
    internal var requestStatusUpdatedClosure: (() -> Void)?
    internal var requestStatusUpdatedCalled: Bool {
        requestStatusUpdatedCallsCount > 0
    }

    internal func requestStatusUpdated() {
        requestStatusUpdatedCallsCount += 1
        requestStatusUpdatedClosure?()
    }

    // MARK: - invoiceRequestCreated

    internal private(set) var invoiceRequestCreatedCallsCount = 0
    internal var invoiceRequestCreatedClosure: (() -> Void)?
    internal var invoiceRequestCreatedCalled: Bool {
        invoiceRequestCreatedCallsCount > 0
    }

    internal func invoiceRequestCreated() {
        invoiceRequestCreatedCallsCount += 1
        invoiceRequestCreatedClosure?()
    }
}

internal final class PaymentRequestOnboardingPresenterMock: PaymentRequestOnboardingPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentRequestOnboardingView?
    internal private(set) var startReceivedInvocations: [PaymentRequestOnboardingView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentRequestOnboardingView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentRequestOnboardingView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismissTapped

    internal private(set) var dismissTappedCallsCount = 0
    internal var dismissTappedClosure: (() -> Void)?
    internal var dismissTappedCalled: Bool {
        dismissTappedCallsCount > 0
    }

    internal func dismissTapped() {
        dismissTappedCallsCount += 1
        dismissTappedClosure?()
    }
}

internal final class PaymentRequestOnboardingRoutingDelegateMock: PaymentRequestOnboardingRoutingDelegate {
    // MARK: - moveToNextStepAfterOnboarding

    internal private(set) var moveToNextStepAfterOnboardingReceivedIsOnboardingRequired: Bool?
    internal private(set) var moveToNextStepAfterOnboardingReceivedInvocations: [Bool] = []
    internal private(set) var moveToNextStepAfterOnboardingCallsCount = 0
    internal var moveToNextStepAfterOnboardingClosure: ((Bool) -> Void)?
    internal var moveToNextStepAfterOnboardingCalled: Bool {
        moveToNextStepAfterOnboardingCallsCount > 0
    }

    internal func moveToNextStepAfterOnboarding(isOnboardingRequired: Bool) {
        moveToNextStepAfterOnboardingCallsCount += 1
        moveToNextStepAfterOnboardingReceivedIsOnboardingRequired = isOnboardingRequired
        moveToNextStepAfterOnboardingReceivedInvocations.append(isOnboardingRequired)
        moveToNextStepAfterOnboardingClosure?(isOnboardingRequired)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PaymentRequestOnboardingViewMock: PaymentRequestOnboardingView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentRequestOnboardingViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentRequestOnboardingViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentRequestOnboardingViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentRequestOnboardingViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class PaymentRequestQRSharingPresenterMock: PaymentRequestQRSharingPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentRequestQRSharingView?
    internal private(set) var startReceivedInvocations: [PaymentRequestQRSharingView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentRequestQRSharingView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentRequestQRSharingView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class PaymentRequestQRSharingViewMock: PaymentRequestQRSharingView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentRequestQRSharingViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentRequestQRSharingViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentRequestQRSharingViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentRequestQRSharingViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class PaymentRequestsListPresenterMock: PaymentRequestsListPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: PaymentRequestsListView?
    internal private(set) var startReceivedInvocations: [PaymentRequestsListView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((PaymentRequestsListView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: PaymentRequestsListView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - rowTapped

    internal private(set) var rowTappedReceivedId: String?
    internal private(set) var rowTappedReceivedInvocations: [String] = []
    internal private(set) var rowTappedCallsCount = 0
    internal var rowTappedClosure: ((String) -> Void)?
    internal var rowTappedCalled: Bool {
        rowTappedCallsCount > 0
    }

    internal func rowTapped(id: String) {
        rowTappedCallsCount += 1
        rowTappedReceivedId = id
        rowTappedReceivedInvocations.append(id)
        rowTappedClosure?(id)
    }

    // MARK: - prefetch

    internal private(set) var prefetchReceivedId: String?
    internal private(set) var prefetchReceivedInvocations: [String] = []
    internal private(set) var prefetchCallsCount = 0
    internal var prefetchClosure: ((String) -> Void)?
    internal var prefetchCalled: Bool {
        prefetchCallsCount > 0
    }

    internal func prefetch(id: String) {
        prefetchCallsCount += 1
        prefetchReceivedId = id
        prefetchReceivedInvocations.append(id)
        prefetchClosure?(id)
    }

    // MARK: - refresh

    internal private(set) var refreshCallsCount = 0
    internal var refreshClosure: (() -> Void)?
    internal var refreshCalled: Bool {
        refreshCallsCount > 0
    }

    internal func refresh() {
        refreshCallsCount += 1
        refreshClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class PaymentRequestsListRouterMock: PaymentRequestsListRouter {
    // MARK: - showRequestDetail

    internal private(set) var showRequestDetailReceivedArguments: (
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    )?
    internal private(set) var showRequestDetailReceivedInvocations: [(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    )] = []
    internal private(set) var showRequestDetailCallsCount = 0
    internal var showRequestDetailClosure: ((PaymentRequestId, Profile, PaymentRequestListUpdater) -> Void)?
    internal var showRequestDetailCalled: Bool {
        showRequestDetailCallsCount > 0
    }

    internal func showRequestDetail(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    ) {
        showRequestDetailCallsCount += 1
        showRequestDetailReceivedArguments = (
            paymentRequestId: paymentRequestId,
            profile: profile,
            listUpdateDelegate: listUpdateDelegate
        )
        showRequestDetailReceivedInvocations.append((
            paymentRequestId: paymentRequestId,
            profile: profile,
            listUpdateDelegate: listUpdateDelegate
        ))
        showRequestDetailClosure?(paymentRequestId, profile, listUpdateDelegate)
    }

    // MARK: - showNewRequestFlow

    internal private(set) var showNewRequestFlowReceivedArguments: (
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    )?
    internal private(set) var showNewRequestFlowReceivedInvocations: [(
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    )] = []
    internal private(set) var showNewRequestFlowCallsCount = 0
    internal var showNewRequestFlowClosure: ((Profile, PaymentRequestListUpdater) -> Void)?
    internal var showNewRequestFlowCalled: Bool {
        showNewRequestFlowCallsCount > 0
    }

    internal func showNewRequestFlow(profile: Profile, listUpdateDelegate: PaymentRequestListUpdater) {
        showNewRequestFlowCallsCount += 1
        showNewRequestFlowReceivedArguments = (profile: profile, listUpdateDelegate: listUpdateDelegate)
        showNewRequestFlowReceivedInvocations.append((profile: profile, listUpdateDelegate: listUpdateDelegate))
        showNewRequestFlowClosure?(profile, listUpdateDelegate)
    }

    // MARK: - showCreateInvoiceOnWeb

    internal private(set) var showCreateInvoiceOnWebReceivedArguments: (
        profileId: ProfileId,
        listUpdateDelegate: PaymentRequestListUpdater
    )?
    internal private(set) var showCreateInvoiceOnWebReceivedInvocations: [(
        profileId: ProfileId,
        listUpdateDelegate: PaymentRequestListUpdater
    )] = []
    internal private(set) var showCreateInvoiceOnWebCallsCount = 0
    internal var showCreateInvoiceOnWebClosure: ((ProfileId, PaymentRequestListUpdater) -> Void)?
    internal var showCreateInvoiceOnWebCalled: Bool {
        showCreateInvoiceOnWebCallsCount > 0
    }

    internal func showCreateInvoiceOnWeb(profileId: ProfileId, listUpdateDelegate: PaymentRequestListUpdater) {
        showCreateInvoiceOnWebCallsCount += 1
        showCreateInvoiceOnWebReceivedArguments = (profileId: profileId, listUpdateDelegate: listUpdateDelegate)
        showCreateInvoiceOnWebReceivedInvocations.append((profileId: profileId, listUpdateDelegate: listUpdateDelegate))
        showCreateInvoiceOnWebClosure?(profileId, listUpdateDelegate)
    }

    // MARK: - showMethodManagementOnWeb

    internal private(set) var showMethodManagementOnWebReceivedProfileId: ProfileId?
    internal private(set) var showMethodManagementOnWebReceivedInvocations: [ProfileId] = []
    internal private(set) var showMethodManagementOnWebCallsCount = 0
    internal var showMethodManagementOnWebClosure: ((ProfileId) -> Void)?
    internal var showMethodManagementOnWebCalled: Bool {
        showMethodManagementOnWebCallsCount > 0
    }

    internal func showMethodManagementOnWeb(profileId: ProfileId) {
        showMethodManagementOnWebCallsCount += 1
        showMethodManagementOnWebReceivedProfileId = profileId
        showMethodManagementOnWebReceivedInvocations.append(profileId)
        showMethodManagementOnWebClosure?(profileId)
    }

    // MARK: - showHelpArticle

    internal private(set) var showHelpArticleReceivedArticleId: HelpCenterArticleId?
    internal private(set) var showHelpArticleReceivedInvocations: [HelpCenterArticleId] = []
    internal private(set) var showHelpArticleCallsCount = 0
    internal var showHelpArticleClosure: ((HelpCenterArticleId) -> Void)?
    internal var showHelpArticleCalled: Bool {
        showHelpArticleCallsCount > 0
    }

    internal func showHelpArticle(articleId: HelpCenterArticleId) {
        showHelpArticleCallsCount += 1
        showHelpArticleReceivedArticleId = articleId
        showHelpArticleReceivedInvocations.append(articleId)
        showHelpArticleClosure?(articleId)
    }
}

internal final class PaymentRequestsListViewMock: PaymentRequestsListView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: PaymentRequestsListViewModel?
    internal private(set) var configureReceivedInvocations: [PaymentRequestsListViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((PaymentRequestsListViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: PaymentRequestsListViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showNewSections

    internal private(set) var showNewSectionsReceivedNewSections: [PaymentRequestsListViewModel.PaymentRequests.Section]?
    internal private(set) var showNewSectionsReceivedInvocations: [[PaymentRequestsListViewModel.PaymentRequests.Section]] = []
    internal private(set) var showNewSectionsCallsCount = 0
    internal var showNewSectionsClosure: (([PaymentRequestsListViewModel.PaymentRequests.Section]) -> Void)?
    internal var showNewSectionsCalled: Bool {
        showNewSectionsCallsCount > 0
    }

    internal func showNewSections(_ newSections: [PaymentRequestsListViewModel.PaymentRequests.Section]) {
        showNewSectionsCallsCount += 1
        showNewSectionsReceivedNewSections = newSections
        showNewSectionsReceivedInvocations.append(newSections)
        showNewSectionsClosure?(newSections)
    }

    // MARK: - showRadioOptions

    internal private(set) var showRadioOptionsReceivedViewModel: PaymentRequestsListRadioOptionsViewModel?
    internal private(set) var showRadioOptionsReceivedInvocations: [PaymentRequestsListRadioOptionsViewModel] = []
    internal private(set) var showRadioOptionsCallsCount = 0
    internal var showRadioOptionsClosure: ((PaymentRequestsListRadioOptionsViewModel) -> Void)?
    internal var showRadioOptionsCalled: Bool {
        showRadioOptionsCallsCount > 0
    }

    internal func showRadioOptions(viewModel: PaymentRequestsListRadioOptionsViewModel) {
        showRadioOptionsCallsCount += 1
        showRadioOptionsReceivedViewModel = viewModel
        showRadioOptionsReceivedInvocations.append(viewModel)
        showRadioOptionsClosure?(viewModel)
    }

    // MARK: - updateRadioOptions

    internal private(set) var updateRadioOptionsReceivedViewModel: PaymentRequestsListRadioOptionsViewModel?
    internal private(set) var updateRadioOptionsReceivedInvocations: [PaymentRequestsListRadioOptionsViewModel] = []
    internal private(set) var updateRadioOptionsCallsCount = 0
    internal var updateRadioOptionsClosure: ((PaymentRequestsListRadioOptionsViewModel) -> Void)?
    internal var updateRadioOptionsCalled: Bool {
        updateRadioOptionsCallsCount > 0
    }

    internal func updateRadioOptions(viewModel: PaymentRequestsListRadioOptionsViewModel) {
        updateRadioOptionsCallsCount += 1
        updateRadioOptionsReceivedViewModel = viewModel
        updateRadioOptionsReceivedInvocations.append(viewModel)
        updateRadioOptionsClosure?(viewModel)
    }

    // MARK: - dismissRadioOptions

    internal private(set) var dismissRadioOptionsCallsCount = 0
    internal var dismissRadioOptionsClosure: (() -> Void)?
    internal var dismissRadioOptionsCalled: Bool {
        dismissRadioOptionsCallsCount > 0
    }

    internal func dismissRadioOptions() {
        dismissRadioOptionsCallsCount += 1
        dismissRadioOptionsClosure?()
    }

    // MARK: - showLoading

    internal private(set) var showLoadingCallsCount = 0
    internal var showLoadingClosure: (() -> Void)?
    internal var showLoadingCalled: Bool {
        showLoadingCallsCount > 0
    }

    internal func showLoading() {
        showLoadingCallsCount += 1
        showLoadingClosure?()
    }

    // MARK: - hideLoading

    internal private(set) var hideLoadingCallsCount = 0
    internal var hideLoadingClosure: (() -> Void)?
    internal var hideLoadingCalled: Bool {
        hideLoadingCallsCount > 0
    }

    internal func hideLoading() {
        hideLoadingCallsCount += 1
        hideLoadingClosure?()
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }
}

internal final class PaymentRequestsListViewModelDelegateMock: PaymentRequestsListViewModelDelegate {
    // MARK: - segmentedControlSelected

    internal private(set) var segmentedControlSelectedReceivedIndex: Int?
    internal private(set) var segmentedControlSelectedReceivedInvocations: [Int] = []
    internal private(set) var segmentedControlSelectedCallsCount = 0
    internal var segmentedControlSelectedClosure: ((Int) -> Void)?
    internal var segmentedControlSelectedCalled: Bool {
        segmentedControlSelectedCallsCount > 0
    }

    internal func segmentedControlSelected(at index: Int) {
        segmentedControlSelectedCallsCount += 1
        segmentedControlSelectedReceivedIndex = index
        segmentedControlSelectedReceivedInvocations.append(index)
        segmentedControlSelectedClosure?(index)
    }

    // MARK: - sortTapped

    internal private(set) var sortTappedCallsCount = 0
    internal var sortTappedClosure: (() -> Void)?
    internal var sortTappedCalled: Bool {
        sortTappedCallsCount > 0
    }

    internal func sortTapped() {
        sortTappedCallsCount += 1
        sortTappedClosure?()
    }

    // MARK: - fetchAvatarModel

    internal private(set) var fetchAvatarModelReceivedArguments: (
        urlString: String,
        badge: UIImage?,
        fallbackModel: ContactsKit.AvatarModel
    )?
    internal private(set) var fetchAvatarModelReceivedInvocations: [(
        urlString: String,
        badge: UIImage?,
        fallbackModel: ContactsKit.AvatarModel
    )] = []
    internal var fetchAvatarModelReturnValue: AnyPublisher<ContactsKit.AvatarModel, Never>!
    internal private(set) var fetchAvatarModelCallsCount = 0
    internal var fetchAvatarModelClosure: ((String, UIImage?, ContactsKit.AvatarModel) -> AnyPublisher<
        ContactsKit.AvatarModel,
        Never
    >)?
    internal var fetchAvatarModelCalled: Bool {
        fetchAvatarModelCallsCount > 0
    }

    internal func fetchAvatarModel(urlString: String, badge: UIImage?, fallbackModel: ContactsKit.AvatarModel) -> AnyPublisher<
        ContactsKit.AvatarModel,
        Never
    > {
        fetchAvatarModelCallsCount += 1
        fetchAvatarModelReceivedArguments = (urlString: urlString, badge: badge, fallbackModel: fallbackModel)
        fetchAvatarModelReceivedInvocations.append((urlString: urlString, badge: badge, fallbackModel: fallbackModel))
        guard let fetchAvatarModelClosure else {
            return fetchAvatarModelReturnValue
        }
        return fetchAvatarModelClosure(urlString, badge, fallbackModel)
    }

    // MARK: - sortingOptionTapped

    internal private(set) var sortingOptionTappedReceivedIndex: Int?
    internal private(set) var sortingOptionTappedReceivedInvocations: [Int] = []
    internal private(set) var sortingOptionTappedCallsCount = 0
    internal var sortingOptionTappedClosure: ((Int) -> Void)?
    internal var sortingOptionTappedCalled: Bool {
        sortingOptionTappedCallsCount > 0
    }

    internal func sortingOptionTapped(at index: Int) {
        sortingOptionTappedCallsCount += 1
        sortingOptionTappedReceivedIndex = index
        sortingOptionTappedReceivedInvocations.append(index)
        sortingOptionTappedClosure?(index)
    }

    // MARK: - applySortingAction

    internal private(set) var applySortingActionCallsCount = 0
    internal var applySortingActionClosure: (() -> Void)?
    internal var applySortingActionCalled: Bool {
        applySortingActionCallsCount > 0
    }

    internal func applySortingAction() {
        applySortingActionCallsCount += 1
        applySortingActionClosure?()
    }

    // MARK: - createRequestPaymentTapped

    internal private(set) var createRequestPaymentTappedCallsCount = 0
    internal var createRequestPaymentTappedClosure: (() -> Void)?
    internal var createRequestPaymentTappedCalled: Bool {
        createRequestPaymentTappedCallsCount > 0
    }

    internal func createRequestPaymentTapped() {
        createRequestPaymentTappedCallsCount += 1
        createRequestPaymentTappedClosure?()
    }

    // MARK: - openSettingsTapped

    internal private(set) var openSettingsTappedCallsCount = 0
    internal var openSettingsTappedClosure: (() -> Void)?
    internal var openSettingsTappedCalled: Bool {
        openSettingsTappedCallsCount > 0
    }

    internal func openSettingsTapped() {
        openSettingsTappedCallsCount += 1
        openSettingsTappedClosure?()
    }

    // MARK: - learnMoreTapped

    internal private(set) var learnMoreTappedCallsCount = 0
    internal var learnMoreTappedClosure: (() -> Void)?
    internal var learnMoreTappedCalled: Bool {
        learnMoreTappedCallsCount > 0
    }

    internal func learnMoreTapped() {
        learnMoreTappedCallsCount += 1
        learnMoreTappedClosure?()
    }
}

internal final class PaymentRequestsListViewModelFactoryMock: PaymentRequestsListViewModelFactory {
    // MARK: - makeGlobalEmptyState

    internal private(set) var makeGlobalEmptyStateReceivedArguments: (
        supportedPaymentRequestType: SupportedPaymentRequestType,
        delegate: PaymentRequestsListViewModelDelegate
    )?
    internal private(set) var makeGlobalEmptyStateReceivedInvocations: [(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        delegate: PaymentRequestsListViewModelDelegate
    )] = []
    internal var makeGlobalEmptyStateReturnValue: PaymentRequestsListViewModel!
    internal private(set) var makeGlobalEmptyStateCallsCount = 0
    internal var makeGlobalEmptyStateClosure: ((SupportedPaymentRequestType, PaymentRequestsListViewModelDelegate) -> PaymentRequestsListViewModel)?
    internal var makeGlobalEmptyStateCalled: Bool {
        makeGlobalEmptyStateCallsCount > 0
    }

    internal func makeGlobalEmptyState(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        makeGlobalEmptyStateCallsCount += 1
        makeGlobalEmptyStateReceivedArguments = (supportedPaymentRequestType: supportedPaymentRequestType, delegate: delegate)
        makeGlobalEmptyStateReceivedInvocations.append((
            supportedPaymentRequestType: supportedPaymentRequestType,
            delegate: delegate
        ))
        guard let makeGlobalEmptyStateClosure else {
            return makeGlobalEmptyStateReturnValue
        }
        return makeGlobalEmptyStateClosure(supportedPaymentRequestType, delegate)
    }

    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile,
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    )?
    internal private(set) var makeReceivedInvocations: [(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile,
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    )] = []
    internal var makeReturnValue: PaymentRequestsListViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((
        SupportedPaymentRequestType,
        Profile,
        PaymentRequestSummaryList,
        PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        profile: Profile,
        paymentRequestSummaryList: PaymentRequestSummaryList,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (
            supportedPaymentRequestType: supportedPaymentRequestType,
            profile: profile,
            paymentRequestSummaryList: paymentRequestSummaryList,
            delegate: delegate
        )
        makeReceivedInvocations.append((
            supportedPaymentRequestType: supportedPaymentRequestType,
            profile: profile,
            paymentRequestSummaryList: paymentRequestSummaryList,
            delegate: delegate
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(supportedPaymentRequestType, profile, paymentRequestSummaryList, delegate)
    }

    // MARK: - makeSectionViewModels

    internal private(set) var makeSectionViewModelsReceivedArguments: (
        paymentRequestSummaryList: PaymentRequestSummaryList,
        groups: [PaymentRequestSummaries.Group],
        delegate: PaymentRequestsListViewModelDelegate
    )?
    internal private(set) var makeSectionViewModelsReceivedInvocations: [(
        paymentRequestSummaryList: PaymentRequestSummaryList,
        groups: [PaymentRequestSummaries.Group],
        delegate: PaymentRequestsListViewModelDelegate
    )] = []
    internal var makeSectionViewModelsReturnValue: [PaymentRequestsListViewModel.PaymentRequests.Section]!
    internal private(set) var makeSectionViewModelsCallsCount = 0
    internal var makeSectionViewModelsClosure: ((
        PaymentRequestSummaryList,
        [PaymentRequestSummaries.Group],
        PaymentRequestsListViewModelDelegate
    ) -> [PaymentRequestsListViewModel.PaymentRequests.Section])?
    internal var makeSectionViewModelsCalled: Bool {
        makeSectionViewModelsCallsCount > 0
    }

    internal func makeSectionViewModels(
        paymentRequestSummaryList: PaymentRequestSummaryList,
        groups: [PaymentRequestSummaries.Group],
        delegate: PaymentRequestsListViewModelDelegate
    ) -> [PaymentRequestsListViewModel.PaymentRequests.Section] {
        makeSectionViewModelsCallsCount += 1
        makeSectionViewModelsReceivedArguments = (
            paymentRequestSummaryList: paymentRequestSummaryList,
            groups: groups,
            delegate: delegate
        )
        makeSectionViewModelsReceivedInvocations.append((
            paymentRequestSummaryList: paymentRequestSummaryList,
            groups: groups,
            delegate: delegate
        ))
        guard let makeSectionViewModelsClosure else {
            return makeSectionViewModelsReturnValue
        }
        return makeSectionViewModelsClosure(paymentRequestSummaryList, groups, delegate)
    }

    // MARK: - makeRadioOptionsViewModel

    internal private(set) var makeRadioOptionsViewModelReceivedArguments: (
        sortingState: PaymentRequestSummaryList.SortingState,
        delegate: PaymentRequestsListViewModelDelegate
    )?
    internal private(set) var makeRadioOptionsViewModelReceivedInvocations: [(
        sortingState: PaymentRequestSummaryList.SortingState,
        delegate: PaymentRequestsListViewModelDelegate
    )] = []
    internal var makeRadioOptionsViewModelReturnValue: PaymentRequestsListRadioOptionsViewModel!
    internal private(set) var makeRadioOptionsViewModelCallsCount = 0
    internal var makeRadioOptionsViewModelClosure: ((PaymentRequestSummaryList.SortingState, PaymentRequestsListViewModelDelegate) -> PaymentRequestsListRadioOptionsViewModel)?
    internal var makeRadioOptionsViewModelCalled: Bool {
        makeRadioOptionsViewModelCallsCount > 0
    }

    internal func makeRadioOptionsViewModel(
        sortingState: PaymentRequestSummaryList.SortingState,
        delegate: PaymentRequestsListViewModelDelegate
    ) -> PaymentRequestsListRadioOptionsViewModel {
        makeRadioOptionsViewModelCallsCount += 1
        makeRadioOptionsViewModelReceivedArguments = (sortingState: sortingState, delegate: delegate)
        makeRadioOptionsViewModelReceivedInvocations.append((sortingState: sortingState, delegate: delegate))
        guard let makeRadioOptionsViewModelClosure else {
            return makeRadioOptionsViewModelReturnValue
        }
        return makeRadioOptionsViewModelClosure(sortingState, delegate)
    }
}

internal final class QRDownloadPresenterMock: QRDownloadPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: QRDownloadView?
    internal private(set) var startReceivedInvocations: [QRDownloadView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((QRDownloadView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: QRDownloadView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class QRDownloadViewMock: QRDownloadView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: QRDownloadViewModel?
    internal private(set) var configureReceivedInvocations: [QRDownloadViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((QRDownloadViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: QRDownloadViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class QRDownloadViewControllerFactoryMock: QRDownloadViewControllerFactory {
    // MARK: - makeDownloadBottomSheet

    internal private(set) var makeDownloadBottomSheetReceivedArguments: (router: QRDownloadRouter, image: UIImage)?
    internal private(set) var makeDownloadBottomSheetReceivedInvocations: [(router: QRDownloadRouter, image: UIImage)] = []
    internal var makeDownloadBottomSheetReturnValue: UIViewController!
    internal private(set) var makeDownloadBottomSheetCallsCount = 0
    internal var makeDownloadBottomSheetClosure: ((QRDownloadRouter, UIImage) -> UIViewController)?
    internal var makeDownloadBottomSheetCalled: Bool {
        makeDownloadBottomSheetCallsCount > 0
    }

    internal func makeDownloadBottomSheet(router: QRDownloadRouter, image: UIImage) -> UIViewController {
        makeDownloadBottomSheetCallsCount += 1
        makeDownloadBottomSheetReceivedArguments = (router: router, image: image)
        makeDownloadBottomSheetReceivedInvocations.append((router: router, image: image))
        guard let makeDownloadBottomSheetClosure else {
            return makeDownloadBottomSheetReturnValue
        }
        return makeDownloadBottomSheetClosure(router, image)
    }
}

internal final class QuickpayPayerPresenterMock: QuickpayPayerPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: QuickpayPayerView?
    internal private(set) var startReceivedInvocations: [QuickpayPayerView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((QuickpayPayerView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: QuickpayPayerView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - moneyValueUpdated

    internal private(set) var moneyValueUpdatedReceivedValue: String?
    internal private(set) var moneyValueUpdatedReceivedInvocations: [String?] = []
    internal private(set) var moneyValueUpdatedCallsCount = 0
    internal var moneyValueUpdatedClosure: ((String?) -> Void)?
    internal var moneyValueUpdatedCalled: Bool {
        moneyValueUpdatedCallsCount > 0
    }

    internal func moneyValueUpdated(_ value: String?) {
        moneyValueUpdatedCallsCount += 1
        moneyValueUpdatedReceivedValue = value
        moneyValueUpdatedReceivedInvocations.append(value)
        moneyValueUpdatedClosure?(value)
    }

    // MARK: - moneyInputCurrencyTapped

    internal private(set) var moneyInputCurrencyTappedCallsCount = 0
    internal var moneyInputCurrencyTappedClosure: (() -> Void)?
    internal var moneyInputCurrencyTappedCalled: Bool {
        moneyInputCurrencyTappedCallsCount > 0
    }

    internal func moneyInputCurrencyTapped() {
        moneyInputCurrencyTappedCallsCount += 1
        moneyInputCurrencyTappedClosure?()
    }

    // MARK: - descriptionValueUpdated

    internal private(set) var descriptionValueUpdatedReceived_text: String?
    internal private(set) var descriptionValueUpdatedReceivedInvocations: [String?] = []
    internal private(set) var descriptionValueUpdatedCallsCount = 0
    internal var descriptionValueUpdatedClosure: ((String?) -> Void)?
    internal var descriptionValueUpdatedCalled: Bool {
        descriptionValueUpdatedCallsCount > 0
    }

    internal func descriptionValueUpdated(_text: String?) {
        descriptionValueUpdatedCallsCount += 1
        descriptionValueUpdatedReceived_text = _text
        descriptionValueUpdatedReceivedInvocations.append(_text)
        descriptionValueUpdatedClosure?(_text)
    }

    // MARK: - continueTapped

    internal private(set) var continueTappedReceivedInputs: QuickpayPayerInputs?
    internal private(set) var continueTappedReceivedInvocations: [QuickpayPayerInputs] = []
    internal private(set) var continueTappedCallsCount = 0
    internal var continueTappedClosure: ((QuickpayPayerInputs) -> Void)?
    internal var continueTappedCalled: Bool {
        continueTappedCallsCount > 0
    }

    internal func continueTapped(inputs: QuickpayPayerInputs) {
        continueTappedCallsCount += 1
        continueTappedReceivedInputs = inputs
        continueTappedReceivedInvocations.append(inputs)
        continueTappedClosure?(inputs)
    }
}

internal final class QuickpayPayerRouterMock: QuickpayPayerRouter {
    // MARK: - showCurrencySelector

    internal private(set) var showCurrencySelectorReceivedArguments: (
        activeCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: (CurrencyCode) -> Void
    )?
    internal private(set) var showCurrencySelectorReceivedInvocations: [(
        activeCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: (CurrencyCode) -> Void
    )] = []
    internal private(set) var showCurrencySelectorCallsCount = 0
    internal var showCurrencySelectorClosure: (([CurrencyCode], CurrencyCode?, @escaping (CurrencyCode) -> Void) -> Void)?
    internal var showCurrencySelectorCalled: Bool {
        showCurrencySelectorCallsCount > 0
    }

    internal func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    ) {
        showCurrencySelectorCallsCount += 1
        showCurrencySelectorReceivedArguments = (
            activeCurrencies: activeCurrencies,
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected
        )
        showCurrencySelectorReceivedInvocations.append((
            activeCurrencies: activeCurrencies,
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected
        ))
        showCurrencySelectorClosure?(activeCurrencies, selectedCurrency, onCurrencySelected)
    }

    // MARK: - navigateToPayWithWise

    internal private(set) var navigateToPayWithWiseReceivedPayerData: QuickpayPayerData?
    internal private(set) var navigateToPayWithWiseReceivedInvocations: [QuickpayPayerData] = []
    internal private(set) var navigateToPayWithWiseCallsCount = 0
    internal var navigateToPayWithWiseClosure: ((QuickpayPayerData) -> Void)?
    internal var navigateToPayWithWiseCalled: Bool {
        navigateToPayWithWiseCallsCount > 0
    }

    internal func navigateToPayWithWise(payerData: QuickpayPayerData) {
        navigateToPayWithWiseCallsCount += 1
        navigateToPayWithWiseReceivedPayerData = payerData
        navigateToPayWithWiseReceivedInvocations.append(payerData)
        navigateToPayWithWiseClosure?(payerData)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class QuickpayPayerViewMock: LoadingPresentableMock, QuickpayPayerView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: QuickpayPayerViewModel?
    internal private(set) var configureReceivedInvocations: [QuickpayPayerViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((QuickpayPayerViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: QuickpayPayerViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - configureError

    internal private(set) var configureErrorReceivedViewModel: ErrorViewModel?
    internal private(set) var configureErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureErrorCallsCount = 0
    internal var configureErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureErrorCalled: Bool {
        configureErrorCallsCount > 0
    }

    internal func configureError(with viewModel: ErrorViewModel) {
        configureErrorCallsCount += 1
        configureErrorReceivedViewModel = viewModel
        configureErrorReceivedInvocations.append(viewModel)
        configureErrorClosure?(viewModel)
    }

    // MARK: - updateSelectedCurrency

    internal private(set) var updateSelectedCurrencyReceivedCurrency: CurrencyCode?
    internal private(set) var updateSelectedCurrencyReceivedInvocations: [CurrencyCode] = []
    internal private(set) var updateSelectedCurrencyCallsCount = 0
    internal var updateSelectedCurrencyClosure: ((CurrencyCode) -> Void)?
    internal var updateSelectedCurrencyCalled: Bool {
        updateSelectedCurrencyCallsCount > 0
    }

    internal func updateSelectedCurrency(currency: CurrencyCode) {
        updateSelectedCurrencyCallsCount += 1
        updateSelectedCurrencyReceivedCurrency = currency
        updateSelectedCurrencyReceivedInvocations.append(currency)
        updateSelectedCurrencyClosure?(currency)
    }

    // MARK: - moneyInputError

    internal private(set) var moneyInputErrorReceivedMessage: String?
    internal private(set) var moneyInputErrorReceivedInvocations: [String] = []
    internal private(set) var moneyInputErrorCallsCount = 0
    internal var moneyInputErrorClosure: ((String) -> Void)?
    internal var moneyInputErrorCalled: Bool {
        moneyInputErrorCallsCount > 0
    }

    internal func moneyInputError(_ message: String) {
        moneyInputErrorCallsCount += 1
        moneyInputErrorReceivedMessage = message
        moneyInputErrorReceivedInvocations.append(message)
        moneyInputErrorClosure?(message)
    }

    // MARK: - descriptionInputError

    internal private(set) var descriptionInputErrorReceivedMessage: String?
    internal private(set) var descriptionInputErrorReceivedInvocations: [String] = []
    internal private(set) var descriptionInputErrorCallsCount = 0
    internal var descriptionInputErrorClosure: ((String) -> Void)?
    internal var descriptionInputErrorCalled: Bool {
        descriptionInputErrorCallsCount > 0
    }

    internal func descriptionInputError(_ message: String) {
        descriptionInputErrorCallsCount += 1
        descriptionInputErrorReceivedMessage = message
        descriptionInputErrorReceivedInvocations.append(message)
        descriptionInputErrorClosure?(message)
    }

    // MARK: - footerButtonState

    internal private(set) var footerButtonStateReceivedEnabled: Bool?
    internal private(set) var footerButtonStateReceivedInvocations: [Bool] = []
    internal private(set) var footerButtonStateCallsCount = 0
    internal var footerButtonStateClosure: ((Bool) -> Void)?
    internal var footerButtonStateCalled: Bool {
        footerButtonStateCallsCount > 0
    }

    internal func footerButtonState(enabled: Bool) {
        footerButtonStateCallsCount += 1
        footerButtonStateReceivedEnabled = enabled
        footerButtonStateReceivedInvocations.append(enabled)
        footerButtonStateClosure?(enabled)
    }
}

internal final class QuickpayPayerViewControllerFactoryMock: QuickpayPayerViewControllerFactory {
    // MARK: - makePayerBottomsheet

    internal private(set) var makePayerBottomsheetReceivedArguments: (
        profile: Profile,
        quickpay: String,
        payerInputs: QuickpayPayerInputs?,
        businessInfo: ContactSearch,
        router: QuickpayPayerRouter
    )?
    internal private(set) var makePayerBottomsheetReceivedInvocations: [(
        profile: Profile,
        quickpay: String,
        payerInputs: QuickpayPayerInputs?,
        businessInfo: ContactSearch,
        router: QuickpayPayerRouter
    )] = []
    internal var makePayerBottomsheetReturnValue: UIViewController!
    internal private(set) var makePayerBottomsheetCallsCount = 0
    internal var makePayerBottomsheetClosure: ((Profile, String, QuickpayPayerInputs?, ContactSearch, QuickpayPayerRouter) -> UIViewController)?
    internal var makePayerBottomsheetCalled: Bool {
        makePayerBottomsheetCallsCount > 0
    }

    internal func makePayerBottomsheet(
        profile: Profile,
        quickpay: String,
        payerInputs: QuickpayPayerInputs?,
        businessInfo: ContactSearch,
        router: QuickpayPayerRouter
    ) -> UIViewController {
        makePayerBottomsheetCallsCount += 1
        makePayerBottomsheetReceivedArguments = (
            profile: profile,
            quickpay: quickpay,
            payerInputs: payerInputs,
            businessInfo: businessInfo,
            router: router
        )
        makePayerBottomsheetReceivedInvocations.append((
            profile: profile,
            quickpay: quickpay,
            payerInputs: payerInputs,
            businessInfo: businessInfo,
            router: router
        ))
        guard let makePayerBottomsheetClosure else {
            return makePayerBottomsheetReturnValue
        }
        return makePayerBottomsheetClosure(profile, quickpay, payerInputs, businessInfo, router)
    }
}

internal final class QuickpayPresenterMock: QuickpayPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: QuickpayView?
    internal private(set) var startReceivedInvocations: [QuickpayView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((QuickpayView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: QuickpayView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class QuickpayRouterMock: QuickpayRouter {
    // MARK: - showIntroStory

    internal private(set) var showIntroStoryReceivedRoute: DeepLinkStoryRoute?
    internal private(set) var showIntroStoryReceivedInvocations: [DeepLinkStoryRoute] = []
    internal private(set) var showIntroStoryCallsCount = 0
    internal var showIntroStoryClosure: ((DeepLinkStoryRoute) -> Void)?
    internal var showIntroStoryCalled: Bool {
        showIntroStoryCallsCount > 0
    }

    internal func showIntroStory(route: DeepLinkStoryRoute) {
        showIntroStoryCallsCount += 1
        showIntroStoryReceivedRoute = route
        showIntroStoryReceivedInvocations.append(route)
        showIntroStoryClosure?(route)
    }

    // MARK: - showInPersonStory

    internal private(set) var showInPersonStoryCallsCount = 0
    internal var showInPersonStoryClosure: (() -> Void)?
    internal var showInPersonStoryCalled: Bool {
        showInPersonStoryCallsCount > 0
    }

    internal func showInPersonStory() {
        showInPersonStoryCallsCount += 1
        showInPersonStoryClosure?()
    }

    // MARK: - showManageQuickpay

    internal private(set) var showManageQuickpayReceivedNickname: String?
    internal private(set) var showManageQuickpayReceivedInvocations: [String?] = []
    internal private(set) var showManageQuickpayCallsCount = 0
    internal var showManageQuickpayClosure: ((String?) -> Void)?
    internal var showManageQuickpayCalled: Bool {
        showManageQuickpayCallsCount > 0
    }

    internal func showManageQuickpay(nickname: String?) {
        showManageQuickpayCallsCount += 1
        showManageQuickpayReceivedNickname = nickname
        showManageQuickpayReceivedInvocations.append(nickname)
        showManageQuickpayClosure?(nickname)
    }

    // MARK: - showDiscoverability

    internal private(set) var showDiscoverabilityReceivedNickname: String?
    internal private(set) var showDiscoverabilityReceivedInvocations: [String?] = []
    internal private(set) var showDiscoverabilityCallsCount = 0
    internal var showDiscoverabilityClosure: ((String?) -> Void)?
    internal var showDiscoverabilityCalled: Bool {
        showDiscoverabilityCallsCount > 0
    }

    internal func showDiscoverability(nickname: String?) {
        showDiscoverabilityCallsCount += 1
        showDiscoverabilityReceivedNickname = nickname
        showDiscoverabilityReceivedInvocations.append(nickname)
        showDiscoverabilityClosure?(nickname)
    }

    // MARK: - showPaymentMethodsOnWeb

    internal private(set) var showPaymentMethodsOnWebCallsCount = 0
    internal var showPaymentMethodsOnWebClosure: (() -> Void)?
    internal var showPaymentMethodsOnWebCalled: Bool {
        showPaymentMethodsOnWebCallsCount > 0
    }

    internal func showPaymentMethodsOnWeb() {
        showPaymentMethodsOnWebCallsCount += 1
        showPaymentMethodsOnWebClosure?()
    }

    // MARK: - showHelpArticle

    internal private(set) var showHelpArticleReceivedUrl: String?
    internal private(set) var showHelpArticleReceivedInvocations: [String] = []
    internal private(set) var showHelpArticleCallsCount = 0
    internal var showHelpArticleClosure: ((String) -> Void)?
    internal var showHelpArticleCalled: Bool {
        showHelpArticleCallsCount > 0
    }

    internal func showHelpArticle(url: String) {
        showHelpArticleCallsCount += 1
        showHelpArticleReceivedUrl = url
        showHelpArticleReceivedInvocations.append(url)
        showHelpArticleClosure?(url)
    }

    // MARK: - startDownload

    internal private(set) var startDownloadReceivedImage: UIImage?
    internal private(set) var startDownloadReceivedInvocations: [UIImage] = []
    internal private(set) var startDownloadCallsCount = 0
    internal var startDownloadClosure: ((UIImage) -> Void)?
    internal var startDownloadCalled: Bool {
        startDownloadCallsCount > 0
    }

    internal func startDownload(image: UIImage) {
        startDownloadCallsCount += 1
        startDownloadReceivedImage = image
        startDownloadReceivedInvocations.append(image)
        startDownloadClosure?(image)
    }

    // MARK: - startAccountDetailsFlow

    internal private(set) var startAccountDetailsFlowReceivedHost: UIViewController?
    internal private(set) var startAccountDetailsFlowReceivedInvocations: [UIViewController] = []
    internal private(set) var startAccountDetailsFlowCallsCount = 0
    internal var startAccountDetailsFlowClosure: ((UIViewController) -> Void)?
    internal var startAccountDetailsFlowCalled: Bool {
        startAccountDetailsFlowCallsCount > 0
    }

    internal func startAccountDetailsFlow(host: UIViewController) {
        startAccountDetailsFlowCallsCount += 1
        startAccountDetailsFlowReceivedHost = host
        startAccountDetailsFlowReceivedInvocations.append(host)
        startAccountDetailsFlowClosure?(host)
    }

    // MARK: - personaliseTapped

    internal private(set) var personaliseTappedReceivedStatus: ShareableLinkStatus.Discoverability?
    internal private(set) var personaliseTappedReceivedInvocations: [ShareableLinkStatus.Discoverability] = []
    internal private(set) var personaliseTappedCallsCount = 0
    internal var personaliseTappedClosure: ((ShareableLinkStatus.Discoverability) -> Void)?
    internal var personaliseTappedCalled: Bool {
        personaliseTappedCallsCount > 0
    }

    internal func personaliseTapped(status: ShareableLinkStatus.Discoverability) {
        personaliseTappedCallsCount += 1
        personaliseTappedReceivedStatus = status
        personaliseTappedReceivedInvocations.append(status)
        personaliseTappedClosure?(status)
    }

    // MARK: - shareLinkTapped

    internal private(set) var shareLinkTappedReceivedLink: String?
    internal private(set) var shareLinkTappedReceivedInvocations: [String] = []
    internal private(set) var shareLinkTappedCallsCount = 0
    internal var shareLinkTappedClosure: ((String) -> Void)?
    internal var shareLinkTappedCalled: Bool {
        shareLinkTappedCallsCount > 0
    }

    internal func shareLinkTapped(link: String) {
        shareLinkTappedCallsCount += 1
        shareLinkTappedReceivedLink = link
        shareLinkTappedReceivedInvocations.append(link)
        shareLinkTappedClosure?(link)
    }

    // MARK: - dismiss

    internal private(set) var dismissReceivedIsShareableLinkDiscoverable: Bool?
    internal private(set) var dismissReceivedInvocations: [Bool] = []
    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: ((Bool) -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss(isShareableLinkDiscoverable: Bool) {
        dismissCallsCount += 1
        dismissReceivedIsShareableLinkDiscoverable = isShareableLinkDiscoverable
        dismissReceivedInvocations.append(isShareableLinkDiscoverable)
        dismissClosure?(isShareableLinkDiscoverable)
    }

    // MARK: - showFeedback

    internal private(set) var showFeedbackReceivedArguments: (
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: () -> Void
    )?
    internal private(set) var showFeedbackReceivedInvocations: [(
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: () -> Void
    )] = []
    internal private(set) var showFeedbackCallsCount = 0
    internal var showFeedbackClosure: ((FeedbackViewModel, FeedbackContext, @escaping () -> Void) -> Void)?
    internal var showFeedbackCalled: Bool {
        showFeedbackCallsCount > 0
    }

    internal func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping () -> Void) {
        showFeedbackCallsCount += 1
        showFeedbackReceivedArguments = (model: model, context: context, onSuccess: onSuccess)
        showFeedbackReceivedInvocations.append((model: model, context: context, onSuccess: onSuccess))
        showFeedbackClosure?(model, context, onSuccess)
    }

    // MARK: - showDynamicFormsMethodManagement

    internal private(set) var showDynamicFormsMethodManagementReceivedArguments: (
        dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    )?
    internal private(set) var showDynamicFormsMethodManagementReceivedInvocations: [(
        dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    )] = []
    internal private(set) var showDynamicFormsMethodManagementCallsCount = 0
    internal var showDynamicFormsMethodManagementClosure: (([PaymentMethodDynamicForm], PaymentMethodsDelegate?) -> Void)?
    internal var showDynamicFormsMethodManagementCalled: Bool {
        showDynamicFormsMethodManagementCallsCount > 0
    }

    internal func showDynamicFormsMethodManagement(_ dynamicForms: [PaymentMethodDynamicForm], delegate: PaymentMethodsDelegate?) {
        showDynamicFormsMethodManagementCallsCount += 1
        showDynamicFormsMethodManagementReceivedArguments = (dynamicForms: dynamicForms, delegate: delegate)
        showDynamicFormsMethodManagementReceivedInvocations.append((dynamicForms: dynamicForms, delegate: delegate))
        showDynamicFormsMethodManagementClosure?(dynamicForms, delegate)
    }
}

internal final class QuickpayShareableLinkStatusUpdaterMock: QuickpayShareableLinkStatusUpdater {
    // MARK: - updateShareableLinkStatus

    internal private(set) var updateShareableLinkStatusReceivedIsDiscoverable: Bool?
    internal private(set) var updateShareableLinkStatusReceivedInvocations: [Bool] = []
    internal private(set) var updateShareableLinkStatusCallsCount = 0
    internal var updateShareableLinkStatusClosure: ((Bool) -> Void)?
    internal var updateShareableLinkStatusCalled: Bool {
        updateShareableLinkStatusCallsCount > 0
    }

    internal func updateShareableLinkStatus(isDiscoverable: Bool) {
        updateShareableLinkStatusCallsCount += 1
        updateShareableLinkStatusReceivedIsDiscoverable = isDiscoverable
        updateShareableLinkStatusReceivedInvocations.append(isDiscoverable)
        updateShareableLinkStatusClosure?(isDiscoverable)
    }
}

internal final class QuickpayViewMock: QuickpayView {
    internal var traitCollection: UITraitCollection {
        get { underlyingTraitCollection }
        set(value) { underlyingTraitCollection = value }
    }

    private var underlyingTraitCollection: UITraitCollection!

    // MARK: - configure

    internal private(set) var configureReceivedViewModel: QuickpayViewModel?
    internal private(set) var configureReceivedInvocations: [QuickpayViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((QuickpayViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: QuickpayViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedErrorViewModel: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with errorViewModel: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedErrorViewModel = errorViewModel
        configureWithErrorReceivedInvocations.append(errorViewModel)
        configureWithErrorClosure?(errorViewModel)
    }

    // MARK: - showSnackbar

    internal private(set) var showSnackbarReceivedMessage: String?
    internal private(set) var showSnackbarReceivedInvocations: [String] = []
    internal private(set) var showSnackbarCallsCount = 0
    internal var showSnackbarClosure: ((String) -> Void)?
    internal var showSnackbarCalled: Bool {
        showSnackbarCallsCount > 0
    }

    internal func showSnackbar(message: String) {
        showSnackbarCallsCount += 1
        showSnackbarReceivedMessage = message
        showSnackbarReceivedInvocations.append(message)
        showSnackbarClosure?(message)
    }

    // MARK: - updateNudge

    internal private(set) var updateNudgeReceivedNudge: NudgeViewModel?
    internal private(set) var updateNudgeReceivedInvocations: [NudgeViewModel?] = []
    internal private(set) var updateNudgeCallsCount = 0
    internal var updateNudgeClosure: ((NudgeViewModel?) -> Void)?
    internal var updateNudgeCalled: Bool {
        updateNudgeCallsCount > 0
    }

    internal func updateNudge(_ nudge: NudgeViewModel?) {
        updateNudgeCallsCount += 1
        updateNudgeReceivedNudge = nudge
        updateNudgeReceivedInvocations.append(nudge)
        updateNudgeClosure?(nudge)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class QuickpayViewModelDelegateMock: QuickpayViewModelDelegate {
    // MARK: - showManageQuickpay

    internal private(set) var showManageQuickpayCallsCount = 0
    internal var showManageQuickpayClosure: (() -> Void)?
    internal var showManageQuickpayCalled: Bool {
        showManageQuickpayCallsCount > 0
    }

    internal func showManageQuickpay() {
        showManageQuickpayCallsCount += 1
        showManageQuickpayClosure?()
    }

    // MARK: - shareTapped

    internal private(set) var shareTappedCallsCount = 0
    internal var shareTappedClosure: (() -> Void)?
    internal var shareTappedCalled: Bool {
        shareTappedCallsCount > 0
    }

    internal func shareTapped() {
        shareTappedCallsCount += 1
        shareTappedClosure?()
    }

    // MARK: - qrCodeTapped

    internal private(set) var qrCodeTappedCallsCount = 0
    internal var qrCodeTappedClosure: (() -> Void)?
    internal var qrCodeTappedCalled: Bool {
        qrCodeTappedCallsCount > 0
    }

    internal func qrCodeTapped() {
        qrCodeTappedCallsCount += 1
        qrCodeTappedClosure?()
    }

    // MARK: - footerButtonTapped

    internal private(set) var footerButtonTappedCallsCount = 0
    internal var footerButtonTappedClosure: (() -> Void)?
    internal var footerButtonTappedCalled: Bool {
        footerButtonTappedCallsCount > 0
    }

    internal func footerButtonTapped() {
        footerButtonTappedCallsCount += 1
        footerButtonTappedClosure?()
    }

    // MARK: - cardTapped

    internal private(set) var cardTappedReceivedArticleId: String?
    internal private(set) var cardTappedReceivedInvocations: [String] = []
    internal private(set) var cardTappedCallsCount = 0
    internal var cardTappedClosure: ((String) -> Void)?
    internal var cardTappedCalled: Bool {
        cardTappedCallsCount > 0
    }

    internal func cardTapped(articleId: String) {
        cardTappedCallsCount += 1
        cardTappedReceivedArticleId = articleId
        cardTappedReceivedInvocations.append(articleId)
        cardTappedClosure?(articleId)
    }

    // MARK: - linkTapped

    internal private(set) var linkTappedCallsCount = 0
    internal var linkTappedClosure: (() -> Void)?
    internal var linkTappedCalled: Bool {
        linkTappedCallsCount > 0
    }

    internal func linkTapped() {
        linkTappedCallsCount += 1
        linkTappedClosure?()
    }

    // MARK: - personaliseTapped

    internal private(set) var personaliseTappedCallsCount = 0
    internal var personaliseTappedClosure: (() -> Void)?
    internal var personaliseTappedCalled: Bool {
        personaliseTappedCallsCount > 0
    }

    internal func personaliseTapped() {
        personaliseTappedCallsCount += 1
        personaliseTappedClosure?()
    }

    // MARK: - giveFeedbackTapped

    internal private(set) var giveFeedbackTappedCallsCount = 0
    internal var giveFeedbackTappedClosure: (() -> Void)?
    internal var giveFeedbackTappedCalled: Bool {
        giveFeedbackTappedCallsCount > 0
    }

    internal func giveFeedbackTapped() {
        giveFeedbackTappedCallsCount += 1
        giveFeedbackTappedClosure?()
    }
}

internal final class QuickpayViewModelMapperMock: QuickpayViewModelMapper {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        status: ShareableLinkStatus.Discoverability,
        profile: Profile,
        qrCodeImage: UIImage?,
        isCardsEnabled: Bool,
        nudge: NudgeViewModel?,
        delegate: QuickpayViewModelDelegate
    )?
    internal private(set) var makeReceivedInvocations: [(
        status: ShareableLinkStatus.Discoverability,
        profile: Profile,
        qrCodeImage: UIImage?,
        isCardsEnabled: Bool,
        nudge: NudgeViewModel?,
        delegate: QuickpayViewModelDelegate
    )] = []
    internal var makeReturnValue: QuickpayViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((
        ShareableLinkStatus.Discoverability,
        Profile,
        UIImage?,
        Bool,
        NudgeViewModel?,
        QuickpayViewModelDelegate
    ) -> QuickpayViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        status: ShareableLinkStatus.Discoverability,
        profile: Profile,
        qrCodeImage: UIImage?,
        isCardsEnabled: Bool,
        nudge: NudgeViewModel?,
        delegate: QuickpayViewModelDelegate
    ) -> QuickpayViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (
            status: status,
            profile: profile,
            qrCodeImage: qrCodeImage,
            isCardsEnabled: isCardsEnabled,
            nudge: nudge,
            delegate: delegate
        )
        makeReceivedInvocations.append((
            status: status,
            profile: profile,
            qrCodeImage: qrCodeImage,
            isCardsEnabled: isCardsEnabled,
            nudge: nudge,
            delegate: delegate
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(status, profile, qrCodeImage, isCardsEnabled, nudge, delegate)
    }
}

internal final class ReceiveMethodActionHandlerMock: ReceiveMethodActionHandler {
    // MARK: - handleReceiveMethodAction

    internal private(set) var handleReceiveMethodActionReceivedAction: ReceiveMethodNavigationAction?
    internal private(set) var handleReceiveMethodActionReceivedInvocations: [ReceiveMethodNavigationAction] = []
    internal private(set) var handleReceiveMethodActionCallsCount = 0
    internal var handleReceiveMethodActionClosure: ((ReceiveMethodNavigationAction) -> Void)?
    internal var handleReceiveMethodActionCalled: Bool {
        handleReceiveMethodActionCallsCount > 0
    }

    internal func handleReceiveMethodAction(action: ReceiveMethodNavigationAction) {
        handleReceiveMethodActionCallsCount += 1
        handleReceiveMethodActionReceivedAction = action
        handleReceiveMethodActionReceivedInvocations.append(action)
        handleReceiveMethodActionClosure?(action)
    }
}

internal final class ReceiveMethodQRSharingViewControllerFactoryMock: ReceiveMethodQRSharingViewControllerFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        mode: ReceiveMethodsQRSharingMode,
        navigationController: UINavigationController
    )?
    internal private(set) var makeReceivedInvocations: [(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        mode: ReceiveMethodsQRSharingMode,
        navigationController: UINavigationController
    )] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((AccountDetailsId, ProfileId, ReceiveMethodsQRSharingMode, UINavigationController) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        mode: ReceiveMethodsQRSharingMode,
        navigationController: UINavigationController
    ) -> UIViewController {
        makeCallsCount += 1
        makeReceivedArguments = (
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            mode: mode,
            navigationController: navigationController
        )
        makeReceivedInvocations.append((
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            mode: mode,
            navigationController: navigationController
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(accountDetailsId, profileId, mode, navigationController)
    }
}

internal final class ReceiveMethodsQRSharingCustomizationDelegateMock: ReceiveMethodsQRSharingCustomizationDelegate {
    // MARK: - customize

    internal private(set) var customizeReceivedArguments: (
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        result: ReceiveMethodsQRSharingCustomizationResult
    )?
    internal private(set) var customizeReceivedInvocations: [(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        result: ReceiveMethodsQRSharingCustomizationResult
    )] = []
    internal private(set) var customizeCallsCount = 0
    internal var customizeClosure: ((AccountDetailsId, ProfileId, ReceiveMethodsQRSharingCustomizationResult) -> Void)?
    internal var customizeCalled: Bool {
        customizeCallsCount > 0
    }

    internal func customize(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        result: ReceiveMethodsQRSharingCustomizationResult
    ) {
        customizeCallsCount += 1
        customizeReceivedArguments = (accountDetailsId: accountDetailsId, profileId: profileId, result: result)
        customizeReceivedInvocations.append((accountDetailsId: accountDetailsId, profileId: profileId, result: result))
        customizeClosure?(accountDetailsId, profileId, result)
    }
}

internal final class ReceiveMethodsQRSharingPresenterMock: ReceiveMethodsQRSharingPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: ReceiveMethodsQRSharingView?
    internal private(set) var startReceivedInvocations: [ReceiveMethodsQRSharingView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((ReceiveMethodsQRSharingView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: ReceiveMethodsQRSharingView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - activeIndexChanged

    internal private(set) var activeIndexChangedReceivedIndex: Int?
    internal private(set) var activeIndexChangedReceivedInvocations: [Int] = []
    internal private(set) var activeIndexChangedCallsCount = 0
    internal var activeIndexChangedClosure: ((Int) -> Void)?
    internal var activeIndexChangedCalled: Bool {
        activeIndexChangedCallsCount > 0
    }

    internal func activeIndexChanged(_ index: Int) {
        activeIndexChangedCallsCount += 1
        activeIndexChangedReceivedIndex = index
        activeIndexChangedReceivedInvocations.append(index)
        activeIndexChangedClosure?(index)
    }
}

internal final class ReceiveMethodsQRSharingRouterMock: ReceiveMethodsQRSharingRouter {
    // MARK: - showDownload

    internal private(set) var showDownloadReceivedArguments: (image: UIImage, viewController: UIViewController)?
    internal private(set) var showDownloadReceivedInvocations: [(image: UIImage, viewController: UIViewController)] = []
    internal private(set) var showDownloadCallsCount = 0
    internal var showDownloadClosure: ((UIImage, UIViewController) -> Void)?
    internal var showDownloadCalled: Bool {
        showDownloadCallsCount > 0
    }

    internal func showDownload(image: UIImage, viewController: UIViewController) {
        showDownloadCallsCount += 1
        showDownloadReceivedArguments = (image: image, viewController: viewController)
        showDownloadReceivedInvocations.append((image: image, viewController: viewController))
        showDownloadClosure?(image, viewController)
    }

    // MARK: - showCustomisation

    internal private(set) var showCustomisationReceivedArguments: (
        alias: ReceiveMethodAlias,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    )?
    internal private(set) var showCustomisationReceivedInvocations: [(
        alias: ReceiveMethodAlias,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    )] = []
    internal private(set) var showCustomisationCallsCount = 0
    internal var showCustomisationClosure: ((ReceiveMethodAlias, AccountDetailsId, ProfileId) -> Void)?
    internal var showCustomisationCalled: Bool {
        showCustomisationCallsCount > 0
    }

    internal func showCustomisation(alias: ReceiveMethodAlias, accountDetailsId: AccountDetailsId, profileId: ProfileId) {
        showCustomisationCallsCount += 1
        showCustomisationReceivedArguments = (alias: alias, accountDetailsId: accountDetailsId, profileId: profileId)
        showCustomisationReceivedInvocations.append((alias: alias, accountDetailsId: accountDetailsId, profileId: profileId))
        showCustomisationClosure?(alias, accountDetailsId, profileId)
    }
}

internal final class ReceiveMethodsQRSharingViewMock: UIViewController, ReceiveMethodsQRSharingView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: ReceiveMethodsQRSharingViewModel?
    internal private(set) var configureReceivedInvocations: [ReceiveMethodsQRSharingViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((ReceiveMethodsQRSharingViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: ReceiveMethodsQRSharingViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedWith: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedWith = with
        configureWithErrorReceivedInvocations.append(with)
        configureWithErrorClosure?(with)
    }

    // MARK: - showSnackbar

    internal private(set) var showSnackbarReceivedMessage: String?
    internal private(set) var showSnackbarReceivedInvocations: [String] = []
    internal private(set) var showSnackbarCallsCount = 0
    internal var showSnackbarClosure: ((String) -> Void)?
    internal var showSnackbarCalled: Bool {
        showSnackbarCallsCount > 0
    }

    internal func showSnackbar(message: String) {
        showSnackbarCallsCount += 1
        showSnackbarReceivedMessage = message
        showSnackbarReceivedInvocations.append(message)
        showSnackbarClosure?(message)
    }

    // MARK: - showShareSheet

    internal private(set) var showShareSheetReceivedText: String?
    internal private(set) var showShareSheetReceivedInvocations: [String] = []
    internal private(set) var showShareSheetCallsCount = 0
    internal var showShareSheetClosure: ((String) -> Void)?
    internal var showShareSheetCalled: Bool {
        showShareSheetCallsCount > 0
    }

    internal func showShareSheet(text: String) {
        showShareSheetCallsCount += 1
        showShareSheetReceivedText = text
        showShareSheetReceivedInvocations.append(text)
        showShareSheetClosure?(text)
    }

    // MARK: - displayHud

    internal private(set) var displayHudCallsCount = 0
    internal var displayHudClosure: (() -> Void)?
    internal var displayHudCalled: Bool {
        displayHudCallsCount > 0
    }

    internal func displayHud() {
        displayHudCallsCount += 1
        displayHudClosure?()
    }

    // MARK: - removeHud

    internal private(set) var removeHudCallsCount = 0
    internal var removeHudClosure: (() -> Void)?
    internal var removeHudCalled: Bool {
        removeHudCallsCount > 0
    }

    internal func removeHud() {
        removeHudCallsCount += 1
        removeHudClosure?()
    }
}

internal final class ReceiveRestrictionPresenterMock: ReceiveRestrictionPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: ReceiveRestrictionView?
    internal private(set) var startReceivedInvocations: [ReceiveRestrictionView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((ReceiveRestrictionView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(view: ReceiveRestrictionView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - handleFooterAction

    internal private(set) var handleFooterActionReceivedType: ReceiveRestriction.Footer.`Type`?
    internal private(set) var handleFooterActionReceivedInvocations: [ReceiveRestriction.Footer.`Type`] = []
    internal private(set) var handleFooterActionCallsCount = 0
    internal var handleFooterActionClosure: ((ReceiveRestriction.Footer.`Type`) -> Void)?
    internal var handleFooterActionCalled: Bool {
        handleFooterActionCallsCount > 0
    }

    internal func handleFooterAction(type: ReceiveRestriction.Footer.`Type`) {
        handleFooterActionCallsCount += 1
        handleFooterActionReceivedType = type
        handleFooterActionReceivedInvocations.append(type)
        handleFooterActionClosure?(type)
    }

    // MARK: - handleURI

    internal private(set) var handleURIReceivedString: String?
    internal private(set) var handleURIReceivedInvocations: [String] = []
    internal private(set) var handleURICallsCount = 0
    internal var handleURIClosure: ((String) -> Void)?
    internal var handleURICalled: Bool {
        handleURICallsCount > 0
    }

    internal func handleURI(string: String) {
        handleURICallsCount += 1
        handleURIReceivedString = string
        handleURIReceivedInvocations.append(string)
        handleURIClosure?(string)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class ReceiveRestrictionRoutingDelegateMock: ReceiveRestrictionRoutingDelegate {
    // MARK: - handleURI

    internal private(set) var handleURIReceivedUri: URI?
    internal private(set) var handleURIReceivedInvocations: [URI] = []
    internal private(set) var handleURICallsCount = 0
    internal var handleURIClosure: ((URI) -> Void)?
    internal var handleURICalled: Bool {
        handleURICallsCount > 0
    }

    internal func handleURI(_ uri: URI) {
        handleURICallsCount += 1
        handleURIReceivedUri = uri
        handleURIReceivedInvocations.append(uri)
        handleURIClosure?(uri)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class ReceiveRestrictionViewMock: ReceiveRestrictionView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: ReceiveRestrictionViewModel?
    internal private(set) var configureReceivedInvocations: [ReceiveRestrictionViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((ReceiveRestrictionViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(viewModel: ReceiveRestrictionViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showErrorState

    internal private(set) var showErrorStateReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorStateReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorStateCallsCount = 0
    internal var showErrorStateClosure: ((String, String) -> Void)?
    internal var showErrorStateCalled: Bool {
        showErrorStateCallsCount > 0
    }

    internal func showErrorState(title: String, message: String) {
        showErrorStateCallsCount += 1
        showErrorStateReceivedArguments = (title: title, message: message)
        showErrorStateReceivedInvocations.append((title: title, message: message))
        showErrorStateClosure?(title, message)
    }
}

internal final class ReceiveRestrictionViewControllerFactoryMock: ReceiveRestrictionViewControllerFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        routingDelegate: ReceiveRestrictionRoutingDelegate,
        navigationController: UINavigationController
    )?
    internal private(set) var makeReceivedInvocations: [(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        routingDelegate: ReceiveRestrictionRoutingDelegate,
        navigationController: UINavigationController
    )] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((ReceiveRestrictionContext, ProfileId, ReceiveRestrictionRoutingDelegate, UINavigationController) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        routingDelegate: ReceiveRestrictionRoutingDelegate,
        navigationController: UINavigationController
    ) -> UIViewController {
        makeCallsCount += 1
        makeReceivedArguments = (
            context: context,
            profileId: profileId,
            routingDelegate: routingDelegate,
            navigationController: navigationController
        )
        makeReceivedInvocations.append((
            context: context,
            profileId: profileId,
            routingDelegate: routingDelegate,
            navigationController: navigationController
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(context, profileId, routingDelegate, navigationController)
    }
}

internal final class RequestFromAnyonePresenterMock: RequestFromAnyonePresenter {
    // MARK: - start

    internal private(set) var startReceivedView: RequestPaymentFromAnyoneView?
    internal private(set) var startReceivedInvocations: [RequestPaymentFromAnyoneView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((RequestPaymentFromAnyoneView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: RequestPaymentFromAnyoneView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - shareTapped

    internal private(set) var shareTappedReceivedUrlString: String?
    internal private(set) var shareTappedReceivedInvocations: [String] = []
    internal private(set) var shareTappedCallsCount = 0
    internal var shareTappedClosure: ((String) -> Void)?
    internal var shareTappedCalled: Bool {
        shareTappedCallsCount > 0
    }

    internal func shareTapped(_ urlString: String) {
        shareTappedCallsCount += 1
        shareTappedReceivedUrlString = urlString
        shareTappedReceivedInvocations.append(urlString)
        shareTappedClosure?(urlString)
    }

    // MARK: - finishSharing

    internal private(set) var finishSharingReceivedDidShareWisetag: Bool?
    internal private(set) var finishSharingReceivedInvocations: [Bool] = []
    internal private(set) var finishSharingCallsCount = 0
    internal var finishSharingClosure: ((Bool) -> Void)?
    internal var finishSharingCalled: Bool {
        finishSharingCallsCount > 0
    }

    internal func finishSharing(didShareWisetag: Bool) {
        finishSharingCallsCount += 1
        finishSharingReceivedDidShareWisetag = didShareWisetag
        finishSharingReceivedInvocations.append(didShareWisetag)
        finishSharingClosure?(didShareWisetag)
    }

    // MARK: - turnOnWisetagTapped

    internal private(set) var turnOnWisetagTappedCallsCount = 0
    internal var turnOnWisetagTappedClosure: (() -> Void)?
    internal var turnOnWisetagTappedCalled: Bool {
        turnOnWisetagTappedCallsCount > 0
    }

    internal func turnOnWisetagTapped() {
        turnOnWisetagTappedCallsCount += 1
        turnOnWisetagTappedClosure?()
    }

    // MARK: - addAmmountAndNoteTapped

    internal private(set) var addAmmountAndNoteTappedCallsCount = 0
    internal var addAmmountAndNoteTappedClosure: (() -> Void)?
    internal var addAmmountAndNoteTappedCalled: Bool {
        addAmmountAndNoteTappedCallsCount > 0
    }

    internal func addAmmountAndNoteTapped() {
        addAmmountAndNoteTappedCallsCount += 1
        addAmmountAndNoteTappedClosure?()
    }
}

internal final class RequestFromAnyoneRoutingDelegateMock: RequestFromAnyoneRoutingDelegate {
    // MARK: - addAmountAndNote

    internal private(set) var addAmountAndNoteCallsCount = 0
    internal var addAmountAndNoteClosure: (() -> Void)?
    internal var addAmountAndNoteCalled: Bool {
        addAmountAndNoteCallsCount > 0
    }

    internal func addAmountAndNote() {
        addAmountAndNoteCallsCount += 1
        addAmountAndNoteClosure?()
    }

    // MARK: - useOldFlow

    internal private(set) var useOldFlowCallsCount = 0
    internal var useOldFlowClosure: (() -> Void)?
    internal var useOldFlowCalled: Bool {
        useOldFlowCallsCount > 0
    }

    internal func useOldFlow() {
        useOldFlowCallsCount += 1
        useOldFlowClosure?()
    }

    // MARK: - endFlow

    internal private(set) var endFlowCallsCount = 0
    internal var endFlowClosure: (() -> Void)?
    internal var endFlowCalled: Bool {
        endFlowCallsCount > 0
    }

    internal func endFlow() {
        endFlowCallsCount += 1
        endFlowClosure?()
    }
}

internal final class RequestMoneyCardOnboardingPromptViewControllerFactoryMock: RequestMoneyCardOnboardingPromptViewControllerFactory {
    // MARK: - makeCardAvailable

    internal private(set) var makeCardAvailableReceivedArguments: (
        primaryButtonAction: (UIViewController?) -> Void,
        secondaryButtonAction: (UIViewController?) -> Void
    )?
    internal private(set) var makeCardAvailableReceivedInvocations: [(
        primaryButtonAction: (UIViewController?) -> Void,
        secondaryButtonAction: (UIViewController?) -> Void
    )] = []
    internal var makeCardAvailableReturnValue: UIViewController!
    internal private(set) var makeCardAvailableCallsCount = 0
    internal var makeCardAvailableClosure: ((@escaping (UIViewController?) -> Void, @escaping (UIViewController?) -> Void) -> UIViewController)?
    internal var makeCardAvailableCalled: Bool {
        makeCardAvailableCallsCount > 0
    }

    internal func makeCardAvailable(
        primaryButtonAction: @escaping (UIViewController?) -> Void,
        secondaryButtonAction: @escaping (UIViewController?) -> Void
    ) -> UIViewController {
        makeCardAvailableCallsCount += 1
        makeCardAvailableReceivedArguments = (
            primaryButtonAction: primaryButtonAction,
            secondaryButtonAction: secondaryButtonAction
        )
        makeCardAvailableReceivedInvocations.append((
            primaryButtonAction: primaryButtonAction,
            secondaryButtonAction: secondaryButtonAction
        ))
        guard let makeCardAvailableClosure else {
            return makeCardAvailableReturnValue
        }
        return makeCardAvailableClosure(primaryButtonAction, secondaryButtonAction)
    }

    // MARK: - makeCardIneligible

    internal private(set) var makeCardIneligibleReceivedPrimaryButtonAction: ((UIViewController?) -> Void)?
    internal private(set) var makeCardIneligibleReceivedInvocations: [(UIViewController?) -> Void] = []
    internal var makeCardIneligibleReturnValue: UIViewController!
    internal private(set) var makeCardIneligibleCallsCount = 0
    internal var makeCardIneligibleClosure: ((@escaping (UIViewController?) -> Void) -> UIViewController)?
    internal var makeCardIneligibleCalled: Bool {
        makeCardIneligibleCallsCount > 0
    }

    internal func makeCardIneligible(primaryButtonAction: @escaping (UIViewController?) -> Void) -> UIViewController {
        makeCardIneligibleCallsCount += 1
        makeCardIneligibleReceivedPrimaryButtonAction = primaryButtonAction
        makeCardIneligibleReceivedInvocations.append(primaryButtonAction)
        guard let makeCardIneligibleClosure else {
            return makeCardIneligibleReturnValue
        }
        return makeCardIneligibleClosure(primaryButtonAction)
    }
}

internal final class RequestMoneyContactPickerMapperMock: RequestMoneyContactPickerMapper {
    // MARK: - makeModel

    internal private(set) var makeModelReceivedArguments: (
        recentContacts: [Contact],
        contacts: [Contact],
        contactList: [ContactList],
        nudge: NudgeViewModel?
    )?
    internal private(set) var makeModelReceivedInvocations: [(
        recentContacts: [Contact],
        contacts: [Contact],
        contactList: [ContactList],
        nudge: NudgeViewModel?
    )] = []
    internal var makeModelReturnValue: RequestMoneyContactPickerViewModel!
    internal private(set) var makeModelCallsCount = 0
    internal var makeModelClosure: (([Contact], [Contact], [ContactList], NudgeViewModel?) -> RequestMoneyContactPickerViewModel)?
    internal var makeModelCalled: Bool {
        makeModelCallsCount > 0
    }

    internal func makeModel(recentContacts: [Contact], contacts: [Contact], contactList: [ContactList], nudge: NudgeViewModel?) -> RequestMoneyContactPickerViewModel {
        makeModelCallsCount += 1
        makeModelReceivedArguments = (recentContacts: recentContacts, contacts: contacts, contactList: contactList, nudge: nudge)
        makeModelReceivedInvocations.append((
            recentContacts: recentContacts,
            contacts: contacts,
            contactList: contactList,
            nudge: nudge
        ))
        guard let makeModelClosure else {
            return makeModelReturnValue
        }
        return makeModelClosure(recentContacts, contacts, contactList, nudge)
    }
}

internal final class RequestMoneyContactPickerPresenterMock: RequestMoneyContactPickerPresenter {
    // MARK: - start

    internal private(set) var startReceivedWith: RequestMoneyContactPickerView?
    internal private(set) var startReceivedInvocations: [RequestMoneyContactPickerView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((RequestMoneyContactPickerView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with: RequestMoneyContactPickerView) {
        startCallsCount += 1
        startReceivedWith = with
        startReceivedInvocations.append(with)
        startClosure?(with)
    }

    // MARK: - startSearch

    internal private(set) var startSearchCallsCount = 0
    internal var startSearchClosure: (() -> Void)?
    internal var startSearchCalled: Bool {
        startSearchCallsCount > 0
    }

    internal func startSearch() {
        startSearchCallsCount += 1
        startSearchClosure?()
    }

    // MARK: - select

    internal private(set) var selectReceivedContact: Contact?
    internal private(set) var selectReceivedInvocations: [Contact?] = []
    internal private(set) var selectCallsCount = 0
    internal var selectClosure: ((Contact?) -> Void)?
    internal var selectCalled: Bool {
        selectCallsCount > 0
    }

    internal func select(contact: Contact?) {
        selectCallsCount += 1
        selectReceivedContact = contact
        selectReceivedInvocations.append(contact)
        selectClosure?(contact)
    }

    // MARK: - inviteFriendsTapped

    internal private(set) var inviteFriendsTappedCallsCount = 0
    internal var inviteFriendsTappedClosure: (() -> Void)?
    internal var inviteFriendsTappedCalled: Bool {
        inviteFriendsTappedCallsCount > 0
    }

    internal func inviteFriendsTapped() {
        inviteFriendsTappedCallsCount += 1
        inviteFriendsTappedClosure?()
    }

    // MARK: - findFriendsTapped

    internal private(set) var findFriendsTappedCallsCount = 0
    internal var findFriendsTappedClosure: (() -> Void)?
    internal var findFriendsTappedCalled: Bool {
        findFriendsTappedCallsCount > 0
    }

    internal func findFriendsTapped() {
        findFriendsTappedCallsCount += 1
        findFriendsTappedClosure?()
    }

    // MARK: - nudgeDismissed

    internal private(set) var nudgeDismissedReceivedNudgeType: ContactPickerNudgeType?
    internal private(set) var nudgeDismissedReceivedInvocations: [ContactPickerNudgeType] = []
    internal private(set) var nudgeDismissedCallsCount = 0
    internal var nudgeDismissedClosure: ((ContactPickerNudgeType) -> Void)?
    internal var nudgeDismissedCalled: Bool {
        nudgeDismissedCallsCount > 0
    }

    internal func nudgeDismissed(nudgeType: ContactPickerNudgeType) {
        nudgeDismissedCallsCount += 1
        nudgeDismissedReceivedNudgeType = nudgeType
        nudgeDismissedReceivedInvocations.append(nudgeType)
        nudgeDismissedClosure?(nudgeType)
    }

    // MARK: - loadMore

    internal private(set) var loadMoreCallsCount = 0
    internal var loadMoreClosure: (() -> Void)?
    internal var loadMoreCalled: Bool {
        loadMoreCallsCount > 0
    }

    internal func loadMore() {
        loadMoreCallsCount += 1
        loadMoreClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class RequestMoneyContactPickerRouterMock: RequestMoneyContactPickerRouter {
    // MARK: - createPaymentRequest

    internal private(set) var createPaymentRequestReceivedContact: Contact?
    internal private(set) var createPaymentRequestReceivedInvocations: [Contact?] = []
    internal private(set) var createPaymentRequestCallsCount = 0
    internal var createPaymentRequestClosure: ((Contact?) -> Void)?
    internal var createPaymentRequestCalled: Bool {
        createPaymentRequestCallsCount > 0
    }

    internal func createPaymentRequest(contact: Contact?) {
        createPaymentRequestCallsCount += 1
        createPaymentRequestReceivedContact = contact
        createPaymentRequestReceivedInvocations.append(contact)
        createPaymentRequestClosure?(contact)
    }

    // MARK: - startSearch

    internal private(set) var startSearchCallsCount = 0
    internal var startSearchClosure: (() -> Void)?
    internal var startSearchCalled: Bool {
        startSearchCallsCount > 0
    }

    internal func startSearch() {
        startSearchCallsCount += 1
        startSearchClosure?()
    }

    // MARK: - inviteFriendsNudgeTapped

    internal private(set) var inviteFriendsNudgeTappedCallsCount = 0
    internal var inviteFriendsNudgeTappedClosure: (() -> Void)?
    internal var inviteFriendsNudgeTappedCalled: Bool {
        inviteFriendsNudgeTappedCallsCount > 0
    }

    internal func inviteFriendsNudgeTapped() {
        inviteFriendsNudgeTappedCallsCount += 1
        inviteFriendsNudgeTappedClosure?()
    }

    // MARK: - findFriendsNudgeTapped

    internal private(set) var findFriendsNudgeTappedCallsCount = 0
    internal var findFriendsNudgeTappedClosure: (() -> Void)?
    internal var findFriendsNudgeTappedCalled: Bool {
        findFriendsNudgeTappedCallsCount > 0
    }

    internal func findFriendsNudgeTapped() {
        findFriendsNudgeTappedCallsCount += 1
        findFriendsNudgeTappedClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class RequestMoneyContactPickerViewMock: RequestMoneyContactPickerView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: RequestMoneyContactPickerViewModel?
    internal private(set) var configureReceivedInvocations: [RequestMoneyContactPickerViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((RequestMoneyContactPickerViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(viewModel: RequestMoneyContactPickerViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - reset

    internal private(set) var resetCallsCount = 0
    internal var resetClosure: (() -> Void)?
    internal var resetCalled: Bool {
        resetCallsCount > 0
    }

    internal func reset() {
        resetCallsCount += 1
        resetClosure?()
    }

    // MARK: - showLoading

    internal private(set) var showLoadingCallsCount = 0
    internal var showLoadingClosure: (() -> Void)?
    internal var showLoadingCalled: Bool {
        showLoadingCallsCount > 0
    }

    internal func showLoading() {
        showLoadingCallsCount += 1
        showLoadingClosure?()
    }

    // MARK: - hideLoading

    internal private(set) var hideLoadingCallsCount = 0
    internal var hideLoadingClosure: (() -> Void)?
    internal var hideLoadingCalled: Bool {
        hideLoadingCallsCount > 0
    }

    internal func hideLoading() {
        hideLoadingCallsCount += 1
        hideLoadingClosure?()
    }

    // MARK: - showErrorAlert

    internal private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorAlertCallsCount = 0
    internal var showErrorAlertClosure: ((String, String) -> Void)?
    internal var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    internal func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }
}

internal final class RequestMoneyPayWithWiseEducationFlowFactoryMock: RequestMoneyPayWithWiseEducationFlowFactory {
    // MARK: - makeBottomSheetFlow

    internal private(set) var makeBottomSheetFlowReceivedParentViewController: UIViewController?
    internal private(set) var makeBottomSheetFlowReceivedInvocations: [UIViewController] = []
    internal var makeBottomSheetFlowReturnValue: (any Flow<RequestMoneyPayWithWiseEducationFlowResult>)!
    internal private(set) var makeBottomSheetFlowCallsCount = 0
    internal var makeBottomSheetFlowClosure: ((UIViewController) -> any Flow<RequestMoneyPayWithWiseEducationFlowResult>)?
    internal var makeBottomSheetFlowCalled: Bool {
        makeBottomSheetFlowCallsCount > 0
    }

    internal func makeBottomSheetFlow(parentViewController: UIViewController) -> any Flow<RequestMoneyPayWithWiseEducationFlowResult> {
        makeBottomSheetFlowCallsCount += 1
        makeBottomSheetFlowReceivedParentViewController = parentViewController
        makeBottomSheetFlowReceivedInvocations.append(parentViewController)
        guard let makeBottomSheetFlowClosure else {
            return makeBottomSheetFlowReturnValue
        }
        return makeBottomSheetFlowClosure(parentViewController)
    }
}

internal final class RequestMoneyPayWithWiseEducationPresenterMock: RequestMoneyPayWithWiseEducationPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: RequestMoneyPayWithWiseEducationView?
    internal private(set) var startReceivedInvocations: [RequestMoneyPayWithWiseEducationView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((RequestMoneyPayWithWiseEducationView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: RequestMoneyPayWithWiseEducationView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class RequestMoneyPayWithWiseEducationRoutingDelegateMock: RequestMoneyPayWithWiseEducationRoutingDelegate {
    // MARK: - showInviteFriends

    internal private(set) var showInviteFriendsCallsCount = 0
    internal var showInviteFriendsClosure: (() -> Void)?
    internal var showInviteFriendsCalled: Bool {
        showInviteFriendsCallsCount > 0
    }

    internal func showInviteFriends() {
        showInviteFriendsCallsCount += 1
        showInviteFriendsClosure?()
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class RequestMoneyPayWithWiseEducationViewMock: RequestMoneyPayWithWiseEducationView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: RequestMoneyPayWithWiseEducationViewModel?
    internal private(set) var configureReceivedInvocations: [RequestMoneyPayWithWiseEducationViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((RequestMoneyPayWithWiseEducationViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: RequestMoneyPayWithWiseEducationViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class RequestMoneyPayWithWiseEducationViewControllerFactoryMock: RequestMoneyPayWithWiseEducationViewControllerFactory {
    // MARK: - make

    internal private(set) var makeReceivedRoutingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegate?
    internal private(set) var makeReceivedInvocations: [RequestMoneyPayWithWiseEducationRoutingDelegate] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((RequestMoneyPayWithWiseEducationRoutingDelegate) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(routingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegate) -> UIViewController {
        makeCallsCount += 1
        makeReceivedRoutingDelegate = routingDelegate
        makeReceivedInvocations.append(routingDelegate)
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(routingDelegate)
    }
}

internal final class RequestPaymentFromAnyoneViewMock: RequestPaymentFromAnyoneView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: RequestPaymentFromAnyoneViewModel?
    internal private(set) var configureReceivedInvocations: [RequestPaymentFromAnyoneViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((RequestPaymentFromAnyoneViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: RequestPaymentFromAnyoneViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - showShareSheet

    internal private(set) var showShareSheetReceivedText: String?
    internal private(set) var showShareSheetReceivedInvocations: [String] = []
    internal private(set) var showShareSheetCallsCount = 0
    internal var showShareSheetClosure: ((String) -> Void)?
    internal var showShareSheetCalled: Bool {
        showShareSheetCallsCount > 0
    }

    internal func showShareSheet(text: String) {
        showShareSheetCallsCount += 1
        showShareSheetReceivedText = text
        showShareSheetReceivedInvocations.append(text)
        showShareSheetClosure?(text)
    }

    // MARK: - showDismissableAlert

    internal private(set) var showDismissableAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showDismissableAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showDismissableAlertCallsCount = 0
    internal var showDismissableAlertClosure: ((String, String) -> Void)?
    internal var showDismissableAlertCalled: Bool {
        showDismissableAlertCallsCount > 0
    }

    internal func showDismissableAlert(title: String, message: String) {
        showDismissableAlertCallsCount += 1
        showDismissableAlertReceivedArguments = (title: title, message: message)
        showDismissableAlertReceivedInvocations.append((title: title, message: message))
        showDismissableAlertClosure?(title, message)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class SalarySwitchFactoryMock: SalarySwitchFactory {
    // MARK: - makeUpsellViewController

    internal private(set) var makeUpsellViewControllerReceivedViewModel: UpsellViewModel?
    internal private(set) var makeUpsellViewControllerReceivedInvocations: [UpsellViewModel] = []
    internal var makeUpsellViewControllerReturnValue: UIViewController!
    internal private(set) var makeUpsellViewControllerCallsCount = 0
    internal var makeUpsellViewControllerClosure: ((UpsellViewModel) -> UIViewController)?
    internal var makeUpsellViewControllerCalled: Bool {
        makeUpsellViewControllerCallsCount > 0
    }

    internal func makeUpsellViewController(viewModel: UpsellViewModel) -> UIViewController {
        makeUpsellViewControllerCallsCount += 1
        makeUpsellViewControllerReceivedViewModel = viewModel
        makeUpsellViewControllerReceivedInvocations.append(viewModel)
        guard let makeUpsellViewControllerClosure else {
            return makeUpsellViewControllerReturnValue
        }
        return makeUpsellViewControllerClosure(viewModel)
    }

    // MARK: - makeOptionsSelectionViewController

    internal private(set) var makeOptionsSelectionViewControllerReceivedArguments: (
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profileId: ProfileId,
        navigationHost: UINavigationController
    )?
    internal private(set) var makeOptionsSelectionViewControllerReceivedInvocations: [(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profileId: ProfileId,
        navigationHost: UINavigationController
    )] = []
    internal var makeOptionsSelectionViewControllerReturnValue: UIViewController!
    internal private(set) var makeOptionsSelectionViewControllerCallsCount = 0
    internal var makeOptionsSelectionViewControllerClosure: ((BalanceId, CurrencyCode, ProfileId, UINavigationController) -> UIViewController)?
    internal var makeOptionsSelectionViewControllerCalled: Bool {
        makeOptionsSelectionViewControllerCallsCount > 0
    }

    internal func makeOptionsSelectionViewController(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profileId: ProfileId,
        navigationHost: UINavigationController
    ) -> UIViewController {
        makeOptionsSelectionViewControllerCallsCount += 1
        makeOptionsSelectionViewControllerReceivedArguments = (
            balanceId: balanceId,
            currencyCode: currencyCode,
            profileId: profileId,
            navigationHost: navigationHost
        )
        makeOptionsSelectionViewControllerReceivedInvocations.append((
            balanceId: balanceId,
            currencyCode: currencyCode,
            profileId: profileId,
            navigationHost: navigationHost
        ))
        guard let makeOptionsSelectionViewControllerClosure else {
            return makeOptionsSelectionViewControllerReturnValue
        }
        return makeOptionsSelectionViewControllerClosure(balanceId, currencyCode, profileId, navigationHost)
    }
}

internal final class SalarySwitchFlowFactoryMock: SalarySwitchFlowFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        origin: SalarySwitchFlowStartOrigin,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        profile: Profile,
        currencyCode: CurrencyCode,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    )?
    internal private(set) var makeReceivedInvocations: [(
        origin: SalarySwitchFlowStartOrigin,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        profile: Profile,
        currencyCode: CurrencyCode,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    )] = []
    internal var makeReturnValue: (any Flow<Void>)!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((
        SalarySwitchFlowStartOrigin,
        SalarySwitchFlowAccountDetailsRequirementStatus,
        Profile,
        CurrencyCode,
        UIViewController,
        HelpCenterArticleFactory,
        OrderAccountDetailsFlowFactory
    ) -> any Flow<Void>)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(
        origin: SalarySwitchFlowStartOrigin,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        profile: Profile,
        currencyCode: CurrencyCode,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    ) -> any Flow<Void> {
        makeCallsCount += 1
        makeReceivedArguments = (
            origin: origin,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            profile: profile,
            currencyCode: currencyCode,
            host: host,
            articleFactory: articleFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory
        )
        makeReceivedInvocations.append((
            origin: origin,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            profile: profile,
            currencyCode: currencyCode,
            host: host,
            articleFactory: articleFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory
        ))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(
            origin,
            accountDetailsRequirementStatus,
            profile,
            currencyCode,
            host,
            articleFactory,
            orderAccountDetailsFlowFactory
        )
    }
}

internal final class SalarySwitchOptionSelectionPresenterMock: SalarySwitchOptionSelectionPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: SalarySwitchOptionSelectionView?
    internal private(set) var startReceivedInvocations: [SalarySwitchOptionSelectionView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((SalarySwitchOptionSelectionView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(view: SalarySwitchOptionSelectionView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - selectedOption

    internal private(set) var selectedOptionReceivedArguments: (index: Int, sender: UIView)?
    internal private(set) var selectedOptionReceivedInvocations: [(index: Int, sender: UIView)] = []
    internal private(set) var selectedOptionCallsCount = 0
    internal var selectedOptionClosure: ((Int, UIView) -> Void)?
    internal var selectedOptionCalled: Bool {
        selectedOptionCallsCount > 0
    }

    internal func selectedOption(at index: Int, sender: UIView) {
        selectedOptionCallsCount += 1
        selectedOptionReceivedArguments = (index: index, sender: sender)
        selectedOptionReceivedInvocations.append((index: index, sender: sender))
        selectedOptionClosure?(index, sender)
    }
}

internal final class SalarySwitchOptionSelectionRouterMock: SalarySwitchOptionSelectionRouter {
    // MARK: - displayShareSheet

    internal private(set) var displayShareSheetReceivedArguments: (content: String, sender: UIView)?
    internal private(set) var displayShareSheetReceivedInvocations: [(content: String, sender: UIView)] = []
    internal private(set) var displayShareSheetCallsCount = 0
    internal var displayShareSheetClosure: ((String, UIView) -> Void)?
    internal var displayShareSheetCalled: Bool {
        displayShareSheetCallsCount > 0
    }

    internal func displayShareSheet(content: String, sender: UIView) {
        displayShareSheetCallsCount += 1
        displayShareSheetReceivedArguments = (content: content, sender: sender)
        displayShareSheetReceivedInvocations.append((content: content, sender: sender))
        displayShareSheetClosure?(content, sender)
    }

    // MARK: - displayOwnershipProofDocument

    internal private(set) var displayOwnershipProofDocumentReceivedArguments: (
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate?
    )?
    internal private(set) var displayOwnershipProofDocumentReceivedInvocations: [(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate?
    )] = []
    internal private(set) var displayOwnershipProofDocumentCallsCount = 0
    internal var displayOwnershipProofDocumentClosure: ((URL, UIDocumentInteractionControllerDelegate?) -> Void)?
    internal var displayOwnershipProofDocumentCalled: Bool {
        displayOwnershipProofDocumentCallsCount > 0
    }

    internal func displayOwnershipProofDocument(url: URL, delegate: UIDocumentInteractionControllerDelegate?) {
        displayOwnershipProofDocumentCallsCount += 1
        displayOwnershipProofDocumentReceivedArguments = (url: url, delegate: delegate)
        displayOwnershipProofDocumentReceivedInvocations.append((url: url, delegate: delegate))
        displayOwnershipProofDocumentClosure?(url, delegate)
    }
}

internal final class SalarySwitchUpsellFactoryMock: SalarySwitchUpsellFactory {
    // MARK: - makePresenter

    internal private(set) var makePresenterReceivedArguments: (
        profile: Profile,
        currency: CurrencyCode,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        navigationHost: UIViewController,
        presenterFactory: ViewControllerPresenterFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        factory: SalarySwitchFactory,
        articleFactory: HelpCenterArticleFactory,
        dismisserCapturer: (ViewControllerDismisser) -> Void
    )?
    internal private(set) var makePresenterReceivedInvocations: [(
        profile: Profile,
        currency: CurrencyCode,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        navigationHost: UIViewController,
        presenterFactory: ViewControllerPresenterFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        factory: SalarySwitchFactory,
        articleFactory: HelpCenterArticleFactory,
        dismisserCapturer: (ViewControllerDismisser) -> Void
    )] = []
    internal var makePresenterReturnValue: SalarySwitchUpsellPresenter!
    internal private(set) var makePresenterCallsCount = 0
    internal var makePresenterClosure: ((
        Profile,
        CurrencyCode,
        SalarySwitchFlowAccountDetailsRequirementStatus,
        UIViewController,
        ViewControllerPresenterFactory,
        OrderAccountDetailsFlowFactory,
        SalarySwitchFactory,
        HelpCenterArticleFactory,
        @escaping (ViewControllerDismisser) -> Void
    ) -> SalarySwitchUpsellPresenter)?
    internal var makePresenterCalled: Bool {
        makePresenterCallsCount > 0
    }

    internal func makePresenter(
        profile: Profile,
        currency: CurrencyCode,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        navigationHost: UIViewController,
        presenterFactory: ViewControllerPresenterFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        factory: SalarySwitchFactory,
        articleFactory: HelpCenterArticleFactory,
        dismisserCapturer: @escaping (ViewControllerDismisser) -> Void
    ) -> SalarySwitchUpsellPresenter {
        makePresenterCallsCount += 1
        makePresenterReceivedArguments = (
            profile: profile,
            currency: currency,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            navigationHost: navigationHost,
            presenterFactory: presenterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            factory: factory,
            articleFactory: articleFactory,
            dismisserCapturer: dismisserCapturer
        )
        makePresenterReceivedInvocations.append((
            profile: profile,
            currency: currency,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            navigationHost: navigationHost,
            presenterFactory: presenterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            factory: factory,
            articleFactory: articleFactory,
            dismisserCapturer: dismisserCapturer
        ))
        guard let makePresenterClosure else {
            return makePresenterReturnValue
        }
        return makePresenterClosure(
            profile,
            currency,
            accountDetailsRequirementStatus,
            navigationHost,
            presenterFactory,
            orderAccountDetailsFlowFactory,
            factory,
            articleFactory,
            dismisserCapturer
        )
    }
}

internal final class SalarySwitchUpsellPresenterMock: SalarySwitchUpsellPresenter {
    // MARK: - start

    internal private(set) var startCallsCount = 0
    internal var startClosure: (() -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start() {
        startCallsCount += 1
        startClosure?()
    }
}

internal final class SalarySwitchUpsellRouterMock: SalarySwitchUpsellRouter {
    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }

    // MARK: - showErrorAlert

    internal private(set) var showErrorAlertReceivedArguments: (title: String, message: String)?
    internal private(set) var showErrorAlertReceivedInvocations: [(title: String, message: String)] = []
    internal private(set) var showErrorAlertCallsCount = 0
    internal var showErrorAlertClosure: ((String, String) -> Void)?
    internal var showErrorAlertCalled: Bool {
        showErrorAlertCallsCount > 0
    }

    internal func showErrorAlert(title: String, message: String) {
        showErrorAlertCallsCount += 1
        showErrorAlertReceivedArguments = (title: title, message: message)
        showErrorAlertReceivedInvocations.append((title: title, message: message))
        showErrorAlertClosure?(title, message)
    }

    // MARK: - showUpsell

    internal private(set) var showUpsellReceivedViewModel: UpsellViewModel?
    internal private(set) var showUpsellReceivedInvocations: [UpsellViewModel] = []
    internal private(set) var showUpsellCallsCount = 0
    internal var showUpsellClosure: ((UpsellViewModel) -> Void)?
    internal var showUpsellCalled: Bool {
        showUpsellCallsCount > 0
    }

    internal func showUpsell(viewModel: UpsellViewModel) {
        showUpsellCallsCount += 1
        showUpsellReceivedViewModel = viewModel
        showUpsellReceivedInvocations.append(viewModel)
        showUpsellClosure?(viewModel)
    }

    // MARK: - showFAQ

    internal private(set) var showFAQReceivedPath: String?
    internal private(set) var showFAQReceivedInvocations: [String] = []
    internal private(set) var showFAQCallsCount = 0
    internal var showFAQClosure: ((String) -> Void)?
    internal var showFAQCalled: Bool {
        showFAQCallsCount > 0
    }

    internal func showFAQ(path: String) {
        showFAQCallsCount += 1
        showFAQReceivedPath = path
        showFAQReceivedInvocations.append(path)
        showFAQClosure?(path)
    }

    // MARK: - showOrderAccountDetailsFlow

    internal private(set) var showOrderAccountDetailsFlowReceivedArguments: (profile: Profile, currency: CurrencyCode)?
    internal private(set) var showOrderAccountDetailsFlowReceivedInvocations: [(profile: Profile, currency: CurrencyCode)] = []
    internal private(set) var showOrderAccountDetailsFlowCallsCount = 0
    internal var showOrderAccountDetailsFlowClosure: ((Profile, CurrencyCode) -> Void)?
    internal var showOrderAccountDetailsFlowCalled: Bool {
        showOrderAccountDetailsFlowCallsCount > 0
    }

    internal func showOrderAccountDetailsFlow(profile: Profile, currency: CurrencyCode) {
        showOrderAccountDetailsFlowCallsCount += 1
        showOrderAccountDetailsFlowReceivedArguments = (profile: profile, currency: currency)
        showOrderAccountDetailsFlowReceivedInvocations.append((profile: profile, currency: currency))
        showOrderAccountDetailsFlowClosure?(profile, currency)
    }

    // MARK: - showOptionSelection

    internal private(set) var showOptionSelectionReceivedArguments: (
        balanceId: BalanceId,
        currency: CurrencyCode,
        profileId: ProfileId
    )?
    internal private(set) var showOptionSelectionReceivedInvocations: [(
        balanceId: BalanceId,
        currency: CurrencyCode,
        profileId: ProfileId
    )] = []
    internal private(set) var showOptionSelectionCallsCount = 0
    internal var showOptionSelectionClosure: ((BalanceId, CurrencyCode, ProfileId) -> Void)?
    internal var showOptionSelectionCalled: Bool {
        showOptionSelectionCallsCount > 0
    }

    internal func showOptionSelection(balanceId: BalanceId, currency: CurrencyCode, profileId: ProfileId) {
        showOptionSelectionCallsCount += 1
        showOptionSelectionReceivedArguments = (balanceId: balanceId, currency: currency, profileId: profileId)
        showOptionSelectionReceivedInvocations.append((balanceId: balanceId, currency: currency, profileId: profileId))
        showOptionSelectionClosure?(balanceId, currency, profileId)
    }
}

internal final class ShareMessageFactoryMock: ShareMessageFactory {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (profile: Profile, paymentRequest: PaymentRequestV2)?
    internal private(set) var makeReceivedInvocations: [(profile: Profile, paymentRequest: PaymentRequestV2)] = []
    internal var makeReturnValue: String!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((Profile, PaymentRequestV2) -> String)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(profile: Profile, paymentRequest: PaymentRequestV2) -> String {
        makeCallsCount += 1
        makeReceivedArguments = (profile: profile, paymentRequest: paymentRequest)
        makeReceivedInvocations.append((profile: profile, paymentRequest: paymentRequest))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(profile, paymentRequest)
    }
}

internal final class WisetagContactOnWisePresenterMock: WisetagContactOnWisePresenter {
    // MARK: - start

    internal private(set) var startReceivedView: WisetagContactOnWiseView?
    internal private(set) var startReceivedInvocations: [WisetagContactOnWiseView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((WisetagContactOnWiseView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: WisetagContactOnWiseView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }
}

internal final class WisetagContactOnWiseRouterMock: WisetagContactOnWiseRouter {
    // MARK: - dismissAndUpdateShareableLinkStatus

    internal private(set) var dismissAndUpdateShareableLinkStatusReceivedArguments: (
        didChangeDiscoverability: Bool,
        isDiscoverable: Bool
    )?
    internal private(set) var dismissAndUpdateShareableLinkStatusReceivedInvocations: [(
        didChangeDiscoverability: Bool,
        isDiscoverable: Bool
    )] = []
    internal private(set) var dismissAndUpdateShareableLinkStatusCallsCount = 0
    internal var dismissAndUpdateShareableLinkStatusClosure: ((Bool, Bool) -> Void)?
    internal var dismissAndUpdateShareableLinkStatusCalled: Bool {
        dismissAndUpdateShareableLinkStatusCallsCount > 0
    }

    internal func dismissAndUpdateShareableLinkStatus(didChangeDiscoverability: Bool, isDiscoverable: Bool) {
        dismissAndUpdateShareableLinkStatusCallsCount += 1
        dismissAndUpdateShareableLinkStatusReceivedArguments = (
            didChangeDiscoverability: didChangeDiscoverability,
            isDiscoverable: isDiscoverable
        )
        dismissAndUpdateShareableLinkStatusReceivedInvocations.append((
            didChangeDiscoverability: didChangeDiscoverability,
            isDiscoverable: isDiscoverable
        ))
        dismissAndUpdateShareableLinkStatusClosure?(didChangeDiscoverability, isDiscoverable)
    }
}

internal final class WisetagContactOnWiseViewMock: WisetagContactOnWiseView {
    // MARK: - configure

    internal private(set) var configureReceivedViewModel: WisetagContactOnWiseViewModel?
    internal private(set) var configureReceivedInvocations: [WisetagContactOnWiseViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((WisetagContactOnWiseViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: WisetagContactOnWiseViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }
}

internal final class WisetagInteractorMock: WisetagInteractor {
    // MARK: - fetchNextStep

    internal var fetchNextStepReturnValue: AnyPublisher<WisetagNextStep, Error>!
    internal private(set) var fetchNextStepCallsCount = 0
    internal var fetchNextStepClosure: (() -> AnyPublisher<WisetagNextStep, Error>)?
    internal var fetchNextStepCalled: Bool {
        fetchNextStepCallsCount > 0
    }

    internal func fetchNextStep() -> AnyPublisher<WisetagNextStep, Error> {
        fetchNextStepCallsCount += 1
        guard let fetchNextStepClosure else {
            return fetchNextStepReturnValue
        }
        return fetchNextStepClosure()
    }

    // MARK: - fetchQRCode

    internal private(set) var fetchQRCodeReceivedArguments: (status: ShareableLinkStatus, link: String?)?
    internal private(set) var fetchQRCodeReceivedInvocations: [(status: ShareableLinkStatus, link: String?)] = []
    internal var fetchQRCodeReturnValue: AnyPublisher<
        (ShareableLinkStatus, UIImage?),
        Error
    >!
    internal private(set) var fetchQRCodeCallsCount = 0
    internal var fetchQRCodeClosure: ((ShareableLinkStatus, String?) -> AnyPublisher<
        (ShareableLinkStatus, UIImage?),
        Error
    >)?
    internal var fetchQRCodeCalled: Bool {
        fetchQRCodeCallsCount > 0
    }

    internal func fetchQRCode(status: ShareableLinkStatus, link: String?) -> AnyPublisher<
        (ShareableLinkStatus, UIImage?),
        Error
    > {
        fetchQRCodeCallsCount += 1
        fetchQRCodeReceivedArguments = (status: status, link: link)
        fetchQRCodeReceivedInvocations.append((status: status, link: link))
        guard let fetchQRCodeClosure else {
            return fetchQRCodeReturnValue
        }
        return fetchQRCodeClosure(status, link)
    }

    // MARK: - updateShareableLinkStatus

    internal private(set) var updateShareableLinkStatusReceivedArguments: (profileId: ProfileId, isDiscoverable: Bool)?
    internal private(set) var updateShareableLinkStatusReceivedInvocations: [(profileId: ProfileId, isDiscoverable: Bool)] = []
    internal var updateShareableLinkStatusReturnValue: AnyPublisher<(ShareableLinkStatus, UIImage?), Error>!
    internal private(set) var updateShareableLinkStatusCallsCount = 0
    internal var updateShareableLinkStatusClosure: ((ProfileId, Bool) -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error>)?
    internal var updateShareableLinkStatusCalled: Bool {
        updateShareableLinkStatusCallsCount > 0
    }

    internal func updateShareableLinkStatus(profileId: ProfileId, isDiscoverable: Bool) -> AnyPublisher<
        (ShareableLinkStatus, UIImage?),
        Error
    > {
        updateShareableLinkStatusCallsCount += 1
        updateShareableLinkStatusReceivedArguments = (profileId: profileId, isDiscoverable: isDiscoverable)
        updateShareableLinkStatusReceivedInvocations.append((profileId: profileId, isDiscoverable: isDiscoverable))
        guard let updateShareableLinkStatusClosure else {
            return updateShareableLinkStatusReturnValue
        }
        return updateShareableLinkStatusClosure(profileId, isDiscoverable)
    }

    // MARK: - shouldShowNudge

    internal private(set) var shouldShowNudgeReceivedArguments: (profileId: ProfileId, nudgeType: CardNudgeType)?
    internal private(set) var shouldShowNudgeReceivedInvocations: [(profileId: ProfileId, nudgeType: CardNudgeType)] = []
    internal var shouldShowNudgeReturnValue: Bool!
    internal private(set) var shouldShowNudgeCallsCount = 0
    internal var shouldShowNudgeClosure: ((ProfileId, CardNudgeType) -> Bool)?
    internal var shouldShowNudgeCalled: Bool {
        shouldShowNudgeCallsCount > 0
    }

    internal func shouldShowNudge(profileId: ProfileId, nudgeType: CardNudgeType) -> Bool {
        shouldShowNudgeCallsCount += 1
        shouldShowNudgeReceivedArguments = (profileId: profileId, nudgeType: nudgeType)
        shouldShowNudgeReceivedInvocations.append((profileId: profileId, nudgeType: nudgeType))
        guard let shouldShowNudgeClosure else {
            return shouldShowNudgeReturnValue
        }
        return shouldShowNudgeClosure(profileId, nudgeType)
    }

    // MARK: - setShouldShowNudge

    internal private(set) var setShouldShowNudgeReceivedArguments: (
        shouldShow: Bool,
        profileId: ProfileId,
        nudgeType: CardNudgeType
    )?
    internal private(set) var setShouldShowNudgeReceivedInvocations: [(
        shouldShow: Bool,
        profileId: ProfileId,
        nudgeType: CardNudgeType
    )] = []
    internal private(set) var setShouldShowNudgeCallsCount = 0
    internal var setShouldShowNudgeClosure: ((Bool, ProfileId, CardNudgeType) -> Void)?
    internal var setShouldShowNudgeCalled: Bool {
        setShouldShowNudgeCallsCount > 0
    }

    internal func setShouldShowNudge(_ shouldShow: Bool, profileId: ProfileId, nudgeType: CardNudgeType) {
        setShouldShowNudgeCallsCount += 1
        setShouldShowNudgeReceivedArguments = (shouldShow: shouldShow, profileId: profileId, nudgeType: nudgeType)
        setShouldShowNudgeReceivedInvocations.append((shouldShow: shouldShow, profileId: profileId, nudgeType: nudgeType))
        setShouldShowNudgeClosure?(shouldShow, profileId, nudgeType)
    }

    // MARK: - fetchCardDynamicForms

    internal var fetchCardDynamicFormsReturnValue: AnyPublisher<
        [PaymentMethodDynamicForm],
        Error
    >!
    internal private(set) var fetchCardDynamicFormsCallsCount = 0
    internal var fetchCardDynamicFormsClosure: (() -> AnyPublisher<
        [PaymentMethodDynamicForm],
        Error
    >)?
    internal var fetchCardDynamicFormsCalled: Bool {
        fetchCardDynamicFormsCallsCount > 0
    }

    internal func fetchCardDynamicForms() -> AnyPublisher<
        [PaymentMethodDynamicForm],
        Error
    > {
        fetchCardDynamicFormsCallsCount += 1
        guard let fetchCardDynamicFormsClosure else {
            return fetchCardDynamicFormsReturnValue
        }
        return fetchCardDynamicFormsClosure()
    }
}

internal final class WisetagPresenterMock: WisetagPresenter {
    // MARK: - start

    internal private(set) var startReceivedView: WisetagView?
    internal private(set) var startReceivedInvocations: [WisetagView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((WisetagView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: WisetagView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - showDiscoverabilityBottomSheet

    internal private(set) var showDiscoverabilityBottomSheetCallsCount = 0
    internal var showDiscoverabilityBottomSheetClosure: (() -> Void)?
    internal var showDiscoverabilityBottomSheetCalled: Bool {
        showDiscoverabilityBottomSheetCallsCount > 0
    }

    internal func showDiscoverabilityBottomSheet() {
        showDiscoverabilityBottomSheetCallsCount += 1
        showDiscoverabilityBottomSheetClosure?()
    }

    // MARK: - copyLinkTapped

    internal private(set) var copyLinkTappedCallsCount = 0
    internal var copyLinkTappedClosure: (() -> Void)?
    internal var copyLinkTappedCalled: Bool {
        copyLinkTappedCallsCount > 0
    }

    internal func copyLinkTapped() {
        copyLinkTappedCallsCount += 1
        copyLinkTappedClosure?()
    }
}

internal final class WisetagRouterMock: WisetagRouter {
    // MARK: - startAccountDetailsFlow

    internal private(set) var startAccountDetailsFlowReceivedHost: UIViewController?
    internal private(set) var startAccountDetailsFlowReceivedInvocations: [UIViewController] = []
    internal private(set) var startAccountDetailsFlowCallsCount = 0
    internal var startAccountDetailsFlowClosure: ((UIViewController) -> Void)?
    internal var startAccountDetailsFlowCalled: Bool {
        startAccountDetailsFlowCallsCount > 0
    }

    internal func startAccountDetailsFlow(host: UIViewController) {
        startAccountDetailsFlowCallsCount += 1
        startAccountDetailsFlowReceivedHost = host
        startAccountDetailsFlowReceivedInvocations.append(host)
        startAccountDetailsFlowClosure?(host)
    }

    // MARK: - showWisetagLearnMore

    internal private(set) var showWisetagLearnMoreReceivedRoute: DeepLinkStoryRoute?
    internal private(set) var showWisetagLearnMoreReceivedInvocations: [DeepLinkStoryRoute] = []
    internal private(set) var showWisetagLearnMoreCallsCount = 0
    internal var showWisetagLearnMoreClosure: ((DeepLinkStoryRoute) -> Void)?
    internal var showWisetagLearnMoreCalled: Bool {
        showWisetagLearnMoreCallsCount > 0
    }

    internal func showWisetagLearnMore(route: DeepLinkStoryRoute) {
        showWisetagLearnMoreCallsCount += 1
        showWisetagLearnMoreReceivedRoute = route
        showWisetagLearnMoreReceivedInvocations.append(route)
        showWisetagLearnMoreClosure?(route)
    }

    // MARK: - showScanQRcode

    internal private(set) var showScanQRcodeCallsCount = 0
    internal var showScanQRcodeClosure: (() -> Void)?
    internal var showScanQRcodeCalled: Bool {
        showScanQRcodeCallsCount > 0
    }

    internal func showScanQRcode() {
        showScanQRcodeCallsCount += 1
        showScanQRcodeClosure?()
    }

    // MARK: - showContactOnWise

    internal private(set) var showContactOnWiseReceivedNickname: String?
    internal private(set) var showContactOnWiseReceivedInvocations: [String?] = []
    internal private(set) var showContactOnWiseCallsCount = 0
    internal var showContactOnWiseClosure: ((String?) -> Void)?
    internal var showContactOnWiseCalled: Bool {
        showContactOnWiseCallsCount > 0
    }

    internal func showContactOnWise(nickname: String?) {
        showContactOnWiseCallsCount += 1
        showContactOnWiseReceivedNickname = nickname
        showContactOnWiseReceivedInvocations.append(nickname)
        showContactOnWiseClosure?(nickname)
    }

    // MARK: - showDownload

    internal private(set) var showDownloadReceivedImage: UIImage?
    internal private(set) var showDownloadReceivedInvocations: [UIImage] = []
    internal private(set) var showDownloadCallsCount = 0
    internal var showDownloadClosure: ((UIImage) -> Void)?
    internal var showDownloadCalled: Bool {
        showDownloadCallsCount > 0
    }

    internal func showDownload(image: UIImage) {
        showDownloadCallsCount += 1
        showDownloadReceivedImage = image
        showDownloadReceivedInvocations.append(image)
        showDownloadClosure?(image)
    }

    // MARK: - dismiss

    internal private(set) var dismissReceivedIsShareableLinkDiscoverable: Bool?
    internal private(set) var dismissReceivedInvocations: [Bool] = []
    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: ((Bool) -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss(isShareableLinkDiscoverable: Bool) {
        dismissCallsCount += 1
        dismissReceivedIsShareableLinkDiscoverable = isShareableLinkDiscoverable
        dismissReceivedInvocations.append(isShareableLinkDiscoverable)
        dismissClosure?(isShareableLinkDiscoverable)
    }

    // MARK: - showStory

    internal private(set) var showStoryReceivedRoute: DeepLinkStoryRoute?
    internal private(set) var showStoryReceivedInvocations: [DeepLinkStoryRoute] = []
    internal private(set) var showStoryCallsCount = 0
    internal var showStoryClosure: ((DeepLinkStoryRoute) -> Void)?
    internal var showStoryCalled: Bool {
        showStoryCallsCount > 0
    }

    internal func showStory(route: DeepLinkStoryRoute) {
        showStoryCallsCount += 1
        showStoryReceivedRoute = route
        showStoryReceivedInvocations.append(route)
        showStoryClosure?(route)
    }

    // MARK: - showLearnMoreStory

    internal private(set) var showLearnMoreStoryReceivedRoute: DeepLinkStoryRoute?
    internal private(set) var showLearnMoreStoryReceivedInvocations: [DeepLinkStoryRoute] = []
    internal private(set) var showLearnMoreStoryCallsCount = 0
    internal var showLearnMoreStoryClosure: ((DeepLinkStoryRoute) -> Void)?
    internal var showLearnMoreStoryCalled: Bool {
        showLearnMoreStoryCallsCount > 0
    }

    internal func showLearnMoreStory(route: DeepLinkStoryRoute) {
        showLearnMoreStoryCallsCount += 1
        showLearnMoreStoryReceivedRoute = route
        showLearnMoreStoryReceivedInvocations.append(route)
        showLearnMoreStoryClosure?(route)
    }
}

internal final class WisetagScannedProfileModelDelegateMock: WisetagScannedProfileModelDelegate {
    // MARK: - sendButtonTapped

    internal private(set) var sendButtonTappedCallsCount = 0
    internal var sendButtonTappedClosure: (() -> Void)?
    internal var sendButtonTappedCalled: Bool {
        sendButtonTappedCallsCount > 0
    }

    internal func sendButtonTapped() {
        sendButtonTappedCallsCount += 1
        sendButtonTappedClosure?()
    }

    // MARK: - requestButtonTapped

    internal private(set) var requestButtonTappedCallsCount = 0
    internal var requestButtonTappedClosure: (() -> Void)?
    internal var requestButtonTappedCalled: Bool {
        requestButtonTappedCallsCount > 0
    }

    internal func requestButtonTapped() {
        requestButtonTappedCallsCount += 1
        requestButtonTappedClosure?()
    }

    // MARK: - addRecipientButtonTapped

    internal private(set) var addRecipientButtonTappedCallsCount = 0
    internal var addRecipientButtonTappedClosure: (() -> Void)?
    internal var addRecipientButtonTappedCalled: Bool {
        addRecipientButtonTappedCallsCount > 0
    }

    internal func addRecipientButtonTapped() {
        addRecipientButtonTappedCallsCount += 1
        addRecipientButtonTappedClosure?()
    }
}

internal final class WisetagScannedProfilePresenterMock: WisetagScannedProfilePresenter {
    // MARK: - start

    internal private(set) var startReceivedView: WisetagScannedProfileView?
    internal private(set) var startReceivedInvocations: [WisetagScannedProfileView] = []
    internal private(set) var startCallsCount = 0
    internal var startClosure: ((WisetagScannedProfileView) -> Void)?
    internal var startCalled: Bool {
        startCallsCount > 0
    }

    internal func start(with view: WisetagScannedProfileView) {
        startCallsCount += 1
        startReceivedView = view
        startReceivedInvocations.append(view)
        startClosure?(view)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }

    // MARK: - setBottomSheet

    internal private(set) var setBottomSheetReceivedBottomSheet: BottomSheet?
    internal private(set) var setBottomSheetReceivedInvocations: [BottomSheet?] = []
    internal private(set) var setBottomSheetCallsCount = 0
    internal var setBottomSheetClosure: ((BottomSheet?) -> Void)?
    internal var setBottomSheetCalled: Bool {
        setBottomSheetCallsCount > 0
    }

    internal func setBottomSheet(_ bottomSheet: BottomSheet?) {
        setBottomSheetCallsCount += 1
        setBottomSheetReceivedBottomSheet = bottomSheet
        setBottomSheetReceivedInvocations.append(bottomSheet)
        setBottomSheetClosure?(bottomSheet)
    }
}

internal final class WisetagScannedProfileRouterMock: WisetagScannedProfileRouter {
    // MARK: - sendMoney

    internal private(set) var sendMoneyReceivedArguments: (contact: RecipientResolved, contactId: String?)?
    internal private(set) var sendMoneyReceivedInvocations: [(contact: RecipientResolved, contactId: String?)] = []
    internal private(set) var sendMoneyCallsCount = 0
    internal var sendMoneyClosure: ((RecipientResolved, String?) -> Void)?
    internal var sendMoneyCalled: Bool {
        sendMoneyCallsCount > 0
    }

    internal func sendMoney(_ contact: RecipientResolved, contactId: String?) {
        sendMoneyCallsCount += 1
        sendMoneyReceivedArguments = (contact: contact, contactId: contactId)
        sendMoneyReceivedInvocations.append((contact: contact, contactId: contactId))
        sendMoneyClosure?(contact, contactId)
    }

    // MARK: - requestMoney

    internal private(set) var requestMoneyReceivedContact: Contact?
    internal private(set) var requestMoneyReceivedInvocations: [Contact] = []
    internal private(set) var requestMoneyCallsCount = 0
    internal var requestMoneyClosure: ((Contact) -> Void)?
    internal var requestMoneyCalled: Bool {
        requestMoneyCallsCount > 0
    }

    internal func requestMoney(_ contact: Contact) {
        requestMoneyCallsCount += 1
        requestMoneyReceivedContact = contact
        requestMoneyReceivedInvocations.append(contact)
        requestMoneyClosure?(contact)
    }

    // MARK: - dismiss

    internal private(set) var dismissCallsCount = 0
    internal var dismissClosure: (() -> Void)?
    internal var dismissCalled: Bool {
        dismissCallsCount > 0
    }

    internal func dismiss() {
        dismissCallsCount += 1
        dismissClosure?()
    }
}

internal final class WisetagScannedProfileViewMock: WisetagScannedProfileView {
    internal var bottomSheetContent: UIViewController {
        get { underlyingBottomSheetContent }
        set(value) { underlyingBottomSheetContent = value }
    }

    private var underlyingBottomSheetContent: UIViewController!

    // MARK: - configure

    internal private(set) var configureReceivedViewModel: WisetagScannedProfileViewModel?
    internal private(set) var configureReceivedInvocations: [WisetagScannedProfileViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((WisetagScannedProfileViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: WisetagScannedProfileViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - configureError

    internal private(set) var configureErrorReceivedViewModel: ErrorViewModel?
    internal private(set) var configureErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureErrorCallsCount = 0
    internal var configureErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureErrorCalled: Bool {
        configureErrorCallsCount > 0
    }

    internal func configureError(with viewModel: ErrorViewModel) {
        configureErrorCallsCount += 1
        configureErrorReceivedViewModel = viewModel
        configureErrorReceivedInvocations.append(viewModel)
        configureErrorClosure?(viewModel)
    }
}

internal final class WisetagScannedProfileViewControllerFactoryMock: WisetagScannedProfileViewControllerFactory {
    // MARK: - makeScannedProfile

    internal private(set) var makeScannedProfileReceivedArguments: (
        profile: Profile,
        nickname: String,
        contactSearch: ContactSearch,
        router: WisetagScannedProfileRouter
    )?
    internal private(set) var makeScannedProfileReceivedInvocations: [(
        profile: Profile,
        nickname: String,
        contactSearch: ContactSearch,
        router: WisetagScannedProfileRouter
    )] = []
    internal var makeScannedProfileReturnValue: (UIViewController, WisetagScannedProfilePresenter)!
    internal private(set) var makeScannedProfileCallsCount = 0
    internal var makeScannedProfileClosure: ((Profile, String, ContactSearch, WisetagScannedProfileRouter) -> (
        UIViewController,
        WisetagScannedProfilePresenter
    ))?
    internal var makeScannedProfileCalled: Bool {
        makeScannedProfileCallsCount > 0
    }

    internal func makeScannedProfile(
        profile: Profile,
        nickname: String,
        contactSearch: ContactSearch,
        router: WisetagScannedProfileRouter
    ) -> (UIViewController, WisetagScannedProfilePresenter) {
        makeScannedProfileCallsCount += 1
        makeScannedProfileReceivedArguments = (profile: profile, nickname: nickname, contactSearch: contactSearch, router: router)
        makeScannedProfileReceivedInvocations.append((
            profile: profile,
            nickname: nickname,
            contactSearch: contactSearch,
            router: router
        ))
        guard let makeScannedProfileClosure else {
            return makeScannedProfileReturnValue
        }
        return makeScannedProfileClosure(profile, nickname, contactSearch, router)
    }
}

internal final class WisetagScannedProfileViewModelMapperMock: WisetagScannedProfileViewModelMapper {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        state: WisetagScannedProfileLoadingState,
        nickname: String,
        delegate: WisetagScannedProfileModelDelegate
    )?
    internal private(set) var makeReceivedInvocations: [(
        state: WisetagScannedProfileLoadingState,
        nickname: String,
        delegate: WisetagScannedProfileModelDelegate
    )] = []
    internal var makeReturnValue: WisetagScannedProfileViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((WisetagScannedProfileLoadingState, String, WisetagScannedProfileModelDelegate) -> WisetagScannedProfileViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(state: WisetagScannedProfileLoadingState, nickname: String, delegate: WisetagScannedProfileModelDelegate) -> WisetagScannedProfileViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (state: state, nickname: nickname, delegate: delegate)
        makeReceivedInvocations.append((state: state, nickname: nickname, delegate: delegate))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(state, nickname, delegate)
    }
}

internal final class WisetagShareableLinkStatusUpdaterMock: WisetagShareableLinkStatusUpdater {
    // MARK: - updateShareableLinkStatus

    internal private(set) var updateShareableLinkStatusReceivedIsDiscoverable: Bool?
    internal private(set) var updateShareableLinkStatusReceivedInvocations: [Bool] = []
    internal private(set) var updateShareableLinkStatusCallsCount = 0
    internal var updateShareableLinkStatusClosure: ((Bool) -> Void)?
    internal var updateShareableLinkStatusCalled: Bool {
        updateShareableLinkStatusCallsCount > 0
    }

    internal func updateShareableLinkStatus(isDiscoverable: Bool) {
        updateShareableLinkStatusCallsCount += 1
        updateShareableLinkStatusReceivedIsDiscoverable = isDiscoverable
        updateShareableLinkStatusReceivedInvocations.append(isDiscoverable)
        updateShareableLinkStatusClosure?(isDiscoverable)
    }
}

internal final class WisetagViewMock: WisetagView {
    internal var traitCollection: UITraitCollection {
        get { underlyingTraitCollection }
        set(value) { underlyingTraitCollection = value }
    }

    private var underlyingTraitCollection: UITraitCollection!

    // MARK: - configure

    internal private(set) var configureReceivedViewModel: WisetagViewModel?
    internal private(set) var configureReceivedInvocations: [WisetagViewModel] = []
    internal private(set) var configureCallsCount = 0
    internal var configureClosure: ((WisetagViewModel) -> Void)?
    internal var configureCalled: Bool {
        configureCallsCount > 0
    }

    internal func configure(with viewModel: WisetagViewModel) {
        configureCallsCount += 1
        configureReceivedViewModel = viewModel
        configureReceivedInvocations.append(viewModel)
        configureClosure?(viewModel)
    }

    // MARK: - configureWithError

    internal private(set) var configureWithErrorReceivedWith: ErrorViewModel?
    internal private(set) var configureWithErrorReceivedInvocations: [ErrorViewModel] = []
    internal private(set) var configureWithErrorCallsCount = 0
    internal var configureWithErrorClosure: ((ErrorViewModel) -> Void)?
    internal var configureWithErrorCalled: Bool {
        configureWithErrorCallsCount > 0
    }

    internal func configureWithError(with: ErrorViewModel) {
        configureWithErrorCallsCount += 1
        configureWithErrorReceivedWith = with
        configureWithErrorReceivedInvocations.append(with)
        configureWithErrorClosure?(with)
    }

    // MARK: - showSnackbar

    internal private(set) var showSnackbarReceivedMessage: String?
    internal private(set) var showSnackbarReceivedInvocations: [String] = []
    internal private(set) var showSnackbarCallsCount = 0
    internal var showSnackbarClosure: ((String) -> Void)?
    internal var showSnackbarCalled: Bool {
        showSnackbarCallsCount > 0
    }

    internal func showSnackbar(message: String) {
        showSnackbarCallsCount += 1
        showSnackbarReceivedMessage = message
        showSnackbarReceivedInvocations.append(message)
        showSnackbarClosure?(message)
    }

    // MARK: - showShareSheet

    internal private(set) var showShareSheetReceivedText: String?
    internal private(set) var showShareSheetReceivedInvocations: [String] = []
    internal private(set) var showShareSheetCallsCount = 0
    internal var showShareSheetClosure: ((String) -> Void)?
    internal var showShareSheetCalled: Bool {
        showShareSheetCallsCount > 0
    }

    internal func showShareSheet(text: String) {
        showShareSheetCallsCount += 1
        showShareSheetReceivedText = text
        showShareSheetReceivedInvocations.append(text)
        showShareSheetClosure?(text)
    }

    // MARK: - showHud

    internal private(set) var showHudCallsCount = 0
    internal var showHudClosure: (() -> Void)?
    internal var showHudCalled: Bool {
        showHudCallsCount > 0
    }

    internal func showHud() {
        showHudCallsCount += 1
        showHudClosure?()
    }

    // MARK: - hideHud

    internal private(set) var hideHudCallsCount = 0
    internal var hideHudClosure: (() -> Void)?
    internal var hideHudCalled: Bool {
        hideHudCallsCount > 0
    }

    internal func hideHud() {
        hideHudCallsCount += 1
        hideHudClosure?()
    }
}

internal final class WisetagViewControllerFactoryMock: WisetagViewControllerFactory {
    // MARK: - makeWisetag

    internal private(set) var makeWisetagReceivedArguments: (
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        router: WisetagRouter
    )?
    internal private(set) var makeWisetagReceivedInvocations: [(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        router: WisetagRouter
    )] = []
    internal var makeWisetagReturnValue: (UIViewController, WisetagShareableLinkStatusUpdater)!
    internal private(set) var makeWisetagCallsCount = 0
    internal var makeWisetagClosure: ((Bool, Profile, WisetagRouter) -> (UIViewController, WisetagShareableLinkStatusUpdater))?
    internal var makeWisetagCalled: Bool {
        makeWisetagCallsCount > 0
    }

    internal func makeWisetag(shouldBecomeDiscoverable: Bool, profile: Profile, router: WisetagRouter) -> (
        UIViewController,
        WisetagShareableLinkStatusUpdater
    ) {
        makeWisetagCallsCount += 1
        makeWisetagReceivedArguments = (shouldBecomeDiscoverable: shouldBecomeDiscoverable, profile: profile, router: router)
        makeWisetagReceivedInvocations.append((
            shouldBecomeDiscoverable: shouldBecomeDiscoverable,
            profile: profile,
            router: router
        ))
        guard let makeWisetagClosure else {
            return makeWisetagReturnValue
        }
        return makeWisetagClosure(shouldBecomeDiscoverable, profile, router)
    }

    // MARK: - makeQuickpay

    internal private(set) var makeQuickpayReceivedArguments: (profile: Profile, router: QuickpayRouter)?
    internal private(set) var makeQuickpayReceivedInvocations: [(profile: Profile, router: QuickpayRouter)] = []
    internal var makeQuickpayReturnValue: (UIViewController, QuickpayShareableLinkStatusUpdater)!
    internal private(set) var makeQuickpayCallsCount = 0
    internal var makeQuickpayClosure: ((Profile, QuickpayRouter) -> (UIViewController, QuickpayShareableLinkStatusUpdater))?
    internal var makeQuickpayCalled: Bool {
        makeQuickpayCallsCount > 0
    }

    internal func makeQuickpay(profile: Profile, router: QuickpayRouter) -> (UIViewController, QuickpayShareableLinkStatusUpdater) {
        makeQuickpayCallsCount += 1
        makeQuickpayReceivedArguments = (profile: profile, router: router)
        makeQuickpayReceivedInvocations.append((profile: profile, router: router))
        guard let makeQuickpayClosure else {
            return makeQuickpayReturnValue
        }
        return makeQuickpayClosure(profile, router)
    }

    // MARK: - makeWisetagLearnMore

    internal private(set) var makeWisetagLearnMoreReceivedArguments: (router: WisetagRouter, route: DeepLinkStoryRoute)?
    internal private(set) var makeWisetagLearnMoreReceivedInvocations: [(router: WisetagRouter, route: DeepLinkStoryRoute)] = []
    internal var makeWisetagLearnMoreReturnValue: UIViewController!
    internal private(set) var makeWisetagLearnMoreCallsCount = 0
    internal var makeWisetagLearnMoreClosure: ((WisetagRouter, DeepLinkStoryRoute) -> UIViewController)?
    internal var makeWisetagLearnMoreCalled: Bool {
        makeWisetagLearnMoreCallsCount > 0
    }

    internal func makeWisetagLearnMore(router: WisetagRouter, route: DeepLinkStoryRoute) -> UIViewController {
        makeWisetagLearnMoreCallsCount += 1
        makeWisetagLearnMoreReceivedArguments = (router: router, route: route)
        makeWisetagLearnMoreReceivedInvocations.append((router: router, route: route))
        guard let makeWisetagLearnMoreClosure else {
            return makeWisetagLearnMoreReturnValue
        }
        return makeWisetagLearnMoreClosure(router, route)
    }

    // MARK: - makeContactOnWise

    internal private(set) var makeContactOnWiseReceivedArguments: (
        nickname: String?,
        profile: Profile,
        router: WisetagContactOnWiseRouter
    )?
    internal private(set) var makeContactOnWiseReceivedInvocations: [(
        nickname: String?,
        profile: Profile,
        router: WisetagContactOnWiseRouter
    )] = []
    internal var makeContactOnWiseReturnValue: UIViewController!
    internal private(set) var makeContactOnWiseCallsCount = 0
    internal var makeContactOnWiseClosure: ((String?, Profile, WisetagContactOnWiseRouter) -> UIViewController)?
    internal var makeContactOnWiseCalled: Bool {
        makeContactOnWiseCallsCount > 0
    }

    internal func makeContactOnWise(nickname: String?, profile: Profile, router: WisetagContactOnWiseRouter) -> UIViewController {
        makeContactOnWiseCallsCount += 1
        makeContactOnWiseReceivedArguments = (nickname: nickname, profile: profile, router: router)
        makeContactOnWiseReceivedInvocations.append((nickname: nickname, profile: profile, router: router))
        guard let makeContactOnWiseClosure else {
            return makeContactOnWiseReturnValue
        }
        return makeContactOnWiseClosure(nickname, profile, router)
    }

    // MARK: - makeManageQuickpay

    internal private(set) var makeManageQuickpayReceivedArguments: (router: QuickpayRouter, nickname: String?)?
    internal private(set) var makeManageQuickpayReceivedInvocations: [(router: QuickpayRouter, nickname: String?)] = []
    internal var makeManageQuickpayReturnValue: UIViewController!
    internal private(set) var makeManageQuickpayCallsCount = 0
    internal var makeManageQuickpayClosure: ((QuickpayRouter, String?) -> UIViewController)?
    internal var makeManageQuickpayCalled: Bool {
        makeManageQuickpayCallsCount > 0
    }

    internal func makeManageQuickpay(router: QuickpayRouter, nickname: String?) -> UIViewController {
        makeManageQuickpayCallsCount += 1
        makeManageQuickpayReceivedArguments = (router: router, nickname: nickname)
        makeManageQuickpayReceivedInvocations.append((router: router, nickname: nickname))
        guard let makeManageQuickpayClosure else {
            return makeManageQuickpayReturnValue
        }
        return makeManageQuickpayClosure(router, nickname)
    }

    // MARK: - makeQuickpayInPerson

    internal private(set) var makeQuickpayInPersonReceivedArguments: (
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    )?
    internal private(set) var makeQuickpayInPersonReceivedInvocations: [(
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    )] = []
    internal var makeQuickpayInPersonReturnValue: (UIViewController, QuickpayShareableLinkStatusUpdater)!
    internal private(set) var makeQuickpayInPersonCallsCount = 0
    internal var makeQuickpayInPersonClosure: ((Profile, ShareableLinkStatus.Discoverability, QuickpayRouter) -> (
        UIViewController,
        QuickpayShareableLinkStatusUpdater
    ))?
    internal var makeQuickpayInPersonCalled: Bool {
        makeQuickpayInPersonCallsCount > 0
    }

    internal func makeQuickpayInPerson(profile: Profile, status: ShareableLinkStatus.Discoverability, router: QuickpayRouter) -> (
        UIViewController,
        QuickpayShareableLinkStatusUpdater
    ) {
        makeQuickpayInPersonCallsCount += 1
        makeQuickpayInPersonReceivedArguments = (profile: profile, status: status, router: router)
        makeQuickpayInPersonReceivedInvocations.append((profile: profile, status: status, router: router))
        guard let makeQuickpayInPersonClosure else {
            return makeQuickpayInPersonReturnValue
        }
        return makeQuickpayInPersonClosure(profile, status, router)
    }

    // MARK: - makeQuickpayPersonalise

    internal private(set) var makeQuickpayPersonaliseReceivedArguments: (
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    )?
    internal private(set) var makeQuickpayPersonaliseReceivedInvocations: [(
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    )] = []
    internal var makeQuickpayPersonaliseReturnValue: UIViewController!
    internal private(set) var makeQuickpayPersonaliseCallsCount = 0
    internal var makeQuickpayPersonaliseClosure: ((Profile, ShareableLinkStatus.Discoverability, QuickpayRouter) -> UIViewController)?
    internal var makeQuickpayPersonaliseCalled: Bool {
        makeQuickpayPersonaliseCallsCount > 0
    }

    internal func makeQuickpayPersonalise(profile: Profile, status: ShareableLinkStatus.Discoverability, router: QuickpayRouter) -> UIViewController {
        makeQuickpayPersonaliseCallsCount += 1
        makeQuickpayPersonaliseReceivedArguments = (profile: profile, status: status, router: router)
        makeQuickpayPersonaliseReceivedInvocations.append((profile: profile, status: status, router: router))
        guard let makeQuickpayPersonaliseClosure else {
            return makeQuickpayPersonaliseReturnValue
        }
        return makeQuickpayPersonaliseClosure(profile, status, router)
    }
}

internal final class WisetagViewModelDelegateMock: WisetagViewModelDelegate {
    // MARK: - showWisetagLearnMore

    internal private(set) var showWisetagLearnMoreCallsCount = 0
    internal var showWisetagLearnMoreClosure: (() -> Void)?
    internal var showWisetagLearnMoreCalled: Bool {
        showWisetagLearnMoreCallsCount > 0
    }

    internal func showWisetagLearnMore() {
        showWisetagLearnMoreCallsCount += 1
        showWisetagLearnMoreClosure?()
    }

    // MARK: - shareLinkTapped

    internal private(set) var shareLinkTappedReceivedUrlString: String?
    internal private(set) var shareLinkTappedReceivedInvocations: [String] = []
    internal private(set) var shareLinkTappedCallsCount = 0
    internal var shareLinkTappedClosure: ((String) -> Void)?
    internal var shareLinkTappedCalled: Bool {
        shareLinkTappedCallsCount > 0
    }

    internal func shareLinkTapped(_ urlString: String) {
        shareLinkTappedCallsCount += 1
        shareLinkTappedReceivedUrlString = urlString
        shareLinkTappedReceivedInvocations.append(urlString)
        shareLinkTappedClosure?(urlString)
    }

    // MARK: - qrCodeTapped

    internal private(set) var qrCodeTappedCallsCount = 0
    internal var qrCodeTappedClosure: (() -> Void)?
    internal var qrCodeTappedCalled: Bool {
        qrCodeTappedCallsCount > 0
    }

    internal func qrCodeTapped() {
        qrCodeTappedCallsCount += 1
        qrCodeTappedClosure?()
    }

    // MARK: - footerButtonTapped

    internal private(set) var footerButtonTappedCallsCount = 0
    internal var footerButtonTappedClosure: (() -> Void)?
    internal var footerButtonTappedCalled: Bool {
        footerButtonTappedCallsCount > 0
    }

    internal func footerButtonTapped() {
        footerButtonTappedCallsCount += 1
        footerButtonTappedClosure?()
    }

    // MARK: - showDiscoverabilityBottomSheet

    internal private(set) var showDiscoverabilityBottomSheetCallsCount = 0
    internal var showDiscoverabilityBottomSheetClosure: (() -> Void)?
    internal var showDiscoverabilityBottomSheetCalled: Bool {
        showDiscoverabilityBottomSheetCallsCount > 0
    }

    internal func showDiscoverabilityBottomSheet() {
        showDiscoverabilityBottomSheetCallsCount += 1
        showDiscoverabilityBottomSheetClosure?()
    }

    // MARK: - scanQRcodeTapped

    internal private(set) var scanQRcodeTappedCallsCount = 0
    internal var scanQRcodeTappedClosure: (() -> Void)?
    internal var scanQRcodeTappedCalled: Bool {
        scanQRcodeTappedCallsCount > 0
    }

    internal func scanQRcodeTapped() {
        scanQRcodeTappedCallsCount += 1
        scanQRcodeTappedClosure?()
    }

    // MARK: - downloadTapped

    internal private(set) var downloadTappedCallsCount = 0
    internal var downloadTappedClosure: (() -> Void)?
    internal var downloadTappedCalled: Bool {
        downloadTappedCallsCount > 0
    }

    internal func downloadTapped() {
        downloadTappedCallsCount += 1
        downloadTappedClosure?()
    }

    // MARK: - linkTapped

    internal private(set) var linkTappedCallsCount = 0
    internal var linkTappedClosure: (() -> Void)?
    internal var linkTappedCalled: Bool {
        linkTappedCallsCount > 0
    }

    internal func linkTapped() {
        linkTappedCallsCount += 1
        linkTappedClosure?()
    }
}

internal final class WisetagViewModelMapperMock: WisetagViewModelMapper {
    // MARK: - make

    internal private(set) var makeReceivedArguments: (
        profile: Profile,
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?,
        delegate: WisetagViewModelDelegate
    )?
    internal private(set) var makeReceivedInvocations: [(
        profile: Profile,
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?,
        delegate: WisetagViewModelDelegate
    )] = []
    internal var makeReturnValue: WisetagViewModel!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((Profile, ShareableLinkStatus, UIImage?, WisetagViewModelDelegate) -> WisetagViewModel)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(profile: Profile, status: ShareableLinkStatus, qrCodeImage: UIImage?, delegate: WisetagViewModelDelegate) -> WisetagViewModel {
        makeCallsCount += 1
        makeReceivedArguments = (profile: profile, status: status, qrCodeImage: qrCodeImage, delegate: delegate)
        makeReceivedInvocations.append((profile: profile, status: status, qrCodeImage: qrCodeImage, delegate: delegate))
        guard let makeClosure else {
            return makeReturnValue
        }
        return makeClosure(profile, status, qrCodeImage, delegate)
    }
}

// swiftlint:enable line_length
// swiftlint:enable variable_name
