import UIKit
import SnapKit

/// 默认菜单 Cell
///
/// 组件内置的简单菜单 cell，仅展示标题
/// 实际使用时建议通过 `PagerMenuContentProviding` 提供自定义 cell
final class PagerMenuDefaultCell: UICollectionViewCell {
    
    static let reuseIdentifier = "PagerMenuDefaultCell"
    
    // MARK: - UI Components
    
    private let titleLabel = UILabel()

    // MARK: - Initialization

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

    // MARK: - Configuration

    /// 配置 cell
    /// - Parameter title: 菜单标题
    func configure(title: String) {
        titleLabel.text = title
    }
}
