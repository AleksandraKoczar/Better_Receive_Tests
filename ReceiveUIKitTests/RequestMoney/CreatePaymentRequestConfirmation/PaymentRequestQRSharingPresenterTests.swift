import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class PaymentRequestQRSharingPresenterTests: TWTestCase {
    private let amount: Decimal = 20
    private let currency = CurrencyCode.GBP
    private let link = "https://wise.com/pay/abcd-efgh-ijkl-nmop"
    private let message = LoremIpsum.long
    private let profileName = LoremIpsum.short
    private let avatar = Icons.receive.image
    private let qrCodeImage = UIImage()

    private lazy var businessProfile = {
        let info = FakeBusinessProfileInfo()
        info.name = profileName
        info.avatar = .build(downloadedImage: avatar)
        return info.asProfile()
    }()

    private lazy var personalProfile = {
        let info = FakePersonalProfileInfo()
        info.firstName = profileName
        info.lastName = profileName
        info.avatar = .build(downloadedImage: avatar)
        return info.asProfile()
    }()

    private var view: PaymentRequestQRSharingViewMock!
    private var presenter: PaymentRequestQRSharingPresenterImpl!
    private var wisetagUseCase: WisetagUseCaseMock!

    override func setUp() {
        super.setUp()
        view = PaymentRequestQRSharingViewMock()
        wisetagUseCase = WisetagUseCaseMock()
    }

    override func tearDown() {
        presenter = nil
        view = nil
        wisetagUseCase = nil
        super.tearDown()
    }

    func test_start_forBusinessProfile_andPaymentRequestWithMessage_andFetchQRCodeSuccess() {
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)

        let paymentRequest = PaymentRequestV2.build(
            amount: .build(currency: currency, value: amount),
            message: message,
            link: link
        )
        presenter = makePresenter(
            profile: businessProfile,
            paymentRequest: paymentRequest
        )
        presenter.start(with: view)

        let expected = makeViewModel(
            subtitle: profileName,
            listItems: [
                PaymentRequestQRSharingViewModel.ListItemViewModel(
                    title: "Amount",
                    value: MoneyFormatter.format(amount, withCurrencyCode: currency)
                ),
                PaymentRequestQRSharingViewModel.ListItemViewModel(
                    title: "Note",
                    value: message
                ),
            ]
        )
        expectNoDifference(view.configureReceivedViewModel, expected)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 1)
        XCTAssertEqual(wisetagUseCase.qrCodeReceivedContent, link)
    }

    func test_start_forBusinessProfile_andPaymentRequestWithoutMessage() {
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)

        let paymentRequest = PaymentRequestV2.build(
            amount: .build(currency: currency, value: amount),
            link: link
        )
        let presenter = makePresenter(
            profile: businessProfile,
            paymentRequest: paymentRequest
        )
        presenter.start(with: view)

        let expected = makeViewModel(
            subtitle: profileName,
            listItems: [
                PaymentRequestQRSharingViewModel.ListItemViewModel(
                    title: "Amount",
                    value: MoneyFormatter.format(paymentRequest.amount.value, withCurrencyCode: paymentRequest.amount.currency)
                ),
            ]
        )
        expectNoDifference(view.configureReceivedViewModel, expected)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 1)
        XCTAssertEqual(wisetagUseCase.qrCodeReceivedContent, link)
    }

    func test_start_forPersonalProfile_andPaymentRequestWithMessage() {
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)

        let paymentRequest = PaymentRequestV2.build(
            amount: .build(currency: currency, value: amount),
            message: message,
            link: link
        )
        let presenter = makePresenter(
            profile: personalProfile,
            paymentRequest: paymentRequest
        )
        presenter.start(with: view)

        let expected = makeViewModel(
            subtitle: profileName + " " + profileName,
            listItems: [
                PaymentRequestQRSharingViewModel.ListItemViewModel(
                    title: "Amount",
                    value: MoneyFormatter.format(paymentRequest.amount.value, withCurrencyCode: paymentRequest.amount.currency)
                ),
                PaymentRequestQRSharingViewModel.ListItemViewModel(
                    title: "Note",
                    value: message
                ),
            ]
        )
        expectNoDifference(view.configureReceivedViewModel, expected)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 1)
        XCTAssertEqual(wisetagUseCase.qrCodeReceivedContent, link)
    }

    func test_start_forPersonalProfile_andPaymentRequestWithoutMessage() {
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)

        let paymentRequest = PaymentRequestV2.build(
            amount: .build(currency: currency, value: amount),
            link: link
        )
        let presenter = makePresenter(
            profile: personalProfile,
            paymentRequest: paymentRequest
        )
        presenter.start(with: view)

        let expected = makeViewModel(
            subtitle: profileName + " " + profileName,
            listItems: [
                PaymentRequestQRSharingViewModel.ListItemViewModel(
                    title: "Amount",
                    value: MoneyFormatter.format(paymentRequest.amount.value, withCurrencyCode: paymentRequest.amount.currency)
                ),
            ]
        )
        expectNoDifference(view.configureReceivedViewModel, expected)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 1)
        XCTAssertEqual(wisetagUseCase.qrCodeReceivedContent, link)
    }
}

// MARK: - Helpers

private extension PaymentRequestQRSharingPresenterTests {
    func makePresenter(
        profile: Profile,
        paymentRequest: PaymentRequestV2
    ) -> PaymentRequestQRSharingPresenterImpl {
        PaymentRequestQRSharingPresenterImpl(
            profile: profile,
            paymentRequest: paymentRequest,
            wisetagUseCase: wisetagUseCase,
            scheduler: .immediate
        )
    }

    func makeViewModel(
        subtitle: String,
        listItems: [PaymentRequestQRSharingViewModel.ListItemViewModel]
    ) -> PaymentRequestQRSharingViewModel {
        PaymentRequestQRSharingViewModel(
            avatar: .image(avatar),
            title: "Scan to pay",
            subtitle: subtitle,
            qrCodeImage: qrCodeImage,
            requestDetailsHeader: "Request details",
            requestItems: listItems
        )
    }
}
