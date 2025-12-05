import Combine
import Foundation

/// 通用分页 ViewModel（Promise 版本）
///
/// 泛型类，用于管理分页数据的加载状态和数据列表。
/// 支持首次加载、刷新、重试、加载更多等操作。
/// 使用 Combine 的 AnyPublisher 进行异步操作。
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
/// let viewModel = PageableViewModelPromise<NewsItem, Int>(initialCursor: 0) { page in
///     api.fetchNews(page: page)
///         .map { response in
///             let nextCursor = response.hasMore ? page + 1 : nil
///             return PageResult(items: response.list, nextCursor: nextCursor)
///         }
///         .eraseToAnyPublisher()
/// }
/// ```
///
/// 使用示例（Int 游标，从 1 开始）：
/// ```swift
/// let viewModel = PageableViewModelPromise<NewsItem, Int>(initialCursor: 1) { page in
///     api.fetchNews(page: page)
///         .map { response in
///             let nextCursor = response.hasMore ? page + 1 : nil
///             return PageResult(items: response.list, nextCursor: nextCursor)
///         }
///         .eraseToAnyPublisher()
/// }
/// ```
///
/// 使用示例（String 游标）：
/// ```swift
/// let viewModel = PageableViewModelPromise<Post, String>(initialCursor: "") { cursor in
///     api.fetchTimeline(cursor: cursor)
///         .map { response in
///             PageResult(items: response.posts, nextCursor: response.nextCursor)
///         }
///         .eraseToAnyPublisher()
/// }
/// ```
@MainActor
public final class PageableViewModelPromise<Item, Cursor>: ObservableObject {

    // MARK: - Published State

    /// 当前视图状态
    @Published public private(set) var viewState: ViewState = .idle

    /// 当前数据列表
    @Published public private(set) var items: [Item] = []

    /// 加载更多状态
    @Published public private(set) var loadMoreState: LoadMoreState = .idle

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
    private let fetchPage: (Cursor) -> AnyPublisher<PageResult<Item, Cursor>, Error>

    /// 当前加载订阅（用于取消）
    private var loadCancellable: AnyCancellable?

    // MARK: - Initialization

    /// 通过闭包初始化
    ///
    /// - Parameters:
    ///   - initialCursor: 初始游标值
    ///   - fetcher: 分页数据获取闭包，接收游标返回 Publisher
    public init(
        initialCursor: Cursor,
        fetcher: @escaping (Cursor) -> AnyPublisher<PageResult<Item, Cursor>, Error>
    ) {
        self.initialCursor = initialCursor
        self.currentCursor = initialCursor
        self.fetchPage = fetcher
    }

    /// 通过协议初始化
    ///
    /// - Parameters:
    ///   - initialCursor: 初始游标值
    ///   - fetcher: 实现 `PageableDataFetchingPromise` 协议的对象
    public convenience init<F: PageableDataFetchingPromise>(
        initialCursor: Cursor,
        fetcher: F
    ) where F.Item == Item, F.Cursor == Cursor {
        self.init(initialCursor: initialCursor) { cursor in
            fetcher.fetchPage(cursor)
        }
    }

    deinit {
        loadCancellable?.cancel()
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
    /// 取消当前请求，重置状态后重新加载
    public func refresh() {
        loadCancellable?.cancel()
        reset()
        viewState = .loading
        performLoad(cursor: initialCursor, isLoadMore: false)
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
        loadCancellable?.cancel()
        items = []
        currentCursor = initialCursor
        nextCursor = nil
        loadMoreState = .idle
    }

    /// 执行加载
    private func performLoad(cursor: Cursor, isLoadMore: Bool) {
        loadCancellable = fetchPage(cursor)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }

                    if case let .failure(error) = completion {
                        self.handleFailure(error: error, isLoadMore: isLoadMore)
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self else { return }

                    self.handleSuccess(result: result, cursor: cursor, isLoadMore: isLoadMore)
                }
            )
    }

    /// 处理加载成功
    private func handleSuccess(
        result: PageResult<Item, Cursor>,
        cursor: Cursor,
        isLoadMore: Bool
    ) {
        if isLoadMore {
            items.append(contentsOf: result.items)
        } else {
            items = result.items
        }

        currentCursor = cursor
        nextCursor = result.nextCursor

        // 更新视图状态（仅首次加载时更新，loadMore 不改变主状态）
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

        if isLoadMore {
            // 加载更多失败不改变主视图状态
            loadMoreState = .failed
        } else {
            viewState = .failed(stateError)
            loadMoreState = .idle
        }
    }
}

// MARK: - Convenience Init (Int Cursor)

extension PageableViewModelPromise where Cursor == Int {
    /// 便捷初始化（Int 游标，默认从 0 开始）
    ///
    /// - Parameters:
    ///   - fetcher: 分页数据获取闭包
    ///
    /// 使用默认初始游标 0，避免与主构造函数参数签名完全一致导致的递归调用。
    public convenience init(
        fetcher: @escaping (Int) -> AnyPublisher<PageResult<Item, Int>, Error>
    ) {
        self.init(initialCursor: 0, fetcher: fetcher)
    }
}
