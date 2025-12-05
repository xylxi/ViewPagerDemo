import UIKit
import SnapKit

// MARK: - Demo Page State Provider

final class DemoPageStateProvider: PagerPagePresentationProviding {
    
    private weak var dataStore: DemoDataStore?
    
    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }
    
    func registerPageStateCells(in collectionView: UICollectionView) {
        collectionView.register(DemoPageStateCell.self, forCellWithReuseIdentifier: DemoPageStateCell.reuseIdentifier)
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, pageContainer: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell? {
        guard let pageData = dataStore?.pageData(for: page.pageId) else { return nil }
        
        switch pageData.state {
        case .loaded:
            // 返回 nil 表示展示数据列表
            return nil
        case .loading, .empty, .failed:
            guard let cell = pageContainer.dequeueReusableCell(withReuseIdentifier: DemoPageStateCell.reuseIdentifier, for: indexPath) as? DemoPageStateCell else {
                return nil
            }
            cell.render(state: pageData.state)
            return cell
        }
    }
}

// MARK: - Demo Page State Cell

final class DemoPageStateCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoPageStateCell"

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

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

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
    }

    func render(state: DemoDataStore.PageState) {
        switch state {
        case .loading:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            titleLabel.text = "加载中..."
            subtitleLabel.text = "正在获取数据，请稍候"
        case .empty:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = "暂无内容"
            subtitleLabel.text = "可以稍后再试或更换分类"
        case .failed(let message):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = "加载失败"
            subtitleLabel.text = message
        case .loaded:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = nil
            subtitleLabel.text = nil
        }
    }
}
