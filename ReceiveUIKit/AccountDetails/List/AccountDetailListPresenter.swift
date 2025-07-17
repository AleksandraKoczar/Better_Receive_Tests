import UIKit

// sourcery: AutoMockable
protocol AccountDetailListPresenter {
    func viewDidAppear()
    func start(withView view: AccountDetailsListView)
    func cellTapped(indexPath: IndexPath)
    func updateSearchQuery(_ searchText: String)
    func footerTapped()
    func dismissed()
}
