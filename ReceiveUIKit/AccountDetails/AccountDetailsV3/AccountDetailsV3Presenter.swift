import BalanceKit
import Combine
import CombineSchedulers
import DeepLinkKit
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsV3Presenter: AnyObject {
    var viewActionDelegate: AccountDetailsV3ViewActionDelegate { get }
    var isCurrencySwitcherEnabled: Bool { get }
    func start(with view: AccountDetailsV3View)
    func dismiss()
    func refresh()
}

final class AccountDetailsV3PresenterImpl {
    private weak var view: AccountDetailsV3View?
    private let invocationSource: AccountDetailsInfoInvocationSource
    private let profile: Profile
    private let pasteboard: Pasteboard
    private let accountDetailsUseCase: AccountDetailsV3UseCase
    private let payerPDFUseCase: AccountDetailsPayerPDFUseCase
    private let accountOwnershipProofUseCase: AccountOwnershipProofUseCase
    private let receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCase
    private var accountDetailsId: AccountDetailsId
    private let router: AccountDetailsInfoRouter
    private let accountDetailsSwitcherFactory: AccountDetailsV3SwitcherViewControllerFactory
    private let analyticsTracker: ReceiveMethodsTracking
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var accountDetailsCancellable: AnyCancellable?
    private var payerPDFDownloadCancellable: AnyCancellable?
    private var accountProofOfOwnershipCancellable: AnyCancellable?

    private var accountDetails: AccountDetailsV3?
    private var aliasRegistrationChecked = false
    private var isPayerPDFAvailable = false
    private var analyticsContext: AccountDetailsV3AnalyticsContext?

    init(
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        accountDetailsUseCase: AccountDetailsV3UseCase,
        accountOwnershipProofUseCase: AccountOwnershipProofUseCase,
        payerPDFUseCase: AccountDetailsPayerPDFUseCase,
        receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCase,
        accountDetailsSwitcherFactory: AccountDetailsV3SwitcherViewControllerFactory,
        router: AccountDetailsInfoRouter,
        analyticsTracker: ReceiveMethodsTracking,
        pasteboard: Pasteboard = UIPasteboard.general,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.invocationSource = invocationSource
        self.accountDetailsId = accountDetailsId
        self.profile = profile
        self.accountDetailsUseCase = accountDetailsUseCase
        self.accountOwnershipProofUseCase = accountOwnershipProofUseCase
        self.payerPDFUseCase = payerPDFUseCase
        self.receiveMethodsAliasUseCase = receiveMethodsAliasUseCase
        self.accountDetailsSwitcherFactory = accountDetailsSwitcherFactory
        self.router = router
        self.analyticsTracker = analyticsTracker
        self.pasteboard = pasteboard
        self.scheduler = scheduler
    }
}

// MARK: - AccountDetailsV3Presenter

extension AccountDetailsV3PresenterImpl: AccountDetailsV3Presenter {
    var viewActionDelegate: AccountDetailsV3ViewActionDelegate { self }

    var isCurrencySwitcherEnabled: Bool {
        switch invocationSource {
        case .accountDetailsList:
            true
        case .balanceHeaderAction,
             .orderAccountDetailsFlow,
             .accountDetailsIntro,
             .launchpad,
             .directDebits:
            false
        }
    }

    func start(with view: AccountDetailsV3View) {
        self.view = view
        fetchData()
    }

    func refresh() {
        accountDetailsUseCase.refresh()
        payerPDFUseCase.refresh()
    }

    func dismiss() {}
}

// MARK: - ReceiveMethodActionHandler

extension AccountDetailsV3PresenterImpl: ReceiveMethodActionHandler {
    func handleReceiveMethodAction(action: ReceiveMethodNavigationAction) {
        switch action {
        case let .order(currency, _, _):
            router.orderReceiveMethod(currency: currency, profile: profile)
        case let .query(_, currency, _, _, _):
            router.queryReceiveMethod(currency: currency, profile: profile)
        case let .view(id, _):
            router.cleanViewMethodNavigation()
            accountDetailsId = id
            fetchData()
        }
    }
}

