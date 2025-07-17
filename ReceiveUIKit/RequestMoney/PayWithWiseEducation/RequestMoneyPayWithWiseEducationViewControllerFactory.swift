import UIKit

// sourcery: AutoMockable
protocol RequestMoneyPayWithWiseEducationViewControllerFactory {
    func make(routingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegate) -> UIViewController
}

struct RequestMoneyPayWithWiseEducationViewControllerFactoryImpl: RequestMoneyPayWithWiseEducationViewControllerFactory {
    func make(routingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegate) -> UIViewController {
        let presenter = RequestMoneyPayWithWiseEducationPresenterImpl(routingDelegate: routingDelegate)
        return RequestMoneyPayWithWiseEducationViewController(presenter: presenter)
    }
}
