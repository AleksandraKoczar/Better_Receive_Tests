import Combine
import CombineSchedulers
import ContactsKit
import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class CancellableAvatarFetcherTests: TWTestCase {
    private struct _Constants {
        let expectedInitials = Initials(first: "A", second: "B")
        let expectedImage = Icons.switch.image
    }

    private let Constants = _Constants()
    private var avatarFetcher: CancellableAvatarFetcherImpl!

    override func setUp() {
        super.setUp()
        avatarFetcher = CancellableAvatarFetcherImpl(scheduler: .immediate)
    }

    override func tearDown() {
        avatarFetcher = nil
        super.tearDown()
    }
}

// MARK: - Tests

extension CancellableAvatarFetcherTests {
    func testFetchingAvatar_GivenDifferentAvatars_ThenAvatarIsUpdatedCorrectly() {
        let avatarSubject: CurrentValueSubject<AvatarModel, Never> = CurrentValueSubject(
            AvatarModel.initials(
                Constants.expectedInitials,
                badge: nil
            )
        )

        let publisher = AvatarPublisher.icon(
            avatarPublisher: avatarSubject.eraseToAnyPublisher(),
            gradientPublisher: .canned,
            path: .canned
        )

        var avatarModel: AvatarModel?
        avatarFetcher.fetch(
            publisher: publisher,
            completion: {
                avatarModel = $0
            }
        )
        XCTAssertEqual(
            avatarModel,
            AvatarModel.initials(Constants.expectedInitials, badge: nil)
        )

        avatarSubject.send(
            AvatarModel.image(Constants.expectedImage, badge: nil)
        )
        XCTAssertEqual(
            avatarModel,
            AvatarModel.image(
                Constants.expectedImage,
                badge: nil
            )
        )
    }

    func testCancelling_GivenDifferentAvatars_WhenFetcherCanceled_ThenAvatarIsNotUpdated() {
        let avatarSubject: CurrentValueSubject<AvatarModel, Never> = CurrentValueSubject(
            AvatarModel.initials(
                Constants.expectedInitials,
                badge: nil
            )
        )

        let publisher = AvatarPublisher.icon(
            avatarPublisher: avatarSubject.eraseToAnyPublisher(),
            gradientPublisher: .canned,
            path: .canned
        )

        var avatarModel: AvatarModel?
        avatarFetcher.fetch(
            publisher: publisher,
            completion: {
                avatarModel = $0
            }
        )
        XCTAssertEqual(
            avatarModel,
            AvatarModel.initials(Constants.expectedInitials, badge: nil)
        )

        avatarFetcher.cancel()
        avatarSubject.send(
            AvatarModel.image(Constants.expectedImage, badge: nil)
        )

        XCTAssertEqual(
            avatarModel,
            AvatarModel.initials(
                Constants.expectedInitials,
                badge: nil
            )
        )
    }
}
