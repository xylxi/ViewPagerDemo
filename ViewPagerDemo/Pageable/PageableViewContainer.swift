import UIKit
import Combine
import SnapKit
import MJRefresh

// MARK: - Architecture Overview
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │                        PageableViewContainer 架构                            │
// ├─────────────────────────────────────────────────────────────────────────────┤
// │                                                                             │
// │  ┌─────────────────┐         Combine          ┌──────────────────────┐     │
// │  │                 │ ──────────────────────── │                      │     │
// │  │  PageableView-  │  viewState / items /     │   PageableView-      │     │
// │  │    Model        │  loadMoreState           │     Container        │     │
// │  │                 │ ◀──────────────────────  │                      │     │
// │  └─────────────────┘   refresh / loadMore     └──────────────────────┘     │
// │          │                                              │                  │
// │          │                                              │                  │
// │          ▼                                              ▼                  │
// │  ┌─────────────────┐                          ┌──────────────────────┐     │
// │  │   PageResult    │                          │   UICollectionView   │     │
// │  │  (items+cursor) │                          │  + DiffableDataSource│     │
// │  └─────────────────┘                          └──────────────────────┘     │
// │                                                         │                  │
// │                                                         ▼                  │
// │                                               ┌──────────────────────┐     │
// │                                               │ Extensible Components│     │
// │                                               ├──────────────────────┤     │
// │                                               │ • CellConfigurator   │     │
// │                                               │ • StateViewProvider  │     │
// │                                               │ • SelectionHandler   │     │
// │                                               │ • RefreshHeader      │     │
// │                                               │ • LoadMoreFooter     │     │
// │                                               └──────────────────────┘     │
// │                                                                             │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// MARK: - State Flow
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │                              状态流转图                                      │
// ├─────────────────────────────────────────────────────────────────────────────┤
// │                                                                             │
// │  ViewState:                                                                 │
// │  ┌───────┐  loadInitial()  ┌─────────┐  success(empty)  ┌───────┐          │
// │  │ idle  │ ───────────────▶│ loading │ ────────────────▶│ empty │          │
// │  └───────┘                 └─────────┘                  └───────┘          │
// │                                  │                                          │
// │                                  │ success(hasData)                         │
// │                                  ▼                                          │
// │                            ┌──────────┐  refresh()  ┌─────────┐            │
// │                            │  loaded  │ ◀──────────▶│ loading │            │
// │                            └──────────┘             └─────────┘            │
// │                                  │                       │                  │
// │                                  │ failure               │ failure          │
// │                                  ▼                       ▼                  │
// │                            ┌──────────┐            ┌──────────┐            │
// │                            │  failed  │ ◀─────────▶│  failed  │            │
// │                            └──────────┘  retry()   └──────────┘            │
// │                                                                             │
// │  LoadMoreState:                                                             │
// │  ┌───────┐  loadMore()  ┌─────────┐  success  ┌───────┐                    │
// │  │ idle  │ ────────────▶│ loading │ ─────────▶│ idle  │ (hasMore)          │
// │  └───────┘              └─────────┘           └───────┘                    │
// │                              │                    │                         │
// │                              │ failure            │ success (!hasMore)      │
// │                              ▼                    ▼                         │
// │                         ┌────────┐          ┌────────────┐                  │
// │                         │ failed │          │ noMoreData │                  │
// │                         └────────┘          └────────────┘                  │
// │                                                                             │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// MARK: - Component Responsibilities
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │                              组件职责                                        │
// ├─────────────────────────────────────────────────────────────────────────────┤
// │                                                                             │
// │  PageableViewContainer (本类)                                               │
// │  ├── 职责：UI 容器，负责组装和协调各组件                                       │
// │  ├── 绑定 ViewModel 状态变化                                                 │
// │  ├── 管理 CollectionView + DiffableDataSource                               │
// │  ├── 管理 StateView 的添加/移除                                              │
// │  └── 管理 RefreshHeader / LoadMoreFooter                                    │
// │                                                                             │
// │  PageableCellConfiguring (协议)                                             │
// │  ├── 职责：Cell 配置，外部注入                                               │
// │  ├── registerCells(in:) - 注册 Cell                                         │
// │  ├── collectionView(_:cellFor:at:) - 配置 Cell                              │
// │  └── layout(for:) - 提供布局                                                │
// │                                                                             │
// │  PageableStateView (协议)                                                   │
// │  ├── 职责：状态视图，内部闭环处理状态变化                                      │
// │  └── updateState(_:retryAction:) - 响应状态变化                              │
// │                                                                             │
// │  PageableStateViewProviding (协议)                                          │
// │  ├── 职责：状态视图工厂                                                      │
// │  └── makeStateView() - 创建状态视图实例                                      │
// │                                                                             │
// │  PageableItemSelectionHandling (协议)                                       │
// │  ├── 职责：处理 Item 点击事件                                                │
// │  └── didSelectItem(_:at:) - 响应点击                                        │
// │                                                                             │
// │  MJRefreshHeader / MJRefreshFooter (外部依赖)                               │
// │  ├── 职责：下拉刷新 / 加载更多 UI                                            │
// │  └── 支持注入任意 MJRefresh 子类                                             │
// │                                                                             │
// │  PageableEventTracking (协议)                                               │
// │  ├── 职责：事件追踪，用于埋点上报                                             │
// │  ├── 加载事件：initialStart/Success/Failure, refreshStart/Success/Failure  │
// │  ├── 加载更多：loadMoreStart/Success/Failure                                │
// │  ├── Item 曝光：itemExposure(item, index)                                   │
// │  └── Item 点击：itemClick(item, index)                                      │
// │                                                                             │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// MARK: - Usage Examples
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │                              使用示例                                        │
// ├─────────────────────────────────────────────────────────────────────────────┤
// │                                                                             │
// │  // 1. 基础用法                                                              │
// │  let vm = PageableViewModel<Item, Int>(initialCursor: 0) { page in          │
// │      try await api.fetch(page: page)                                        │
// │  }                                                                          │
// │  let container = PageableViewContainer(                                     │
// │      viewModel: vm,                                                         │
// │      cellConfigurator: MyCellConfigurator()                                 │
// │  )                                                                          │
// │  vm.loadInitial()                                                           │
// │                                                                             │
// │  // 2. 自定义状态视图                                                         │
// │  let container = PageableViewContainer(                                     │
// │      viewModel: vm,                                                         │
// │      cellConfigurator: config,                                              │
// │      stateViewProvider: CustomStateViewProvider()                           │
// │  )                                                                          │
// │                                                                             │
// │  // 3. 自定义刷新控件                                                         │
// │  let container = PageableViewContainer(                                     │
// │      viewModel: vm,                                                         │
// │      cellConfigurator: config,                                              │
// │      refreshHeader: MJRefreshGifHeader(),                                   │
// │      loadMoreFooter: MJRefreshBackNormalFooter()                            │
// │  )                                                                          │
// │                                                                             │
// │  // 4. 禁用刷新功能                                                           │
// │  let container = PageableViewContainer(                                     │
// │      viewModel: vm,                                                         │
// │      cellConfigurator: config,                                              │
// │      refreshHeader: nil,      // 禁用下拉刷新                                 │
// │      loadMoreFooter: nil      // 禁用加载更多                                 │
// │  )                                                                          │
// │                                                                             │
// │  // 5. 处理点击事件                                                           │
// │  let container = PageableViewContainer(                                     │
// │      viewModel: vm,                                                         │
// │      cellConfigurator: config,                                              │
// │      selectionHandler: MySelectionHandler()                                 │
// │  )                                                                          │
// │                                                                             │
// │  // 6. 埋点追踪                                                               │
// │  class MyTracker: PageableEventTracking {                                   │
// │      func onEvent(_ event: PageableEvent<Item>) {                           │
// │          switch event {                                                     │
// │          case .load(let e): trackLoad(e)                                    │
// │          case .itemExposure(let item, let idx): trackExposure(item, idx)    │
// │          case .itemClick(let item, let idx): trackClick(item, idx)          │
// │          }                                                                  │
// │      }                                                                      │
// │  }                                                                          │
// │  let container = PageableViewContainer(                                     │
// │      viewModel: vm,                                                         │
// │      cellConfigurator: config,                                              │
// │      eventTracker: MyTracker()                                              │
// │  )                                                                          │
// │                                                                             │
// └─────────────────────────────────────────────────────────────────────────────┘

