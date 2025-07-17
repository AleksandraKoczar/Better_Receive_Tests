import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport
import WiseAtomsIcons
import WiseCore

final class ReceiveMethodsQRSharingPresenterTests: TWTestCase {
    private var presenter: ReceiveMethodsQRSharingPresenterImpl!

    private var profile = FakePersonalProfileInfo().asProfile()
    private var useCase: PixQRUseCaseMock!
    private var receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCaseMock!
    private var router: ReceiveMethodsQRSharingRouterMock!
    private var view: ReceiveMethodsQRSharingViewMock!
    private var pasteboard: MockPasteboard!

    private let accountDetailsId = AccountDetailsId(32)
    private let phoneNumber = "+449999999"
    private let payload = "load"
    private let email = "email@example.com"
    private let imageString = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABAABJzQnCgAAAABJRU5ErkJggg=="

    private lazy var inactiveAlias = ReceiveMethodAlias.build(
        id: ReceiveMethodAlias.AliasId(64),
        state: .inactive,
        key: ReceiveMethodAlias.AliasKey.build(
            type: .email,
            value: email
        ),
        aliasScheme: "Pix"
    )

    private lazy var registeredAlias = ReceiveMethodAlias.build(
        id: ReceiveMethodAlias.AliasId(128),
        state: .registered,
        key: ReceiveMethodAlias.AliasKey.build(
            type: .phoneNumber,
            value: phoneNumber
        ),
        aliasScheme: "Pix"
    )

    private lazy var registeredAlias2 = ReceiveMethodAlias.build(
        id: ReceiveMethodAlias.AliasId(64),
        state: .registered,
        key: ReceiveMethodAlias.AliasKey.build(
            type: .email,
            value: email
        ),
        aliasScheme: "Pix"
    )

