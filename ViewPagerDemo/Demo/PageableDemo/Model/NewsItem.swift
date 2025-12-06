import Foundation

/// 新闻数据模型
struct NewsItem: Hashable {
    let id: String
    let title: String
    let summary: String
    let publishTime: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.id == rhs.id
    }
}