/// 通用分页视图容器
///
/// 基于 PageableViewModel 的 UI 容器，自动响应 ViewModel 的状态变化并渲染对应的 UI。
///
/// ## 功能特性
/// - 自动根据 ViewState 切换视图（loading/empty/error/loaded）
/// - 使用 UICollectionViewDiffableDataSource 驱动数据渲染
/// - 使用 Combine 进行数据绑定
/// - 支持下拉刷新和加载更多（可注入自定义 MJRefresh 子类）
/// - 支持外部定制 Cell、状态视图、点击处理
///
/// ## 泛型参数
/// - `Item`: 数据项类型（需要实现 Hashable）
/// - `Cursor`: 游标类型
///
/// ## 设计原则
/// - **组合优于继承**：通过协议注入各组件，而非子类化
/// - **职责单一**：Container 只负责组装和协调，具体逻辑由各组件实现
/// - **状态内聚**：StateView 内部闭环处理所有状态，Container 只负责添加/移除
/// - **按需创建**：StateView 在需要时创建，成功后移除，节省内存
public final class PageableViewContainer<Item: Hashable, Cursor>: UIView, UICollectionViewDelegate {

    // MARK: - Type Aliases

    public typealias ViewModel = PageableViewModel<Item, Cursor>
    public typealias CellConfigurator = any PageableCellConfiguring<Item>
    public typealias StateViewProvider = PageableStateViewProviding
    public typealias SelectionHandler = any PageableItemSelectionHandling<Item>
    public typealias EventTracker = any PageableEventTracking<Item>

