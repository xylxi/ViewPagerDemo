import Foundation

// MARK: - Section

public struct PagerSection: Hashable, Sendable {
    public let id: AnyHashable

    public init(id: AnyHashable) {
        self.id = id
    }
}

// MARK: - Page
nonisolated
public struct PageModel: Hashable {
    public let pageId: AnyHashable
    /// 外部自定义数据载体，组件不关心具体类型
    public var userInfo: Any?

    public init(pageId: AnyHashable, userInfo: Any? = nil) {
        self.pageId = pageId
        self.userInfo = userInfo
    }

    nonisolated public static func == (lhs: PageModel, rhs: PageModel) -> Bool {
        lhs.pageId == rhs.pageId
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(pageId)
    }
}

// MARK: - Section Snapshot
nonisolated
public struct PagerSectionSnapshot: Hashable {
    public let section: PagerSection
    public var pages: [PageModel]

    public init(section: PagerSection, pages: [PageModel]) {
        self.section = section
        self.pages = pages
    }

    nonisolated public static func == (lhs: PagerSectionSnapshot, rhs: PagerSectionSnapshot) -> Bool {
        lhs.section == rhs.section
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(section)
    }
}

// MARK: - Page Item (for data cell diffable datasource)
nonisolated
public struct PageItemModel: Hashable {
    public let id: AnyHashable
    public let payload: Any

    public init(id: AnyHashable, payload: Any) {
        self.id = id
        self.payload = payload
    }

    nonisolated public static func == (lhs: PageItemModel, rhs: PageItemModel) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