    override func setUp() {
        super.setUp()

        useCase = PixQRUseCaseMock()
        receiveMethodsAliasUseCase = ReceiveMethodsAliasUseCaseMock()
        router = ReceiveMethodsQRSharingRouterMock()
        view = ReceiveMethodsQRSharingViewMock()
        pasteboard = MockPasteboard()

        presenter = ReceiveMethodsQRSharingPresenterImpl(
            accountDetailsId: accountDetailsId,
            profile: profile,
            mode: .all,
            useCase: useCase,
            aliasUseCase: receiveMethodsAliasUseCase,
            router: router,
            pasteboard: pasteboard,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        presenter = nil
        router = nil
        useCase = nil
        receiveMethodsAliasUseCase = nil
        view = nil
        pasteboard = nil

        super.tearDown()
    }

    func testAllMode() {
        receiveMethodsAliasUseCase.aliasesReturnValue = .just([
            inactiveAlias,
            registeredAlias,
        ])
        useCase.qrReturnValue = .just(
            PixQR.build(
                payload: payload,
                imageString: imageString
            )
        )
        presenter.start(with: view)

        XCTAssertEqual(
            receiveMethodsAliasUseCase.aliasesReceivedArguments?.accountDetailsId,
            accountDetailsId
        )
        XCTAssertEqual(
            receiveMethodsAliasUseCase.aliasesReceivedArguments?.profileId,
            profile.id
        )
        XCTAssertEqual(
            useCase.qrReceivedRequest,
            PixQRRequest(
                alias: phoneNumber,
                profileId: profile.id,
                amount: nil,
                message: nil,
                transactionId: nil
            )
        )

        guard let data = Data(base64Encoded: imageString),
              let image = UIImage(data: data) else {
            XCTFail()
            return
        }

        XCTAssertEqual(view.displayHudCallsCount, 1)
        XCTAssertEqual(view.removeHudCallsCount, 1)
        XCTAssertEqual(view.configureReceivedViewModel?.title, L10n.Receive.Pix.Share.title)
        XCTAssertEqual(view.configureReceivedViewModel?.subtitle, L10n.Receive.Pix.Share.subtitle)
        XCTAssertEqual(view.configureReceivedViewModel?.keys.count, 1)
        XCTAssertEqual(
            view.configureReceivedViewModel?.keys.first?.qr.toBase64Str(),
            image.toBase64Str()
        )
        XCTAssertEqual(view.configureReceivedViewModel?.keys.first?.type, "Phone number")
        XCTAssertEqual(view.configureReceivedViewModel?.keys.first?.value, phoneNumber)

        XCTAssertFalse(view.showShareSheetCalled)
        view.configureReceivedViewModel?.buttons.first?.action()
        XCTAssertEqual(
            view.showShareSheetReceivedText,
            phoneNumber
        )

        XCTAssertFalse(router.showCustomisationCalled)
        view.configureReceivedViewModel?.buttons[safe: 1]?.action()
        XCTAssertEqual(router.showCustomisationReceivedArguments?.alias.key.value, phoneNumber)

        XCTAssertFalse(router.showDownloadCalled)
        view.configureReceivedViewModel?.buttons[safe: 2]?.action()
        XCTAssertEqual(
            router.showDownloadReceivedArguments?.image.toBase64Str(),
            image.toBase64Str()
        )
    }

    func testSingleMode() {
        let amount: Decimal = 10
        let message = "Beer"
        presenter = ReceiveMethodsQRSharingPresenterImpl(
            accountDetailsId: accountDetailsId,
            profile: profile,
            mode: .single(
                ReceiveMethodsQRSharingMode.SingleSharingModel.build(
                    alias: registeredAlias,
                    amount: amount,
                    message: message
                )
            ),
            useCase: useCase,
            aliasUseCase: receiveMethodsAliasUseCase,
            router: router,
            scheduler: .immediate
        )

        receiveMethodsAliasUseCase.aliasesReturnValue = .just([])
        useCase.qrReturnValue = .just(
            PixQR.build(
                payload: payload,
                imageString: imageString
            )
        )
        presenter.start(with: view)

        XCTAssertEqual(view.displayHudCallsCount, 1)
        XCTAssertEqual(view.removeHudCallsCount, 1)
        XCTAssertFalse(receiveMethodsAliasUseCase.aliasesCalled)
        XCTAssertEqual(
            useCase.qrReceivedRequest,
            PixQRRequest(
                alias: phoneNumber,
                profileId: profile.id,
                amount: amount,
                message: message,
                transactionId: nil
            )
        )

        XCTAssertEqual(
            view.configureReceivedViewModel?.title,
            L10n.Receive.Pix.Share.SingleKey.title
        )
        XCTAssertEqual(
            view.configureReceivedViewModel?.subtitle,
            L10n.Receive.Pix.Share.SingleKey.Subtitle.amountAndMessage("10\u{A0}BRL", message)
        )
        XCTAssertEqual(
            view.configureReceivedViewModel?.buttons.first?.title,
            L10n.Receive.Pix.Share.Action.PixCopyPaste.title
        )
        view.configureReceivedViewModel?.buttons.first?.action()

        XCTAssertEqual(
            view.showSnackbarReceivedMessage,
            L10n.Receive.Pix.Share.Action.PixCopyPaste.completed
        )
    }

    func testFailure() {
        receiveMethodsAliasUseCase.aliasesReturnValue = .fail(with: MockError.dummy)
        presenter.start(with: view)

        XCTAssertEqual(view.displayHudCallsCount, 1)
        XCTAssertEqual(view.removeHudCallsCount, 1)
        XCTAssertTrue(view.configureWithErrorCalled)
    }

    func testAllMode_GivenMultipleAliases_WhenIndexChanged_ThenCorrectQRShared() {
        receiveMethodsAliasUseCase.aliasesReturnValue = .just([
            inactiveAlias,
            registeredAlias,
            registeredAlias2,
        ])
        useCase.qrReturnValue = .just(
            PixQR.build(
                payload: payload,
                imageString: imageString
            )
        )
        presenter.start(with: view)
        presenter.activeIndexChanged(1)

        XCTAssertFalse(router.showCustomisationCalled)
        view.configureReceivedViewModel?.buttons[safe: 1]?.action()
        XCTAssertEqual(router.showCustomisationReceivedArguments?.alias.key.value, email)
    }
}

private extension UIImage {
    func toBase64Str() -> String? {
        jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}
