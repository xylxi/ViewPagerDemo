import UIKit
import SnapKit

final class PagerMenuDefaultCell: UICollectionViewCell {
    static let reuseIdentifier = "PagerMenuDefaultCell"
    
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
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemGray5
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}

