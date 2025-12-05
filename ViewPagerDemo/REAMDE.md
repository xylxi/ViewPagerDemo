# ViewPagerDemo

基于 `MultiCategoryPagerView` 组件的多分类数据流示例项目。

## 快速开始

### 1. 创建 DataStore

外部管理状态和数据，组件不感知业务逻辑：

```swift
final class MyDataStore {
    enum PageState { case loading, empty, failed(String), loaded }
    
    private var stateMap: [AnyHashable: PageState] = [:]
    private var itemsMap: [AnyHashable: [PageItemModel]] = [:]
    
    func state(for pageId: AnyHashable) -> PageState
    func items(for pageId: AnyHashable) -> [PageItemModel]
    func update(pageId: AnyHashable, state: PageState, items: [PageItemModel])
}
```

### 2. 实现协议

```swift
// Menu 样式
final class MyMenuProvider: PagerMenuContentProviding {
    func registerMenuCells(in collectionView: UICollectionView) { ... }
    func pagerMenuCollectionView(_:cellFor:at:) -> UICollectionViewCell { ... }
}

// 状态决策
final class MyStateProvider: PagerPagePresentationProviding {
    private weak var dataStore: MyDataStore?
    
    func pagerView(_:pageContainer:cellFor page:at:) -> UICollectionViewCell? {
        let state = dataStore?.state(for: page.pageId)
        return state == .loaded ? nil : makeStateCell(state)  // nil = 展示数据
    }
}

// 数据渲染
final class MyDataAdapter: PagerPageDataRendering {
    private weak var dataStore: MyDataStore?
    
    func pagerView(_:itemsFor page:) -> [PageItemModel] {
        dataStore?.items(for: page.pageId) ?? []
    }
    func pagerView(_:collectionView:cellFor:at:page:) -> UICollectionViewCell { ... }
}
```

### 3. 初始化组件

```swift
let dataStore = MyDataStore()
let pagerView = MultiCategoryPagerView(
    menuProvider: MyMenuProvider(),
    pagePresentationProvider: MyStateProvider(dataStore: dataStore),
    pageDataRenderer: MyDataAdapter(dataStore: dataStore)
)
```

### 4. 加载数据

```swift
// 构建初始快照
let pages = categories.map { PageModel(pageId: $0.id, userInfo: $0) }
let snapshot = PagerSectionSnapshot(section: PagerSection(id: "root"), pages: pages)
pagerView.apply(sections: [snapshot], animated: false)

// 数据更新后刷新
dataStore.update(pageId: "news", state: .loaded, items: newsItems)
pagerView.update(pageId: "news") { _ in }  // 触发重新渲染
```

## 项目结构

```
ViewPagerDemo/
├── Pager/                    # 组件源码（详见 Pager/README.md）
│   ├── MultiCategoryPagerView.swift
│   ├── Cells/
│   ├── PagerModels.swift
│   ├── PagerProtocols.swift
│   └── PageScrollCache.swift
├── ViewController.swift      # 示例代码
│   ├── DemoDataStore         # 数据管理示例
│   ├── DemoMenuProvider      # Menu 实现示例
│   ├── DemoPageStateProvider # 状态决策示例
│   └── DemoPageDataAdapter   # 数据渲染示例
└── REAMDE.md                 # 本文档
```

## 核心概念

| 概念 | 说明 |
|------|------|
| `PageModel` | 页面标识，`userInfo` 携带自定义数据 |
| `PagerSectionSnapshot` | `[Section: [Page]]` 快照结构 |
| `PresentationProvider` | 返回 cell = 状态页；返回 nil = 数据页 |
| `DataRenderer` | 通过 `itemsFor` 协议方法获取数据 |

## 运行要求

- iOS 13.0+
- Xcode 14+
- SnapKit

## 技术文档

组件详细技术方案请查看 [Pager/README.md](Pager/README.md)
