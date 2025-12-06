import Combine
import Foundation

/// 自定义分页 ViewModel 示例
///
/// 展示如何继承 `PageableViewModelPromise` 并重写关键方法
/// 添加了日志、埋点、数据过滤等自定义功能
@MainActor
class CustomPageableViewModel<Item, Cursor>: PageableViewModelPromise<Item, Cursor> {

    // MARK: - Custom Properties

    /// 是否启用日志
    private let enableLogging: Bool

    /// 自定义数据过滤闭包（可选）
    private let itemFilter: ((Item) -> Bool)?

    // MARK: - Initialization

    init(
        initialCursor: Cursor,
        enableLogging: Bool = true,
        itemFilter: ((Item) -> Bool)? = nil,
        fetcher: @escaping (Cursor) -> AnyPublisher<PageResult<Item, Cursor>, Error>
    ) {
        self.enableLogging = enableLogging
        self.itemFilter = itemFilter
        super.init(initialCursor: initialCursor, fetcher: fetcher)
    }

    // MARK: - Override Methods

    /// 重写重置方法，添加日志
    override func reset() {
        if enableLogging {
            print("📝 [CustomPageableViewModel] Resetting state...")
        }
        super.reset()
    }

    /// 重写加载方法，添加埋点
    override func performLoad(cursor: Cursor, isLoadMore: Bool) {
        if enableLogging {
            print("📝 [CustomPageableViewModel] Starting load - Cursor: \(cursor), IsLoadMore: \(isLoadMore)")
        }

        // 这里可以添加埋点逻辑
        // Analytics.track("page_load_start", properties: ["is_load_more": isLoadMore])

        super.performLoad(cursor: cursor, isLoadMore: isLoadMore)
    }

    /// 重写成功处理，添加数据过滤和日志
    override func handleSuccess(
        result: PageResult<Item, Cursor>,
        cursor: Cursor,
        isLoadMore: Bool
    ) {
        if enableLogging {
            print("✅ [CustomPageableViewModel] Load succeeded - Items: \(result.items.count), HasMore: \(result.nextCursor != nil)")
        }

        // 如果有自定义过滤器，先过滤数据
        var filteredResult = result
        if let filter = itemFilter {
            let filteredItems = result.items.filter(filter)
            if enableLogging && filteredItems.count != result.items.count {
                print("🔍 [CustomPageableViewModel] Filtered \(result.items.count - filteredItems.count) items")
            }
            filteredResult = PageResult(items: filteredItems, nextCursor: result.nextCursor)
        }

        // 这里可以添加埋点逻辑
        // Analytics.track("page_load_success", properties: ["item_count": filteredResult.items.count])

        super.handleSuccess(result: filteredResult, cursor: cursor, isLoadMore: isLoadMore)
    }

    /// 重写失败处理，添加错误上报和重试策略
    override func handleFailure(error: Error, isLoadMore: Bool) {
        if enableLogging {
            print("❌ [CustomPageableViewModel] Load failed - Error: \(error.localizedDescription), IsLoadMore: \(isLoadMore)")
        }

        // 这里可以添加错误上报逻辑
        // ErrorReporter.report(error, context: ["is_load_more": isLoadMore])

        // 这里可以添加自定义重试策略
        // if shouldAutoRetry(error) {
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        //         self.retry()
        //     }
        // }

        super.handleFailure(error: error, isLoadMore: isLoadMore)
    }

    /// 重写加载更多条件，添加自定义逻辑
    override var canLoadMore: Bool {
        // 可以添加额外的条件判断，比如网络状态检查
        // guard NetworkMonitor.shared.isConnected else { return false }

        return super.canLoadMore
    }
}

// MARK: - Usage Example

/*
 使用示例：

 ```swift
 // 1. 基础使用（带日志）
 let viewModel = CustomPageableViewModel<NewsItem, Int>(
     initialCursor: 0,
     enableLogging: true
 ) { page in
     api.fetchNews(page: page)
         .map { response in
             PageResult(items: response.list, nextCursor: response.hasMore ? page + 1 : nil)
         }
         .eraseToAnyPublisher()
 }

 // 2. 带数据过滤
 let viewModel = CustomPageableViewModel<NewsItem, Int>(
     initialCursor: 0,
     enableLogging: true,
     itemFilter: { item in
         // 只保留未读的新闻
         !item.isRead
     }
 ) { page in
     api.fetchNews(page: page)
         .map { response in
             PageResult(items: response.list, nextCursor: response.hasMore ? page + 1 : nil)
         }
         .eraseToAnyPublisher()
 }
 ```
 */
