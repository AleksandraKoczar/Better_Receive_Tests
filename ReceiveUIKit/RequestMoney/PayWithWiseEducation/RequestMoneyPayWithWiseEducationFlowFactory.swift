import TWFoundation
import TWUI

// sourcery: AutoMockable
protocol RequestMoneyPayWithWiseEducationFlowFactory {
    func makeBottomSheetFlow(parentViewController: UIViewController) -> any Flow<RequestMoneyPayWithWiseEducationFlowResult>
}

struct RequestMoneyPayWithWiseEducationFlowFactoryImpl: RequestMoneyPayWithWiseEducationFlowFactory {
    func makeBottomSheetFlow(parentViewController: UIViewController) -> any Flow<RequestMoneyPayWithWiseEducationFlowResult> {
        let viewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
        let bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(parent: parentViewController)
        return RequestMoneyPayWithWiseEducationFlow(
            educationviewControllerFactory: RequestMoneyPayWithWiseEducationViewControllerFactoryImpl(),
            viewControllerPresenter: bottomSheetPresenter
        )
    }
}
