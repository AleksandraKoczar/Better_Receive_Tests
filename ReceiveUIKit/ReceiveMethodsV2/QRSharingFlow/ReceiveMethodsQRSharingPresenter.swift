import Combine
import CombineSchedulers
import Foundation
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol ReceiveMethodsQRSharingPresenter: AnyObject {
    func start(with view: ReceiveMethodsQRSharingView)
    func activeIndexChanged(_ index: Int)
}

final class ReceiveMethodsQRSharingPresenterImpl {
    private weak var view: ReceiveMethodsQRSharingView?
    private var activeIndex = 0
    private var aliasContainers: [ReceiveMethodAliasContainer] = []

    private let accountDetailsId: AccountDetailsId
    private let profile: Profile
    private let mode: ReceiveMethodsQRSharingMode
    private let useCase: PixQRUseCase
    private let aliasUseCase: ReceiveMethodsAliasUseCase
    private let router: ReceiveMethodsQRSharingRouter
    private let pasteboard: Pasteboard
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var cancellable: AnyCancellable?

    init(
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        mode: ReceiveMethodsQRSharingMode,
        useCase: PixQRUseCase,
        aliasUseCase: ReceiveMethodsAliasUseCase,
        router: ReceiveMethodsQRSharingRouter,
        pasteboard: Pasteboard = UIPasteboard.general,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.accountDetailsId = accountDetailsId
        self.profile = profile
        self.mode = mode
        self.useCase = useCase
        self.aliasUseCase = aliasUseCase
        self.router = router
        self.pasteboard = pasteboard
        self.scheduler = scheduler
    }
}

// MARK: - ReceiveMethodsQRSharingPresenter

extension ReceiveMethodsQRSharingPresenterImpl: ReceiveMethodsQRSharingPresenter {
    func start(with view: ReceiveMethodsQRSharingView) {
        self.view = view
        loadContent()
    }

    func activeIndexChanged(_ index: Int) {
        activeIndex = index
    }
}

// MARK: - Loading data

private extension ReceiveMethodsQRSharingPresenterImpl {
    func loadContent() {
        let requestInfo: (amount: Decimal?, message: String?)? =
            switch mode {
            case .all:
                (nil, nil)
            case let .single(model):
                (model.amount, model.message)
            }

        view?.displayHud()
        cancellable = aliasPublisher()
            .flatMap { [unowned self] aliases -> AnyPublisher<[ReceiveMethodAliasContainer], Error> in
                let qrRequestsWithAliases = aliases
                    .map { alias in
                        self.useCase.qr(
                            request: .init(
                                alias: alias.key.unwrappedValue,
                                profileId: self.profile.id,
                                amount: requestInfo?.amount,
                                message: requestInfo?.message,
                                transactionId: nil
                            )
                        )
                        .compactMap { qr -> ReceiveMethodAliasContainer? in
                            guard let qr,
                                  let data = Data(base64Encoded: qr.imageString),
                                  let image = UIImage(data: data) else {
                                return nil
                            }
                            return ReceiveMethodAliasContainer(
                                alias: alias,
                                qrPayload: qr.payload,
                                qr: image
                            )
                        }
                        .eraseToAnyPublisher()
                    }
                return Publishers.combineLatestMany(qrRequestsWithAliases)
            }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }
                view?.removeHud()
                switch result {
                case let .success(aliasContainers):
                    guard aliasContainers.isNonEmpty else {
                        showError()
                        return
                    }
                    self.aliasContainers = aliasContainers
                    configureView(aliasContainers: aliasContainers)
                case .failure:
                    showError()
                }
            }
    }

    func aliasPublisher() -> AnyPublisher<[ReceiveMethodAlias], Error> {
        switch mode {
        case .all:
            aliasUseCase.aliases(
                accountDetailsId: accountDetailsId,
                profileId: profile.id
            )
            .map { aliases -> [ReceiveMethodAlias] in
                aliases
                    .lazy
                    .filter { $0.state == .registered }
                    // Ignore aliases without a key value and use the extension below to access it
                    .filter { $0.key.value != nil }
            }.eraseToAnyPublisher()
        case let .single(model):
            .just([model.alias])
        }
    }
}

// MARK: - Actions

private extension ReceiveMethodsQRSharingPresenterImpl {
    func shareTapped() {
        guard let aliasContainer = aliasContainers[safe: activeIndex] else { return }
        view?.showShareSheet(text: aliasContainer.alias.key.unwrappedValue)
    }

    func downloadTapped() {
        guard let vc = view as? UIViewController,
              let aliasContainer = aliasContainers[safe: activeIndex] else {
            return
        }
        router.showDownload(image: aliasContainer.qr, viewController: vc)
    }

    func addDetailsTapped() {
        guard let aliasContainer = aliasContainers[safe: activeIndex] else {
            return
        }
        router.showCustomisation(
            alias: aliasContainer.alias,
            accountDetailsId: accountDetailsId,
            profileId: profile.id
        )
    }

    func pixCopyPasteTapped() {
        guard let aliasContainer = aliasContainers[safe: activeIndex] else {
            return
        }
        pasteboard.addToClipboard(aliasContainer.qrPayload)
        view?.showSnackbar(message: L10n.Receive.Pix.Share.Action.PixCopyPaste.completed)
    }
}

