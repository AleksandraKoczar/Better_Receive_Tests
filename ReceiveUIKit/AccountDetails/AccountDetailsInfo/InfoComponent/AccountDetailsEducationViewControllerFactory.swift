import Foundation
import UIKit

public enum AccountDetailsEducationViewControllerFactory {
    public static func make(model: AccountDetailsBottomSheetViewModel) -> UIViewController {
        AccountDetailsEducationViewController(model: model)
    }
}
