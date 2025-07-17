import Lottie
import Neptune
import TWFoundation
import TWUI

final class FindFriendsPageView: UIView {
    private lazy var titleLabel: Label = {
        let l = Label(style: \.smallDisplay)
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    private lazy var subtitleLabel: Label = {
        let l = Label(style: \.largeBody)
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    private lazy var stackView = UIStackView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.spacing = theme.spacing.vertical.componentDefault
    }

    var illustrationView: IllustrationView?

    func configure(model: FindFriendsViewModel) {
        backgroundColor = .clear
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        illustrationView = IllustrationView(
            asset: model.asset
        )

        layoutViews()
    }

    private func layoutViews() {
        guard let illustrationView else {
            return
        }

        addSubview(stackView)

        stackView.addArrangedSubviews(
            [
                illustrationView,
                titleLabel,
                subtitleLabel,
            ]
        )

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: centerYAnchor,
                constant: theme.spacing.vertical.value32
            ),
            stackView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: theme.spacing.horizontal.value32
            ),
            stackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -theme.spacing.horizontal.value32
            ),
        ])
    }
}
