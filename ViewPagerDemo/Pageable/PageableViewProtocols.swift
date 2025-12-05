import UIKit
import Combine

// MARK: - Cell Configuration

/// Cell 配置协议
///
/// 外部实现此协议来提供自定义的数据 Cell
public protocol PageableCellConfiguring {
    associatedtype Item

    /// 注册数据 Cell
    ///
    /// - Parameter collectionView: 目标 CollectionView
    func registerCells(in collectionView: UICollectionView)

    /// 配置数据 Cell
    ///
    /// - Parameters:
    ///   - collectionView: 目标 CollectionView
    ///   - item: 数据项
    ///   - indexPath: 索引位置
    /// - Returns: 配置好的 Cell
    func collectionView(_ collectionView: UICollectionView, cellFor item: Item, at indexPath: IndexPath) -> UICollectionViewCell

    /// 返回 Cell 对应的 CollectionView 布局
    ///
    /// - Parameter collectionView: 目标 CollectionView
    /// - Returns: 布局对象
    func layout(for collectionView: UICollectionView) -> UICollectionViewLayout
}

// MARK: - State View Providing

/// 状态视图提供协议
///
/// 外部实现此协议来提供不同状态下的视图（loading、empty、error）
public protocol PageableStateViewProviding {

    /// 提供 Loading 状态视图
    ///
    /// - Returns: Loading 视图，如果返回 nil 则使用默认视图
    func loadingView() -> UIView?

    /// 提供 Empty 状态视图
    ///
    /// - Returns: Empty 视图，如果返回 nil 则使用默认视图
    func emptyView() -> UIView?

    /// 提供 Error 状态视图
    ///
    /// - Parameters:
    ///   - error: 错误信息
    ///   - retryAction: 重试操作闭包
    /// - Returns: Error 视图，如果返回 nil 则使用默认视图
    func errorView(error: ViewStateError, retryAction: @escaping () -> Void) -> UIView?
}

// MARK: - State View Providing Default Implementation

extension PageableStateViewProviding {
    public func loadingView() -> UIView? { nil }
    public func emptyView() -> UIView? { nil }
    public func errorView(error: ViewStateError, retryAction: @escaping () -> Void) -> UIView? { nil }
}

// MARK: - Item Selection Handling

/// Item 选中处理协议
public protocol PageableItemSelectionHandling {
    associatedtype Item

    /// Item 被选中
    ///
    /// - Parameters:
    ///   - item: 被选中的数据项
    ///   - indexPath: 索引位置
    func didSelectItem(_ item: Item, at indexPath: IndexPath)
}

// MARK: - Load More Handling

/// 加载更多处理协议
public protocol PageableLoadMoreHandling {

    /// 是否显示加载更多 Footer
    ///
    /// - Parameter loadMoreState: 当前加载更多状态
    /// - Returns: 是否显示 Footer
    func shouldShowLoadMoreFooter(for loadMoreState: LoadMoreState) -> Bool

    /// 配置加载更多 Footer 视图
    ///
    /// - Parameter loadMoreState: 当前加载更多状态
    /// - Returns: Footer 视图，如果返回 nil 则隐藏 Footer
    func loadMoreFooterView(for loadMoreState: LoadMoreState) -> UIView?
}

// MARK: - Load More Handling Default Implementation

extension PageableLoadMoreHandling {
    public func shouldShowLoadMoreFooter(for loadMoreState: LoadMoreState) -> Bool {
        loadMoreState != .idle
    }

    public func loadMoreFooterView(for loadMoreState: LoadMoreState) -> UIView? {
        nil
    }
}
