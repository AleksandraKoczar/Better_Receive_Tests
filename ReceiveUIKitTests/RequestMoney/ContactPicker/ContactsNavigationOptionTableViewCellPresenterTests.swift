import Combine
import CombineSchedulers
import ContactsKit
import ContactsKitTestingSupport
import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit
import WiseCore

final class ContactsNavigationOptionTableViewCellPresenterTests: TWTestCase {
    func test_GivenAvatarsAndViewModel_WhenPresenterStarted_ThenCellConfiguredWithCorrectValues() {
        let expectedInitials = Initials(first: "A", second: "B")
        let expectedImage = Icons.switch.image
        let expectedTitle = "title"
        let expectedSubtitle = "subtitle"
        let presenter = AvatarLoadableNavigationOptionTableViewCellPresenterImpl(
            avatarFetcher: CancellableAvatarFetcherImpl(
                scheduler: .immediate
            )
        )
        let cell = AvatarLoadableNavigationOptionTableViewCellMock()
        let avatarSubject: CurrentValueSubject<AvatarModel, Never> = CurrentValueSubject(
            AvatarModel.initials(expectedInitials, badge: nil)
        )

        presenter.start(
            title: expectedTitle,
            subtitle: expectedSubtitle,
            avatarPublisher: AvatarPublisher.icon(
                avatarPublisher: avatarSubject.eraseToAnyPublisher(),
                gradientPublisher: .canned,
                path: .canned
            ),
            cell: cell
        )

        XCTAssertEqual(
            cell.configureReceivedViewModel?.title,
            expectedTitle
        )
        XCTAssertEqual(
            cell.configureReceivedViewModel?.subtitle?.text,
            expectedSubtitle
        )

        XCTAssertEqual(
            cell.configureReceivedViewModel?.leadingView,
            .avatar(AvatarViewModel.initials(expectedInitials, badge: nil))
        )

        avatarSubject.send(AvatarModel.image(expectedImage, badge: nil))

        XCTAssertEqual(
            cell.configureReceivedViewModel?.leadingView,
            .avatar(AvatarViewModel.image(expectedImage, badge: nil))
        )
    }
}
