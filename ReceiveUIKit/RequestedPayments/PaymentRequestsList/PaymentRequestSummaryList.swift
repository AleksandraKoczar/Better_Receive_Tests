import LoggingKit
import ReceiveKit

// sourcery: AutoEquatableForTest
struct PaymentRequestSummaryList {
    var unpaid: PaymentRequestSummaryList.Unpaid
    var paid: PaymentRequestSummaries
    var active: PaymentRequestSummaries
    var inactive: PaymentRequestSummaries
    var upcoming: PaymentRequestSummaryList.Upcoming
    var past: PaymentRequestSummaries
    var visibleState: PaymentRequestSummaryList.State
}

extension PaymentRequestSummaryList {
    enum SortingState: CaseIterable {
        case closestToExpiry
        case mostRecentlyRequested
    }

    // sourcery: AutoEquatableForTest
    struct Unpaid {
        var closestToExpiry: PaymentRequestSummaries
        var mostRecentlyRequested: PaymentRequestSummaries
        var visibleState: PaymentRequestSummaryList.SortingState
    }

    // sourcery: AutoEquatableForTest
    struct Upcoming {
        var closestToExpiry: PaymentRequestSummaries
        var mostRecentlyRequested: PaymentRequestSummaries
        var visibleState: PaymentRequestSummaryList.SortingState
    }

    enum State: Equatable {
        case unpaid(PaymentRequestSummaryList.SortingState)
        case paid
        case active
        case inactive
        case upcoming(PaymentRequestSummaryList.SortingState)
        case past
    }
}

extension PaymentRequestSummaryList {
    private static func getVisibleUnpaidState(
        from state: PaymentRequestSummaryList.State
    ) -> PaymentRequestSummaryList.SortingState {
        guard case let .unpaid(visibleState) = state else {
            return .closestToExpiry
        }
        return visibleState
    }

    private static func getVisibleUpcomingState(
        from state: PaymentRequestSummaryList.State
    ) -> PaymentRequestSummaryList.SortingState {
        guard case let .upcoming(visibleState) = state else {
            return .closestToExpiry
        }
        return visibleState
    }

    static func makeInitial(state: PaymentRequestSummaryList.State) -> PaymentRequestSummaryList {
        PaymentRequestSummaryList(
            unpaid: Unpaid(
                closestToExpiry: PaymentRequestSummaries.makeInitial(),
                mostRecentlyRequested: PaymentRequestSummaries.makeInitial(),
                visibleState: getVisibleUnpaidState(from: state)
            ),
            paid: PaymentRequestSummaries.makeInitial(),
            active: PaymentRequestSummaries.makeInitial(),
            inactive: PaymentRequestSummaries.makeInitial(),
            upcoming: Upcoming(
                closestToExpiry: PaymentRequestSummaries.makeInitial(),
                mostRecentlyRequested: PaymentRequestSummaries.makeInitial(),
                visibleState: getVisibleUpcomingState(from: state)
            ),
            past: PaymentRequestSummaries.makeInitial(),
            visibleState: state
        )
    }
}
