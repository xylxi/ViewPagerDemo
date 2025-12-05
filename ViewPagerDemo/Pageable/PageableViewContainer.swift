import UIKit
import Combine
import SnapKit
import MJRefresh

/// 通用分页视图容器
///
/// 基于 PageableViewModel 的 UI 容器，自动响应 ViewModel 的状态变化并渲染对应的 UI。
///
/// 功能特性：
/// - 自动根据 ViewState 切换视图（loading/empty/error/loaded）
/// - 使用 UICollectionViewDiffableDataSource 驱动数据渲染
/// - 使用 Combine 进行数据绑定
/// - 支持下拉刷新和加载更多
/// - 支持外部定制 Cell 和状态视图
///
/// 泛型参数：
/// - `Item`: 数据项类型（需要实现 Hashable）
/// - `Cursor`: 游标类型
///
/// 使用示例：
/// ```swift
/// // 1. 创建 ViewModel
/// let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
///     try await api.fetchNews(page: page)
/// }
///
/// // 2. 实现 Cell 配置协议
/// class NewsCellConfigurator: PageableCellConfiguring {
///     func registerCells(in collectionView: UICollectionView) {
///         collectionView.register(NewsCell.self, forCellWithReuseIdentifier: "NewsCell")
///     }
///
///     func collectionView(_ collectionView: UICollectionView, cellFor item: NewsItem, at indexPath: IndexPath) -> UICollectionViewCell {
///         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as! NewsCell
///         cell.configure(with: item)
///         return cell
///     }
///
///     func layout(for collectionView: UICollectionView) -> UICollectionViewLayout {
///         let layout = UICollectionViewFlowLayout()
///         layout.itemSize = CGSize(width: collectionView.bounds.width, height: 100)
///         return layout
///     }
/// }
///
/// // 3. 创建视图容器
/// let container = PageableViewContainer(
///     viewModel: viewModel,
///     cellConfigurator: NewsCellConfigurator()
/// )
///
/// // 4. 开始加载
/// viewModel.loadInitial()
/// ```
public final class PageableViewContainer<Item: Hashable, Cursor>: UIView {

    // MARK: - Type Aliases

    public typealias ViewModel = PageableViewModel<Item, Cursor>
    public typealias CellConfigurator = any PageableCellConfiguring<Item>
    public typealias StateViewProvider = any PageableStateViewProviding
    public typealias SelectionHandler = any PageableItemSelectionHandling<Item>
    public typealias LoadMoreHandler = any PageableLoadMoreHandling

    // MARK: - Public Properties

    /// ViewModel（通过 Combine 绑定）
    public let viewModel: ViewModel

    /// Cell 配置器
    public let cellConfigurator: CellConfigurator

    /// 状态视图提供者（可选）
    public var stateViewProvider: StateViewProvider?

    /// Item 选中处理器（可选）
    public var selectionHandler: SelectionHandler?

    /// 加载更多处理器（可选）
    public var loadMoreHandler: LoadMoreHandler?

    /// 是否启用下拉刷新（默认 true）
    public var enablePullToRefresh: Bool = true {
        didSet { updateRefreshHeader() }
    }

    /// 是否启用加载更多（默认 true）
    public var enableLoadMore: Bool = true {
        didSet { updateLoadMoreFooter() }
    }

    // MARK: - Private Properties

    /// 数据源
    private var dataSource: UICollectionViewDiffableDataSource<Int, Item>?

    /// Combine 订阅
    private var cancellables = Set<AnyCancellable>()

    /// 当前显示的状态视图
    private var currentStateView: UIView?

    // MARK: - UI Components

