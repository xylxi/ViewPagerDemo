import Foundation

/// 新闻数据服务（模拟网络请求）
final class NewsService {

    /// 请求模式
    enum Mode {
        /// 正常模式
        case normal
        /// 错误模式（前 N 次请求失败）
        case error(failCount: Int)
        /// 空数据模式
        case empty
    }

    private let mode: Mode
    private var requestCount = 0

    init(mode: Mode = .normal) {
        self.mode = mode
    }

    /// 获取新闻列表
    ///
    /// - Parameter page: 页码
    /// - Returns: 分页结果
    func fetchNews(page: Int) async throws -> PageResult<NewsItem, Int> {
        requestCount += 1

        switch mode {
        case .normal:
            return try await fetchNormalNews(page: page)

        case .error(let failCount):
            if requestCount <= failCount {
                try await Task.sleep(nanoseconds: 500_000_000)
                throw NewsError.networkError
            }
            return try await fetchNormalNews(page: page)

        case .empty:
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return PageResult(items: [], hasMore: false, currentPage: page)
        }
    }

    // MARK: - Private

    private func fetchNormalNews(page: Int) async throws -> PageResult<NewsItem, Int> {
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
}

// MARK: - News Error

enum NewsError: LocalizedError {
    case networkError

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "网络连接失败，请检查网络设置"
        }
    }
}
