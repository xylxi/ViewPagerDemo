import UIKit
import SnapKit

// MARK: - Demo Page Data Adapter

/// 页面数据适配器
///
/// 从 `PageableViewModel` 读取数据列表
final class DemoPageDataAdapter: PagerPageDataRendering {

    private weak var dataStore: DemoDataStore?

    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }

    func registerDataCells(in collectionView: UICollectionView) {
        collectionView.register(
            DemoFeedCell.self,
            forCellWithReuseIdentifier: DemoFeedCell.reuseIdentifier
        )
        collectionView.register(
            DemoGridCell.self,
            forCellWithReuseIdentifier: DemoGridCell.reuseIdentifier
        )
    }

    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        layoutFor page: PageModel
    ) -> UICollectionViewLayout {
        guard let category = page.userInfo as? DemoCategoryMeta else {
            return makeListLayout()
        }

        switch category.layoutType {
        case .list:
            return makeListLayout()
        case .grid3:
            return makeGridLayout(columns: 3)
        case .grid4:
            return makeGridLayout(columns: 4)
        }
    }

    // MARK: - Layout Builders

    /// 列表布局（一行一列）
    private func makeListLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }

    /// 等分网格布局
    private func makeGridLayout(columns: Int) -> UICollectionViewLayout {
        let fraction: CGFloat = 1.0 / CGFloat(columns)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(fraction),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: columns
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }

    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        itemsFor page: PageModel
    ) -> [PageItemModel] {
        guard let viewModel = dataStore?.viewModel(for: page.pageId) else {
            return []
        }
        // 从 ViewModel 读取 items，转换为 PageItemModel
        return viewModel.items.map { PageItemModel(id: $0.id, payload: $0) }
    }

    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        collectionView: UICollectionView,
        cellFor item: PageItemModel,
        at indexPath: IndexPath,
        page: PageModel
    ) -> UICollectionViewCell {
        guard let category = page.userInfo as? DemoCategoryMeta else {
            return UICollectionViewCell()
        }

        switch category.layoutType {
        case .list:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DemoFeedCell.reuseIdentifier,
                for: indexPath
            ) as? DemoFeedCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: item.payload as? DemoFeedItem)
            return cell

        case .grid3, .grid4:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DemoGridCell.reuseIdentifier,
                for: indexPath
            ) as? DemoGridCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: item.payload as? DemoFeedItem)
            return cell
        }
    }

    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        didSelect item: PageItemModel,
        at indexPath: IndexPath,
        page: PageModel
    ) {
        let feedTitle = (item.payload as? DemoFeedItem)?.title ?? ""
        print("Tapped feed \(feedTitle) under page \(page.pageId)")
    }
}

// MARK: - Demo Feed Cell (列表样式)

final class DemoFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoFeedCell"

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(containerView)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.backgroundColor = UIColor.secondarySystemBackground

        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        containerView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(with item: DemoFeedItem?) {
        titleLabel.text = item?.title ?? "未命名 Item"
        subtitleLabel.text = item?.subtitle ?? ""
    }
}

// MARK: - Demo Grid Cell (网格样式)

final class DemoGridCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoGridCell"

    private let containerView = UIView()
    private let imageView = UIView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(containerView)
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = UIColor.secondarySystemBackground

        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(6)
            make.height.equalTo(imageView.snp.width)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    func configure(with item: DemoFeedItem?) {
        titleLabel.text = item?.title ?? "未命名"
        imageView.backgroundColor = item?.imageColor ?? .systemGray4
    }
}
