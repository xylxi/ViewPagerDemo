import UIKit
import SnapKit

// MARK: - Demo Menu Provider

final class DemoMenuProvider: PagerMenuContentProviding {
    func registerMenuCells(in collectionView: UICollectionView) {
        collectionView.register(DemoMenuCell.self, forCellWithReuseIdentifier: DemoMenuCell.reuseIdentifier)
    }

    func pagerMenuCollectionView(_ collectionView: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DemoMenuCell.reuseIdentifier, for: indexPath) as? DemoMenuCell else {
            return UICollectionViewCell()
        }
        let meta = page.userInfo as? DemoCategoryMeta
        cell.configure(title: meta?.title ?? "分类\(indexPath.item + 1)", accentColor: meta?.accentColor ?? .systemGray)
        return cell
    }

    func pagerMenuCollectionView(_ collectionView: UICollectionView, sizeFor page: PageModel, at indexPath: IndexPath) -> CGSize {
        CGSize(width: 96, height: collectionView.bounds.height - 12)
    }

    func menuContentInsets(for collectionView: UICollectionView) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

// MARK: - Demo Menu Cell

final class DemoMenuCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoMenuCell"

    private let titleLabel = UILabel()
    private let indicator = UIView()
    private var accentColor: UIColor = .systemBlue

    override var isSelected: Bool {
        didSet { updateSelectionAppearance() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemGray5

        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textAlignment = .center

        indicator.layer.cornerRadius = 1.5
        indicator.backgroundColor = accentColor

        contentView.addSubview(titleLabel)
        contentView.addSubview(indicator)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        indicator.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(24)
            make.height.equalTo(3)
        }
        updateSelectionAppearance()
    }

    func configure(title: String, accentColor: UIColor) {
        titleLabel.text = title
        self.accentColor = accentColor
        indicator.backgroundColor = accentColor
        updateSelectionAppearance()
    }

    private func updateSelectionAppearance() {
        contentView.backgroundColor = isSelected ? accentColor.withAlphaComponent(0.15) : UIColor.systemGray5
        indicator.isHidden = !isSelected
        titleLabel.textColor = isSelected ? accentColor : .label
    }
}
