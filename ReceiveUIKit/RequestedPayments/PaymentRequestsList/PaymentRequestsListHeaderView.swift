import LoggingKit
import Neptune
import TWUI

final class PaymentRequestsListHeaderView: UIView, HeaderView {
    var contentOffset: CGPoint = .zero
    var contentInset: UIEdgeInsets = .zero
    var scrollObserver: ScrollObserver? {
        get {
            titleView.scrollObserver
        }
        set {
            titleView.scrollObserver = newValue
        }
    }

    var delegate: HeaderViewDelegate? {
        get {
            titleView.delegate
        }
        set {
            titleView.delegate = newValue
        }
    }

    var layoutDelegate: HeaderViewLayoutDelegate? {
        get {
            titleView.layoutDelegate
        }
        set {
            titleView.layoutDelegate = newValue
        }
    }

    private let titleView = LargeTitleView()
    private let segmentedControlView = SegmentedControlView(segments: [])

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            titleView,
            segmentedControlView,
        ],
        axis: .vertical,
        spacing: .defaultSpacing
    ).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(.defaultMargin / 2)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.constrainToSuperview(.contentArea)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with viewModel: PaymentRequestsListHeaderView.ViewModel) {
        titleView.configure(with: viewModel.title)

        if let viewModel = viewModel.segmentedControl {
            segmentedControlView.configure(with: viewModel)
            segmentedControlView.isHidden = false
        } else {
            segmentedControlView.isHidden = true
        }

        layoutIfNeeded()
    }
}

extension PaymentRequestsListHeaderView {
    // sourcery: AutoEquatableForTest
    struct ViewModel {
        let title: LargeTitleViewModel
        let segmentedControl: SegmentedControlView.ViewModel?
    }
}
