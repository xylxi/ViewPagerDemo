import UIKit

// MARK: - PageableViewContainer 滚动事件处理示例

/// 本文件展示如何使用 PageableViewContainer 的滚动事件转发功能

// MARK: - 使用场景 1: 监听滚动实现导航栏隐藏/显示

/*
 ```swift
 class MyViewController: UIViewController {
     private lazy var container: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel,
             cellConfigurator: cellConfigurator
         )

         // 方式 1: 使用闭包监听滚动
         container.scrollHandler = { [weak self] scrollView in
             self?.handleScroll(scrollView)
         }

         return container
     }()

     private func handleScroll(_ scrollView: UIScrollView) {
         let offsetY = scrollView.contentOffset.y

         // 示例：根据滚动位置隐藏/显示导航栏
         if offsetY > 100 {
             navigationController?.setNavigationBarHidden(true, animated: true)
         } else {
             navigationController?.setNavigationBarHidden(false, animated: true)
         }
     }
 }
 ```
 */

// MARK: - 使用场景 2: 多个滚动视图联动

/*
 ```swift
 class MyViewController: UIViewController {
     private var lastContentOffset: CGFloat = 0

     private lazy var container1: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel1,
             cellConfigurator: cellConfigurator
         )
         container.scrollHandler = { [weak self] scrollView in
             self?.syncScroll(scrollView, to: self?.container2.collectionView)
         }
         return container
     }()

     private lazy var container2: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel2,
             cellConfigurator: cellConfigurator
         )
         return container
     }()

     private func syncScroll(_ source: UIScrollView, to target: UIScrollView?) {
         // 同步滚动位置
         target?.contentOffset = source.contentOffset
     }
 }
 ```
 */

// MARK: - 使用场景 3: 实现下拉放大头图效果

/*
 ```swift
 class MyViewController: UIViewController {
     private let headerImageView = UIImageView()
     private let headerHeight: CGFloat = 200

     private lazy var container: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel,
             cellConfigurator: cellConfigurator
         )
         container.scrollHandler = { [weak self] scrollView in
             self?.updateHeaderScale(scrollView)
         }
         return container
     }()

     private func updateHeaderScale(_ scrollView: UIScrollView) {
         let offsetY = scrollView.contentOffset.y

         if offsetY < 0 {
             // 下拉放大效果
             let scale = 1 + abs(offsetY) / headerHeight
             headerImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
         } else {
             // 上滑缩小效果
             let alpha = max(0, 1 - offsetY / headerHeight)
             headerImageView.alpha = alpha
         }
     }
 }
 ```
 */

// MARK: - 使用场景 4: 埋点追踪滚动深度

/*
 ```swift
 class MyViewController: UIViewController {
     private var maxScrollDepth: CGFloat = 0

     private lazy var container: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel,
             cellConfigurator: cellConfigurator
         )
         container.scrollHandler = { [weak self] scrollView in
             self?.trackScrollDepth(scrollView)
         }
         return container
     }()

     private func trackScrollDepth(_ scrollView: UIScrollView) {
         let contentHeight = scrollView.contentSize.height
         let scrollViewHeight = scrollView.bounds.height
         let offsetY = scrollView.contentOffset.y

         // 计算滚动深度百分比
         let scrollDepth = (offsetY + scrollViewHeight) / contentHeight

         // 记录最大滚动深度
         if scrollDepth > maxScrollDepth {
             maxScrollDepth = scrollDepth

             // 埋点上报（按 25%、50%、75%、100% 分段上报）
             if maxScrollDepth >= 0.25 && maxScrollDepth < 0.5 {
                 print("📊 [Analytics] User scrolled to 25%")
             } else if maxScrollDepth >= 0.5 && maxScrollDepth < 0.75 {
                 print("📊 [Analytics] User scrolled to 50%")
             } else if maxScrollDepth >= 0.75 && maxScrollDepth < 1.0 {
                 print("📊 [Analytics] User scrolled to 75%")
             } else if maxScrollDepth >= 1.0 {
                 print("📊 [Analytics] User scrolled to 100%")
             }
         }
     }
 }
 ```
 */

// MARK: - 使用场景 5: 吸顶效果

