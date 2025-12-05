import UIKit
import SnapKit

/// 多分类数据流容器组件
///
/// 组件设计原则：**组件只负责驱动渲染，不感知业务状态**
///
/// 架构：
/// ```
/// ┌─────────────────────────────────────┐
/// │           Menu (水平滚动)            │
/// │    ← PagerMenuContentProviding      │
/// ├─────────────────────────────────────┤
/// │           Page (分页容器)            │
/// │  ← PagerPagePresentationProviding   │
/// │    ├─ 返回 cell → 展示 StateCell    │
/// │    └─ 返回 nil  → 展示 DataCell     │
/// │         ← PagerPageDataRendering    │
/// └─────────────────────────────────────┘
/// ```
///
/// 使用示例：
/// ```swift
/// let pagerView = MultiCategoryPagerView(
///     menuProvider: menuProvider,
///     pagePresentationProvider: stateProvider,
///     pageDataRenderer: dataAdapter
/// )
/// pagerView.apply(sections: snapshots, animated: false)
/// ```
public final class MultiCategoryPagerView: UIView {

    // MARK: - Nested Types

    /// Section 在原始数据中的位置信息
    private struct SectionPosition {
        let sectionIndex: Int
        let pageIndex: Int
    }

    // MARK: - Public API (依赖注入)

    /// 菜单内容提供者：负责菜单 cell 的注册、渲染、尺寸计算
    public weak var menuProvider: PagerMenuContentProviding? {
        didSet { menuProvider?.registerMenuCells(in: menuCollectionView) }
    }
    
    /// 页面状态提供者：决定展示状态页还是数据页
    public weak var presentationProvider: PagerPagePresentationProviding? {
        didSet { presentationProvider?.registerPageStateCells(in: pageCollectionView) }
    }
    
    /// 数据页渲染器：负责数据列表的 layout、items、cell 渲染
    public weak var dataRenderer: PagerPageDataRendering? {
        didSet { pageCollectionView.reloadData() }
    }
    
    /// 菜单选中回调处理器
    public weak var selectionHandler: PagerMenuSelectionHandling?
    
    /// 加载更多能力提供者
    public weak var loadMoreProvider: PagerLoadMoreProviding?
    
    /// Page 曝光回调处理器
    public weak var pageExposureHandler: PagerPageExposureHandling?
    
    /// Item 曝光回调处理器
    public weak var itemExposureHandler: PagerItemExposureHandling?

    // MARK: - Initialization

    /// 初始化 Pager 组件
    /// - Parameters:
    ///   - menuLayout: 自定义菜单布局，默认为水平滚动的 FlowLayout
    ///   - menuProvider: 菜单内容提供者（必需）
    ///   - pagePresentationProvider: 页面状态提供者（可选，用于展示 loading/empty/error 等状态）
    ///   - pageDataRenderer: 数据页渲染器（必需）
    ///   - selectionHandler: 菜单选中回调处理器（可选）
    public init(menuLayout: UICollectionViewLayout? = nil,
                menuProvider: PagerMenuContentProviding,
                pagePresentationProvider: PagerPagePresentationProviding? = nil,
                pageDataRenderer: PagerPageDataRendering,
                selectionHandler: PagerMenuSelectionHandling? = nil) {
        self.menuLayout = menuLayout ?? Self.defaultMenuLayout()
        self.menuProvider = menuProvider
        self.presentationProvider = pagePresentationProvider
        self.dataRenderer = pageDataRenderer
        self.selectionHandler = selectionHandler
        super.init(frame: .zero)
        setup()
        menuProvider.registerMenuCells(in: menuCollectionView)
        presentationProvider?.registerPageStateCells(in: pageCollectionView)
    }

    required init?(coder: NSCoder) {
        self.menuLayout = Self.defaultMenuLayout()
        super.init(coder: coder)
        setup()
    }

    // MARK: - Public Methods

    /// 应用数据快照，驱动 UI 渲染
    /// - Parameters:
    ///   - sections: 分组数据快照
    ///   - animated: 是否使用动画
    public func apply(sections: [PagerSectionSnapshot], animated: Bool = true) {
        sectionSnapshots = sections
        rebuildCaches()
        applyMenuSnapshot(animated: animated)
        applyPageSnapshot(animated: animated)
        selectMenuItem(at: currentIndex, animated: false)
        // 首次 apply 时触发初始 page 曝光
        emitPageExposureIfNeeded()
    }