    // MARK: - Public Properties

    /// ViewModel（通过 Combine 绑定）
    public let viewModel: ViewModel

    /// Cell 配置器
    public let cellConfigurator: CellConfigurator

    /// 状态视图提供者
    public var stateViewProvider: StateViewProvider

    /// Item 选中处理器（可选）
    public var selectionHandler: SelectionHandler?

    /// 下拉刷新 Header（设置 nil 禁用下拉刷新）
    public var refreshHeader: MJRefreshHeader? {
        didSet { setupRefreshHeader() }
    }

    /// 加载更多 Footer（设置 nil 禁用加载更多）
    public var loadMoreFooter: MJRefreshFooter? {
        didSet { setupLoadMoreFooter() }
    }

    /// 事件追踪器（可选，用于埋点上报）
    public var eventTracker: EventTracker?

    // MARK: - Private Properties

    /// 数据源
    private var dataSource: UICollectionViewDiffableDataSource<Int, Item>?

    /// Combine 订阅
    private var cancellables = Set<AnyCancellable>()

    /// 当前状态视图（按需创建）
    private var stateView: PageableStateView?

    /// 上一次 ViewState（用于事件追踪）
    private var previousViewState: ViewState = .idle

    /// 上一次 LoadMoreState（用于事件追踪）
    private var previousLoadMoreState: LoadMoreState = .idle

    /// 当前加载更多的页码（用于事件追踪）
    private var currentLoadMorePage: Int = 0

    // MARK: - UI Components

    /// 数据列表 CollectionView
    private(set) lazy var collectionView: UICollectionView = {
        let layout = cellConfigurator.layout(for: UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()))
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Initialization

