import Neptune
import NeptuneTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWTestingSupportKit

final class AccountDetailsStatusViewControllerTests: TWSnapshotTestCase {
    private var view: AccountDetailsStatusViewController!

    override func setUpWithError() throws {
        try super.setUpWithError()
        view = AccountDetailsStatusViewController(
            presenter: AccountDetailsStatusPresenterMock()
        )
    }

    override func tearDownWithError() throws {
        view = nil
        try super.tearDownWithError()
    }

    func testState_whenFailedToLoad_thenShowsErrorView() {
        view.configure(
            with: .failedToLoad(
                ErrorViewModel.canned
            )
        )
        TWSnapshotVerifyViewController(view)
    }

    func testState_whenLoadedModel_thenShowsStatusView() {
        view.configure(
            with: .loaded(
                Self.makeModel(
                    sections: Self.makeSections(count: 2)
                )
            )
        )
        TWSnapshotVerifyViewController(view)
    }

    func testState_whenLoadedModel_withoutButton_thenShowsStatusViewWithoutButton() {
        view.configure(
            with: .loaded(
                Self.makeModel(
                    sections: Self.makeSections(count: 2),
                    button: nil
                )
            )
        )
        TWSnapshotVerifyViewController(view)
    }

    func testState_whenLoadedModel_withAlert_thenShowsStatusViewWithAlert() {
        view.configure(with: .loaded(
            Self.makeModel(
                alertStyle: .warning,
                sections: Self.makeSections(count: 1)
            )
        ))
        TWSnapshotVerifyViewController(view)
    }

    private static func makeModel(
        alertStyle: AccountDetailsStatus.Alert.Style? = nil,
        sections: [AccountDetailsStatus.Section],
        button: AccountDetailsStatus.Button? = .build(action: .proceed, title: "Continue")
    ) -> AccountDetailsStatusViewState.Model {
        .build(
            header: .build(
                title: "Lorem ipsum dolor sit amet",
                description: "Duis aute irure dolor in reprehenderit in voluptate velit esse."
            ),
            status: .build(
                alert: alertStyle.flatMap { style in
                    .build(
                        message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
                        style: style
                    )
                },
                sections: sections,
                button: button
            )
        )
    }

    private static func makeSections(
        count: Int
    ) -> [AccountDetailsStatus.Section] {
        (0..<count).enumerated().map {
            .build(
                summaries: [
                    .build(
                        description: "Duis aute irure dolor in reprehenderit in voluptate velit esse.",
                        icon: Icons.money.image,
                        info: .build(),
                        title: "Lorem ipsum dolor sit amet"
                    ),
                    .build(
                        description: "Duis aute irure dolor in reprehenderit in voluptate velit esse.",
                        icon: Icons.money.image,
                        title: "Lorem ipsum dolor sit amet",
                        status: .pending
                    ),
                ],
                title: "Section \($0.offset)"
            )
        }
    }
}
