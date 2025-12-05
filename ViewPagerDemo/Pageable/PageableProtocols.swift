import Combine
import Foundation

// MARK: - Pageable Data Fetching (Task 版本)

/// 分页数据获取协议（Task 版本）
///
/// 定义分页数据的获取接口，外部实现具体的网络请求逻辑。
/// 使用 Swift Concurrency (async/await) 进行异步操作。
///
/// 使用示例（Int 游标）：
/// ```swift
/// class NewsPageFetcher: PageableDataFetching {
///     typealias Cursor = Int
///
///     func fetchPage(_ cursor: Int) async throws -> PageResult<NewsItem, Int> {
///         let response = try await api.fetchNews(page: cursor)
///         let nextCursor = response.hasMore ? cursor + 1 : nil
///         return PageResult(items: response.list, nextCursor: nextCursor)
///     }
/// }
/// ```
///
/// 使用示例（String 游标）：
/// ```swift
/// class TimelinePageFetcher: PageableDataFetching {
///     typealias Cursor = String
///
///     func fetchPage(_ cursor: String) async throws -> PageResult<Post, String> {
///         let response = try await api.fetchTimeline(cursor: cursor)
///         return PageResult(items: response.posts, nextCursor: response.nextCursor)
///     }
/// }
/// ```
public protocol PageableDataFetching {
    associatedtype Item
    associatedtype Cursor

    /// 获取指定游标的数据
    ///
    /// - Parameter cursor: 游标（首次加载使用初始游标）
    /// - Returns: 分页结果
    /// - Throws: 请求失败时抛出错误
    func fetchPage(_ cursor: Cursor) async throws -> PageResult<Item, Cursor>
}

// MARK: - Pageable Data Fetching (Promise 版本)

/// 分页数据获取协议（Promise 版本）
///
/// 定义分页数据的获取接口，外部实现具体的网络请求逻辑。
/// 使用 Combine 的 AnyPublisher 进行异步操作。
///
/// 使用示例（Int 游标）：
/// ```swift
/// class NewsPageFetcher: PageableDataFetchingPromise {
///     typealias Cursor = Int
///
///     func fetchPage(_ cursor: Int) -> AnyPublisher<PageResult<NewsItem, Int>, Error> {
///         return api.fetchNews(page: cursor)
///             .map { response in
///                 let nextCursor = response.hasMore ? cursor + 1 : nil
///                 return PageResult(items: response.list, nextCursor: nextCursor)
///             }
///             .eraseToAnyPublisher()
///     }
/// }
/// ```
///
/// 使用示例（String 游标）：
/// ```swift
/// class TimelinePageFetcher: PageableDataFetchingPromise {
///     typealias Cursor = String
///
///     func fetchPage(_ cursor: String) -> AnyPublisher<PageResult<Post, String>, Error> {
///         return api.fetchTimeline(cursor: cursor)
///             .map { response in
///                 PageResult(items: response.posts, nextCursor: response.nextCursor)
///             }
///             .eraseToAnyPublisher()
///     }
/// }
/// ```
public protocol PageableDataFetchingPromise {
    associatedtype Item
    associatedtype Cursor

    /// 获取指定游标的数据
    ///
    /// - Parameter cursor: 游标（首次加载使用初始游标）
    /// - Returns: 包含分页结果的 Publisher
    func fetchPage(_ cursor: Cursor) -> AnyPublisher<PageResult<Item, Cursor>, Error>
}
