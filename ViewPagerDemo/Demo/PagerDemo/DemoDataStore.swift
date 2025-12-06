import Combine
import Foundation
import UIKit

/// 外部数据存储：管理分类和 ViewModel，组件只负责驱动渲染
///
/// 不同布局类型对应不同的 ViewModel 和 Item 模型：
/// - list  布局 → PageableViewModel<DemoListItem, Int>
/// - grid3 布局 → PageableViewModel<DemoGridItem, Int>
/// - grid4 布局 → PageableViewModel<DemoGridItem, Int>
@MainActor
final class DemoDataStore {

    // MARK: - Type Aliases

    typealias ListViewModel = PageableViewModel<DemoListItem, Int>
    
    typealias GridViewModel = PageableViewModel<DemoGridItem, Int>

    // MARK: - Properties

    private(set) var categories: [DemoCategoryMeta] = []

    /// pageId -> 任意类型的 ViewModel 包装
    private var viewModels: [String: AnyDemoPageViewModel] = [:]

    var allPageIds: [String] {
        categories.map { $0.id }
    }

    // MARK: - Initialization

    func makeInitialSnapshots() -> [PagerSectionSnapshot] {
        // 配置不同布局类型的分类
        categories = [
            // 列表布局（一行一列）
            DemoCategoryMeta(id: "news", title: "热点", accentColor: .systemOrange, layoutType: .list),
            DemoCategoryMeta(id: "sport", title: "体育", accentColor: .systemGreen, layoutType: .list),

            // 三列网格布局
            DemoCategoryMeta(id: "tech", title: "科技", accentColor: .systemBlue, layoutType: .grid3),
            DemoCategoryMeta(id: "finance", title: "财经", accentColor: .systemPurple, layoutType: .grid3),
            DemoCategoryMeta(id: "travel", title: "旅行", accentColor: .systemTeal, layoutType: .grid3),

            // 四列网格布局
            DemoCategoryMeta(id: "food", title: "美食", accentColor: .systemRed, layoutType: .grid4),
            DemoCategoryMeta(id: "movie", title: "影视", accentColor: .systemIndigo, layoutType: .grid4),
            DemoCategoryMeta(id: "game", title: "游戏", accentColor: .systemPink, layoutType: .grid4),

            // 混合：回到列表布局
            DemoCategoryMeta(id: "auto", title: "汽车", accentColor: .systemYellow, layoutType: .list),
            DemoCategoryMeta(id: "fashion", title: "时尚", accentColor: .systemBrown, layoutType: .grid3)
        ]

        // 为每个分类创建对应的 ViewModel
        for category in categories {
            viewModels[category.id] = createViewModel(for: category)
        }

        let pages = categories.map { category in
            PageModel(pageId: category.id, userInfo: category)
        }
        return [PagerSectionSnapshot(section: PagerSection(id: "root"), pages: pages)]
    }

    // MARK: - ViewModel Access

    func viewModel(for pageId: String) -> AnyDemoPageViewModel? {
        viewModels[pageId]
    }

    func viewModel(for pageId: AnyHashable) -> AnyDemoPageViewModel? {
        guard let id = pageId as? String else { return nil }
        return viewModels[id]
    }

    func category(for pageId: AnyHashable) -> DemoCategoryMeta? {
        guard let id = pageId as? String else { return nil }
        return categories.first { $0.id == id }
    }

    // MARK: - Private Methods

    private func createViewModel(for category: DemoCategoryMeta) -> AnyDemoPageViewModel {
        switch category.layoutType {
        case .list:
            let vm = ListViewModel(initialCursor: 0) { [weak self] page in
                guard let self else { throw NSError(domain: "DemoDataStore", code: -1) }
                return try await self.fetchListItems(for: category, page: page)
            }
            return AnyDemoPageViewModel(vm) { item in
                PageItemModel(id: item.id, payload: item)
            }

        case .grid3, .grid4:
            let vm = GridViewModel(initialCursor: 0) { [weak self] page in
                guard let self else { throw NSError(domain: "DemoDataStore", code: -1) }
                return try await self.fetchGridItems(for: category, page: page)
            }
            return AnyDemoPageViewModel(vm) { item in
                PageItemModel(id: item.id, payload: item)
            }
        }
    }

    // MARK: - Mock Fetchers

    private func fetchListItems(
        for category: DemoCategoryMeta,
        page: Int
    ) async throws -> PageResult<DemoListItem, Int> {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let categoryIndex = categories.firstIndex { $0.id == category.id } ?? 0

        if page == 0 {
            switch categoryIndex {
            case 1:
                return PageResult(items: [], nextCursor: nil)     // 空数据
            case 2:
                throw NSError(
                    domain: "DemoDataStore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "网络异常，请稍后重试"]
                )
            default:
                break
            }
        }

        let items = generateListItems(for: category, page: page)
        let nextCursor: Int? = page < 2 ? page + 1 : nil
        return PageResult(items: items, nextCursor: nextCursor)
    }

