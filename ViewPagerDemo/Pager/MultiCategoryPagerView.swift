import UIKit
import SnapKit

public final class MultiCategoryPagerView: UIView {

    // MARK: - Nested Types

    private struct SectionPosition {
        let sectionIndex: Int
        let pageIndex: Int
    }

    // MARK: - Public API

    public weak var menuProvider: PagerMenuContentProviding? {
        didSet { menuProvider?.registerMenuCells(in: menuCollectionView) }
    }
    public weak var presentationProvider: PagerPagePresentationProviding? {
        didSet { presentationProvider?.registerPageStateCells(in: pageCollectionView) }
    }
    public weak var dataRenderer: PagerPageDataRendering? {
        didSet { pageCollectionView.reloadData() }
    }
    public weak var selectionHandler: PagerMenuSelectionHandling?
    public weak var loadMoreProvider: PagerLoadMoreProviding?

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

    public func apply(sections: [PagerSectionSnapshot], animated: Bool = true) {
        sectionSnapshots = sections
        rebuildCaches()
        applyMenuSnapshot(animated: animated)
        applyPageSnapshot(animated: animated)
        selectMenuItem(at: currentIndex, animated: false)
    }

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
    
    /// 刷新指定 page 的数据列表，保持滚动位置（用于加载更多等场景）
    public func reloadPageData(pageId: AnyHashable) {
        // 找到对应的 cell 并刷新数据
        for cell in pageCollectionView.visibleCells {
            if let dataCell = cell as? PagerPageDataCell {
                // 通过 indexPath 获取对应的 page
                if let indexPath = pageCollectionView.indexPath(for: cell),
                   indexPath.item < flattenedPages.count,
                   flattenedPages[indexPath.item].pageId == pageId {
                    dataCell.reloadData()
                    return
                }
            }
        }
    }

    public func selectPage(at index: Int, animated: Bool) {
        guard index >= 0, index < flattenedPages.count else { return }
        scrollToPage(at: index, animated: animated, origin: .external)
    }

    // MARK: - Private properties

    private enum SelectionOrigin {
        case menuTap
        case scrolling
        case external
    }

    private let menuLayout: UICollectionViewLayout
    private var sectionSnapshots: [PagerSectionSnapshot] = []
    private var flattenedPages: [PageModel] = []
    private var flatIndexToSection: [Int: SectionPosition] = [:]
    private var pageIdToSectionPosition: [AnyHashable: SectionPosition] = [:]
    private var currentIndex: Int = 0
    private var pendingSelectionOrigin: SelectionOrigin?

    private lazy var menuCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: menuLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsMultipleSelection = false
        return collectionView
    }()

    private lazy var menuDataSource: UICollectionViewDiffableDataSource<Int, PageModel> = {
        UICollectionViewDiffableDataSource<Int, PageModel>(collectionView: menuCollectionView) { [weak self] collectionView, indexPath, page in
            guard let self = self else { return UICollectionViewCell() }
            if let customCell = self.menuProvider?.pagerMenuCollectionView(collectionView, cellFor: page, at: indexPath) {
                return customCell
            }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PagerMenuDefaultCell.reuseIdentifier, for: indexPath) as? PagerMenuDefaultCell else {
                return UICollectionViewCell()
            }
            cell.configure(title: "Item \(indexPath.item + 1)")
            return cell
        }
    }()

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

    private lazy var pageDataSource: UICollectionViewDiffableDataSource<Int, PageModel> = {
        UICollectionViewDiffableDataSource<Int, PageModel>(collectionView: pageCollectionView) { [weak self] collectionView, indexPath, page in
            guard let self else { return UICollectionViewCell() }
            if let customCell = self.presentationProvider?.pagerView(self, pageContainer: collectionView, cellFor: page, at: indexPath) {
                return customCell
            }
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

    // MARK: - Data

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
        if currentIndex >= flattenedPages.count {
            currentIndex = max(flattenedPages.count - 1, 0)
        }
    }

    private func applyMenuSnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PageModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(flattenedPages, toSection: 0)
        menuDataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func applyPageSnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PageModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(flattenedPages, toSection: 0)
        pageDataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func scrollToPage(at index: Int, animated: Bool, origin: SelectionOrigin) {
        guard index >= 0, index < flattenedPages.count else { return }
        pendingSelectionOrigin = origin
        currentIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        pageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        selectMenuItem(at: index, animated: true)
        if animated {
            // wait until scroll animation finishes before emitting selection
        } else {
            emitSelectionIfNeeded()
        }
    }

    private func selectMenuItem(at index: Int, animated: Bool) {
        guard index >= 0, index < flattenedPages.count else { return }
        let indexPath = IndexPath(item: index, section: 0)
        menuCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
        menuCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    private func emitSelectionIfNeeded() {
        guard let origin = pendingSelectionOrigin,
              currentIndex >= 0,
              currentIndex < flattenedPages.count else { return }
        selectionHandler?.pagerView(self, didSelect: flattenedPages[currentIndex], at: currentIndex)
        pendingSelectionOrigin = nil
    }

    private static func defaultMenuLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 12
        flowLayout.sectionInset = .zero
        return flowLayout
    }
}

// MARK: - UICollectionViewDelegate

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
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == pageCollectionView else { return }
        let index = currentPageIndex()
        currentIndex = index
        selectMenuItem(at: index, animated: true)
        pendingSelectionOrigin = .scrolling
        emitSelectionIfNeeded()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == pageCollectionView else { return }
        emitSelectionIfNeeded()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == pageCollectionView, !decelerate else { return }
        let index = currentPageIndex()
        currentIndex = index
        selectMenuItem(at: index, animated: true)
        pendingSelectionOrigin = .scrolling
        emitSelectionIfNeeded()
    }

    private func currentPageIndex() -> Int {
        guard pageCollectionView.bounds.width > 0 else { return 0 }
        let rawIndex = pageCollectionView.contentOffset.x / pageCollectionView.bounds.width
        let index = Int(round(rawIndex))
        return max(0, min(index, flattenedPages.count - 1))
    }
}
