import UIKit
import SnapKit

/// 新闻状态视图（内部闭环处理所有状态）
final class NewsStateView: UIView, PageableStateView {

    // MARK: - UI Components

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("点击重试", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isHidden = true
        return button
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Properties

    private var retryAction: (() -> Void)?

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
        backgroundColor = .systemBackground

        contentStackView.addArrangedSubview(activityIndicator)
        contentStackView.addArrangedSubview(imageView)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(retryButton)

        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(80)
        }

        retryButton.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(44)
        }

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
    }

    // MARK: - PageableStateView

    func updateState(_ state: ViewState, retryAction: (() -> Void)?) {
        self.retryAction = retryAction

        switch state {
        case .idle, .loaded:
            activityIndicator.stopAnimating()
            imageView.isHidden = true
            messageLabel.isHidden = true
            retryButton.isHidden = true

        case .loading:
            activityIndicator.startAnimating()
            imageView.isHidden = true
            messageLabel.text = "正在加载新闻..."
            messageLabel.isHidden = false
            retryButton.isHidden = true

        case .empty:
            activityIndicator.stopAnimating()
            imageView.image = UIImage(systemName: "doc.text.magnifyingglass")
            imageView.tintColor = .systemGray3
            imageView.isHidden = false
            messageLabel.text = "暂无新闻"
            messageLabel.isHidden = false
            retryButton.isHidden = true

        case .failed(let error):
            activityIndicator.stopAnimating()
            imageView.image = UIImage(systemName: "exclamationmark.triangle")
            imageView.tintColor = .systemRed
            imageView.isHidden = false
            messageLabel.text = error.message
            messageLabel.isHidden = false
            retryButton.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func handleRetryTap() {
        retryAction?()
    }
}

// MARK: - State View Provider

/// 新闻状态视图提供者
struct NewsStateViewProvider: PageableStateViewProviding {
    func makeStateView() -> PageableStateView {
        NewsStateView()
    }
}