    /// 更新指定 page 的数据（触发 cell 重新配置）
    ///
    /// 适用场景：状态变化（loading → loaded）、数据变化等
    /// - Parameters:
    ///   - pageId: 页面标识
    ///   - animated: 是否使用动画
    ///   - transform: 数据变换闭包
    public func update(pageId: AnyHashable, animated: Bool = true, transform: (inout PageModel) -> Void) {
        guard let position = pageIdToSectionPosition[pageId] else { return }
        var target = sectionSnapshots[position.sectionIndex].pages[position.pageIndex]
        transform(&target)
        sectionSnapshots[position.sectionIndex].pages[position.pageIndex] = target
        rebuildCaches()
        applyMenuSnapshot(animated: animated)
        
        // 使用 reloadItems 强制刷新指定 page 的 cell，确保内部数据列表更新
        var snapshot = pageDataSource.snapshot()
        let itemsToReload = snapshot.itemIdentifiers.filter { $0.pageId == pageId }
        if !itemsToReload.isEmpty {
            snapshot.reloadItems(itemsToReload)
        }
        pageDataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    /// 刷新指定 page 的数据列表，保持滚动位置
    ///
    /// 适用场景：加载更多数据后刷新列表，避免滚动位置重置导致的回弹
    /// - Parameter pageId: 页面标识
    public func reloadPageData(pageId: AnyHashable) {
        for cell in pageCollectionView.visibleCells {
            if let dataCell = cell as? PagerPageDataCell {
                if let indexPath = pageCollectionView.indexPath(for: cell),
                   indexPath.item < flattenedPages.count,
                   flattenedPages[indexPath.item].pageId == pageId {
                    dataCell.reloadData()
                    return
                }
            }
        }
    }

    /// 程序化选中指定索引的 page
    /// - Parameters:
    ///   - index: page 索引
    ///   - animated: 是否使用动画
    public func selectPage(at index: Int, animated: Bool) {
        guard index >= 0, index < flattenedPages.count else { return }
        scrollToPage(at: index, animated: animated, origin: .external)
    }

    // MARK: - Private Properties

    /// 选中来源：用于区分是用户操作还是程序化操作
    private enum SelectionOrigin {
        case menuTap      // 点击菜单
        case scrolling    // 滑动页面
        case external     // 外部调用
    }

    private let menuLayout: UICollectionViewLayout
    /// 原始分组数据
    private var sectionSnapshots: [PagerSectionSnapshot] = []
    /// 扁平化的 page 数组（用于 DiffableDataSource）
    private var flattenedPages: [PageModel] = []
    /// 扁平索引 → 原始位置的映射
    private var flatIndexToSection: [Int: SectionPosition] = [:]
    /// pageId → 原始位置的映射
    private var pageIdToSectionPosition: [AnyHashable: SectionPosition] = [:]
    /// 当前选中的 page 索引
    private var currentIndex: Int = 0
    /// 待触发的选中事件来源
    private var pendingSelectionOrigin: SelectionOrigin?
    /// 上次曝光的 page 索引（用于去重）
    private var lastExposedPageIndex: Int = -1

    // MARK: - UI Components

    /// 菜单 CollectionView（水平滚动）
    private lazy var menuCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: menuLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsMultipleSelection = false
        return collectionView
    }()

