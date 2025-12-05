import UIKit
import SnapKit

final class ViewController: UIViewController {

    private lazy var menuProvider = DemoMenuProvider()
    private lazy var stateProvider = DemoPageStateProvider(dataStore: dataStore)
    private lazy var dataAdapter = DemoPageDataAdapter(dataStore: dataStore)
    private lazy var loadMoreProvider = DemoLoadMoreProvider(dataStore: dataStore) { [weak self] page in
        self?.loadMore(for: page)
    }
    private lazy var pagerView = MultiCategoryPagerView(menuProvider: menuProvider,
                                                        pagePresentationProvider: stateProvider,
                                                        pageDataRenderer: dataAdapter)

    /// 外部数据存储，组件不感知 state/items
    private let dataStore = DemoDataStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupPager()
        loadInitialData()
    }

    private func setupPager() {
        view.addSubview(pagerView)
        pagerView.selectionHandler = self
        pagerView.loadMoreProvider = loadMoreProvider
        pagerView.pageExposureHandler = self
        pagerView.itemExposureHandler = self
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func loadInitialData() {
        let snapshots = dataStore.makeInitialSnapshots()
        pagerView.apply(sections: snapshots, animated: false)
        simulateNetworkLoading()
    }

    private func simulateNetworkLoading() {
        for (index, pageId) in dataStore.allPageIds.enumerated() {
            let delay = DispatchTime.now() + .seconds(2)
            DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
                guard let self else { return }
                switch index {
                case 1:
                    self.dataStore.update(pageId: pageId, state: .empty, items: [])
                case 2:
                    self.dataStore.update(pageId: pageId, state: .failed(message: "网络异常，请稍后重试"), items: [])
                default:
                    let items = self.dataStore.makeItems(for: pageId)
                    self.dataStore.update(pageId: pageId, state: .loaded, items: items)
                }
                // 通知 pagerView 刷新（触发 cell 重新配置）
                self.pagerView.update(pageId: pageId) { _ in }
            }
        }
    }
    
    private func loadMore(for page: PageModel) {
        let pageId = page.pageId
        
        // MJRefresh 触发回调时已自动进入 refreshing 状态，直接进行网络请求
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            
            // 获取更多数据
            let newItems = self.dataStore.makeMoreItems(for: pageId)
            
            // 模拟：加载 3 次后没有更多数据
            let currentPage = self.dataStore.pageData(for: pageId)?.currentPage ?? 0
            let hasMore = currentPage < 2
            
            // 更新数据
            self.dataStore.appendItems(pageId: pageId, newItems: newItems, hasMore: hasMore)
            
            // 刷新数据列表（保持滚动位置，避免回弹）
            self.pagerView.reloadPageData(pageId: pageId)
            
            // 结束加载，更新 footer 状态
            self.loadMoreProvider.endRefreshing(for: pageId, hasMore: hasMore)
            
            print("Loaded more items for \(pageId), hasMore: \(hasMore)")
        }
    }
}

// MARK: - PagerMenuSelectionHandling

extension ViewController: PagerMenuSelectionHandling {
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect page: PageModel, at index: Int) {
        print("📌 Selected page \(page.pageId) at index \(index)")
    }
}

// MARK: - PagerPageExposureHandling

extension ViewController: PagerPageExposureHandling {
    func pagerView(_ pagerView: MultiCategoryPagerView, didExposePage page: PageModel, at index: Int) {
        let category = dataStore.category(for: page.pageId)
        print("📊 [Page 曝光] \(category?.title ?? "Unknown") (index: \(index))")
    }
}

// MARK: - PagerItemExposureHandling

extension ViewController: PagerItemExposureHandling {
    func pagerView(_ pagerView: MultiCategoryPagerView, didExposeItem item: PageItemModel, at indexPath: IndexPath, page: PageModel) {
        let feedItem = item.payload as? DemoFeedItem
        print("👁 [Item 曝光] \(feedItem?.title ?? "Unknown") (row: \(indexPath.item)) in page \(page.pageId)")
    }
}
