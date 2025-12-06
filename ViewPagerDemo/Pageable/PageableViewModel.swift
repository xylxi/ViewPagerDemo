import Combine
import Foundation

/// 通用分页 ViewModel
///
/// 泛型类，用于管理分页数据的加载状态和数据列表。
/// 支持首次加载、刷新、重试、加载更多等操作。
///
/// 泛型参数：
/// - `Item`: 数据项类型
/// - `Cursor`: 游标类型（可以是 Int、String 或其他类型）
///
/// 设计原则：
/// - **数据无关**：通过泛型 `Item` 支持任意数据类型
/// - **游标灵活**：通过泛型 `Cursor` 支持任意游标类型
/// - **请求无关**：通过闭包注入请求逻辑，ViewModel 不依赖具体网络层
/// - **状态统一**：内置 `loading / empty / failed / loaded` 四种状态
/// - **响应式**：使用 Combine 发布状态变化
///
/// 使用示例（Int 游标，从 0 开始）：
/// ```swift
/// let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
///     let response = try await api.fetchNews(page: page)
///     let nextCursor = response.hasMore ? page + 1 : nil
///     return PageResult(items: response.list, nextCursor: nextCursor)
/// }
/// ```
///
/// 使用示例（Int 游标，从 1 开始）：
/// ```swift
/// let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 1) { page in
///     let response = try await api.fetchNews(page: page)
///     let nextCursor = response.hasMore ? page + 1 : nil
///     return PageResult(items: response.list, nextCursor: nextCursor)
/// }
/// ```
///
/// 使用示例（String 游标）：
/// ```swift
/// let viewModel = PageableViewModel<Post, String>(initialCursor: "") { cursor in
///     let response = try await api.fetchTimeline(cursor: cursor)
///     return PageResult(items: response.posts, nextCursor: response.nextCursor)
/// }
/// ```
@MainActor
public final class PageableViewModel<Item, Cursor>: ObservableObject {

    // MARK: - Published State

    /// 当前视图状态
    @Published public private(set) var viewState: ViewState = .idle

    /// 当前数据列表
    @Published public private(set) var items: [Item] = []

    /// 加载更多状态
    @Published public private(set) var loadMoreState: LoadMoreState = .idle

    /// 是否正在刷新（用于区分首次加载和下拉刷新）
    @Published public private(set) var isRefreshing: Bool = false

    // MARK: - Public State (Read-Only)

    /// 当前游标
    public private(set) var currentCursor: Cursor

    /// 下一页游标（nil 表示没有更多数据）
    public private(set) var nextCursor: Cursor?

    /// 是否还有更多数据
    public var hasMore: Bool {
        nextCursor != nil
    }

    // MARK: - Private Properties

    /// 初始游标（用于重置）
    private let initialCursor: Cursor

    /// 分页数据获取闭包
    private let fetchPage: (Cursor) async throws -> PageResult<Item, Cursor>

    /// 当前加载任务（用于取消）
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    /// 通过闭包初始化
    ///
    /// - Parameters:
    ///   - initialCursor: 初始游标值
    ///   - fetcher: 分页数据获取闭包，接收游标返回分页结果
    public init(
        initialCursor: Cursor,
        fetcher: @escaping (Cursor) async throws -> PageResult<Item, Cursor>
    ) {
        self.initialCursor = initialCursor
        self.currentCursor = initialCursor
        self.fetchPage = fetcher
    }

