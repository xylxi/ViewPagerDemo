import UIKit
import SnapKit

/// PageableViewContainer 使用示例
///
/// 演示如何使用 PageableViewContainer 创建一个简单的新闻列表
final class DemoPageableContainer {

    // MARK: - Demo News Item

    /// 示例新闻数据项
    struct NewsItem: Hashable {
        let id: String
        let title: String
        let summary: String
        let publishTime: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
            lhs.id == rhs.id
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

    // MARK: - News Cell

    /// 新闻列表 Cell
    final class NewsCell: UICollectionViewCell {
        static let reuseIdentifier = "NewsCell"

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

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

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

        func configure(with item: NewsItem) {
            titleLabel.text = item.title
            summaryLabel.text = item.summary
            timeLabel.text = item.publishTime
        }
    }

    // MARK: - Custom State View Provider

    /// 自定义状态视图提供者
    final class CustomStateViewProvider: PageableStateViewProviding {
        func loadingView() -> UIView? {
            let view = CustomLoadingView()
            return view
        }

        func emptyView() -> UIView? {
            let view = CustomEmptyView()
            return view
        }

        func errorView(error: ViewStateError, retryAction: @escaping () -> Void) -> UIView? {
            let view = CustomErrorView(error: error, retryAction: retryAction)
            return view
        }
    }

    /// 自定义 Loading 视图
    final class CustomLoadingView: UIView {
        private let activityIndicator: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .systemBlue
            indicator.startAnimating()
            return indicator
        }()

        private let label: UILabel = {
            let label = UILabel()
            label.text = "正在加载新闻..."
            label.font = .systemFont(ofSize: 15)
            label.textColor = .systemGray
            label.textAlignment = .center
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setup() {
            backgroundColor = .systemBackground

            let stackView = UIStackView(arrangedSubviews: [activityIndicator, label])
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.alignment = .center

            addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
    }

    /// 自定义 Empty 视图
    final class CustomEmptyView: UIView {
        private let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(systemName: "doc.text.magnifyingglass")
            imageView.tintColor = .systemGray3
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()

        private let label: UILabel = {
            let label = UILabel()
            label.text = "暂无新闻"
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.textColor = .systemGray
            label.textAlignment = .center
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setup() {
            backgroundColor = .systemBackground

            let stackView = UIStackView(arrangedSubviews: [imageView, label])
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.alignment = .center

            addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            imageView.snp.makeConstraints { make in
                make.size.equalTo(80)
            }
        }
    }

    /// 自定义 Error 视图
    final class CustomErrorView: UIView {
        private let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(systemName: "exclamationmark.triangle")
            imageView.tintColor = .systemRed
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()

        private let label: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14)
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
            return button
        }()

        private let retryAction: () -> Void

        init(error: ViewStateError, retryAction: @escaping () -> Void) {
            self.retryAction = retryAction
            super.init(frame: .zero)
            label.text = error.message
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setup() {
            backgroundColor = .systemBackground

            let stackView = UIStackView(arrangedSubviews: [imageView, label, retryButton])
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.alignment = .center

            addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview().offset(20)
                make.trailing.lessThanOrEqualToSuperview().offset(-20)
            }

            imageView.snp.makeConstraints { make in
                make.size.equalTo(60)
            }

            retryButton.snp.makeConstraints { make in
                make.width.equalTo(120)
                make.height.equalTo(44)
            }

            retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
        }

        @objc private func handleRetryTap() {
            retryAction()
        }
    }

    // MARK: - Selection Handler

    /// Item 选中处理器
    final class NewsSelectionHandler: PageableItemSelectionHandling {
        func didSelectItem(_ item: NewsItem, at indexPath: IndexPath) {
            print("选中新闻：\(item.title)")
        }
    }

    // MARK: - Usage Example

    /// 创建 PageableViewContainer 示例
    ///
    /// - Returns: 配置好的 PageableViewContainer
    static func createExample() -> PageableViewContainer<NewsItem, Int> {
        // 1. 创建 ViewModel（模拟网络请求）
        let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // 模拟数据
            let items = (0..<20).map { index in
                NewsItem(
                    id: "news_\(page)_\(index)",
                    title: "新闻标题 \(page * 20 + index + 1)",
                    summary: "这是一条新闻的摘要内容，用于展示列表预览信息。这是一条新闻的摘要内容，用于展示列表预览信息。",
                    publishTime: "2024-01-\(String(format: "%02d", (index % 30) + 1)) 12:00"
                )
            }

            // 模拟分页（只有 3 页）
            let hasMore = page < 2
            return PageResult(items: items, hasMore: hasMore, currentPage: page)
        }

        // 2. 创建视图容器
        let container = PageableViewContainer(
            viewModel: viewModel,
            cellConfigurator: NewsCellConfigurator(),
            stateViewProvider: CustomStateViewProvider(),
            selectionHandler: NewsSelectionHandler()
        )

        // 3. 开始加载
        viewModel.loadInitial()

        return container
    }

    // MARK: - Error Simulation Example

    /// 创建带错误模拟的示例
    ///
    /// - Returns: 配置好的 PageableViewContainer
    static func createErrorExample() -> PageableViewContainer<NewsItem, Int> {
        var requestCount = 0

        let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
            requestCount += 1

            // 前两次请求模拟失败
            if requestCount <= 2 {
                try await Task.sleep(nanoseconds: 500_000_000)
                throw NSError(domain: "NetworkError", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "网络连接失败，请检查网络设置"
                ])
            }

            // 第三次请求成功
            try await Task.sleep(nanoseconds: 1_000_000_000)

            let items = (0..<20).map { index in
                NewsItem(
                    id: "news_\(page)_\(index)",
                    title: "新闻标题 \(page * 20 + index + 1)",
                    summary: "这是一条新闻的摘要内容。",
                    publishTime: "2024-01-\(String(format: "%02d", (index % 30) + 1)) 12:00"
                )
            }

            let hasMore = page < 2
            return PageResult(items: items, hasMore: hasMore, currentPage: page)
        }

        let container = PageableViewContainer(
            viewModel: viewModel,
            cellConfigurator: NewsCellConfigurator(),
            stateViewProvider: CustomStateViewProvider(),
            selectionHandler: NewsSelectionHandler()
        )

        viewModel.loadInitial()

        return container
    }

    // MARK: - Empty Data Example

    /// 创建空数据示例
    ///
    /// - Returns: 配置好的 PageableViewContainer
    static func createEmptyExample() -> PageableViewContainer<NewsItem, Int> {
        let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
            try await Task.sleep(nanoseconds: 1_000_000_000)
            // 返回空数据
            return PageResult(items: [], hasMore: false, currentPage: page)
        }

        let container = PageableViewContainer(
            viewModel: viewModel,
            cellConfigurator: NewsCellConfigurator(),
            stateViewProvider: CustomStateViewProvider(),
            selectionHandler: NewsSelectionHandler()
        )

        viewModel.loadInitial()

        return container
    }
}
