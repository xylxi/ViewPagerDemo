# Pageable - 通用分页 ViewModel

通用分页 ViewModel 组件，用于管理页面的加载状态（loading/empty/failed/loaded）和分页数据。
使用 **Combine** 发布状态变化，支持响应式编程。

## 设计目标

| 目标 | 说明 |
|-----|------|
| **数据无关** | 通过泛型 `<Item>` 支持任意数据类型 |
| **请求无关** | 通过闭包/协议注入请求逻辑，ViewModel 不关心具体实现 |
| **状态统一** | 内置 `loading / empty / failed / loaded` 四种状态 |
| **分页内置** | 自动管理 `currentPage`、`hasMore`、防重复请求 |
| **响应式** | 使用 Combine `@Published` 属性发布状态变化 |

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    PageableViewModel<Item>                  │
│                      : ObservableObject                     │
├─────────────────────────────────────────────────────────────┤
│  @Published State:                                          │
│    - viewState: ViewState                                   │
│    - items: [Item]                                          │
│    - loadMoreState: LoadMoreState                           │
│                                                             │
│  Read-Only State:                                           │
│    - currentPage: Int                                       │
│    - hasMore: Bool                                          │
├─────────────────────────────────────────────────────────────┤
│  Actions (输入):                                             │
│    - loadInitial()      // 首次加载                          │
│    - loadMore()         // 加载更多                          │
│    - retry()            // 重试                             │
│    - refresh()          // 刷新                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 依赖注入
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Fetcher (外部实现)                       │
│  (Int) async throws -> PageResult<Item>                     │
└─────────────────────────────────────────────────────────────┘
```

## 文件结构

```
Pageable/
├── PageableModels.swift      # 状态和结果模型
├── PageableProtocols.swift   # 协议定义
├── PageableViewModel.swift   # 核心 ViewModel (Combine)
└── README.md                 # 本文档
```

## 核心类型

### ViewState - 视图状态

```swift
public enum ViewState: Equatable {
    case idle           // 初始状态
    case loading        // 首次加载中
    case empty          // 数据为空
    case failed(ViewStateError)  // 加载失败
    case loaded         // 加载成功
}
```

### LoadMoreState - 加载更多状态

```swift
public enum LoadMoreState: Equatable {
    case idle           // 空闲（可以加载更多）
    case loading        // 加载中
    case noMoreData     // 没有更多数据
    case failed         // 加载失败（可重试）
}
```

### PageResult - 分页结果

```swift
public struct PageResult<Item> {
    public let items: [Item]    // 当前页数据
    public let hasMore: Bool    // 是否还有更多
}
```

## 状态流转图

```
                    ┌─────────┐
                    │  idle   │
                    └────┬────┘
                         │ loadInitial()
                         ▼
                    ┌─────────┐
          ┌────────│ loading │────────┐
          │        └─────────┘        │
          │ 成功                    失败 │
          ▼                           ▼
    ┌───────────┐               ┌──────────┐
    │  loaded   │◄──── retry ───│  failed  │
    │  / empty  │               └──────────┘
    └─────┬─────┘
          │ loadMore()
          ▼
    ┌───────────────┐
    │ loadMoreState │
    │   = loading   │
    └───────┬───────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
  成功          失败
     │             │
     ▼             ▼
┌─────────┐  ┌─────────┐
│  idle   │  │ failed  │◄── retry
│ / noMore│  └─────────┘
└─────────┘
```

## 使用示例

### 1. 基础用法（Combine 订阅）

```swift
import Combine

class NewsViewController: UIViewController {

    private var viewModel: PageableViewModel<NewsItem>!
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 创建 ViewModel
        viewModel = PageableViewModel<NewsItem> { page in
            let response = try await self.api.fetchNews(page: page, size: 20)
            return PageResult(items: response.list, hasMore: response.hasMore)
        }

        // 订阅视图状态
        viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)

        // 订阅数据列表
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        // 订阅加载更多状态
        viewModel.$loadMoreState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleLoadMoreState(state)
            }
            .store(in: &cancellables)

        // 首次加载
        viewModel.loadInitial()
    }

    private func handleStateChange(_ state: ViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            showLoadingView()
        case .empty:
            showEmptyView()
        case .failed(let error):
            showErrorView(message: error.message)
        case .loaded:
            showContentView()
        }
    }

    private func handleLoadMoreState(_ state: LoadMoreState) {
        switch state {
        case .idle:
            tableView.mj_footer?.resetNoMoreData()
        case .loading:
            break
        case .noMoreData:
            tableView.mj_footer?.endRefreshingWithNoMoreData()
        case .failed:
            tableView.mj_footer?.endRefreshing()
        }
    }
}
```

### 2. 协议方式

```swift
// 定义 Fetcher
class NewsPageFetcher: PageableDataFetching {
    private let api: NewsAPI