    /// 通过协议初始化
    ///
    /// - Parameters:
    ///   - initialCursor: 初始游标值
    ///   - fetcher: 实现 `PageableDataFetching` 协议的对象
    public convenience init<F: PageableDataFetching>(
        initialCursor: Cursor,
        fetcher: F
    ) where F.Item == Item, F.Cursor == Cursor {
        self.init(initialCursor: initialCursor) { cursor in
            try await fetcher.fetchPage(cursor)
        }
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public Actions

    /// 首次加载
    ///
    /// 从初始游标开始加载数据，会重置所有状态
    public func loadInitial() {
        guard viewState != .loading else { return }

        reset()
        viewState = .loading
        performLoad(cursor: initialCursor, isLoadMore: false)
    }

    /// 刷新
    ///
    /// 取消当前请求后重新加载。
    /// - 如果已有数据，保持当前列表显示，只显示 header 刷新动画
    /// - 如果无数据，显示全屏 loading
    public func refresh() {
        loadTask?.cancel()

        // 如果已有数据，标记为刷新状态，不改变 viewState
        // 这样可以保持列表显示，避免全屏 loading 覆盖
        if !items.isEmpty {
            isRefreshing = true
            performLoad(cursor: initialCursor, isLoadMore: false)
        } else {
            // 无数据时走首次加载逻辑
            reset()
            viewState = .loading
            performLoad(cursor: initialCursor, isLoadMore: false)
        }
    }

    /// 重试
    ///
    /// 失败后重试：
    /// - 如果主状态失败，重新首次加载
    /// - 如果加载更多失败，重新加载更多
    public func retry() {
        if case .failed = viewState {
            loadInitial()
            return
        }

        if loadMoreState == .failed {
            loadMore()
        }
    }

    /// 加载更多
    ///
    /// 使用 nextCursor 加载下一页数据，自动追加到现有列表
    public func loadMore() {
        guard canLoadMore, let cursor = nextCursor else { return }

        loadMoreState = .loading
        performLoad(cursor: cursor, isLoadMore: true)
    }

    // MARK: - Private Methods

    /// 是否可以加载更多
    private var canLoadMore: Bool {
        viewState == .loaded && hasMore && loadMoreState != .loading
    }

    /// 重置所有状态
    private func reset() {
        loadTask?.cancel()
        items = []
        currentCursor = initialCursor
        nextCursor = nil
        loadMoreState = .idle
    }

    /// 执行加载
    private func performLoad(cursor: Cursor, isLoadMore: Bool) {
        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await self.fetchPage(cursor)

                guard !Task.isCancelled else { return }

                self.handleSuccess(result: result, cursor: cursor, isLoadMore: isLoadMore)

            } catch {
                guard !Task.isCancelled else { return }

                self.handleFailure(error: error, isLoadMore: isLoadMore)
            }
        }
    }

    /// 处理加载成功
    private func handleSuccess(
        result: PageResult<Item, Cursor>,
        cursor: Cursor,
        isLoadMore: Bool
    ) {
        // 重置刷新状态
        let wasRefreshing = isRefreshing
        isRefreshing = false

        if isLoadMore {
            items.append(contentsOf: result.items)
        } else {
            items = result.items
            // 刷新成功时重置游标
            currentCursor = initialCursor
        }

        currentCursor = cursor
        nextCursor = result.nextCursor

        // 更新视图状态（仅首次加载/刷新时更新，loadMore 不改变主状态）
        if !isLoadMore {
            if items.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded
            }
        }

        // 更新加载更多状态
        if hasMore {
            loadMoreState = .idle
        } else {
            loadMoreState = .noMoreData
        }
    }

    /// 处理加载失败
    private func handleFailure(error: Error, isLoadMore: Bool) {
        let stateError = ViewStateError(error)

        // 重置刷新状态
        let wasRefreshing = isRefreshing
        isRefreshing = false

        if isLoadMore {
            // 加载更多失败不改变主视图状态
            loadMoreState = .failed
        } else if wasRefreshing {
            // 刷新失败时保持原有数据和状态，不显示错误页
            // 可以通过其他方式提示用户（如 Toast）
        } else {
            // 首次加载失败
            viewState = .failed(stateError)
            loadMoreState = .idle
        }
    }
}

// MARK: - Convenience Init (Int Cursor)

extension PageableViewModel where Cursor == Int {
    /// 便捷初始化（Int 游标，默认从 0 开始）
    ///
    /// - Parameters:
    ///   - fetcher: 分页数据获取闭包
    ///
    /// 使用默认初始游标 0，避免与主构造函数参数签名完全一致导致的递归调用。
    public convenience init(
        fetcher: @escaping (Int) async throws -> PageResult<Item, Int>
    ) {
        self.init(initialCursor: 0, fetcher: fetcher)
    }
}
