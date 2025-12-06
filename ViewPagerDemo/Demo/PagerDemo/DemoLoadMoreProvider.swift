import UIKit
import MJRefresh

// MARK: - Demo Load More Provider

/// 加载更多提供者
///
/// 从 `AnyDemoPageViewModel` 读取状态，创建和管理 MJRefresh footer
final class DemoLoadMoreProvider: PagerLoadMoreProviding {

    private weak var dataStore: DemoDataStore?

    /// Footer 缓存：pageId -> footer，避免重复创建
    private var footerCache: [AnyHashable: MJRefreshAutoNormalFooter] = [:]

    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }

    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        loadMoreFooterFor page: PageModel
    ) -> MJRefreshFooter? {
        guard let viewModel = dataStore?.viewModel(for: page.pageId) else {
            return nil
        }

        // 只有 loaded 状态且有数据时才返回 footer
        guard viewModel.viewState == .loaded, !viewModel.items.isEmpty else {
            return nil
        }

        // 获取或创建 footer
        let footer = footerCache[page.pageId] ?? createFooter(for: page)

        // 根据 loadMoreState 配置 footer 状态
        switch viewModel.loadMoreState {
        case .idle:
            footer.resetNoMoreData()
        case .loading:
            break
        case .noMoreData:
            footer.endRefreshingWithNoMoreData()
        case .failed:
            footer.endRefreshing()
        }

        return footer
    }

    /// 结束加载更多
    func endRefreshing(for pageId: AnyHashable) {
        guard let viewModel = dataStore?.viewModel(for: pageId),
              let footer = footerCache[pageId] else {
            return
        }

        switch viewModel.loadMoreState {
        case .idle:
            footer.endRefreshing()
        case .noMoreData:
            footer.endRefreshingWithNoMoreData()
        case .failed:
            footer.endRefreshing()
        case .loading:
            break
        }
    }

    private func createFooter(for page: PageModel) -> MJRefreshAutoNormalFooter {
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.triggerLoadMore(for: page)
        }
        footer.setTitle("上拉加载更多", for: .idle)
        footer.setTitle("正在加载...", for: .refreshing)
        footer.setTitle("— 已经到底了 —", for: .noMoreData)
        footer.stateLabel?.font = UIFont.systemFont(ofSize: 14)
        footer.stateLabel?.textColor = .secondaryLabel

        footerCache[page.pageId] = footer
        return footer
    }

    private func triggerLoadMore(for page: PageModel) {
        guard let viewModel = dataStore?.viewModel(for: page.pageId) else { return }
        viewModel.loadMore()
    }
}