    /// 菜单数据源
    private lazy var menuDataSource: UICollectionViewDiffableDataSource<Int, PageModel> = {
        UICollectionViewDiffableDataSource<Int, PageModel>(collectionView: menuCollectionView) { [weak self] collectionView, indexPath, page in
            guard let self = self else { return UICollectionViewCell() }
            // 优先使用外部提供的自定义 cell
            if let customCell = self.menuProvider?.pagerMenuCollectionView(collectionView, cellFor: page, at: indexPath) {
                return customCell
            }
            // 回退到默认 cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PagerMenuDefaultCell.reuseIdentifier, for: indexPath) as? PagerMenuDefaultCell else {
                return UICollectionViewCell()
            }
            cell.configure(title: "Item \(indexPath.item + 1)")
            return cell
        }
    }()

    /// 页面 CollectionView（水平分页）
    private lazy var pageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(PagerPageDataCell.self, forCellWithReuseIdentifier: PagerPageDataCell.reuseIdentifier)
        return collectionView
    }()

    /// 页面数据源
    private lazy var pageDataSource: UICollectionViewDiffableDataSource<Int, PageModel> = {
        UICollectionViewDiffableDataSource<Int, PageModel>(collectionView: pageCollectionView) { [weak self] collectionView, indexPath, page in
            guard let self else { return UICollectionViewCell() }
            // 优先检查是否需要展示状态页（loading/empty/error）
            if let customCell = self.presentationProvider?.pagerView(self, pageContainer: collectionView, cellFor: page, at: indexPath) {
                return customCell
            }
            // 展示数据页
            guard let renderer = self.dataRenderer else { return UICollectionViewCell() }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PagerPageDataCell.reuseIdentifier, for: indexPath) as? PagerPageDataCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: page,
                           pagerView: self,
                           adapter: renderer,
                           scrollCache: self.scrollCache,
                           loadMoreProvider: self.loadMoreProvider)
            return cell
        }
    }()

    /// 滚动位置缓存（用于切换 page 时恢复滚动位置）
    let scrollCache = PageScrollCache()

    // MARK: - Setup

    private func setup() {
        backgroundColor = .systemBackground
        addSubview(menuCollectionView)
        addSubview(pageCollectionView)

        menuCollectionView.dataSource = menuDataSource
        menuCollectionView.delegate = self
        pageCollectionView.dataSource = pageDataSource
        pageCollectionView.delegate = self

        menuCollectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        pageCollectionView.snp.makeConstraints { make in
            make.top.equalTo(menuCollectionView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        menuCollectionView.register(PagerMenuDefaultCell.self, forCellWithReuseIdentifier: PagerMenuDefaultCell.reuseIdentifier)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 确保 page cell 尺寸与 pageCollectionView 相同
        if let flowLayout = pageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let size = pageCollectionView.bounds.size
            if flowLayout.itemSize != size {
                flowLayout.itemSize = size
                flowLayout.invalidateLayout()
            }
        }
        updateMenuInsetsIfNeeded()
    }

    private func updateMenuInsetsIfNeeded() {
        guard let provider = menuProvider else { return }
        menuCollectionView.contentInset = provider.menuContentInsets(for: menuCollectionView)
        if let flowLayout = menuCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = provider.menuMinimumInteritemSpacing(for: menuCollectionView)
        }
    }

    // MARK: - Data Management

    /// 重建内部缓存（将分组数据扁平化）
    private func rebuildCaches() {
        flattenedPages.removeAll()
        flatIndexToSection.removeAll()
        pageIdToSectionPosition.removeAll()
        var flatIndex = 0
        for (sectionIdx, section) in sectionSnapshots.enumerated() {
            for (pageIdx, page) in section.pages.enumerated() {
                flattenedPages.append(page)
                let position = SectionPosition(sectionIndex: sectionIdx, pageIndex: pageIdx)
                flatIndexToSection[flatIndex] = position
                pageIdToSectionPosition[page.pageId] = position
                flatIndex += 1
            }
        }
        // 确保 currentIndex 不越界
        if currentIndex >= flattenedPages.count {
            currentIndex = max(flattenedPages.count - 1, 0)
        }
    }

    /// 应用菜单快照
    private func applyMenuSnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PageModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(flattenedPages, toSection: 0)
        menuDataSource.apply(snapshot, animatingDifferences: animated)
    }

    /// 应用页面快照
    private func applyPageSnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PageModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(flattenedPages, toSection: 0)
        pageDataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Page Navigation

    /// 滚动到指定 page
    private func scrollToPage(at index: Int, animated: Bool, origin: SelectionOrigin) {
        guard index >= 0, index < flattenedPages.count else { return }
        pendingSelectionOrigin = origin
        currentIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        pageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        selectMenuItem(at: index, animated: true)
        if !animated {
            emitSelectionIfNeeded()
        }
        // animated = true 时，在 scrollViewDidEndScrollingAnimation 中触发
    }

    /// 选中菜单项
    private func selectMenuItem(at index: Int, animated: Bool) {
        guard index >= 0, index < flattenedPages.count else { return }
        let indexPath = IndexPath(item: index, section: 0)
        menuCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        menuCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    // MARK: - Event Emission

    /// 触发选中事件
    private func emitSelectionIfNeeded() {
        guard let origin = pendingSelectionOrigin,
              currentIndex >= 0,
              currentIndex < flattenedPages.count else { return }
        selectionHandler?.pagerView(self, didSelect: flattenedPages[currentIndex], at: currentIndex)
        pendingSelectionOrigin = nil
        
        // 触发 page 曝光
        emitPageExposureIfNeeded()
    }

    /// 触发 page 曝光（去重处理）
    private func emitPageExposureIfNeeded() {
        guard currentIndex >= 0,
              currentIndex < flattenedPages.count,
              currentIndex != lastExposedPageIndex else { return }
        lastExposedPageIndex = currentIndex
        pageExposureHandler?.pagerView(self, didExposePage: flattenedPages[currentIndex], at: currentIndex)
    }

    /// 默认菜单布局
    private static func defaultMenuLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 12
        flowLayout.sectionInset = .zero
        return flowLayout
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MultiCategoryPagerView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == menuCollectionView {
            scrollToPage(at: indexPath.item, animated: false, origin: .menuTap)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard collectionView == menuCollectionView,
              indexPath.item < flattenedPages.count else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
        }
        return menuProvider?.pagerMenuCollectionView(collectionView, sizeFor: flattenedPages[indexPath.item], at: indexPath) ?? CGSize(width: 80, height: collectionView.bounds.height)
    }
}

// MARK: - UIScrollViewDelegate

extension MultiCategoryPagerView: UIScrollViewDelegate {
    
    /// 滑动减速结束
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == pageCollectionView else { return }
        let index = currentPageIndex()
        currentIndex = index
        selectMenuItem(at: index, animated: true)
        pendingSelectionOrigin = .scrolling
        emitSelectionIfNeeded()
    }

    /// 滚动动画结束（程序化滚动）
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == pageCollectionView else { return }
        emitSelectionIfNeeded()
    }

    /// 拖拽结束（无减速时）
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == pageCollectionView, !decelerate else { return }
        let index = currentPageIndex()
        currentIndex = index
        selectMenuItem(at: index, animated: true)
        pendingSelectionOrigin = .scrolling
        emitSelectionIfNeeded()
    }

    /// 计算当前 page 索引
    private func currentPageIndex() -> Int {
        guard pageCollectionView.bounds.width > 0 else { return 0 }
        let rawIndex = pageCollectionView.contentOffset.x / pageCollectionView.bounds.width
        let index = Int(round(rawIndex))
        return max(0, min(index, flattenedPages.count - 1))
    }
}