    /// 初始化分页视图容器
    ///
    /// - Parameters:
    ///   - viewModel: 分页 ViewModel
    ///   - cellConfigurator: Cell 配置器
    ///   - stateViewProvider: 状态视图提供者（默认使用 DefaultStateViewProvider）
    ///   - selectionHandler: Item 选中处理器（可选）
    ///   - eventTracker: 事件追踪器（可选，用于埋点上报）
    ///   - refreshHeader: 下拉刷新 Header（默认使用 MJRefreshNormalHeader）
    ///   - loadMoreFooter: 加载更多 Footer（默认使用 MJRefreshAutoNormalFooter）
    public init(
        viewModel: ViewModel,
        cellConfigurator: CellConfigurator,
        stateViewProvider: StateViewProvider = DefaultStateViewProvider(),
        selectionHandler: SelectionHandler? = nil,
        eventTracker: EventTracker? = nil,
        refreshHeader: MJRefreshHeader? = nil,
        loadMoreFooter: MJRefreshFooter? = MJRefreshAutoNormalFooter()
    ) {
        self.viewModel = viewModel
        self.cellConfigurator = cellConfigurator
        self.stateViewProvider = stateViewProvider
        self.selectionHandler = selectionHandler
        self.eventTracker = eventTracker
        self.refreshHeader = refreshHeader
        self.loadMoreFooter = loadMoreFooter
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

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 注册 Cell
        cellConfigurator.registerCells(in: collectionView)

        // 配置数据源
        setupDataSource()

        // 配置刷新控件
        setupRefreshHeader()
        setupLoadMoreFooter()
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

        // 绑定 isRefreshing（刷新结束时停止 header 动画）
        viewModel.$isRefreshing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshing in
                if !isRefreshing {
                    self?.collectionView.mj_header?.endRefreshing()
                }
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
        defer { previousViewState = state }

        // 刷新时不结束 header 动画，由 isRefreshing 绑定控制
        if !viewModel.isRefreshing {
            hideRefreshHeader()
        }

        // 事件追踪
        trackViewStateEvent(from: previousViewState, to: state)

        switch state {
        case .idle:
            removeStateView()

        case .loading:
            // 如果正在刷新（已有数据），不显示全屏 loading
            if !viewModel.isRefreshing {
                showStateView(state: state)
            }

        case .empty, .failed:
            showStateView(state: state)

        case .loaded:
            removeStateView()
        }
    }

    private func handleLoadMoreStateChange(_ state: LoadMoreState) {
        defer { previousLoadMoreState = state }

        // 事件追踪
        trackLoadMoreStateEvent(from: previousLoadMoreState, to: state)

        switch state {
        case .idle:
            collectionView.mj_footer?.resetNoMoreData()

        case .loading:
            currentLoadMorePage += 1

        case .noMoreData:
            collectionView.mj_footer?.endRefreshingWithNoMoreData()

        case .failed:
            collectionView.mj_footer?.endRefreshing()
        }
    }

    // MARK: - Event Tracking

    private func trackViewStateEvent(from oldState: ViewState, to newState: ViewState) {
        guard let tracker = eventTracker else { return }

        // 进入 loading 状态
        if case .loading = newState {
            // 判断是首次加载还是刷新
            if case .idle = oldState {
                tracker.onEvent(.load(.initialStart))
            } else {
                tracker.onEvent(.load(.refreshStart))
            }
        }

        // 从 loading 状态退出
        if case .loading = oldState {
            switch newState {
            case .loaded, .empty:
                let itemCount = viewModel.items.count
                // 判断是首次加载成功还是刷新成功
                if previousViewState == .idle || (previousViewState == .loading && currentLoadMorePage == 0) {
                    tracker.onEvent(.load(.initialSuccess(itemCount: itemCount)))
                } else {
                    tracker.onEvent(.load(.refreshSuccess(itemCount: itemCount)))
                }

            case .failed(let error):
                if previousViewState == .idle {
                    tracker.onEvent(.load(.initialFailure(error: error)))
                } else {
                    tracker.onEvent(.load(.refreshFailure(error: error)))
                }

            default:
                break
            }
        }
    }