// MARK: - AccountDetailsV3ViewActionDelegate

extension AccountDetailsV3PresenterImpl: AccountDetailsV3ViewActionDelegate {
    func handleHeaderAction(_ action: AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction) {
        switch action {
        case let .share(shareAction):
            guard let view = view?.activeView else { return }
            shareDetails(shareText: shareAction.copyText, sender: view)
        case let .urn(urnAction):
            guard let urn = try? URN(urnAction.value) else {
                softFailure("[REC]: Invalid value for URN received - (\(urnAction.value))")
                return
            }
            router.handleURI(.urn(urn))
        }
    }

    func containerTapped(content: AccountDetailsV3Information.InformationItem.DetailedSummary) {
        let model = AccountDetailsV3ViewModelMapper.mapKeyInformationDetails(content: content, router: router)
        router.showDetails(model: model)
    }

    func handleExternalAction(action: AccountDetailsExternalAction?) {
        switch action {
        case let .modal(content):
            let button: AccountDetailsV3Modal.ModalButton? = content.buttons?.first.map {
                AccountDetailsV3Modal.ModalButton(
                    value: $0.value,
                    title: $0.title,
                    priority: AccountDetailsV3ViewModelMapper.mapToButtonStyle(
                        buttonPriority: $0.priority
                    ),
                    type: $0.type
                )
            }

            let modal = AccountDetailsV3Modal(
                title: content.title,
                body: content.body,
                button: button,
                trackModalButtonTapped: { [weak self] in
                    guard let self else { return }
                    trackEvent(event: .modalButtonSelected(value: button?.value))
                }
            )
            router.showBottomsheetAccountDetailsV3(modal: modal)
        case let .urn(urnString):
            router.handleURI(.urn(urnString))
        case let .url(urlString):
            router.showArticle(url: urlString)
        case .none:
            break
        }
    }

    func handleAlertAction(uri: URI) {
        router.handleURI(uri)
    }

    func handleCopyAction(copyText: String, feedbackText: String) {
        copy(
            content: copyText,
            fieldName: feedbackText
        )
    }

    func handleFeedbackAction() {
        let model = FeedbackViewModel(
            title: L10n.AccountDetailsV3.FeedbackForm.Form.title,
            description: L10n.AccountDetailsV3.FeedbackForm.Form.description,
            ratingMode: .sevenScale(legend: .range(
                min: L10n.AccountDetailsV3.FeedbackForm.Form.minValue,
                max: L10n.AccountDetailsV3.FeedbackForm.Form.maxValue
            )),
            placeholder: L10n.Balance.Shared.Feedback.placeholder,
            submitButtonTitle: L10n.AccountDetailsV3.FeedbackForm.Form.submit
        )
        let context = FeedbackContext(
            feature: "ACCOUNT_DETAILS_QUALITY_SURVEY",
            pageName: nil,
            profileId: profile.id
        )

        router.showFeedback(
            model: model,
            context: context
        ) { [weak self] in
            self?.view?.showConfirmation(
                message: L10n.AccountDetailsV3.FeedbackForm.successMessage
            )
        }

        trackEvent(event: .feedbackFormSelected)
    }

