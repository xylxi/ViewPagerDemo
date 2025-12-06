import UIKit
import SnapKit

/// 新闻列表 Cell
final class NewsCell: UICollectionViewCell {

    static let reuseIdentifier = "NewsCell"

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(UIScreen.main.bounds.width - 32)
        }

        let stackView = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, timeLabel])
        stackView.axis = .vertical
        stackView.spacing = 8

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    // MARK: - Configure

    func configure(with item: NewsItem) {
        titleLabel.text = item.title
        summaryLabel.text = item.summary
        timeLabel.text = item.publishTime
    }
}

// MARK: - Cell Configurator

/// 新闻 Cell 配置器
final class NewsCellConfigurator: PageableCellConfiguring {

    func registerCells(in collectionView: UICollectionView) {
        collectionView.register(NewsCell.self, forCellWithReuseIdentifier: NewsCell.reuseIdentifier)
    }

    func collectionView(_ collectionView: UICollectionView, cellFor item: NewsItem, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NewsCell.reuseIdentifier,
            for: indexPath
        ) as? NewsCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: item)
        return cell
    }

    func layout(for collectionView: UICollectionView) -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }
}
