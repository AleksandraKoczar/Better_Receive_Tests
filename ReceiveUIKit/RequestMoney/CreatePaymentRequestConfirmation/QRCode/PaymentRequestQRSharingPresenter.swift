import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import UserKit

// sourcery: AutoMockable
protocol PaymentRequestQRSharingPresenter: AnyObject {
    func start(with view: PaymentRequestQRSharingView)
}

final class PaymentRequestQRSharingPresenterImpl {
    private weak var view: PaymentRequestQRSharingView?

    private let profile: Profile
    private let paymentRequest: PaymentRequestV2
    private let wisetagUseCase: WisetagUseCase
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var fetchQRCodeCancellable: AnyCancellable?

    @Environment(\.colorScheme)
    private var colorScheme

    init(
        profile: Profile,
        paymentRequest: PaymentRequestV2,
        wisetagUseCase: WisetagUseCase = WisetagUseCaseFactory.make(),
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.paymentRequest = paymentRequest
        self.wisetagUseCase = wisetagUseCase
        self.scheduler = scheduler
    }
}

// MARK: - Helpers

private extension PaymentRequestQRSharingPresenterImpl {
    func getProfileAvatar() -> AvatarViewModel {
        if let avatar = profile.avatar.downloadedImage {
            return .image(avatar)
        } else {
            let profileInitials = ProfileInitialsDisplayName(profile: profile)
            let initials = Initials(value: profileInitials.name)
            return .initials(initials)
        }
    }

    func getRequestItems() -> [PaymentRequestQRSharingViewModel.ListItemViewModel] {
        let requestDisplayAmount = MoneyFormatter.format(
            paymentRequest.amount.value,
            withCurrencyCode: paymentRequest.amount.currency
        )
        let amountItem = PaymentRequestQRSharingViewModel.ListItemViewModel(
            title: L10n.PaymentRequest.Create.Confirm.Share.QrCode.RequestDetails.amount,
            value: requestDisplayAmount
        )

        guard let note = paymentRequest.message,
              note.isNonEmpty else {
            return [amountItem]
        }

        let noteItem = PaymentRequestQRSharingViewModel.ListItemViewModel(
            title: L10n.PaymentRequest.Create.Confirm.Share.QrCode.RequestDetails.note,
            value: note
        )
        return [amountItem, noteItem]
    }

    func makeViewModel(qrCodeImage: UIImage?) -> PaymentRequestQRSharingViewModel {
        PaymentRequestQRSharingViewModel(
            avatar: getProfileAvatar(),
            title: L10n.PaymentRequest.Create.Confirm.Share.QrCode.title,
            subtitle: ProfileLocaleDisplayName(profile: profile, style: .full).name,
            qrCodeImage: qrCodeImage,
            requestDetailsHeader: L10n.PaymentRequest.Create.Confirm.Share.QrCode.RequestDetails.header,
            requestItems: getRequestItems()
        )
    }
}

// MARK: - PaymentRequestQRSharingPresenter

extension PaymentRequestQRSharingPresenterImpl: PaymentRequestQRSharingPresenter {
    func start(with view: PaymentRequestQRSharingView) {
        self.view = view
        let link = paymentRequest.link
        fetchQRCodeCancellable = wisetagUseCase.qrCode(content: link)
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success(qrCodeImage):
                    let viewModel = makeViewModel(qrCodeImage: qrCodeImage)
                    self.view?.configure(with: viewModel)
                case .failure:
                    let qrCodeImage = UIImage.qrCode(from: link)
                    let viewModel = makeViewModel(qrCodeImage: qrCodeImage)
                    self.view?.configure(with: viewModel)
                }
            }
    }
}