    // swiftlint:disable cyclomatic_complexity
    func trackEvent(event: AccountDetailsV3AnalyticsEvent.Event) {
        guard let analyticsContext else { return }
        switch event {
        case .pageLoaded:
            analyticsTracker.onLoaded(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context)
            )
        case let .chipSelected(chip):
            analyticsTracker.onChipSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context),
                chip: mapChipType(chip)
            )
        case let .containerSelected(chip):
            analyticsTracker.onContainerSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context),
                chip: mapChipType(chip)
            )
        case .feedbackFormSelected:
            analyticsTracker.onFeedbackFormSelected()
        case let .modalButtonSelected(value):
            analyticsTracker.onModalButtonSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context),
                value: value ?? ""
            )
        case let .currencyHeaderMarkupClicked(value):
            analyticsTracker.onCurrencyHeaderMarkupClicked(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context),
                value: value
            )
        case let .markupLinkClicked(detailType, value):
            analyticsTracker.onMarkupMarkupClicked(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context),
                detailType: mapDetail(detailType),
                value: value ?? ""
            )
        case let .detailCopied(detailType):
            analyticsTracker.onDetailCopied(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context),
                detailType: mapDetail(detailType)
            )
        case .shareButtonSelected:
            analyticsTracker.onShareSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context)
            )
        case .shareDetailsSelected:
            analyticsTracker.onShareDetailsSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context)
            )
        case .copyDetailsSelected:
            analyticsTracker.onCopyDetailsSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context)
            )
        case .downloadDetailsSelected:
            analyticsTracker.onDownloadDetailsSelected(
                currency: analyticsContext.currency,
                type: mapType(analyticsContext.type),
                context: mapContext(analyticsContext.context)
            )
        }
    }
}

// MARK: - Data loading

private extension AccountDetailsV3PresenterImpl {
    func fetchData() {
        guard let view else { return }

        let accountDetailsPublisher = accountDetailsUseCase.getAccountDetailsV3(
            profileId: profile.id,
            methodType: AccountDetailsMethodType.accountDetails,
            methodId: accountDetailsId
        )

        let combinedAccountDetailsPublisher = appendShouldNavigateAlias(
            to: accountDetailsPublisher
        )

        let publisher = Publishers.CombineLatest(
            combinedAccountDetailsPublisher,
            payerPDFUseCase.checkAvailability(
                accountDetailsId: accountDetailsId,
                profileId: profile.id
            )
        ).eraseToAnyPublisher()

        accountDetailsCancellable = publisher.map { accountDetailsModel, pdfModel in
            ModelState<(AccountDetailsV3, Bool, Bool), any Error>.mergeThree(
                first: accountDetailsModel.0,
                second: accountDetailsModel.1,
                third: pdfModel
            )
        }.eraseToAnyPublisher()
            .receive(on: scheduler)
            .handleLoading(view)
            .compactMap { $0.content }
            .sink { [weak self] (result: (AccountDetailsV3, Bool, Bool)) in
                guard let self else {
                    return
                }
                let (accountDetails, shouldNavigateAliasRegistration, isPayerPDFAvailable) = result
                self.accountDetails = accountDetails
                self.isPayerPDFAvailable = isPayerPDFAvailable
                configureViewModel(model: accountDetails)
                analyticsContext = .init(
                    currency: accountDetails.currency.value,
                    type: .ACCOUNT_DETAILS,
                    context: .DEFAULT
                )
                trackEvent(event: .pageLoaded)

                handleAliasRegistraionResult(
                    shouldNavigateAliasRegistration: shouldNavigateAliasRegistration,
                    accountDetailsId: accountDetails.id
                )
            }
    }

    func configureViewModel(model: AccountDetailsV3) {
        view?.configure(with: model)

        let navigationBarModel = AccountDetailsV3CurrencySelectorViewModel(
            title: model.currency.value,
            subtitle: model.title,
            currency: model.currency,
            isOnTapEnabled: isCurrencySwitcherEnabled,
            onTap: { [weak self] in
                guard let self else { return }
                currencySelectorTapped()
            }
        )
        view?.configureNavigationBar(with: navigationBarModel)
    }

    func currencySelectorTapped() {
        if isCurrencySwitcherEnabled {
            let vc = accountDetailsSwitcherFactory.make(profile: profile, actionHandler: self)
            router.showSwitcher(viewController: vc)
        }
    }

