import UIKit
import SnapKit

// MARK: - Demo Page State Provider

/// 页面状态提供者
///
/// 从 `AnyDemoPageViewModel` 读取状态，决定展示状态页还是数据页
final class DemoPageStateProvider: PagerPagePresentationProviding {

    private weak var dataStore: DemoDataStore?

    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }

    func registerPageStateCells(in collectionView: UICollectionView) {
        collectionView.register(
            DemoPageStateCell.self,
            forCellWithReuseIdentifier: DemoPageStateCell.reuseIdentifier
        )
    }

    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        pageContainer: UICollectionView,
        cellFor page: PageModel,
        at indexPath: IndexPath
    ) -> UICollectionViewCell? {
        guard let viewModel = dataStore?.viewModel(for: page.pageId) else {
            return nil
        }

        switch viewModel.viewState {
        case .loaded:
            return nil  // 展示数据列表
        case .idle, .loading, .empty, .failed:
            guard let cell = pageContainer.dequeueReusableCell(
                withReuseIdentifier: DemoPageStateCell.reuseIdentifier,
                for: indexPath
            ) as? DemoPageStateCell else {
                return nil
            }
            cell.render(state: viewModel.viewState)
            cell.onRetry = { [weak viewModel] in
                viewModel?.retry()
            }
            return cell
        }
    }
}

// MARK: - Demo Page State Cell

/// 页面状态 Cell
///
/// 展示 loading / empty / failed 状态
final class DemoPageStateCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoPageStateCell"

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let retryButton = UIButton(type: .system)

    /// 重试回调
    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        retryButton.setTitle("点击重试", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.isHidden = true

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(retryButton)

        stackView.setCustomSpacing(16, after: subtitleLabel)
    }

    @objc private func retryTapped() {
        onRetry?()
    }

    func render(state: ViewState) {
        switch state {
        case .idle, .loading:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            titleLabel.text = "加载中..."
            subtitleLabel.text = "正在获取数据，请稍候"
            retryButton.isHidden = true

        case .empty:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = "暂无内容"
            subtitleLabel.text = "可以稍后再试或更换分类"
            retryButton.isHidden = true

        case .failed(let error):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = "加载失败"
            subtitleLabel.text = error.message
            retryButton.isHidden = false

        case .loaded:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = nil
            subtitleLabel.text = nil
            retryButton.isHidden = true
        }
    }
}
