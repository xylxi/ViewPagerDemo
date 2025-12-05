import Foundation
import UIKit

/// 外部数据存储：管理 state 和 items，组件只负责驱动渲染
final class DemoDataStore {
    
    enum PageState {
        case loading
        case empty
        case failed(message: String)
        case loaded
    }
    
    struct PageData {
        var state: PageState = .loading
        var items: [PageItemModel] = []
        var hasMore: Bool = true           // 是否还有更多数据
        var currentPage: Int = 0           // 当前页码
    }
    
    private(set) var categories: [DemoCategoryMeta] = []
    private var pageDataMap: [AnyHashable: PageData] = [:]
    
    var allPageIds: [AnyHashable] {
        categories.map { $0.id }
    }
    
    func makeInitialSnapshots() -> [PagerSectionSnapshot] {
        categories = [
            DemoCategoryMeta(id: "news", title: "热点", accentColor: .systemOrange),
            DemoCategoryMeta(id: "sport", title: "体育", accentColor: .systemGreen),
            DemoCategoryMeta(id: "tech", title: "科技", accentColor: .systemBlue),
            DemoCategoryMeta(id: "finance", title: "财经", accentColor: .systemPurple),
            DemoCategoryMeta(id: "travel", title: "旅行", accentColor: .systemTeal),
            DemoCategoryMeta(id: "food", title: "美食", accentColor: .systemRed),
            DemoCategoryMeta(id: "movie", title: "影视", accentColor: .systemIndigo),
            DemoCategoryMeta(id: "game", title: "游戏", accentColor: .systemPink),
            DemoCategoryMeta(id: "auto", title: "汽车", accentColor: .systemYellow),
            DemoCategoryMeta(id: "fashion", title: "时尚", accentColor: .systemBrown)
        ]
        
        // 初始化 page data
        for category in categories {
            pageDataMap[category.id] = PageData()
        }
        
        let pages = categories.map { category in
            PageModel(pageId: category.id, userInfo: category)
        }
        return [PagerSectionSnapshot(section: PagerSection(id: "root"), pages: pages)]
    }
    
    func update(pageId: AnyHashable, state: PageState, items: [PageItemModel]) {
        pageDataMap[pageId]?.state = state
        pageDataMap[pageId]?.items = items
    }
    
    func pageData(for pageId: AnyHashable) -> PageData? {
        pageDataMap[pageId]
    }
    
    func category(for pageId: AnyHashable) -> DemoCategoryMeta? {
        categories.first { $0.id == pageId as? String }
    }
    
    func makeItems(for pageId: AnyHashable) -> [PageItemModel] {
        guard let category = category(for: pageId) else { return [] }
        let feeds = (0..<20).map { index -> DemoFeedItem in
            DemoFeedItem(title: "\(category.title) Item \(index + 1)",
                         subtitle: "示例描述第 \(index + 1) 行，展示多分类数据流效果。")
        }
        return feeds.map { PageItemModel(id: $0.id, payload: $0) }
    }
    
    // MARK: - Load More Support
    
    func appendItems(pageId: AnyHashable, newItems: [PageItemModel], hasMore: Bool) {
        pageDataMap[pageId]?.items.append(contentsOf: newItems)
        pageDataMap[pageId]?.hasMore = hasMore
        pageDataMap[pageId]?.currentPage += 1
    }
    
    func makeMoreItems(for pageId: AnyHashable) -> [PageItemModel] {
        guard let category = category(for: pageId),
              let pageData = pageDataMap[pageId] else { return [] }
        let startIndex = pageData.items.count
        let feeds = (0..<10).map { index -> DemoFeedItem in
            DemoFeedItem(title: "\(category.title) Item \(startIndex + index + 1)",
                         subtitle: "加载更多示例第 \(startIndex + index + 1) 行。")
        }
        return feeds.map { PageItemModel(id: $0.id, payload: $0) }
    }
}