    func copy(
        content: String,
        fieldName: String
    ) {
        pasteboard.addToClipboard(content)
        view?.generateHapticFeedback()
        view?.showConfirmation(
            message: fieldName
        )
    }

    func downloadPayerPDF() {
        guard let id = accountDetails?.id else {
            softFailure("[REC]: Account details id for account details V3 is nil")
            return
        }

        view?.showHud()
        payerPDFDownloadCancellable = payerPDFUseCase.pdf(
            accountDetailsId: id,
            profileId: profile.id
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self,
                  let view else {
                return
            }
            view.hideHud()
            switch result {
            case let .success(url):
                router.showFile(
                    url: url,
                    delegate: view.documentInteractionControllerDelegate
                )
            case .failure:
                view.showErrorAlert(
                    title: L10n.Generic.Error.title,
                    message: L10n.Generic.Error.message
                )
            }
        }
    }

    func downloadCertifiedProofOfOwnership() {
        guard let id = accountDetails?.id,
              let currencyCode = accountDetails?.currency else { return }

        view?.showHud()
        accountProofOfOwnershipCancellable = accountOwnershipProofUseCase.accountOwnershipProof(
            profileId: profile.id,
            accountDetailsId: id,
            currencyCode: currencyCode,
            addStamp: true
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self,
                  let view else {
                return
            }
            view.hideHud()
            switch result {
            case let .success(url):
                router.showFile(
                    url: url,
                    delegate: view.documentInteractionControllerDelegate
                )
            case .failure:
                view.showErrorAlert(
                    title: L10n.Generic.Error.title,
                    message: L10n.Generic.Error.message
                )
            }
        }
    }

    func shareDetails(shareText: String, sender: UIView?) {
        guard let currencyCode = accountDetails?.currency else {
            return
        }

        let shareActions: [AccountDetailsShareAction] = createShareActions(
            shareText: shareText,
            sender: sender
        )

        router.showShareActionsAccountDetailsV3(
            title: L10n.AccountDetails.Share.Sheet.title,
            currencyCode: currencyCode,
            actions: shareActions
        )

        trackEvent(event: .shareButtonSelected)
    }

    func createShareActions(shareText: String, sender: UIView?) -> [AccountDetailsShareAction] {
        var actions: [AccountDetailsShareAction] = [
            AccountDetailsShareAction(
                title: L10n.AccountDetails.Share.Sheet.Items.shareToContact,
                image: Icons.shareIos.image,
                handler: { [weak self] in
                    guard let self,
                          let sender else {
                        return
                    }
                    router.showShareSheet(
                        with: shareText,
                        sender: sender,
                        completion: { _, _ in }
                    )
                    trackEvent(event: .shareDetailsSelected)
                }
            ),
            AccountDetailsShareAction(
                title: L10n.AccountDetails.Share.Sheet.Items.copyDetails,
                image: Icons.documents.image,
                handler: { [weak self] in
                    guard let self else { return }
                    copy(content: shareText, fieldName: L10n.AccountDetails.Info.Details.Copy.Snack.AccountDetails.Copied.message)
                    trackEvent(event: .copyDetailsSelected)
                }
            ),
        ]

        var pdfActions = [
            AccountDetailsV3ShareAction(
                title: L10n.AccountDetailsV3.Share.OwnershipProof.title,
                subtitle: L10n.AccountDetailsV3.Share.OwnershipProof.subtitle,
                handler: { [weak self] in
                    guard let self else { return }
                    downloadCertifiedProofOfOwnership()
                }
            ),
        ]

        if isPayerPDFAvailable {
            pdfActions.insert(
                AccountDetailsV3ShareAction(
                    title: L10n.AccountDetailsV3.Share.Pdf.title,
                    subtitle: L10n.AccountDetailsV3.Share.Pdf.subtitle,
                    handler: { [weak self] in
                        self?.downloadPayerPDF()
                    }
                ),
                at: 0
            )
        }

        actions.append(
            AccountDetailsShareAction(
                title: L10n.AccountDetailsV3.Share.Pdf.Download.title,
                image: Icons.download.image,
                handler: { [weak self] in
                    guard let self else { return }
                    router.showDownloadPDFSheet(actions: pdfActions)
                    trackEvent(event: .downloadDetailsSelected)
                }
            )
        )
        return actions
    }
}

