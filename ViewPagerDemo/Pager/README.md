# Pager 技术方案

多分类数据流容器组件，Menu + Page 解耦设计。

## 设计原则

**组件只负责驱动渲染，不感知业务状态**

```
┌──────────────────────────────────────────────────────┐
│                  外部 DataStore                       │
│         (state / items / 业务逻辑)                    │
└──────────────────────────────────────────────────────┘
                         ↓ 协议方法查询
┌──────────────────────────────────────────────────────┐
│              MultiCategoryPagerView                   │
│  ┌────────────────────────────────────────────────┐  │
│  │  Menu (UICollectionView - 水平滚动)             │  │
│  │  ← PagerMenuContentProviding                   │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │  Page (UICollectionView - 分页)                 │  │
│  │  ← PagerPagePresentationProviding (决策层)      │  │
│  │    ├─ 返回 cell → 展示 StateCell               │  │
│  │    └─ 返回 nil  → 展示 DataCell                │  │
│  │         └─ 内嵌纵向 Collection                  │  │
│  │            ← PagerPageDataRendering            │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

## 目录结构

```
Pager/
├── MultiCategoryPagerView.swift   # 主容器
├── Cells/
│   ├── PagerMenuDefaultCell.swift # 默认菜单 Cell
│   └── PagerPageDataCell.swift    # 数据页面 Cell
├── PageScrollCache.swift          # 滚动偏移缓存
├── PagerModels.swift              # 数据模型
├── PagerProtocols.swift           # 协议定义
└── README.md                      # 本文档
```

## 数据模型

| 类型 | 职责 | 字段 |
|------|------|------|
| `PagerSection` | Section 标识 | `id: AnyHashable` |
| `PageModel` | Page 标识 | `pageId` / `userInfo` |
| `PageItemModel` | 列表项 | `id` / `payload` |
| `PagerSectionSnapshot` | 快照结构 | `section` / `pages` |

> **关键**：模型不包含 `state`、`items`，业务状态由外部管理

## 协议设计

### PagerMenuContentProviding

```swift
protocol PagerMenuContentProviding: AnyObject {
    func registerMenuCells(in collectionView: UICollectionView)
    func pagerMenuCollectionView(_:cellFor:at:) -> UICollectionViewCell
    func pagerMenuCollectionView(_:sizeFor:at:) -> CGSize
    func menuContentInsets(for:) -> UIEdgeInsets
    func menuMinimumInteritemSpacing(for:) -> CGFloat
}
```

### PagerPagePresentationProviding

```swift
protocol PagerPagePresentationProviding: AnyObject {
    func registerPageStateCells(in collectionView: UICollectionView)
    // 返回 cell = 展示状态页；返回 nil = 展示数据列表
    func pagerView(_:pageContainer:cellFor:at:) -> UICollectionViewCell?
}
```

### PagerPageDataRendering

```swift
protocol PagerPageDataRendering: AnyObject {
    func registerDataCells(in collectionView: UICollectionView)
    func pagerView(_:layoutFor:) -> UICollectionViewLayout
    func pagerView(_:itemsFor:) -> [PageItemModel]  // 外部提供数据
    func pagerView(_:collectionView:cellFor:at:page:) -> UICollectionViewCell
    func pagerView(_:didSelect:at:page:)
}
```

## 滚动偏移缓存

`PageScrollCache` + `isRestoringOffset` 标志位解决复用问题：

```
configure 开始
    ↓
isRestoringOffset = true  ← 开启保护
    ↓
setCollectionViewLayout / apply snapshot
    ↓ (期间 scrollViewDidScroll 不写缓存)
restoreContentOffset
    ↓
isRestoringOffset = false ← 关闭保护
    ↓
用户滚动 → 正常写入缓存
```

## 公开 API

```swift
public final class MultiCategoryPagerView: UIView {
    // 依赖注入
    weak var menuProvider: PagerMenuContentProviding?
    weak var presentationProvider: PagerPagePresentationProviding?
    weak var dataRenderer: PagerPageDataRendering?
    weak var selectionHandler: PagerMenuSelectionHandling?
    
    // 数据驱动
    func apply(sections: [PagerSectionSnapshot], animated: Bool)
    func update(pageId: AnyHashable, animated: Bool, transform: (inout PageModel) -> Void)
    func selectPage(at index: Int, animated: Bool)
}
```

## 渲染流程

```
1. apply(sections:)
   ↓
2. rebuildCaches() → 扁平化 [Section:[Page]] → [Page]
   ↓
3. applyMenuSnapshot() / applyPageSnapshot()
   ↓
4. Cell 渲染时:
   ├─ Menu: menuProvider.pagerMenuCollectionView(cellFor:)
   └─ Page: 
      ├─ presentationProvider 返回 cell? → StateCell
      └─ presentationProvider 返回 nil   → PagerPageDataCell
         └─ dataRenderer.pagerView(itemsFor:) → 获取数据
         └─ dataRenderer.pagerView(cellFor:)  → 渲染 cell
```

## 技术要点

| 特性 | 实现 |
|------|------|
| 数据驱动 | `UICollectionViewDiffableDataSource` |
| 布局 | SnapKit 约束 |
| 并发安全 | `nonisolated` Hashable 实现 |
| 复用安全 | `isRestoringOffset` 标志位 |
| 最低版本 | iOS 13+ |

## 依赖

- UIKit
- SnapKit

