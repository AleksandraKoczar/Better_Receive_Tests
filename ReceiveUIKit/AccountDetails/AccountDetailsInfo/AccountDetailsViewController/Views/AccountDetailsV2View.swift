import LoggingKit
import Neptune
import UIKit

protocol AccountDetailsV2ViewActionDelegate: AnyObject {
    func view(
        _ view: AccountDetailsV2View,
        didChangeSegmentIndexTo index: Int,
        type: AccountDetailsReceiveOptionReceiveType?
    )
}

final class AccountDetailsV2View: UIView {
    weak var delegate: AccountDetailsV2ViewActionDelegate?

    private let segmentedControl = SegmentedControlView(segments: [])

    private let pagingScrollView = UIScrollView().with {
        $0.isPagingEnabled = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.showsHorizontalScrollIndicator = false
        $0.alwaysBounceVertical = false
        $0.alwaysBounceHorizontal = false
        $0.showsVerticalScrollIndicator = false
        $0.isDirectionalLockEnabled = true
        $0.scrollsToTop = false
        $0.contentInsetAdjustmentBehavior = .never
    }

    private let pageStack = UIStackView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.alignment = .top
    }

    private var pageHeights: [CGFloat] = Array(repeating: 0, count: 10)
    private lazy var pageStackHeightConstraint = pageStack.heightAnchor.constraint(
        equalToConstant: 0
    )

    private lazy var segmentHeightConstraint = segmentedControl.heightAnchor.constraint(
        equalToConstant: 0
    )

    private var hasMultipleSegments: Bool {
        segmentedControl.numberOfSegments > 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Hack for aligning different page stack heights
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for index in 0..<self.pageStack.arrangedSubviews.count {
                if self.pageHeights[index] == 0,
                   let page = self.pageStack.arrangedSubviews[safe: index],
                   page.frame.height != 0 {
                    self.pageHeights[index] = page.frame.height
                }
            }
        }
    }
}

// MARK: - Interface

extension AccountDetailsV2View {
    func configure(with viewModel: AccountDetailsV2ViewModel) {
        pageStack.removeAllArrangedSubviews()

        setupSegmentedControl(receiveOptions: viewModel.receiveOptions)
        setupPageViews(viewModel: viewModel)
    }
}

// MARK: - UI Helpers

private extension AccountDetailsV2View {
    func setupSubviews() {
        addSubview(segmentedControl)
        addSubview(pagingScrollView)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -theme.spacing.horizontal.componentDefault
            ),
            segmentedControl.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: theme.spacing.horizontal.componentDefault
            ),
            pagingScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            pagingScrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            pagingScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            pagingScrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
            pagingScrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func setupSegmentedControl(receiveOptions: [AccountDetailsReceiveOptionV2PageViewModel]) {
        // Select initial state
        delegate?.view(
            self,
            didChangeSegmentIndexTo: 0,
            type: receiveOptions.first?.type
        )

        let segments = receiveOptions.compactMap { $0.title }
        let shouldHideSegment = receiveOptions.count < 2
        segmentedControl.isHidden = shouldHideSegment
        segmentHeightConstraint.isActive = shouldHideSegment

        segmentedControl.configure(
            with: SegmentedControlView.ViewModel(
                segments: segments,
                onChange: { [weak self] index in
                    guard let self else { return }
                    delegate?.view(
                        self,
                        didChangeSegmentIndexTo: index,
                        type: receiveOptions[safe: index]?.type
                    )

                    if let height = pageHeights[safe: index],
                       height != 0,
                       hasMultipleSegments {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.pageStackHeightConstraint.constant = max(height, self.pageStackHeightConstraint.constant)
                            self.pageStackHeightConstraint.isActive = true
                            self.pageStack.arrangedSubviews[safe: index]?.layoutIfNeeded()
                        })
                    }
                    pagingScrollView.scrollToPage(index)
                }
            )
        )
    }

    func setupPageViews(viewModel: AccountDetailsV2ViewModel) {
        setupPageContainer()

        viewModel.receiveOptions.forEach { pageModel in
            setupPageView(viewModel: pageModel)
        }

        bringSubviewToFront(segmentedControl)
        layoutIfNeeded()
    }

    func setupPageContainer() {
        pagingScrollView.addSubview(pageStack)
        pagingScrollView.delegate = self
        NSLayoutConstraint.activate([
            pageStack.topAnchor.constraint(equalTo: pagingScrollView.contentLayoutGuide.topAnchor),
            pageStack.leadingAnchor.constraint(equalTo: pagingScrollView.contentLayoutGuide.leadingAnchor),
            pageStack.trailingAnchor.constraint(equalTo: pagingScrollView.contentLayoutGuide.trailingAnchor),
            pageStack.bottomAnchor.constraint(equalTo: pagingScrollView.contentLayoutGuide.bottomAnchor),
        ])
    }

    func setupPageView(viewModel: AccountDetailsReceiveOptionV2PageViewModel) {
        let page = AccountDetailsReceiveOptionV2PageView(
            viewModel: viewModel
        )
        pageStack.addArrangedSubview(page)
        page.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
}

// MARK: - UIScrollViewDelegate

extension AccountDetailsV2View: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        var targetPageIndex = Int(floor(scrollView.contentOffset.x / pageWidth))
        if targetPageIndex < 0 {
            targetPageIndex = 0
        } else if targetPageIndex >= pageStack.subviews.count {
            targetPageIndex = pageStack.subviews.count - 1
        }
        segmentedControl.selectedSegmentIndex = targetPageIndex
    }
}
