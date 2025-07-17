import LoggingKit
import Neptune
import TWUI

final class WisetagScannedProfileFooterView: UIView, ComponentView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerStackView)
        footerStackView.constrainToSuperview(.contentArea)
    }

    private lazy var footerStackView = UIStackView(
        axis: .horizontal,
        alignment: .center
    ).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.distribution = .fillEqually
        $0.layoutMargins = UIEdgeInsets(
            top: .zero,
            left: theme.spacing.horizontal.componentDefault,
            bottom: theme.spacing.vertical.componentDefault,
            right: theme.spacing.horizontal.componentDefault
        )
    }

    private func configureFooterButtons(with viewModels: [WisetagScannedProfileViewModel.ButtonViewModel]) {
        footerStackView.removeAllArrangedSubviews()

        let buttons = viewModels.map { vm in
            let button = CircularButton()
            button.setTitle(vm.title, for: .normal)
            button.setIcon(vm.icon, for: .normal)
            button.isEnabled = vm.enabled

            button.touchHandler = vm.action
            return button
        }
        if buttons.count == 2 {
            footerStackView.addArrangedSubview(.spacer(2))
            footerStackView.addArrangedSubview(buttons[0])
            footerStackView.addArrangedSubview(.spacer(2))
            footerStackView.addArrangedSubview(buttons[1])
            footerStackView.addArrangedSubview(.spacer(2))
        } else {
            footerStackView.addArrangedSubviews(buttons)
        }
    }

    private func configureLoader() {
        footerStackView.removeAllArrangedSubviews()
        footerStackView.addArrangedSubview(LoadingView())
    }

    func configure(with viewModel: WisetagScannedProfileViewModel.FooterViewModel) {
        if let buttons = viewModel.buttons {
            configureFooterButtons(with: buttons)
        } else {
            if viewModel.isLoading {
                configureLoader()
            } else {
                footerStackView.removeAllArrangedSubviews()
            }
        }
        layoutIfNeeded()
    }
}
