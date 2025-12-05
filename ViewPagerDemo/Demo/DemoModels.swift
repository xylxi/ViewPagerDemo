import UIKit

// MARK: - Layout Type

/// Feed 布局类型
enum FeedLayoutType {
    case list           // 一行一列（列表）
    case grid3          // 一行三列（三等分网格）
    case grid4          // 一行四列（四等分网格）
    
    /// 每行的列数
    var columnsPerRow: Int {
        switch self {
        case .list: return 1
        case .grid3: return 3
        case .grid4: return 4
        }
    }
}

// MARK: - Demo Models

/// 分类元信息
struct DemoCategoryMeta {
    let id: String
    let title: String
    let accentColor: UIColor
    let layoutType: FeedLayoutType  // 布局类型
    
    init(id: String, title: String, accentColor: UIColor, layoutType: FeedLayoutType = .list) {
        self.id = id
        self.title = title
        self.accentColor = accentColor
        self.layoutType = layoutType
    }
}

/// Feed 数据项
struct DemoFeedItem: Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageColor: UIColor  // 模拟图片的颜色
    
    init(title: String, subtitle: String, imageColor: UIColor = .systemGray4) {
        self.title = title
        self.subtitle = subtitle
        self.imageColor = imageColor
    }
}
