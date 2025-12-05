import UIKit
import MJRefresh

// MARK: - Menu Content Providing

/// 菜单内容提供协议
///
/// 负责菜单 cell 的注册、渲染、尺寸计算
public protocol PagerMenuContentProviding: AnyObject {
    /// 注册菜单 cell
    func registerMenuCells(in collectionView: UICollectionView)
    
    /// 返回指定 page 的菜单 cell
    func pagerMenuCollectionView(_ collectionView: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell
    
    /// 返回指定 page 的菜单 cell 尺寸
    func pagerMenuCollectionView(_ collectionView: UICollectionView, sizeFor page: PageModel, at indexPath: IndexPath) -> CGSize
    
    /// 返回菜单的内容边距
    func menuContentInsets(for collectionView: UICollectionView) -> UIEdgeInsets
    
    /// 返回菜单项之间的间距
    func menuMinimumInteritemSpacing(for collectionView: UICollectionView) -> CGFloat
}

/// 默认实现
public extension PagerMenuContentProviding {
    func pagerMenuCollectionView(_ collectionView: UICollectionView, sizeFor page: PageModel, at indexPath: IndexPath) -> CGSize {
        CGSize(width: 80, height: collectionView.bounds.height)
    }

    func menuContentInsets(for collectionView: UICollectionView) -> UIEdgeInsets { .zero }

    func menuMinimumInteritemSpacing(for collectionView: UICollectionView) -> CGFloat { 12 }
}

// MARK: - Page Presentation Providing

/// 页面状态提供协议
///
/// 决定页面展示状态页（loading/empty/error）还是数据页
/// - 返回 cell：展示状态页
/// - 返回 nil：展示数据页（由 `PagerPageDataRendering` 处理）
public protocol PagerPagePresentationProviding: AnyObject {
    /// 注册状态页 cell
    func registerPageStateCells(in collectionView: UICollectionView)
    
    /// 返回状态页 cell，返回 nil 表示展示数据页
    func pagerView(_ pagerView: MultiCategoryPagerView, pageContainer: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell?
}

// MARK: - Page Data Rendering

/// 数据页渲染协议
///
/// 负责数据列表的 layout、items 提供、cell 渲染
public protocol PagerPageDataRendering: AnyObject {
    /// 注册数据 cell
    func registerDataCells(in collectionView: UICollectionView)
    
    /// 返回指定 page 的列表布局
    func pagerView(_ pagerView: MultiCategoryPagerView, layoutFor page: PageModel) -> UICollectionViewLayout
    
    /// 返回指定 page 的数据项（外部提供，组件不持有数据）
    func pagerView(_ pagerView: MultiCategoryPagerView, itemsFor page: PageModel) -> [PageItemModel]
    
    /// 返回指定 item 的 cell
    func pagerView(_ pagerView: MultiCategoryPagerView, collectionView: UICollectionView, cellFor item: PageItemModel, at indexPath: IndexPath, page: PageModel) -> UICollectionViewCell
    
    /// item 被点击时的回调
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect item: PageItemModel, at indexPath: IndexPath, page: PageModel)
}

/// 默认实现
public extension PagerPageDataRendering {
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect item: PageItemModel, at indexPath: IndexPath, page: PageModel) { }
}

// MARK: - Menu Selection Handling

/// 菜单选中回调协议
public protocol PagerMenuSelectionHandling: AnyObject {
    /// page 被选中时的回调
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect page: PageModel, at index: Int)
}

// MARK: - Page Exposure Handling

/// Page 曝光回调协议
public protocol PagerPageExposureHandling: AnyObject {
    /// Page 曝光回调（切换到某个 page 并停止滚动时触发）
    ///
    /// - Note: 同一 page 不会重复触发
    func pagerView(_ pagerView: MultiCategoryPagerView, didExposePage page: PageModel, at index: Int)
}

// MARK: - Item Exposure Handling

/// Item 曝光回调协议
public protocol PagerItemExposureHandling: AnyObject {
    /// Item 曝光回调（item 出现在可视区域时触发）
    func pagerView(_ pagerView: MultiCategoryPagerView, didExposeItem item: PageItemModel, at indexPath: IndexPath, page: PageModel)
}

// MARK: - Load More Providing

/// 加载更多能力提供协议
///
/// - Note: 组件不感知 footer 的具体实现，由外部创建并配置
/// - Note: 每次 cell 配置时会调用此方法，外部应根据当前数据状态返回正确状态的 footer
public protocol PagerLoadMoreProviding: AnyObject {
    /// 获取指定 page 的加载更多 footer
    ///
    /// - Note: 仅在数据页面（非状态页面）时会被调用
    /// - Note: 外部应根据数据状态配置 footer（idle/refreshing/noMoreData）
    /// - Returns: 返回配置好的 footer 实例，返回 nil 表示不需要加载更多
    func pagerView(_ pagerView: MultiCategoryPagerView,
                   loadMoreFooterFor page: PageModel) -> MJRefreshFooter?
}
