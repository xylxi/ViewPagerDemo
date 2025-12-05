#if canImport(UIKit)
import UIKit
import MJRefresh

public protocol PagerMenuContentProviding: AnyObject {
    func registerMenuCells(in collectionView: UICollectionView)
    func pagerMenuCollectionView(_ collectionView: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell
    func pagerMenuCollectionView(_ collectionView: UICollectionView, sizeFor page: PageModel, at indexPath: IndexPath) -> CGSize
    func menuContentInsets(for collectionView: UICollectionView) -> UIEdgeInsets
    func menuMinimumInteritemSpacing(for collectionView: UICollectionView) -> CGFloat
}

public extension PagerMenuContentProviding {
    func pagerMenuCollectionView(_ collectionView: UICollectionView, sizeFor page: PageModel, at indexPath: IndexPath) -> CGSize {
        CGSize(width: 80, height: collectionView.bounds.height)
    }

    func menuContentInsets(for collectionView: UICollectionView) -> UIEdgeInsets { .zero }

    func menuMinimumInteritemSpacing(for collectionView: UICollectionView) -> CGFloat { 12 }
}

public protocol PagerPagePresentationProviding: AnyObject {
    func registerPageStateCells(in collectionView: UICollectionView)
    func pagerView(_ pagerView: MultiCategoryPagerView, pageContainer: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell?
}

public protocol PagerPageDataRendering: AnyObject {
    func registerDataCells(in collectionView: UICollectionView)
    func pagerView(_ pagerView: MultiCategoryPagerView, layoutFor page: PageModel) -> UICollectionViewLayout
    /// 外部提供当前 page 的数据项，组件不持有 items
    func pagerView(_ pagerView: MultiCategoryPagerView, itemsFor page: PageModel) -> [PageItemModel]
    func pagerView(_ pagerView: MultiCategoryPagerView, collectionView: UICollectionView, cellFor item: PageItemModel, at indexPath: IndexPath, page: PageModel) -> UICollectionViewCell
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect item: PageItemModel, at indexPath: IndexPath, page: PageModel)
}

public extension PagerPageDataRendering {
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect item: PageItemModel, at indexPath: IndexPath, page: PageModel) { }
}

public protocol PagerMenuSelectionHandling: AnyObject {
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect page: PageModel, at index: Int)
}

/// 加载更多能力提供者
/// - Note: 组件不感知 footer 的具体实现，由外部创建并配置
/// - Note: 每次 cell 配置时会调用此方法，外部应根据当前数据状态返回正确状态的 footer
public protocol PagerLoadMoreProviding: AnyObject {
    /// 获取指定 page 的加载更多 footer
    /// - Note: 仅在数据页面（非状态页面）时会被调用
    /// - Note: 外部应根据数据状态配置 footer（idle/refreshing/noMoreData）
    /// - Returns: 返回配置好的 footer 实例，返回 nil 表示不需要加载更多
    func pagerView(_ pagerView: MultiCategoryPagerView,
                   loadMoreFooterFor page: PageModel) -> MJRefreshFooter?
}
#endif

