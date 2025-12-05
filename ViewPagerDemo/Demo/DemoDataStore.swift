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
        
        // 根据布局类型生成不同数量的数据
        let count: Int
        switch category.layoutType {
        case .list: count = 20
        case .grid3: count = 30  // 网格需要更多数据才能填满
        case .grid4: count = 40
        }
        
        let feeds = (0..<count).map { index -> DemoFeedItem in
            // 为网格布局使用不同的随机颜色
            let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange,
                                     .systemPurple, .systemPink, .systemTeal, .systemIndigo]
            let randomColor = colors[index % colors.count]
            
            return DemoFeedItem(
                title: "\(category.title) \(index + 1)",
                subtitle: category.layoutType == .list ? "示例描述第 \(index + 1) 行，展示多分类数据流效果。" : "",
                imageColor: category.layoutType == .list ? .systemGray4 : randomColor
            )
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
        
        // 根据布局类型生成不同数量的增量数据
        let count: Int
        switch category.layoutType {
        case .list: count = 10
        case .grid3: count = 15
        case .grid4: count = 20
        }
        
        let startIndex = pageData.items.count
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange,
                                 .systemPurple, .systemPink, .systemTeal, .systemIndigo]
        
        let feeds = (0..<count).map { index -> DemoFeedItem in
            let randomColor = colors[(startIndex + index) % colors.count]
            return DemoFeedItem(
                title: "\(category.title) \(startIndex + index + 1)",
                subtitle: category.layoutType == .list ? "加载更多示例第 \(startIndex + index + 1) 行。" : "",
                imageColor: category.layoutType == .list ? .systemGray4 : randomColor
            )
        }
        return feeds.map { PageItemModel(id: $0.id, payload: $0) }
    }
}