    private func fetchGridItems(
        for category: DemoCategoryMeta,
        page: Int
    ) async throws -> PageResult<DemoGridItem, Int> {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let items = generateGridItems(for: category, page: page)
        let nextCursor: Int? = page < 2 ? page + 1 : nil
        return PageResult(items: items, nextCursor: nextCursor)
    }

    // MARK: - Mock Generators

    private func generateListItems(for category: DemoCategoryMeta, page: Int) -> [DemoListItem] {
        let count = page == 0 ? 20 : 10
        return (0..<count).map { index in
            let actualIndex = page * count + index
            return DemoListItem(
                title: "\(category.title) \(actualIndex + 1)",
                subtitle: "示例描述第 \(actualIndex + 1) 行，展示多分类数据流效果。"
            )
        }
    }

    private func generateGridItems(for category: DemoCategoryMeta, page: Int) -> [DemoGridItem] {
        let count: Int
        switch category.layoutType {
        case .grid3:
            count = page == 0 ? 30 : 15
        case .grid4:
            count = page == 0 ? 40 : 20
        case .list:
            count = 0  // 不会进入这里
        }

        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemPink, .systemTeal, .systemIndigo
        ]

        return (0..<count).map { index in
            let actualIndex = page * count + index
            let color = colors[actualIndex % colors.count]
            return DemoGridItem(
                title: "\(category.title) \(actualIndex + 1)",
                imageColor: color
            )
        }
    }
}

// MARK: - Type-Erased ViewModel Wrapper

/// 将不同 Item 类型的 PageableViewModel 包装为统一接口，方便 UI 层使用
final class AnyDemoPageViewModel {

    // Published bridging
    let viewStatePublisher: AnyPublisher<ViewState, Never>
    let itemsPublisher: AnyPublisher<[PageItemModel], Never>
    let loadMoreStatePublisher: AnyPublisher<LoadMoreState, Never>

    // Current values (用于非订阅场景，如 footer 状态读取)
    private(set) var viewState: ViewState
    private(set) var loadMoreState: LoadMoreState
    private(set) var items: [PageItemModel]

    // Subjects for bridging（避免初始化时 self 使用顺序问题）
    private let viewStateSubject: CurrentValueSubject<ViewState, Never>
    private let itemsSubject: CurrentValueSubject<[PageItemModel], Never>
    private let loadMoreStateSubject: CurrentValueSubject<LoadMoreState, Never>

    // Subscriptions storage & retention
    private var cancellables = Set<AnyCancellable>()
    private let retainedViewModel: AnyObject  // 保持对底层 ViewModel 的强引用

    // Actions
    private let loadInitialClosure: () -> Void
    private let loadMoreClosure: () -> Void
    private let retryClosure: () -> Void
    private let refreshClosure: () -> Void

    init<Item>(_ viewModel: PageableViewModel<Item, Int>, mapItem: @escaping (Item) -> PageItemModel) {
        // Current values
        viewState = viewModel.viewState
        loadMoreState = viewModel.loadMoreState
        items = viewModel.items.map(mapItem)

        // Retain underlying viewModel to keep publishers alive
        retainedViewModel = viewModel

        // Subjects
        viewStateSubject = CurrentValueSubject(viewState)
        itemsSubject = CurrentValueSubject(items)
        loadMoreStateSubject = CurrentValueSubject(loadMoreState)

        // Exposed publishers
        viewStatePublisher = viewStateSubject.eraseToAnyPublisher()
        itemsPublisher = itemsSubject.eraseToAnyPublisher()
        loadMoreStatePublisher = loadMoreStateSubject.eraseToAnyPublisher()

        // Actions
        loadInitialClosure = { [weak viewModel] in viewModel?.loadInitial() }
        loadMoreClosure = { [weak viewModel] in viewModel?.loadMore() }
        retryClosure = { [weak viewModel] in viewModel?.retry() }
        refreshClosure = { [weak viewModel] in viewModel?.refresh() }

        // Bridge ViewModel publishers to subjects & cached values
        viewModel.$viewState
            .sink { [weak self] state in
                self?.viewState = state
                self?.viewStateSubject.send(state)
            }
            .store(in: &cancellables)

        viewModel.$items
            .map { $0.map(mapItem) }
            .sink { [weak self] mappedItems in
                self?.items = mappedItems
                self?.itemsSubject.send(mappedItems)
            }
            .store(in: &cancellables)

        viewModel.$loadMoreState
            .sink { [weak self] state in
                self?.loadMoreState = state
                self?.loadMoreStateSubject.send(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Exposed Actions

    func loadInitial() { loadInitialClosure() }
    func loadMore() { loadMoreClosure() }
    func retry() { retryClosure() }
    func refresh() { refreshClosure() }
}
