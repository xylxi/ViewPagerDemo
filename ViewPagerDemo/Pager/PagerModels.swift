import Foundation

// MARK: - Section

/// 分组标识模型
///
/// 用于标识 Pager 中的分组（如果需要多分组支持）
public struct PagerSection: Hashable, Sendable {
    /// 分组唯一标识
    public let id: AnyHashable

    public init(id: AnyHashable) {
        self.id = id
    }
}

// MARK: - Page

/// 页面模型
///
/// 代表 Pager 中的一个 tab 页面，组件只关心 `pageId`，
/// `userInfo` 用于外部存储业务数据（如分类元信息）
///
/// - Important: Hashable 实现基于 `pageId`，与 `userInfo` 无关
nonisolated
public struct PageModel: Hashable {
    /// 页面唯一标识
    public let pageId: AnyHashable
    
    /// 外部自定义数据载体，组件不关心具体类型
    ///
    /// 可用于存储分类名称、颜色、图标等业务数据
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

/// 分组快照模型
///
/// 包含一个分组及其下属的所有页面
///
/// - Important: Hashable 实现基于 `section`，与 `pages` 无关
nonisolated
public struct PagerSectionSnapshot: Hashable {
    /// 分组信息
    public let section: PagerSection
    
    /// 该分组下的所有页面
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

// MARK: - Page Item

/// 页面数据项模型
///
/// 代表数据列表中的一个 item，用于 `PagerPageDataCell` 内部的 DiffableDataSource
///
/// - Important: Hashable 实现基于 `id`，与 `payload` 无关
nonisolated
public struct PageItemModel: Hashable {
    /// 数据项唯一标识
    public let id: AnyHashable
    
    /// 数据载体，组件不关心具体类型
    ///
    /// 可用于存储 Feed 数据、商品数据等业务对象
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