    init(api: NewsAPI) {
        self.api = api
    }

    func fetchPage(_ page: Int) async throws -> PageResult<NewsItem> {
        let response = try await api.fetchNews(page: page)
        return PageResult(items: response.list, hasMore: response.hasMore)
    }
}

// 使用
let fetcher = NewsPageFetcher(api: newsAPI)
let viewModel = PageableViewModel(fetcher: fetcher)
```

### 3. SwiftUI 集成

```swift
struct NewsListView: View {
    @StateObject private var viewModel: PageableViewModel<NewsItem>

    init() {
        _viewModel = StateObject(wrappedValue: PageableViewModel { page in
            try await API.shared.fetchNews(page: page)
        })
    }

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView()
            case .empty:
                EmptyStateView()
            case .failed(let error):
                ErrorView(message: error.message) {
                    viewModel.retry()
                }
            case .loaded:
                List(viewModel.items, id: \.id) { item in
                    NewsRowView(item: item)
                }
            }
        }
        .onAppear {
            viewModel.loadInitial()
        }
    }
}
```

### 4. 与 Pager 组件集成

```swift
class DemoDataStore {
    private var viewModels: [String: PageableViewModel<DemoFeedItem>] = [:]

    func viewModel(for pageId: String) -> PageableViewModel<DemoFeedItem> {
        if let vm = viewModels[pageId] {
            return vm
        }

        let vm = PageableViewModel<DemoFeedItem> { [weak self] page in
            guard let self else { throw NSError() }
            return try await self.fetchItems(for: pageId, page: page)
        }

        viewModels[pageId] = vm
        return vm
    }

    private func fetchItems(
        for pageId: String,
        page: Int
    ) async throws -> PageResult<DemoFeedItem> {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let items = generateItems(for: pageId, page: page)
        let hasMore = page < 3

        return PageResult(items: items, hasMore: hasMore)
    }
}
```

## Combine Publishers

`PageableViewModel` 继承 `ObservableObject`，提供以下 `@Published` 属性：

| Publisher | 类型 | 说明 |
|-----------|------|------|
| `$viewState` | `Published<ViewState>.Publisher` | 视图状态变化 |
| `$items` | `Published<[Item]>.Publisher` | 数据列表变化 |
| `$loadMoreState` | `Published<LoadMoreState>.Publisher` | 加载更多状态变化 |

### 组合订阅示例

```swift
// 合并状态订阅
Publishers.CombineLatest(viewModel.$viewState, viewModel.$loadMoreState)
    .sink { viewState, loadMoreState in
        // 处理组合状态
    }
    .store(in: &cancellables)

// 仅在数据加载成功后处理
viewModel.$viewState
    .filter { $0 == .loaded }
    .sink { _ in
        // 加载成功后的处理
    }
    .store(in: &cancellables)
```

## 设计优势

| 特点 | 说明 |
|-----|------|
| **泛型** | `PageableViewModel<Item>` 支持任意数据类型 |
| **请求解耦** | 通过闭包/协议注入，ViewModel 不依赖具体网络层 |
| **防重复** | 内置状态检查，防止重复请求 |
| **可取消** | 使用 `Task` 支持请求取消 |
| **线程安全** | `@MainActor` 确保状态更新在主线程 |
| **响应式** | Combine `@Published` 支持声明式 UI 绑定 |
| **易测试** | 可注入 mock fetcher 进行单元测试 |

## 注意事项

1. **页码从 0 开始**：`currentPage` 从 0 开始计数
2. **首次加载前调用 loadInitial()**：不会自动加载
3. **refresh() 会取消当前请求**：适用于下拉刷新场景
4. **retry() 智能重试**：根据当前状态决定重试首次加载还是加载更多
5. **@MainActor**：ViewModel 所有操作都在主线程执行
6. **ObservableObject**：支持 SwiftUI `@StateObject` / `@ObservedObject`