    /// 数据列表 CollectionView
    private lazy var collectionView: UICollectionView = {
        let layout = cellConfigurator.layout(for: UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()))
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.delegate = self
        return collectionView
    }()

    /// 状态视图容器（用于显示 loading/empty/error）
    private let stateViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    // MARK: - Initialization

    /// 初始化分页视图容器
    ///
    /// - Parameters:
    ///   - viewModel: 分页 ViewModel
    ///   - cellConfigurator: Cell 配置器
    ///   - stateViewProvider: 状态视图提供者（可选）
    ///   - selectionHandler: Item 选中处理器（可选）
    ///   - loadMoreHandler: 加载更多处理器（可选）
    public init(
        viewModel: ViewModel,
        cellConfigurator: CellConfigurator,
        stateViewProvider: StateViewProvider? = nil,
        selectionHandler: SelectionHandler? = nil,
        loadMoreHandler: LoadMoreHandler? = nil
    ) {
        self.viewModel = viewModel
        self.cellConfigurator = cellConfigurator
        self.stateViewProvider = stateViewProvider
        self.selectionHandler = selectionHandler
        self.loadMoreHandler = loadMoreHandler
        super.init(frame: .zero)
        setup()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .systemBackground

        addSubview(collectionView)
        addSubview(stateViewContainer)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stateViewContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 注册 Cell
        cellConfigurator.registerCells(in: collectionView)

        // 配置数据源
        setupDataSource()

        // 配置刷新控件
        updateRefreshHeader()
        updateLoadMoreFooter()
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            return self.cellConfigurator.collectionView(collectionView, cellFor: item, at: indexPath)
        }
    }

    // MARK: - Combine Binding

    private func bindViewModel() {
        // 绑定 ViewState
        viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleViewStateChange(state)
            }
            .store(in: &cancellables)

        // 绑定 Items
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applySnapshot(items: items)
            }
            .store(in: &cancellables)

        // 绑定 LoadMoreState
        viewModel.$loadMoreState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleLoadMoreStateChange(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - State Handling

    private func handleViewStateChange(_ state: ViewState) {
        switch state {
        case .idle:
            hideStateView()
            hideRefreshHeader()

        case .loading:
            showLoadingView()
            hideRefreshHeader()

        case .empty:
            showEmptyView()
            hideRefreshHeader()

        case .failed(let error):
            showErrorView(error: error)
            hideRefreshHeader()

        case .loaded:
            hideStateView()
            hideRefreshHeader()
        }
    }

    private func handleLoadMoreStateChange(_ state: LoadMoreState) {
        updateLoadMoreFooter()

        switch state {
        case .idle:
            collectionView.mj_footer?.resetNoMoreData()

        case .loading:
            collectionView.mj_footer?.beginRefreshing()

        case .noMoreData:
            collectionView.mj_footer?.endRefreshingWithNoMoreData()

        case .failed:
            collectionView.mj_footer?.endRefreshing()
        }
    }

    // MARK: - State View Management

    private func showLoadingView() {
        let view = stateViewProvider?.loadingView() ?? DefaultLoadingView()
        showStateView(view)
    }

    private func showEmptyView() {
        let view = stateViewProvider?.emptyView() ?? DefaultEmptyView()
        showStateView(view)
    }

    private func showErrorView(error: ViewStateError) {
        let view = stateViewProvider?.errorView(error: error, retryAction: { [weak self] in
            self?.viewModel.retry()
        }) ?? DefaultErrorView(error: error, retryAction: { [weak self] in
            self?.viewModel.retry()
        })
        showStateView(view)
    }

    private func showStateView(_ view: UIView) {
        hideStateView()
        currentStateView = view
        stateViewContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stateViewContainer.isHidden = false
        collectionView.isHidden = true
    }

    private func hideStateView() {
        currentStateView?.removeFromSuperview()
        currentStateView = nil
        stateViewContainer.isHidden = true
        collectionView.isHidden = false
    }

    // MARK: - Data Source

    private func applySnapshot(items: [Item]) {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Refresh Control

    private func updateRefreshHeader() {
        if enablePullToRefresh {
            let header = MJRefreshNormalHeader { [weak self] in
                self?.viewModel.refresh()
            }
            collectionView.mj_header = header
        } else {
            collectionView.mj_header = nil
        }
    }

    private func hideRefreshHeader() {
        collectionView.mj_header?.endRefreshing()
    }

    private func updateLoadMoreFooter() {
        guard enableLoadMore else {
            collectionView.mj_footer = nil
            return
        }

        guard let handler = loadMoreHandler else {
            // 使用默认 Footer
            let footer = MJRefreshAutoNormalFooter { [weak self] in
                self?.viewModel.loadMore()
            }
            collectionView.mj_footer = footer
            return
        }

        // 使用自定义 Footer
        if handler.shouldShowLoadMoreFooter(for: viewModel.loadMoreState) {
            if let customView = handler.loadMoreFooterView(for: viewModel.loadMoreState) {
                // 自定义视图需要包装成 MJRefreshComponent
                let footer = MJRefreshAutoNormalFooter { [weak self] in
                    self?.viewModel.loadMore()
                }
                collectionView.mj_footer = footer
            } else {
                // 使用默认 Footer
                let footer = MJRefreshAutoNormalFooter { [weak self] in
                    self?.viewModel.loadMore()
                }
                collectionView.mj_footer = footer
            }
        } else {
            collectionView.mj_footer = nil
        }
    }
}

// MARK: - UICollectionViewDelegate

extension PageableViewContainer: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.items.count else { return }
        let item = viewModel.items[indexPath.item]
        selectionHandler?.didSelectItem(item, at: indexPath)
    }
}

// MARK: - Default State Views

/// 默认 Loading 视图
private final class DefaultLoadingView: UIView {
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemGray
        indicator.startAnimating()
        return indicator
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.text = "加载中..."
        label.font = .systemFont(ofSize: 14)
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
        backgroundColor = .clear

        let stackView = UIStackView(arrangedSubviews: [activityIndicator, label])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

/// 默认 Empty 视图
private final class DefaultEmptyView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "暂无数据"
        label.font = .systemFont(ofSize: 16)
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
        backgroundColor = .clear
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

/// 默认 Error 视图
private final class DefaultErrorView: UIView {
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
        button.setTitle("重试", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
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
        backgroundColor = .clear

        let stackView = UIStackView(arrangedSubviews: [label, retryButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
    }

    @objc private func handleRetryTap() {
        retryAction()
    }
}
