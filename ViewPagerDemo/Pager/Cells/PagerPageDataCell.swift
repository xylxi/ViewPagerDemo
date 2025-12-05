import UIKit
import SnapKit
import MJRefresh

/// 数据页面 Cell
///
/// 用于展示数据列表的 page cell，内嵌一个垂直滚动的 UICollectionView
///
/// 职责：
/// - 管理内部的数据列表 CollectionView
/// - 通过协议从外部获取数据和 cell
/// - 缓存和恢复滚动位置
/// - 支持加载更多功能
/// - 触发 item 曝光回调
final class PagerPageDataCell: UICollectionViewCell, UICollectionViewDelegate {
    
    static let reuseIdentifier = "PagerPageDataCell"

    // MARK: - UI Components

    /// 内部数据列表 CollectionView
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

    // MARK: - Private Properties

    /// 内部数据源
    private var dataSource: UICollectionViewDiffableDataSource<Int, PageItemModel>?
    
    /// 父级 pagerView 引用
    private weak var pagerView: MultiCategoryPagerView?
    
    /// 数据渲染适配器
    private weak var adapter: PagerPageDataRendering?
    
    /// 滚动位置缓存
    private weak var scrollCache: PageScrollCache?
    
    /// 加载更多提供者
    private weak var loadMoreProvider: PagerLoadMoreProviding?
    
    /// 当前展示的 page
    private var currentPage: PageModel?
    
    /// 当前数据项数组
    private var currentItems: [PageItemModel] = []
    
    /// 是否已注册 cell
    private var hasRegistered = false
    
    /// 标志位：正在恢复 offset 期间
    ///
    /// 用途：
    /// - 期间不写入滚动缓存（避免中间状态污染）
    /// - 期间不触发 item 曝光（避免错误曝光）
    private var isRestoringOffset = false

    // MARK: - Initialization

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

    // MARK: - Cell Lifecycle

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

    // MARK: - Configuration

    /// 配置 cell
    ///
    /// 配置流程：
    /// 1. 保存依赖引用
    /// 2. 注册数据 cell（仅首次）
    /// 3. 设置布局
    /// 4. 获取数据并渲染
    /// 5. 配置加载更多 footer
    /// 6. 恢复滚动位置
    /// 7. 触发可见 items 曝光
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

        // 仅首次注册 cell
        if !hasRegistered {
            adapter.registerDataCells(in: collectionView)
            hasRegistered = true
        }

        // 开启恢复标志，避免 layout/snapshot 变化触发的 scroll 污染缓存
        isRestoringOffset = true

        // 设置布局
        let layout = adapter.pagerView(pagerView, layoutFor: page)
        collectionView.setCollectionViewLayout(layout, animated: false)
        ensureDataSource(adapter: adapter, pagerView: pagerView)

        // 获取数据
        let items = adapter.pagerView(pagerView, itemsFor: page)
        currentItems = items
        
        // 配置加载更多 footer
        configureLoadMoreFooter(for: page, pagerView: pagerView)
        
        // 应用数据并恢复滚动位置
        let cachedOffset = scrollCache.offset(for: page.pageId)
        apply(items: items, animated: false) { [weak self] in
            self?.restoreContentOffset(cachedOffset, for: page)
        }
    }
    
    /// 配置加载更多 footer
    private func configureLoadMoreFooter(for page: PageModel, pagerView: MultiCategoryPagerView) {
        guard let provider = loadMoreProvider else {
            collectionView.mj_footer = nil
            return
        }
        
        // 外部提供已配置好状态的 footer（可能为 nil）
        collectionView.mj_footer = provider.pagerView(pagerView, loadMoreFooterFor: page)
    }

    /// 确保数据源已创建
    private func ensureDataSource(adapter: PagerPageDataRendering, pagerView: MultiCategoryPagerView) {
        if dataSource != nil { return }
        dataSource = UICollectionViewDiffableDataSource<Int, PageItemModel>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self, let currentPage = self.currentPage else { return UICollectionViewCell() }
            return adapter.pagerView(pagerView, collectionView: collectionView, cellFor: item, at: indexPath, page: currentPage)
        }
    }

    /// 应用数据快照
    private func apply(items: [PageItemModel], animated: Bool, completion: (() -> Void)? = nil) {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, PageItemModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animated)
        // 确保在主线程下一个 runloop 执行 completion
        DispatchQueue.main.async { [weak self] in
            guard let _ = self else { return }
            completion?()
        }
    }

    /// 恢复滚动位置
    private func restoreContentOffset(_ cachedOffset: CGPoint?, for page: PageModel) {
        guard let currentPage, currentPage.pageId == page.pageId else {
            isRestoringOffset = false
            return
        }
        collectionView.layoutIfNeeded()
        let target = cachedOffset ?? .zero
        collectionView.setContentOffset(target, animated: false)
        // 恢复完成，关闭标志
        isRestoringOffset = false
        
        // 主动触发当前可见 items 的曝光
        // 因为在 isRestoringOffset = true 期间，willDisplay 中的曝光被跳过了
        emitVisibleItemsExposure()
    }
    
    /// 触发当前可见 items 的曝光
    private func emitVisibleItemsExposure() {
        guard let pagerView, let currentPage else { return }
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        for indexPath in visibleIndexPaths {
            guard indexPath.item < currentItems.count else { continue }
            let item = currentItems[indexPath.item]
            pagerView.itemExposureHandler?.pagerView(pagerView, didExposeItem: item, at: indexPath, page: currentPage)
        }
    }
    
    // MARK: - Public Methods

    /// 重新加载数据，保持当前滚动位置
    ///
    /// 适用场景：加载更多数据后刷新列表，避免滚动位置重置
    func reloadData() {
        guard let pagerView, let adapter, let currentPage else { return }
        
        // 获取最新数据
        let items = adapter.pagerView(pagerView, itemsFor: currentPage)
        currentItems = items
        
        // 增量更新，不改变滚动位置
        apply(items: items, animated: false, completion: nil)
    }

    // MARK: - UICollectionViewDelegate

    /// item 点击
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
    
    /// item 即将显示（用于曝光）
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 恢复 offset 期间不触发曝光
        guard
            !isRestoringOffset,
            let pagerView,
            let currentPage,
            indexPath.item < currentItems.count
        else { return }
        let item = currentItems[indexPath.item]
        pagerView.itemExposureHandler?.pagerView(pagerView, didExposeItem: item, at: indexPath, page: currentPage)
    }

    /// 滚动时更新缓存
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 恢复期间不写入缓存，避免中间状态污染
        guard !isRestoringOffset, let pageId = currentPage?.pageId else { return }
        scrollCache?.set(offset: scrollView.contentOffset, for: pageId)
    }
}
