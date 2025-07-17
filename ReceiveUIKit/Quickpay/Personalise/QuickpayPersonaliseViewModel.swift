import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import WiseCore

@MainActor
final class QuickpayPersonaliseViewModel: ModelStateViewModel<QuickpayPersonaliseContent, QuickpayPersonaliseAction, Error> {
    private enum QuickpayPersonaliseError: Error {
        case failedToUpdateQRCode
        case failedToLoad
    }

    private enum Constants {
        static let quickpayDomain = "wise.com/pay/business/"
    }

    private let analyticsTracker: BusinessProfileLinkTracking
    private let quickpayUseCase: QuickpayUseCase
    private let wisetagInteractor: WisetagInteractor
    private let status: ShareableLinkStatus.Discoverability
    private let pasteboard: Pasteboard
    private let nickname: String?
    private let onDownloadQRCodeTapped: ((UIImage) -> Void)?

    init(
        quickpayUseCase: QuickpayUseCase,
        wisetagInteractor: WisetagInteractor,
        status: ShareableLinkStatus.Discoverability,
        analyticsTracker: BusinessProfileLinkTracking,
        pasteboard: Pasteboard,
        onDownloadQRCodeTapped: ((UIImage) -> Void)?
    ) {
        self.quickpayUseCase = quickpayUseCase
        self.wisetagInteractor = wisetagInteractor
        self.status = status
        self.analyticsTracker = analyticsTracker
        self.pasteboard = pasteboard
        self.onDownloadQRCodeTapped = onDownloadQRCodeTapped

        switch status {
        case let .discoverable(_, fullNickname):
            nickname = String(fullNickname.dropFirst())
            link = Constants.quickpayDomain + String(fullNickname.dropFirst())
        case .notDiscoverable:
            nickname = nil
        }
        super.init()
    }

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
    @Published
    var errorMessage: String?

    override func handle(_ action: QuickpayPersonaliseAction) async {
        switch action {
        case .load:
            await load()
        }
    }

    func updateQRCode() async {
        link = generateLink()
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

    private func load() async {
        guard state.content.isNil else { return }
        await loading { [weak self] in
            guard let self, let nickname else { return .initial }

            guard let currencyAvailability = try await quickpayUseCase.getCurrencyAvailability(wisetag: nickname)
                .values.first()?.content else {
                return .error(QuickpayPersonaliseError.failedToLoad)
            }

            guard let (_, image) = try await wisetagInteractor.fetchQRCode(status: .eligible(status), link: generateLink())
                .values.first() else {
                return .error(QuickpayPersonaliseError.failedToLoad)
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
            selectedCurrency = currencyAvailability.preferredCurrency
            allCurrencies = currencyAvailability.availableCurrencies

            let content = QuickpayPersonaliseContent(
                qrCodeViewModel: qrCode,
                preferredCurrency: selectedCurrency,
                availableCurrencies: allCurrencies
            )
            return .content(content)
        }
    }

    private func generateLink() -> String {
        // nickname is guaranteed on load
        guard let nickname else {
            softFailure("[REC] Nickname is null when opening Personalise Quick Pay")
            return ""
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

        if description.isNonEmpty, isValidDescription(description) {
            queryItems.append(descriptionQueryItem)
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.description
    }

    func copyLink() {
        analyticsTracker.onCustomCurrencyAndAmountSet()
        pasteboard.addToClipboard(generateLink())
        link = L10n.Wisetag.SnackBar.Message.copyLink
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self else { return }
            link = generateLink()
        }
    }

    func downloadQRCode() {
        if let image = qrCodeViewModel?.qrCodeImage {
            onDownloadQRCodeTapped?(image)
        }
    }

    func isValidDescription(_ text: String) -> Bool {
        text.unicodeScalars.allSatisfy { Self.allowedDescriptionCharacters.contains($0) }
    }

    static let allowedDescriptionCharacters: CharacterSet = {
        var allowed = CharacterSet.letters
        allowed.formUnion(.decimalDigits)
        allowed.formUnion(CharacterSet(charactersIn: " -"))
        return allowed
    }()

    func onDescriptionChange(text: String) async {
        if isValidDescription(text) {
            errorMessage = nil
            await updateQRCode()
        } else {
            errorMessage = L10n.Quickpay.PersonalisePage.InvalidCharacter.title
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