    private func trackLoadMoreStateEvent(from oldState: LoadMoreState, to newState: LoadMoreState) {
        guard let tracker = eventTracker else { return }

        // 进入 loading 状态
        if case .loading = newState {
            tracker.onEvent(.load(.loadMoreStart(page: currentLoadMorePage + 1)))
        }

        // 从 loading 状态退出
        if case .loading = oldState {
            switch newState {
            case .idle:
                tracker.onEvent(.load(.loadMoreSuccess(
                    page: currentLoadMorePage,
                    itemCount: viewModel.items.count,
                    hasMore: true
                )))

            case .noMoreData:
                tracker.onEvent(.load(.loadMoreSuccess(
                    page: currentLoadMorePage,
                    itemCount: viewModel.items.count,
                    hasMore: false
                )))

            case .failed:
                tracker.onEvent(.load(.loadMoreFailure(
                    page: currentLoadMorePage,
                    error: NSError(domain: "PageableViewContainer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Load more failed"])
                )))

            default:
                break
            }
        }
    }

    // MARK: - State View Management

    private func showStateView(state: ViewState) {
        // 按需创建并添加 stateView
        if stateView == nil {
            let view = stateViewProvider.makeStateView()
            addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            stateView = view
        }

        stateView?.updateState(state, retryAction: { [weak self] in
            self?.viewModel.retry()
        })
        collectionView.isHidden = true
    }

    private func removeStateView() {
        guard let stateView else { return }
        // 通知 stateView 当前状态，让其有机会处理（如动画）
        stateView.updateState(.loaded, retryAction: nil)
        stateView.removeFromSuperview()
        self.stateView = nil
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

    private func setupRefreshHeader() {
        guard let header = refreshHeader else {
            collectionView.mj_header = nil
            return
        }
        header.refreshingBlock = { [weak self] in
            self?.viewModel.refresh()
        }
        collectionView.mj_header = header
    }

    private func hideRefreshHeader() {
        collectionView.mj_header?.endRefreshing()
    }

    private func setupLoadMoreFooter() {
        guard let footer = loadMoreFooter else {
            collectionView.mj_footer = nil
            return
        }
        footer.refreshingBlock = { [weak self] in
            self?.viewModel.loadMore()
        }
        collectionView.mj_footer = footer
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.items.count else {
            return
        }
        let item = viewModel.items[indexPath.item]

        // 事件追踪：点击
        eventTracker?.onEvent(.itemClick(item: item, index: indexPath.item))

        selectionHandler?.didSelectItem(item, at: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.items.count else {
            return
        }
        let item = viewModel.items[indexPath.item]

        // 事件追踪：曝光
        eventTracker?.onEvent(.itemExposure(item: item, index: indexPath.item))
    }
}

// MARK: - Default State View Provider

/// 默认状态视图提供者
public struct DefaultStateViewProvider: PageableStateViewProviding {
    public init() {}

    public func makeStateView() -> PageableStateView {
        DefaultPageableStateView()
    }
}

// MARK: - Default Pageable State View

/// 默认状态视图
///
/// 内部闭环处理所有状态变化（loading/empty/error）
public final class DefaultPageableStateView: UIView, PageableStateView {

    // MARK: - UI Components

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemGray
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let messageLabel: UILabel = {
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
        button.isHidden = true
        return button
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Properties

    private var retryAction: (() -> Void)?

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear

        contentStackView.addArrangedSubview(activityIndicator)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(retryButton)

        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
    }

    // MARK: - PageableStateView

    public func updateState(_ state: ViewState, retryAction: (() -> Void)?) {
        self.retryAction = retryAction

        switch state {
        case .idle, .loaded:
            activityIndicator.stopAnimating()
            messageLabel.isHidden = true
            retryButton.isHidden = true

        case .loading:
            activityIndicator.startAnimating()
            messageLabel.text = "加载中..."
            messageLabel.isHidden = false
            retryButton.isHidden = true

        case .empty:
            activityIndicator.stopAnimating()
            messageLabel.text = "暂无数据"
            messageLabel.isHidden = false
            retryButton.isHidden = true

        case .failed(let error):
            activityIndicator.stopAnimating()
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