// MARK: - View building

private extension ReceiveMethodsQRSharingPresenterImpl {
    func showError() {
        view?.configureWithError(
            with: ErrorViewModel.networkError(
                primaryViewModel: .tryAgain { [weak self] in
                    self?.loadContent()
                }
            )
        )
    }

    func configureView(aliasContainers: [ReceiveMethodAliasContainer]) {
        let keys = makeKeys(aliasContainers: aliasContainers)
        let titleSubtitlePair = makeTitleSubtitlePair()

        view?.configure(
            with: ReceiveMethodsQRSharingViewModel(
                title: titleSubtitlePair.title,
                subtitle: titleSubtitlePair.subtitle,
                keys: keys,
                buttons: makeActionButtons()
            )
        )
    }

    func makeKeys(
        aliasContainers: [ReceiveMethodAliasContainer]
    ) -> [ReceiveMethodsQRSharingViewModel.Key] {
        aliasContainers.map { aliasContainer in
            ReceiveMethodsQRSharingViewModel.Key(
                qr: aliasContainer.qr,
                method: .init(
                    icon: Icons.pix.image,
                    name: aliasContainer.alias.aliasScheme
                ),
                type: {
                    switch aliasContainer.alias.key.type {
                    case .email:
                        L10n.Receive.Pix.Share.Key.Email.title
                    case .phoneNumber:
                        L10n.Receive.Pix.Share.Key.PhoneNumber.title
                    case .randomKey:
                        L10n.Receive.Pix.Share.Key.RandomKey.title
                    case .taxId:
                        switch profile.type {
                        case .personal:
                            L10n.Receive.Pix.Share.Key.TaxId.Personal.title
                        case .business:
                            L10n.Receive.Pix.Share.Key.TaxId.Business.title
                        }
                    case .other:
                        ""
                    }
                }(),
                value: {
                    switch aliasContainer.alias.key.type {
                    case .taxId:
                        BrazillianTaxIDFormatter.format(
                            aliasContainer.alias.key.unwrappedValue,
                            profileType: profile.type
                        )
                    case .email,
                         .phoneNumber,
                         .randomKey,
                         .other:
                        aliasContainer.alias.key.unwrappedValue
                    }
                }()
            )
        }
    }

    func makeTitleSubtitlePair() -> (title: String, subtitle: String) {
        switch mode {
        case .all:
            return (L10n.Receive.Pix.Share.title, L10n.Receive.Pix.Share.subtitle)
        case let .single(model):
            let subtitle = {
                if let amount = model.amount,
                   let message = model.message {
                    let formattedAmount = MoneyFormatter.format(amount, withCurrencyCode: CurrencyCode.BRL)
                    return L10n.Receive.Pix.Share.SingleKey.Subtitle.amountAndMessage(formattedAmount, message)
                } else if let amount = model.amount {
                    return MoneyFormatter.format(amount, withCurrencyCode: CurrencyCode.BRL)
                } else if let message = model.message {
                    return L10n.Receive.Pix.Share.SingleKey.Subtitle.onlyMessage(message)
                } else {
                    return ""
                }
            }()
            return (L10n.Receive.Pix.Share.SingleKey.title, subtitle)
        }
    }

    func makeActionButtons() -> [ReceiveMethodsQRSharingViewModel.ButtonViewModel] {
        let shareAction = shareTapped
        let downloadAction = downloadTapped
        let addDetailsAction = addDetailsTapped
        let pixCopyPasteAction = pixCopyPasteTapped

        let shareButton = ReceiveMethodsQRSharingViewModel.ButtonViewModel(
            icon: Icons.shareIos.image,
            title: L10n.Receive.Pix.Share.Action.Share.title,
            isPrimary: true,
            action: shareAction
        )

        let downloadButton = ReceiveMethodsQRSharingViewModel.ButtonViewModel(
            icon: Icons.download.image,
            title: L10n.Receive.Pix.Share.Action.Download.title,
            isPrimary: false,
            action: downloadAction
        )

        switch mode {
        case .all:
            return [
                shareButton,
                ReceiveMethodsQRSharingViewModel.ButtonViewModel(
                    icon: Icons.edit.image,
                    title: L10n.Receive.Pix.Share.Action.AddDetails.title,
                    isPrimary: false,
                    action: addDetailsAction
                ),
                downloadButton,
            ]
        case .single:
            return [
                ReceiveMethodsQRSharingViewModel.ButtonViewModel(
                    icon: Icons.documents.image,
                    title: L10n.Receive.Pix.Share.Action.PixCopyPaste.title,
                    isPrimary: true,
                    action: pixCopyPasteAction
                ),
                downloadButton,
            ]
        }
    }
}

// MARK: - ReceiveMethodAliasContainer

private struct ReceiveMethodAliasContainer {
    let alias: ReceiveMethodAlias
    let qrPayload: String
    let qr: UIImage
}

// MARK: - ReceiveMethodAlias

private extension ReceiveMethodAlias.AliasKey {
    /// We should use this here as the field without a value is already filtered above
    var unwrappedValue: String {
        guard let value else {
            softFailure("[REC]: AliasKey without value was supposed to be filtered before this point.")
            return ""
        }
        return value
    }
}
