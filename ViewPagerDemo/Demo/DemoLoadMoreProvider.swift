import UIKit
import MJRefresh

// MARK: - Demo Load More Provider

final class DemoLoadMoreProvider: PagerLoadMoreProviding {
    
    private weak var dataStore: DemoDataStore?
    private var loadMoreHandler: ((PageModel) -> Void)?
    
    /// Footer 缓存：pageId -> footer，避免重复创建
    private var footerCache: [AnyHashable: MJRefreshAutoNormalFooter] = [:]
    
    init(dataStore: DemoDataStore, loadMoreHandler: @escaping (PageModel) -> Void) {
        self.dataStore = dataStore
        self.loadMoreHandler = loadMoreHandler
    }
    
    func pagerView(_ pagerView: MultiCategoryPagerView,
                   loadMoreFooterFor page: PageModel) -> MJRefreshFooter? {
        guard let pageData = dataStore?.pageData(for: page.pageId) else {
            return nil
        }
        
        // 只有 loaded 状态且有数据时才返回 footer
        guard case .loaded = pageData.state, !pageData.items.isEmpty else {
            return nil
        }
        
        // 获取或创建 footer
        let footer = footerCache[page.pageId] ?? createFooter(for: page)
        
        // 根据 hasMore 状态配置 footer（仅在 cell 首次配置时生效）
        if !pageData.hasMore {
            footer.endRefreshingWithNoMoreData()
        }
        
        return footer
    }
    
    /// 结束加载更多，更新 footer 状态
    func endRefreshing(for pageId: AnyHashable, hasMore: Bool) {
        guard let footer = footerCache[pageId] else { return }
        if hasMore {
            footer.endRefreshing()
        } else {
            footer.endRefreshingWithNoMoreData()
        }
    }
    
    private func createFooter(for page: PageModel) -> MJRefreshAutoNormalFooter {
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.loadMoreHandler?(page)
        }
        footer.setTitle("上拉加载更多", for: .idle)
        footer.setTitle("正在加载...", for: .refreshing)
        footer.setTitle("— 已经到底了 —", for: .noMoreData)
        footer.stateLabel?.font = UIFont.systemFont(ofSize: 14)
        footer.stateLabel?.textColor = .secondaryLabel
        
        footerCache[page.pageId] = footer
        return footer
    }
}
