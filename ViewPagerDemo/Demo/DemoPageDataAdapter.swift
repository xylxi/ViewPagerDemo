import UIKit
import SnapKit

// MARK: - Demo Page Data Adapter

final class DemoPageDataAdapter: PagerPageDataRendering {
    
    private weak var dataStore: DemoDataStore?
    
    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }
    
    func registerDataCells(in collectionView: UICollectionView) {
        collectionView.register(DemoFeedCell.self, forCellWithReuseIdentifier: DemoFeedCell.reuseIdentifier)
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, layoutFor page: PageModel) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(80))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func pagerView(_ pagerView: MultiCategoryPagerView, itemsFor page: PageModel) -> [PageItemModel] {
        dataStore?.pageData(for: page.pageId)?.items ?? []
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, collectionView: UICollectionView, cellFor item: PageItemModel, at indexPath: IndexPath, page: PageModel) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DemoFeedCell.reuseIdentifier, for: indexPath) as? DemoFeedCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: item.payload as? DemoFeedItem)
        return cell
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect item: PageItemModel, at indexPath: IndexPath, page: PageModel) {
        let feedTitle = (item.payload as? DemoFeedItem)?.title ?? ""
        print("Tapped feed \(feedTitle) under page \(page.pageId)")
    }
}

// MARK: - Demo Feed Cell

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
