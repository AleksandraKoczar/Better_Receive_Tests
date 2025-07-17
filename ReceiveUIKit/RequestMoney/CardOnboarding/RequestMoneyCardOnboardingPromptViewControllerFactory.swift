import TransferResources
import TWUI

// sourcery: AutoMockable
protocol RequestMoneyCardOnboardingPromptViewControllerFactory {
    func makeCardAvailable(
        primaryButtonAction: @escaping (UIViewController?) -> Void,
        secondaryButtonAction: @escaping (UIViewController?) -> Void
    ) -> UIViewController
    func makeCardIneligible(primaryButtonAction: @escaping (UIViewController?) -> Void) -> UIViewController
}

struct RequestMoneyCardOnboardingPromptViewControllerFactoryImpl: RequestMoneyCardOnboardingPromptViewControllerFactory {
    func makeCardAvailable(
        primaryButtonAction: @escaping (UIViewController?) -> Void,
        secondaryButtonAction: @escaping (UIViewController?) -> Void
    ) -> UIViewController {
        let primaryButton = PromptConfiguration.PrimaryButtonConfiguration(
            title: L10n.RequestMoney.CardOnboarding.Prompt.Available.PrimaryButton.title,
            actionHandler: primaryButtonAction
        )
        let secondaryButton = PromptConfiguration.SecondaryButtonConfiguration(
            title: NeptuneLocalization.Button.Title.done,
            actionHandler: secondaryButtonAction
        )
        let configuration = PromptConfiguration.make(
            asset: .scene3D(.confetti),
            title: L10n.RequestMoney.CardOnboarding.Prompt.Available.title,
            message: .text(L10n.RequestMoney.CardOnboarding.Prompt.Available.message),
            primaryButton: primaryButton,
            secondaryButton: secondaryButton,
            appearHaptics: .success
        )
        return PromptViewControllerFactory.make(from: configuration)
    }

    func makeCardIneligible(primaryButtonAction: @escaping (UIViewController?) -> Void) -> UIViewController {
        let primaryButton = PromptConfiguration.PrimaryButtonConfiguration(
            title: L10n.RequestMoney.CardOnboarding.Prompt.Ineligible.PrimaryButton.title,
            actionHandler: primaryButtonAction
        )
        let configuration = PromptConfiguration.make(
            asset: .scene3D(.checkMark),
            title: L10n.RequestMoney.CardOnboarding.Prompt.Ineligible.title,
            message: .text(L10n.RequestMoney.CardOnboarding.Prompt.Ineligible.message),
            primaryButton: primaryButton,
            appearHaptics: .success
        )
        return PromptViewControllerFactory.make(from: configuration)
    }
}
