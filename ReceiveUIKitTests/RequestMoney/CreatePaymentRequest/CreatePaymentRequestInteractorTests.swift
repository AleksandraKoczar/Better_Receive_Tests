import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport
import WiseCore

final class CreatePaymentRequestInteractorTests: TWTestCase {
    private var interactor: CreatePaymentRequestInteractorImpl!
    private var paymentRequestUseCase: PaymentRequestUseCaseV2Mock!
    private var paymentMethodsUseCase: PaymentMethodsUseCaseMock!
    private var paymentRequestProductEligibilityUseCase: PaymentRequestProductEligibilityUseCaseMock!
    private var paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCaseMock!
    private var paymentRequestListUseCase: PaymentRequestListUseCaseMock!
    private var paymentRequestDetailsUseCase: PaymentRequestDetailsUseCaseMock!

    override func setUp() {
        super.setUp()

        paymentRequestUseCase = PaymentRequestUseCaseV2Mock()
        paymentMethodsUseCase = PaymentMethodsUseCaseMock()
        paymentRequestProductEligibilityUseCase = PaymentRequestProductEligibilityUseCaseMock()
        paymentRequestEligibilityUseCase = PaymentRequestEligibilityUseCaseMock()
        paymentRequestListUseCase = PaymentRequestListUseCaseMock()
        paymentRequestDetailsUseCase = PaymentRequestDetailsUseCaseMock()

        makeInteractor()
    }

    override func tearDown() {
        interactor = nil
        paymentRequestUseCase = nil
        paymentMethodsUseCase = nil
        paymentRequestProductEligibilityUseCase = nil
        paymentRequestEligibilityUseCase = nil
        paymentRequestListUseCase = nil
        paymentRequestDetailsUseCase = nil
        super.tearDown()
    }

    func test_fetchEligibilityAndDefaultRequestTypeIsSingleUse_thenSuccess() throws {
        paymentRequestProductEligibilityUseCase.productEligibilityReturnValue = .just([.singleUse, .reusable])
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(PaymentRequestSummaries(
            groups: [.build(
                id: "",
                label: "",
                summaries: [.build(id: "123", title: "", subtitle: "", icon: "", avatar: nil, badge: nil)]
            )],
            nextPageState: .noFurtherItem
        ))
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(PaymentRequestDetails.build(
            id: PaymentRequestId.build(value: "123"),
            amount: .canned,
            title: "",
            subtitle: "",
            icon: "",
            badge: nil,
            avatar: nil,
            type: .singleUse,
            actions: [],
            sections: []
        ))

        let result = try awaitPublisher(interactor.fetchEligibilityAndDefaultRequestType())

        XCTAssertEqual(result.value?.0, .singleUseAndReusable)
        XCTAssertEqual(result.value?.1, .singleUse)
    }

    func test_fetchEligibilityAndDefaultRequestTypeIsReusable_thenSuccess() throws {
        paymentRequestProductEligibilityUseCase.productEligibilityReturnValue = .just([.singleUse, .reusable])
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(PaymentRequestSummaries(
            groups: [.build(
                id: "",
                label: "",
                summaries: [.build(id: "123", title: "", subtitle: "", icon: "", avatar: nil, badge: nil)]
            )],
            nextPageState: .noFurtherItem
        ))
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(PaymentRequestDetails.build(
            id: PaymentRequestId.build(value: "123"),
            amount: .canned,
            title: "",
            subtitle: "",
            icon: "",
            badge: nil,
            avatar: nil,
            type: .reusable,
            actions: [],
            sections: []
        ))

        let result = try awaitPublisher(interactor.fetchEligibilityAndDefaultRequestType())

        XCTAssertEqual(result.value?.0, .singleUseAndReusable)
        XCTAssertEqual(result.value?.1, .reusable)
    }

    func test_fetchEligibilityIsIneligibleAndDefaultRequest_thenFailure() throws {
        paymentRequestProductEligibilityUseCase.productEligibilityReturnValue = .just([])
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(PaymentRequestSummaries(
            groups: [.build(
                id: "",
                label: "",
                summaries: [.build(id: "123", title: "", subtitle: "", icon: "", avatar: nil, badge: nil)]
            )],
            nextPageState: .noFurtherItem
        ))
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(PaymentRequestDetails.build(
            id: PaymentRequestId.build(value: "123"),
            amount: .canned,
            title: "",
            subtitle: "",
            icon: "",
            badge: nil,
            avatar: nil,
            type: .reusable,
            actions: [],
            sections: []
        ))

        let result = try awaitPublisher(interactor.fetchEligibilityAndDefaultRequestType())

        XCTAssertNotNil(result.error)
    }
}

extension CreatePaymentRequestInteractorTests {
    func makeInteractor() {
        interactor = CreatePaymentRequestInteractorImpl(
            profile: FakeBusinessProfileInfo().asProfile(),
            paymentRequestUseCase: paymentRequestUseCase,
            paymentMethodsUseCase: paymentMethodsUseCase,
            paymentRequestProductEligibilityUseCase: paymentRequestProductEligibilityUseCase,
            paymentRequestEligibilityUseCase: paymentRequestEligibilityUseCase,
            paymentRequestListUseCase: paymentRequestListUseCase,
            paymentRequestDetailsUseCase: paymentRequestDetailsUseCase
        )
    }
}
