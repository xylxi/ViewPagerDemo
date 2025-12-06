import UIKit
import Combine

// MARK: - Cell Configuration

/// Cell 配置协议
///
/// 外部实现此协议来提供自定义的数据 Cell
public protocol PageableCellConfiguring<Item> {
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

// MARK: - State View Protocol

/// 状态视图协议
///
/// 状态视图内部闭环处理所有状态变化，外部只需要：
/// 1. 添加/移除视图
/// 2. 更新状态
///
/// 使用示例：
/// ```swift
/// class CustomStateView: UIView, PageableStateView {
///     func updateState(_ state: ViewState, retryAction: (() -> Void)?) {
///         switch state {
///         case .loading: showLoading()
///         case .empty: showEmpty()
///         case .failed(let error): showError(error)
///         default: break
///         }
///     }
/// }
/// ```
public protocol PageableStateView: UIView {
    /// 更新状态
    ///
    /// - Parameters:
    ///   - state: 当前视图状态
    ///   - retryAction: 重试操作闭包（用于错误状态下的重试按钮）
    func updateState(_ state: ViewState, retryAction: (() -> Void)?)
}

// MARK: - State View Providing

/// 状态视图提供协议
///
/// 外部实现此协议来提供自定义的状态视图
public protocol PageableStateViewProviding {
    /// 创建状态视图
    ///
    /// - Returns: 状态视图实例
    func makeStateView() -> PageableStateView
}

// MARK: - Item Selection Handling

/// Item 选中处理协议
public protocol PageableItemSelectionHandling<Item> {
    associatedtype Item

    /// Item 被选中
    ///
    /// - Parameters:
    ///   - item: 被选中的数据项
    ///   - indexPath: 索引位置
    func didSelectItem(_ item: Item, at indexPath: IndexPath)
}

// MARK: - Event Tracking

/// 分页事件类型
public enum PageableEvent<Item> {
    /// 加载事件
    case load(LoadEvent)
    /// Item 曝光
    case itemExposure(item: Item, index: Int)
    /// Item 点击
    case itemClick(item: Item, index: Int)

    /// 加载事件详情
    public enum LoadEvent {
        /// 首次加载开始
        case initialStart
        /// 首次加载成功
        case initialSuccess(itemCount: Int)
        /// 首次加载失败
        case initialFailure(error: Error)

        /// 刷新开始
        case refreshStart
        /// 刷新成功
        case refreshSuccess(itemCount: Int)
        /// 刷新失败
        case refreshFailure(error: Error)

        /// 加载更多开始
        case loadMoreStart(page: Int)
        /// 加载更多成功
        case loadMoreSuccess(page: Int, itemCount: Int, hasMore: Bool)
        /// 加载更多失败
        case loadMoreFailure(page: Int, error: Error)
    }
}

/// 事件追踪协议
///
/// 外部实现此协议来接收分页容器的各类事件，用于埋点上报
///
/// 使用示例：
/// ```swift
/// class AnalyticsTracker: PageableEventTracking {
///     typealias Item = NewsItem
///
///     func onEvent(_ event: PageableEvent<NewsItem>) {
///         switch event {
///         case .load(let loadEvent):
///             trackLoadEvent(loadEvent)
///         case .itemExposure(let item, let index):
///             trackExposure(item: item, index: index)
///         case .itemClick(let item, let index):
///             trackClick(item: item, index: index)
///         }
///     }
/// }
/// ```
public protocol PageableEventTracking<Item> {
    associatedtype Item

    /// 事件回调
    ///
    /// - Parameter event: 分页事件
    func onEvent(_ event: PageableEvent<Item>)
}

