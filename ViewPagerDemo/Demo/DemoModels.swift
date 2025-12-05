import UIKit

// MARK: - Demo Models

struct DemoCategoryMeta {
    let id: String
    let title: String
    let accentColor: UIColor
}

struct DemoFeedItem: Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
}
