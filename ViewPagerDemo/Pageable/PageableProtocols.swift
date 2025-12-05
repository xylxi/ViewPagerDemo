import Foundation

// MARK: - Pageable Data Fetching

/// 分页数据获取协议
///
/// 定义分页数据的获取接口，外部实现具体的网络请求逻辑
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
