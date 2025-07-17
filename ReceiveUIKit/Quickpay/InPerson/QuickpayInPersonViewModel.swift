import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import UserKit
import WiseCore

enum QuickpayPersonaliseAction {
    case load
}

struct QuickpayPersonaliseContent: Equatable, Sendable {
    let qrCodeViewModel: WisetagQRCodeViewModel
    let preferredCurrency: CurrencyCode
    let availableCurrencies: [CurrencyCode]
}

@MainActor
final class QuickpayInPersonViewModel: ModelStateViewModel<QuickpayPersonaliseContent, QuickpayPersonaliseAction, Error> {
    private enum QuickpayPersonaliseError: Error {
        case failedToUpdateQRCode
        case failedToUpdateStatus
        case failedToLoad
    }

    private enum Constants {
        static let quickpayDomain = "wise.com/pay/business/"
    }

    @Published
    var status: ShareableLinkStatus.Discoverability
    @Published
    var isSetAmountToggleOn: Bool
    @Published
    var amount = MoneyInputValue(raw: "")
    @Published
    var selectedCurrency: CurrencyCode = .GBP
    @Published
    var allCurrencies: [CurrencyCode] = []
    @Published
    var description = ""
    @Published
    var link = ""
    @Published
    var showCurrencySelector = false
    @Published
    var qrCodeViewModel: WisetagQRCodeViewModel?

    var errorMessageForDescription: String?

    var footerTitle: String {
        switch status {
        case .discoverable:
            L10n.Quickpay.PersonalisePage.Confirm.title
        case .notDiscoverable:
            L10n.Quickpay.QrCode.TurnOn.title
        }
    }

    var nickname: String? {
        switch status {
        case let .discoverable(_, nickname):
            String(nickname.dropFirst())
        case .notDiscoverable:
            nil
        }
    }

    @Published
    var confirmationSheetViewModel: QuickpayConfirmationSheetViewModel?

    private let quickpayUseCase: QuickpayUseCase
    private let wisetagInteractor: WisetagInteractor
    private let pasteboard: Pasteboard
    private let profile: Profile
    private let onDownloadQRCodeTapped: ((UIImage) -> Void)?

    init(
        profile: Profile,
        quickpayUseCase: QuickpayUseCase,
        wisetagInteractor: WisetagInteractor,
        status: ShareableLinkStatus.Discoverability,
        pasteboard: Pasteboard,
        onDownloadQRCodeTapped: ((UIImage) -> Void)?
    ) {
        self.profile = profile
        self.quickpayUseCase = quickpayUseCase
        self.wisetagInteractor = wisetagInteractor
        self.status = status
        self.pasteboard = pasteboard
        self.onDownloadQRCodeTapped = onDownloadQRCodeTapped
        isSetAmountToggleOn = (status != .notDiscoverable)
        super.init()
    }

    override func handle(_ action: QuickpayPersonaliseAction) async {
        switch action {
        case .load:
            await load()
        }
    }

    private func load() async {
        await loading { [weak self] in
            guard let self else { return .initial }

            guard let (_, image) = try await wisetagInteractor
                .fetchQRCode(
                    status: .eligible(status),
                    link: generateLink()
                )
                .values
                .first() else {
                return .error(QuickpayPersonaliseError.failedToLoad)
            }

            guard let nickname else {
                qrCodeViewModel = WisetagQRCodeViewModel(state: getQRCodeState(image: image))
                selectedCurrency = .GBP
                allCurrencies = []
                let content = QuickpayPersonaliseContent(
                    qrCodeViewModel: qrCodeViewModel!,
                    preferredCurrency: selectedCurrency,
                    availableCurrencies: allCurrencies
                )
                return .content(content)
            }

            guard let currencyAvailability = try await quickpayUseCase
                .getCurrencyAvailability(wisetag: nickname)
                .values
                .first()?
                .content else {
                return .error(QuickpayPersonaliseError.failedToLoad)
            }

            qrCodeViewModel = WisetagQRCodeViewModel(state: getQRCodeState(image: image))
            selectedCurrency = currencyAvailability.preferredCurrency
            allCurrencies = currencyAvailability.availableCurrencies

            let content = QuickpayPersonaliseContent(
                qrCodeViewModel: qrCodeViewModel!,
                preferredCurrency: selectedCurrency,
                availableCurrencies: allCurrencies
            )
            return .content(content)
        }
    }

    func updateLinkStatus(isDiscoverable: Bool) async {
        do {
            guard let (status, _) = try await wisetagInteractor
                .updateShareableLinkStatus(
                    profileId: profile.id,
                    isDiscoverable: isDiscoverable
                ).values
                .first() else {
                state = .error(QuickpayPersonaliseError.failedToUpdateQRCode)
                return
            }
            guard case let .eligible(eligibility) = status else {
                state = .error(QuickpayPersonaliseError.failedToUpdateQRCode)
                return
            }

            self.status = eligibility
            setAmountToggled(isOn: isDiscoverable)
            await load()
        } catch {
            state = .error(QuickpayPersonaliseError.failedToUpdateStatus)
        }
    }

