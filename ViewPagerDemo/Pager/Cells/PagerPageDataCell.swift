#if canImport(UIKit)
import UIKit
import SnapKit
import MJRefresh

final class PagerPageDataCell: UICollectionViewCell, UICollectionViewDelegate {
    static let reuseIdentifier = "PagerPageDataCell"

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        // 避免系统自动调整 contentInset，防止 offset 位置偏移
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Int, PageItemModel>?
    private weak var pagerView: MultiCategoryPagerView?
    private weak var adapter: PagerPageDataRendering?
    private weak var scrollCache: PageScrollCache?
    private weak var loadMoreProvider: PagerLoadMoreProviding?
    private var currentPage: PageModel?
    private var currentItems: [PageItemModel] = []
    private var hasRegistered = false
    /// 标志位：正在恢复 offset 期间不写入缓存，防止中间状态污染
    private var isRestoringOffset = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        collectionView.delegate = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置前开启标志，避免 setContentOffset 触发的 scroll 写入缓存
        isRestoringOffset = true
        currentPage = nil
        currentItems = []
        adapter = nil
        pagerView = nil
        loadMoreProvider = nil
        // 重置 footer
        collectionView.mj_footer?.resetNoMoreData()
        collectionView.mj_footer = nil
        collectionView.setContentOffset(.zero, animated: false)
        isRestoringOffset = false
    }

    func configure(with page: PageModel,
                   pagerView: MultiCategoryPagerView,
                   adapter: PagerPageDataRendering,
                   scrollCache: PageScrollCache,
                   loadMoreProvider: PagerLoadMoreProviding?) {
        self.pagerView = pagerView
        self.adapter = adapter
        self.scrollCache = scrollCache
        self.loadMoreProvider = loadMoreProvider
        currentPage = page

        if !hasRegistered {
            adapter.registerDataCells(in: collectionView)
            hasRegistered = true
        }

        // 在配置期间开启恢复标志，避免 layout/snapshot 变化触发的 scroll 污染缓存
        isRestoringOffset = true

        let layout = adapter.pagerView(pagerView, layoutFor: page)
        collectionView.setCollectionViewLayout(layout, animated: false)
        ensureDataSource(adapter: adapter, pagerView: pagerView)

        // 通过协议获取 items，组件不持有数据
        let items = adapter.pagerView(pagerView, itemsFor: page)
        currentItems = items
        
        // 配置加载更多 footer
        configureLoadMoreFooter(for: page, pagerView: pagerView)
        
        let cachedOffset = scrollCache.offset(for: page.pageId)
        apply(items: items, animated: false) { [weak self] in
            self?.restoreContentOffset(cachedOffset, for: page)
        }
    }
    
    private func configureLoadMoreFooter(for page: PageModel, pagerView: MultiCategoryPagerView) {
        guard let provider = loadMoreProvider else {
            collectionView.mj_footer = nil
            return
        }
        
        // 外部提供已配置好状态的 footer（可能为 nil）
        collectionView.mj_footer = provider.pagerView(pagerView, loadMoreFooterFor: page)
    }

    private func ensureDataSource(adapter: PagerPageDataRendering, pagerView: MultiCategoryPagerView) {
        if dataSource != nil { return }
        dataSource = UICollectionViewDiffableDataSource<Int, PageItemModel>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self, let currentPage = self.currentPage else { return UICollectionViewCell() }
            return adapter.pagerView(pagerView, collectionView: collectionView, cellFor: item, at: indexPath, page: currentPage)
        }
    }

    private func apply(items: [PageItemModel], animated: Bool, completion: (() -> Void)? = nil) {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, PageItemModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animated)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            completion?()
        }
    }

    private func restoreContentOffset(_ cachedOffset: CGPoint?, for page: PageModel) {
        guard let currentPage, currentPage.pageId == page.pageId else {
            isRestoringOffset = false
            return
        }
        collectionView.layoutIfNeeded()
        let target = cachedOffset ?? .zero
        collectionView.setContentOffset(target, animated: false)
        // 恢复完成后关闭标志，允许用户滚动写入缓存
        isRestoringOffset = false
#if DEBUG
        if let cachedOffset {
            print("PagerPageDataCell reuse → restored offset \(cachedOffset) for pageId: \(page.pageId)")
        } else {
            print("PagerPageDataCell reuse → reset offset to .zero for pageId: \(page.pageId)")
        }
#endif
    }
    
    // MARK: - Public Reload (保持滚动位置)
    
    /// 重新加载数据，保持当前滚动位置（用于加载更多等场景）
    func reloadData() {
        guard let pagerView, let adapter, let currentPage else { return }
        
        // 获取最新数据
        let items = adapter.pagerView(pagerView, itemsFor: currentPage)
        currentItems = items
        
        // 增量更新，不改变滚动位置
        apply(items: items, animated: false, completion: nil)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let pagerView,
            let adapter,
            let currentPage,
            indexPath.item < currentItems.count
        else { return }
        let item = currentItems[indexPath.item]
        adapter.pagerView(pagerView, didSelect: item, at: indexPath, page: currentPage)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 恢复期间不写入缓存，避免中间状态污染
        guard !isRestoringOffset, let pageId = currentPage?.pageId else { return }
        scrollCache?.set(offset: scrollView.contentOffset, for: pageId)
#if DEBUG
        print("PagerPageDataCell scroll → cache offset \(scrollView.contentOffset) for pageId: \(pageId)")
#endif
    }
}
#endif
