import Combine
import Foundation
import UIKit

/// 外部数据存储：管理分类和 ViewModel，组件只负责驱动渲染
///
/// 每个 page 使用一个 `PageableViewModel` 管理其状态和数据
@MainActor
final class DemoDataStore {

    // MARK: - Type Aliases

    /// ViewModel 类型（Item: DemoFeedItem, Cursor: Int）
    typealias FeedViewModel = PageableViewModel<DemoFeedItem, Int>

    // MARK: - Properties

    private(set) var categories: [DemoCategoryMeta] = []

    /// 每个 page 对应一个 PageableViewModel
    private var viewModels: [String: FeedViewModel] = [:]

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

        // 为每个分类创建 ViewModel
        for category in categories {
            viewModels[category.id] = createViewModel(for: category)
        }

        let pages = categories.map { category in
            PageModel(pageId: category.id, userInfo: category)
        }
        return [PagerSectionSnapshot(section: PagerSection(id: "root"), pages: pages)]
    }

    // MARK: - ViewModel Access

    /// 获取指定 page 的 ViewModel
    func viewModel(for pageId: String) -> FeedViewModel? {
        viewModels[pageId]
    }

    /// 获取指定 page 的 ViewModel（通过 AnyHashable）
    func viewModel(for pageId: AnyHashable) -> FeedViewModel? {
        guard let id = pageId as? String else { return nil }
        return viewModels[id]
    }

    /// 获取分类信息
    func category(for pageId: AnyHashable) -> DemoCategoryMeta? {
        guard let id = pageId as? String else { return nil }
        return categories.first { $0.id == id }
    }

    // MARK: - Private Methods

    /// 为分类创建 ViewModel（页码从 0 开始）
    private func createViewModel(for category: DemoCategoryMeta) -> FeedViewModel {
        FeedViewModel(initialCursor: 0) { [weak self] page in
            guard let self else {
                throw NSError(domain: "DemoDataStore", code: -1)
            }
            return try await self.fetchItems(for: category, page: page)
        }
    }

    /// 模拟网络请求获取数据
    private func fetchItems(
        for category: DemoCategoryMeta,
        page: Int
    ) async throws -> PageResult<DemoFeedItem, Int> {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // 模拟不同状态：第 2 个分类返回空，第 3 个分类失败
        let categoryIndex = categories.firstIndex { $0.id == category.id } ?? 0

        if page == 0 {
            // 首次加载时模拟不同状态
            switch categoryIndex {
            case 1:
                // 体育：返回空数据
                return PageResult(items: [], nextCursor: nil)
            case 2:
                // 科技：模拟失败
                throw NSError(
                    domain: "DemoDataStore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "网络异常，请稍后重试"]
                )
            default:
                break
            }
        }

        // 生成数据
        let items = generateItems(for: category, page: page)

        // 加载 3 页后没有更多数据
        let nextCursor: Int? = page < 2 ? page + 1 : nil

        return PageResult(items: items, nextCursor: nextCursor)
    }

    /// 生成模拟数据
    private func generateItems(for category: DemoCategoryMeta, page: Int) -> [DemoFeedItem] {
        // 根据布局类型生成不同数量的数据
        let count: Int
        switch category.layoutType {
        case .list:
            count = page == 0 ? 20 : 10
        case .grid3:
            count = page == 0 ? 30 : 15
        case .grid4:
            count = page == 0 ? 40 : 20
        }

        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemPink, .systemTeal, .systemIndigo
        ]

        let startIndex = page == 0 ? 0 : (page == 1 ? count * 2 : count * 3)

        return (0..<count).map { index in
            let actualIndex = startIndex + index
            let randomColor = colors[actualIndex % colors.count]

            return DemoFeedItem(
                title: "\(category.title) \(actualIndex + 1)",
                subtitle: category.layoutType == .list
                    ? "示例描述第 \(actualIndex + 1) 行，展示多分类数据流效果。"
                    : "",
                imageColor: category.layoutType == .list ? .systemGray4 : randomColor
            )
        }
    }
}