// MARK: - Alias registration

private extension AccountDetailsV3PresenterImpl {
    private func appendShouldNavigateAlias(
        to accountDetailsPublisher: AnyPublisher<ModelState<AccountDetailsV3, Error>, Never>
    ) -> AnyPublisher<(ModelState<AccountDetailsV3, Error>, ModelState<Bool, Error>), Never> {
        accountDetailsPublisher.flatMap { [unowned self] modelState in
            shouldNavigateAlias(accountDetails: modelState.content)
                .map {
                    (
                        modelState,
                        ModelState<Bool, Error>.content($0)
                    )
                }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    func shouldNavigateAlias(accountDetails: AccountDetailsV3?) -> AnyPublisher<Bool, Never> {
        guard let accountDetails,
              accountDetails.currency == .BRL,
              profile.has(privilege: BalancePrivilege.manage),
              !aliasRegistrationChecked else {
            return .just(false)
        }
        return receiveMethodsAliasUseCase.aliases(
            accountDetailsId: accountDetailsId,
            profileId: profile.id
        )
        .map { aliases in
            !PixStatusChecker.hasPixAliasRegistered(
                aliases: aliases
            )
        }
        .replaceError(with: false)
        .eraseToAnyPublisher()
    }

    func handleAliasRegistraionResult(
        shouldNavigateAliasRegistration: Bool,
        accountDetailsId: AccountDetailsId
    ) {
        // Copy before modifying
        let _aliasRegistrationChecked = aliasRegistrationChecked
        aliasRegistrationChecked = true
        if shouldNavigateAliasRegistration,
           !_aliasRegistrationChecked {
            router.showReceiveMethodAliasRegistration(
                accountDetailsId: accountDetailsId,
                profileId: profile.id
            )
        }
    }
}

// MARK: Tracking helpers

private extension AccountDetailsV3PresenterImpl {
    func mapType(_ type: AccountDetailsV3AnalyticsContext.`Type`) -> ReceiveMethodsType {
        switch type {
        case .ACCOUNT_DETAILS:
            .AccountDetails()
        case .INTERAC:
            .Interac()
        case .SGD_FAST:
            .SgdFast()
        case .SGD_GIRO:
            .SgdGiro()
        case .PAY_NOW:
            .PayNow()
        case .PIX:
            .Pix()
        }
    }

    func mapContext(_ context: AccountDetailsV3AnalyticsContext.Context) -> ReceiveMethodsContext {
        switch context {
        case .DEFAULT:
            .default_
        case .DIRECT_DEBITS:
            .directDebits
        case .PAYMENT_REQUEST:
            .paymentRequest
        }
    }

    func mapChipType(_ type: KeyInformationType) -> ReceiveMethodsChip {
        switch type {
        case .fees:
            .Fees()
        case .limits:
            .Limits()
        case .speed:
            .Speed()
        }
    }

    func mapDetail(_ detail: AccountDetailsV3AnalyticsEvent.DetailType) -> ReceiveMethodsDetailType {
        switch detail {
        case .ACCOUNT_HOLDER:
            .AccountHolder()
        case .ACCOUNT_NUMBER:
            .AccountNumber()
        case .BANK_CODE:
            .BankCode()
        case .BANK_NAME_ADDRESS:
            .BankNameAddress()
        case .BIC:
            .Bic()
        case .IBAN:
            .Iban()
        case .other:
            .Unknown(trackingName: "")
        }
    }
}

// swiftlint:enable cyclomatic_complexity