    func updateQRCode() async {
        do {
            guard let (_, image) = try await wisetagInteractor.fetchQRCode(status: .eligible(status), link: generateLink())
                .values.first() else {
                state = .error(QuickpayPersonaliseError.failedToUpdateQRCode)
                return
            }
            let qrCode = WisetagQRCodeViewModel(
                state: .qrCodeEnabled(
                    qrCode: image,
                    enabledText: L10n.Quickpay.QrCode.Download.title,
                    enabledTextOnTap: L10n.Quickpay.QrCode.Downloading.title,
                    onTap: { [weak self] in
                        self?.downloadQRCode()
                    }
                )
            )
            qrCodeViewModel = qrCode
        } catch {
            state = .error(QuickpayPersonaliseError.failedToUpdateQRCode)
        }
    }

    func footerTapped() async {
        switch status {
        case let .discoverable(_, nickname):
            let money: Money? = amount.raw.isEmpty ? nil : Money(
                currency: selectedCurrency,
                value: Decimal(string: amount.raw) ?? 1.0
            )

            confirmationSheetViewModel = .init(
                qrCodeImage: qrCodeViewModel?.qrCodeImage,
                title: L10n.Quickpay.PersonalisePage.ScanToPay.title,
                businessName: nickname,
                money: money,
                description: (errorMessageForDescription.isNil && description.isNonEmpty) ? description : nil,
                link: generateLink(),
                copyLink: { [weak self] in
                    self?.pasteboard.addToClipboard(self?.generateLink())
                }
            )

        case .notDiscoverable:
            await updateLinkStatus(isDiscoverable: true)
        }
    }

    func copyLink() {
        pasteboard.addToClipboard(generateLink())

        link = L10n.Wisetag.SnackBar.Message.copyLink
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self else { return }
            link = generateLink()
        }
    }

    func setAmountToggled(isOn: Bool) {
        isSetAmountToggleOn = isOn
    }

    func downloadQRCode() {
        if let image = qrCodeViewModel?.qrCodeImage {
            onDownloadQRCodeTapped?(image)
        }
    }

    func onDescriptionChange(text: String) async {
        if isValidDescription(text) {
            errorMessageForDescription = nil
            await updateQRCode()
        } else {
            errorMessageForDescription = L10n.Quickpay.PersonalisePage.InvalidCharacter.title
        }
    }

    var onChangeCurrency: Binding<Bool>? {
        guard allCurrencies.count > 1 else {
            return nil
        }
        return Binding<Bool>(
            get: { false },
            set: { _ in
                self.showCurrencySelector = true
            }
        )
    }
}

// MARK: Helpers

private extension QuickpayInPersonViewModel {
    func getQRCodeState(image: UIImage?) -> WisetagQRCodeViewModel.QRCodeState {
        switch status {
        case .discoverable:
            .qrCodeEnabled(
                qrCode: image,
                enabledText: L10n.Quickpay.QrCode.Download.title,
                enabledTextOnTap: L10n.Quickpay.QrCode.Downloading.title,
                onTap: { [weak self] in
                    self?.downloadQRCode()
                }
            )
        case .notDiscoverable:
            .qrCodeDisabled(placeholderQRCode: image, disabledText: L10n.Quickpay.QrCode.TurnedOff.title, onTap: {})
        }
    }

    func isValidDescription(_ text: String) -> Bool {
        let allowedCharacters = CharacterSet.letters.union(.decimalDigits).union(CharacterSet(charactersIn: " -"))
        return text.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    func generateLink() -> String {
        guard let nickname else {
            return Branding.current.urlString
        }

        let currrencyQueryItem = URLQueryItem(name: "currency", value: selectedCurrency.value)
        let amountQueryItem = URLQueryItem(name: "amount", value: amount.raw)
        let descriptionQueryItem = URLQueryItem(name: "description", value: description)

        guard let url = URL(string: Constants.quickpayDomain),
              var components = URLComponents(
                  url: url.appendingPathComponent(nickname),
                  resolvingAgainstBaseURL: false
              ) else { return "" }

        var queryItems: [URLQueryItem] = []

        if amount.raw.isNonEmpty {
            queryItems.append(currrencyQueryItem)
            queryItems.append(amountQueryItem)
        }

        if description.isNonEmpty {
            queryItems.append(descriptionQueryItem)
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.description
    }
}

// MARK: Status Update

extension QuickpayInPersonViewModel: QuickpayShareableLinkStatusUpdater {
    func updateShareableLinkStatus(isDiscoverable: Bool) {
        Task { [weak self] in
            guard let self else { return }
            await updateLinkStatus(isDiscoverable: isDiscoverable)
        }
    }
}

// MARK: QuickpayConfirmationSheetViewModel

struct QuickpayConfirmationSheetViewModel: Equatable {
    let qrCodeImage: UIImage?
    let title: String
    let businessName: String
    let money: Money?
    let description: String?
    let link: String
    let copyLink: () -> Void

    static func == (lhs: QuickpayConfirmationSheetViewModel, rhs: QuickpayConfirmationSheetViewModel) -> Bool {
        lhs.title == rhs.title &&
            lhs.businessName == rhs.businessName &&
            lhs.money == rhs.money &&
            lhs.description == rhs.description &&
            lhs.link == rhs.link
    }
}