/*
 ```swift
 class MyViewController: UIViewController {
     private let stickyHeaderView = UIView()
     private let stickyThreshold: CGFloat = 200

     private lazy var container: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel,
             cellConfigurator: cellConfigurator
         )
         container.scrollHandler = { [weak self] scrollView in
             self?.updateStickyHeader(scrollView)
         }
         return container
     }()

     private func updateStickyHeader(_ scrollView: UIScrollView) {
         let offsetY = scrollView.contentOffset.y

         if offsetY >= stickyThreshold {
             // 吸顶
             stickyHeaderView.isHidden = false
             stickyHeaderView.alpha = min(1, (offsetY - stickyThreshold) / 50)
         } else {
             // 隐藏
             stickyHeaderView.isHidden = true
         }
     }
 }
 ```
 */

// MARK: - 方案 2: 使用代理协议（适合需要多个回调方法的场景）

/// 滚动事件代理协议
public protocol PageableScrollDelegate: AnyObject {
    /// 滚动时调用
    func pageableViewContainer<Item, Cursor>(
        _ container: PageableViewContainer<Item, Cursor>,
        didScroll scrollView: UIScrollView
    )

    /// 开始拖拽时调用（可选）
    func pageableViewContainer<Item, Cursor>(
        _ container: PageableViewContainer<Item, Cursor>,
        willBeginDragging scrollView: UIScrollView
    )

    /// 结束拖拽时调用（可选）
    func pageableViewContainer<Item, Cursor>(
        _ container: PageableViewContainer<Item, Cursor>,
        didEndDragging scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    )
}

// 提供默认实现，让协议方法变为可选
public extension PageableScrollDelegate {
    func pageableViewContainer<Item, Cursor>(
        _ container: PageableViewContainer<Item, Cursor>,
        willBeginDragging scrollView: UIScrollView
    ) {}

    func pageableViewContainer<Item, Cursor>(
        _ container: PageableViewContainer<Item, Cursor>,
        didEndDragging scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {}
}

/// 使用代理协议的示例
/*
 ```swift
 // 1. 在 PageableViewContainer 中添加代理属性（需要在类定义中添加）
 // public weak var scrollDelegate: PageableScrollDelegate?

 // 2. 在 scrollViewDidScroll 等方法中调用代理方法
 // public func scrollViewDidScroll(_ scrollView: UIScrollView) {
 //     scrollHandler?(scrollView)
 //     scrollDelegate?.pageableViewContainer(self, didScroll: scrollView)
 // }

 // 3. 使用方式
 class MyViewController: UIViewController, PageableScrollDelegate {
     private lazy var container: PageableViewContainer<Item, Int> = {
         let container = PageableViewContainer(
             viewModel: viewModel,
             cellConfigurator: cellConfigurator
         )
         container.scrollDelegate = self
         return container
     }()

     // 实现代理方法
     func pageableViewContainer<Item, Cursor>(
         _ container: PageableViewContainer<Item, Cursor>,
         didScroll scrollView: UIScrollView
     ) {
         print("Scrolled to: \(scrollView.contentOffset.y)")
     }

     func pageableViewContainer<Item, Cursor>(
         _ container: PageableViewContainer<Item, Cursor>,
         willBeginDragging scrollView: UIScrollView
     ) {
         print("Will begin dragging")
     }
 }
 ```
 */

// MARK: - 最佳实践建议

/*
 ## 选择哪种方案？

 1. **闭包方案（scrollHandler）**
    - ✅ 适合简单场景，只需要监听滚动事件
    - ✅ 代码更简洁，不需要定义协议
    - ✅ 适合单一回调
    - ❌ 不适合需要多个滚动事件回调的场景

 2. **代理方案（PageableScrollDelegate）**
    - ✅ 适合需要监听多个滚动事件（滚动、开始拖拽、结束拖拽等）
    - ✅ 更符合 iOS 传统的代理模式
    - ✅ 类型安全，可以在代理方法中访问 container 本身
    - ❌ 需要额外定义协议和实现代理方法

 ## 推荐使用场景

 - **只需要监听滚动**：使用闭包方案
 - **需要多个滚动事件**：使用代理方案（需要在 PageableViewContainer 中添加支持）
 - **需要弱引用**：两种方案都支持（闭包使用 [weak self]，代理使用 weak var）

 ## 性能注意事项

 - scrollViewDidScroll 会被频繁调用，避免在回调中执行耗时操作
 - 使用节流（throttle）或防抖（debounce）来减少回调频率
 - 避免在滚动回调中进行复杂的视图布局计算
 */
