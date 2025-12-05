import Foundation

// MARK: - View State

/// 页面视图状态
///
/// 用于描述页面的加载状态，支持四种核心状态：
/// - `idle`: 初始状态，尚未开始加载
/// - `loading`: 首次加载中
/// - `empty`: 加载成功但数据为空
/// - `failed`: 加载失败
/// - `loaded`: 加载成功且有数据
public enum ViewState: Equatable {
    /// 初始状态
    case idle
    /// 首次加载中
    case loading
    /// 数据为空
    case empty
    /// 加载失败
    case failed(ViewStateError)
    /// 加载成功（有数据）
    case loaded

    public static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.empty, .empty),
             (.loaded, .loaded):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.message == rhsError.message
        default:
            return false
        }
    }
}

// MARK: - View State Error

/// 视图状态错误
///
/// 封装错误信息，用于 UI 展示
public struct ViewStateError: Error {
    /// 错误信息（用于 UI 展示）
    public let message: String
    /// 原始错误（可选）
    public let underlyingError: Error?

    public init(message: String, underlyingError: Error? = nil) {
        self.message = message
        self.underlyingError = underlyingError
    }

    /// 从任意 Error 创建
    public init(_ error: Error) {
        self.message = error.localizedDescription
        self.underlyingError = error
    }
}

// MARK: - Page Result

/// 分页请求结果
///
/// 泛型结构体，用于封装分页接口的返回数据
/// - `Item`: 数据项类型
/// - `Cursor`: 游标类型（可以是 Int、String 或其他类型）
public struct PageResult<Item, Cursor> {
    /// 当前页的数据列表
    public let items: [Item]
    /// 下一页的游标（nil 表示没有更多数据）
    public let nextCursor: Cursor?

    /// 是否还有更多数据
    public var hasMore: Bool {
        nextCursor != nil
    }

    public init(items: [Item], nextCursor: Cursor?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

// MARK: - PageResult Convenience (Int Cursor)

extension PageResult where Cursor == Int {
    /// 便捷初始化（用于 Int 类型游标，兼容旧 API）
    ///
    /// - Parameters:
    ///   - items: 数据列表
    ///   - hasMore: 是否还有更多数据
    ///   - currentPage: 当前页码
    public init(items: [Item], hasMore: Bool, currentPage: Int) {
        self.items = items
        self.nextCursor = hasMore ? currentPage + 1 : nil
    }
}

// MARK: - Load More State

/// 加载更多状态
///
/// 独立于主视图状态，专门描述加载更多的状态
public enum LoadMoreState: Equatable {
    /// 空闲（可以加载更多）
    case idle
    /// 加载中
    case loading
    /// 没有更多数据
    case noMoreData
    /// 加载失败（可重试）
    case failed
}
