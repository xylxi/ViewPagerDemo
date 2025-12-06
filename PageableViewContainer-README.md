# PageableViewContainer

一个基于 `PageableViewModel` 的通用分页视图容器，支持自动状态管理、数据绑定和UI定制。

## 功能特性

- ✅ **自动状态管理**：根据 `ViewState` 自动切换视图（loading / empty / error / loaded）
- ✅ **数据驱动**：使用 `UICollectionViewDiffableDataSource` 驱动数据渲染
- ✅ **响应式绑定**：使用 `Combine` 进行数据绑定，自动响应 ViewModel 变化
- ✅ **UI 定制**：支持外部定制 Cell 样式和状态视图
- ✅ **下拉刷新**：内置下拉刷新支持（基于 MJRefresh）
- ✅ **加载更多**：内置加载更多支持，自动处理分页逻辑
- ✅ **类型安全**：基于泛型设计，支持任意数据类型和游标类型

## 架构设计

```
┌─────────────────────────────────────────────────┐
│          PageableViewContainer<Item, Cursor>    │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         StateViewContainer                 │ │
│  │  (loading / empty / error)                 │ │
│  │  ← PageableStateViewProviding              │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         CollectionView                     │ │
│  │  (data list)                               │ │
│  │  ← PageableCellConfiguring                 │ │
│  │  ← UICollectionViewDiffableDataSource      │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         PageableViewModel                  │ │
│  │  (viewState, items, loadMoreState)         │ │
│  │  ← Combine Publishers                      │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## 核心组件

### 1. PageableViewContainer

主视图容器，负责：
- 管理 CollectionView 和状态视图容器
- 监听 ViewModel 的状态变化
- 根据状态切换显示内容
- 配置下拉刷新和加载更多

### 2. PageableCellConfiguring

Cell 配置协议，外部实现以提供：
- Cell 注册
- Cell 渲染
- CollectionView 布局

### 3. PageableStateViewProviding

状态视图提供协议，外部实现以定制：
- Loading 视图
- Empty 视图
- Error 视图

### 4. PageableItemSelectionHandling

Item 选中处理协议，外部实现以响应用户点击。

### 5. PageableLoadMoreHandling

加载更多处理协议，外部实现以定制加载更多 Footer。

## 使用示例

### 基础用法

```swift
import UIKit

// 1. 定义数据模型（需要实现 Hashable）
struct NewsItem: Hashable {
    let id: String
    let title: String
    let summary: String
}

// 2. 实现 Cell 配置协议
class NewsCellConfigurator: PageableCellConfiguring {
    func registerCells(in collectionView: UICollectionView) {
        collectionView.register(NewsCell.self, forCellWithReuseIdentifier: "NewsCell")
    }

    func collectionView(_ collectionView: UICollectionView, cellFor item: NewsItem, at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as! NewsCell
        cell.configure(with: item)
        return cell
    }

    func layout(for collectionView: UICollectionView) -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: collectionView.bounds.width, height: 100)
        return layout
    }
}

// 3. 创建 ViewModel
let viewModel = PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
    let response = try await api.fetchNews(page: page)
    return PageResult(items: response.list, hasMore: response.hasMore, currentPage: page)
}

// 4. 创建视图容器
let container = PageableViewContainer(
    viewModel: viewModel,
    cellConfigurator: NewsCellConfigurator()
)

// 5. 添加到视图层级
view.addSubview(container)
container.snp.makeConstraints { make in
    make.edges.equalToSuperview()
}

// 6. 开始加载
viewModel.loadInitial()
```

### 定制状态视图

```swift
// 实现状态视图提供协议
class CustomStateViewProvider: PageableStateViewProviding {
    func loadingView() -> UIView? {
        // 返回自定义 Loading 视图
        return CustomLoadingView()
    }

    func emptyView() -> UIView? {
        // 返回自定义 Empty 视图
        return CustomEmptyView()
    }

    func errorView(error: ViewStateError, retryAction: @escaping () -> Void) -> UIView? {
        // 返回自定义 Error 视图
        return CustomErrorView(error: error, retryAction: retryAction)
    }
}

// 使用自定义状态视图
let container = PageableViewContainer(
    viewModel: viewModel,
    cellConfigurator: NewsCellConfigurator(),
    stateViewProvider: CustomStateViewProvider()
)
```

### 处理 Item 选中

```swift
// 实现选中处理协议
class NewsSelectionHandler: PageableItemSelectionHandling {
    func didSelectItem(_ item: NewsItem, at indexPath: IndexPath) {
        print("选中新闻：\(item.title)")
        // 跳转到详情页等操作
    }
}

// 传入选中处理器
let container = PageableViewContainer(
    viewModel: viewModel,
    cellConfigurator: NewsCellConfigurator(),
    selectionHandler: NewsSelectionHandler()
)
```

### 配置下拉刷新和加载更多

```swift
let container = PageableViewContainer(
    viewModel: viewModel,
    cellConfigurator: NewsCellConfigurator()
)

// 启用/禁用下拉刷新（默认启用）
container.enablePullToRefresh = true

// 启用/禁用加载更多（默认启用）
container.enableLoadMore = true
```

## 完整示例

查看 `DemoPageableContainer.swift` 获取完整的使用示例，包括：
- 基础用法示例
- 错误处理示例
- 空数据示例
- 自定义状态视图示例

## 与 PageableViewModel 集成

`PageableViewContainer` 基于 `PageableViewModel` 构建，自动监听以下状态：

- `viewState`：视图状态（idle / loading / empty / error / loaded）
- `items`：数据列表
- `loadMoreState`：加载更多状态（idle / loading / noMoreData / failed）

当 ViewModel 状态变化时，容器会自动更新 UI。

## 技术要点

1. **协议驱动**：通过协议注入依赖，实现关注点分离
2. **泛型设计**：支持任意数据类型和游标类型，类型安全
3. **DiffableDataSource**：使用现代化的数据源驱动方式，自动处理 diff
4. **Combine 绑定**：响应式编程，自动响应状态变化
5. **默认实现**：提供默认的状态视图，开箱即用
6. **灵活定制**：支持完全自定义 Cell 和状态视图

## 文件结构

```
Pageable/
├── PageableProtocols.swift          # 数据获取协议
├── PageableModels.swift             # 模型定义（ViewState、PageResult 等）
├── PageableViewModel.swift          # 分页 ViewModel
├── PageableViewProtocols.swift      # 视图相关协议（新增）
└── PageableViewContainer.swift      # 视图容器（新增）

Demo/
└── DemoPageableContainer.swift      # 使用示例（新增）
```

## 依赖

- UIKit
- Combine
- SnapKit（布局）
- MJRefresh（下拉刷新和加载更多）

## 代码规范

代码遵循 Swift API 设计指南和项目现有的代码风格：
- 使用协议进行依赖注入
- 分离关注点（Model、ViewModel、View）
- 使用泛型提高代码复用性
- 详细的代码注释和使用示例
- 使用 `// MARK:` 组织代码结构
