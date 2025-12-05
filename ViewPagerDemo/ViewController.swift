import Combine
import UIKit
import SnapKit

final class ViewController: UIViewController {

    // MARK: - Properties

    private let dataStore = DemoDataStore()
    private lazy var menuProvider = DemoMenuProvider()
    private lazy var stateProvider = DemoPageStateProvider(dataStore: dataStore)
    private lazy var dataAdapter = DemoPageDataAdapter(dataStore: dataStore)
    private lazy var loadMoreProvider = DemoLoadMoreProvider(dataStore: dataStore)

    private lazy var pagerView = MultiCategoryPagerView(
        menuProvider: menuProvider,
        pagePresentationProvider: stateProvider,
        pageDataRenderer: dataAdapter
    )

    /// Combine 订阅存储
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupPager()
        loadInitialData()
    }

    // MARK: - Setup

    private func setupPager() {
        view.addSubview(pagerView)
        pagerView.selectionHandler = self
        pagerView.loadMoreProvider = loadMoreProvider
        pagerView.pageExposureHandler = self
        pagerView.itemExposureHandler = self
        dataAdapter.onItemTapped = { [weak self] payload, page, indexPath in
            guard let self else { return }
            let title: String
            if let item = payload as? DemoListItem {
                title = item.title
            } else if let item = payload as? DemoGridItem {
                title = item.title
            } else {
                title = "Unknown"
            }
            print("✅ [Item 点击] \(title) at row \(indexPath.item) in page \(page.pageId)")
        }
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func loadInitialData() {
        let snapshots = dataStore.makeInitialSnapshots()
        pagerView.apply(sections: snapshots, animated: false)

        // 为每个 page 的 ViewModel 绑定状态订阅
        bindViewModels()

        // 触发首次加载
        triggerInitialLoads()
    }

    // MARK: - ViewModel Binding

    private func bindViewModels() {
        for pageId in dataStore.allPageIds {
            guard let viewModel = dataStore.viewModel(for: pageId) else { continue }

            // 订阅视图状态变化 → 刷新 Pager
            viewModel.viewStatePublisher
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.handleStateChange(pageId: pageId, state: state)
                }
                .store(in: &cancellables)

            // 订阅数据变化 → 刷新数据列表
            viewModel.itemsPublisher
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.handleItemsUpdated(pageId: pageId)
                }
                .store(in: &cancellables)

            // 订阅加载更多状态 → 更新 footer
            viewModel.loadMoreStatePublisher
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.handleLoadMoreStateChanged(pageId: pageId)
                }
                .store(in: &cancellables)
        }
    }

    private func triggerInitialLoads() {
        for pageId in dataStore.allPageIds {
            dataStore.viewModel(for: pageId)?.loadInitial()
        }
    }

    // MARK: - State Handlers

    private func handleStateChange(pageId: String, state: ViewState) {
        print("📍 [\(pageId)] State changed: \(state)")
        // 触发 Pager 刷新该 page 的展示
        pagerView.update(pageId: pageId, animated: false) { _ in }
    }

    private func handleItemsUpdated(pageId: String) {
        // 使用 reloadPageData 保持滚动位置
        pagerView.reloadPageData(pageId: pageId)
    }

    private func handleLoadMoreStateChanged(pageId: String) {
        loadMoreProvider.endRefreshing(for: pageId)
    }
}

// MARK: - PagerMenuSelectionHandling

extension ViewController: PagerMenuSelectionHandling {
    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        didSelect page: PageModel,
        at index: Int
    ) {
        print("📌 Selected page \(page.pageId) at index \(index)")
    }
}

// MARK: - PagerPageExposureHandling

extension ViewController: PagerPageExposureHandling {
    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        didExposePage page: PageModel,
        at index: Int
    ) {
        let category = dataStore.category(for: page.pageId)
        print("📊 [Page 曝光] \(category?.title ?? "Unknown") (index: \(index))")
    }
}

// MARK: - PagerItemExposureHandling

extension ViewController: PagerItemExposureHandling {
    func pagerView(
        _ pagerView: MultiCategoryPagerView,
        didExposeItem item: PageItemModel,
        at indexPath: IndexPath,
        page: PageModel
    ) {
        let title: String
        if let feed = item.payload as? DemoListItem {
            title = feed.title
        } else if let feed = item.payload as? DemoGridItem {
            title = feed.title
        } else {
            title = "Unknown"
        }
        print("👁 [Item 曝光] \(title) (row: \(indexPath.item)) in page \(page.pageId)")
    }
}
