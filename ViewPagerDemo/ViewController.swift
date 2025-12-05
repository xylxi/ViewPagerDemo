import UIKit
import SnapKit
import MJRefresh

final class ViewController: UIViewController {

    private lazy var menuProvider = DemoMenuProvider()
    private lazy var stateProvider = DemoPageStateProvider(dataStore: dataStore)
    private lazy var dataAdapter = DemoPageDataAdapter(dataStore: dataStore)
    private lazy var loadMoreProvider = DemoLoadMoreProvider(dataStore: dataStore) { [weak self] page in
        self?.loadMore(for: page)
    }
    private lazy var pagerView = MultiCategoryPagerView(menuProvider: menuProvider,
                                                        pagePresentationProvider: stateProvider,
                                                        pageDataRenderer: dataAdapter)

    /// 外部数据存储，组件不感知 state/items
    private let dataStore = DemoDataStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupPager()
        loadInitialData()
    }

    private func setupPager() {
        view.addSubview(pagerView)
        pagerView.selectionHandler = self
        pagerView.loadMoreProvider = loadMoreProvider
        pagerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func loadInitialData() {
        let snapshots = dataStore.makeInitialSnapshots()
        pagerView.apply(sections: snapshots, animated: false)
        simulateNetworkLoading()
    }

    private func simulateNetworkLoading() {
        for (index, pageId) in dataStore.allPageIds.enumerated() {
            let delay = DispatchTime.now() + .seconds(2)
            DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
                guard let self else { return }
                switch index {
                case 1:
                    self.dataStore.update(pageId: pageId, state: .empty, items: [])
                case 2:
                    self.dataStore.update(pageId: pageId, state: .failed(message: "网络异常，请稍后重试"), items: [])
                default:
                    let items = self.dataStore.makeItems(for: pageId)
                    self.dataStore.update(pageId: pageId, state: .loaded, items: items)
                }
                // 通知 pagerView 刷新（触发 cell 重新配置）
                self.pagerView.update(pageId: pageId) { _ in }
            }
        }
    }
    
    private func loadMore(for page: PageModel) {
        let pageId = page.pageId
        
        // MJRefresh 触发回调时已自动进入 refreshing 状态，直接进行网络请求
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            
            // 获取更多数据
            let newItems = self.dataStore.makeMoreItems(for: pageId)
            
            // 模拟：加载 3 次后没有更多数据
            let currentPage = self.dataStore.pageData(for: pageId)?.currentPage ?? 0
            let hasMore = currentPage < 2
            
            // 更新数据
            self.dataStore.appendItems(pageId: pageId, newItems: newItems, hasMore: hasMore)
            
            // 刷新数据列表（保持滚动位置，避免回弹）
            self.pagerView.reloadPageData(pageId: pageId)
            
            // 结束加载，更新 footer 状态
            self.loadMoreProvider.endRefreshing(for: pageId, hasMore: hasMore)
            
            print("Loaded more items for \(pageId), hasMore: \(hasMore)")
        }
    }
}

extension ViewController: PagerMenuSelectionHandling {
    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect page: PageModel, at index: Int) {
        print("Selected page \(page.pageId) at index \(index)")
    }
}

// MARK: - Demo Data Store

/// 外部数据存储：管理 state 和 items，组件只负责驱动渲染
final class DemoDataStore {
    
    enum PageState {
        case loading
        case empty
        case failed(message: String)
        case loaded
    }
    
    struct PageData {
        var state: PageState = .loading
        var items: [PageItemModel] = []
        var hasMore: Bool = true           // 是否还有更多数据
        var currentPage: Int = 0           // 当前页码
    }
    
    private(set) var categories: [DemoCategoryMeta] = []
    private var pageDataMap: [AnyHashable: PageData] = [:]
    
    var allPageIds: [AnyHashable] {
        categories.map { $0.id }
    }
    
    func makeInitialSnapshots() -> [PagerSectionSnapshot] {
        categories = [
            DemoCategoryMeta(id: "news", title: "热点", accentColor: .systemOrange),
            DemoCategoryMeta(id: "sport", title: "体育", accentColor: .systemGreen),
            DemoCategoryMeta(id: "tech", title: "科技", accentColor: .systemBlue),
            DemoCategoryMeta(id: "finance", title: "财经", accentColor: .systemPurple),
            DemoCategoryMeta(id: "travel", title: "旅行", accentColor: .systemTeal),
            DemoCategoryMeta(id: "food", title: "美食", accentColor: .systemRed),
            DemoCategoryMeta(id: "movie", title: "影视", accentColor: .systemIndigo),
            DemoCategoryMeta(id: "game", title: "游戏", accentColor: .systemPink),
            DemoCategoryMeta(id: "auto", title: "汽车", accentColor: .systemYellow),
            DemoCategoryMeta(id: "fashion", title: "时尚", accentColor: .systemBrown)
        ]
        
        // 初始化 page data
        for category in categories {
            pageDataMap[category.id] = PageData()
        }
        
        let pages = categories.map { category in
            PageModel(pageId: category.id, userInfo: category)
        }
        return [PagerSectionSnapshot(section: PagerSection(id: "root"), pages: pages)]
    }
    
    func update(pageId: AnyHashable, state: PageState, items: [PageItemModel]) {
        pageDataMap[pageId]?.state = state
        pageDataMap[pageId]?.items = items
    }
    
    func pageData(for pageId: AnyHashable) -> PageData? {
        pageDataMap[pageId]
    }
    
    func category(for pageId: AnyHashable) -> DemoCategoryMeta? {
        categories.first { $0.id == pageId as? String }
    }
    
    func makeItems(for pageId: AnyHashable) -> [PageItemModel] {
        guard let category = category(for: pageId) else { return [] }
        let feeds = (0..<20).map { index -> DemoFeedItem in
            DemoFeedItem(title: "\(category.title) Item \(index + 1)",
                         subtitle: "示例描述第 \(index + 1) 行，展示多分类数据流效果。")
        }
        return feeds.map { PageItemModel(id: $0.id, payload: $0) }
    }
    
    // MARK: - Load More Support
    
    func appendItems(pageId: AnyHashable, newItems: [PageItemModel], hasMore: Bool) {
        pageDataMap[pageId]?.items.append(contentsOf: newItems)
        pageDataMap[pageId]?.hasMore = hasMore
        pageDataMap[pageId]?.currentPage += 1
    }
    
    func makeMoreItems(for pageId: AnyHashable) -> [PageItemModel] {
        guard let category = category(for: pageId),
              let pageData = pageDataMap[pageId] else { return [] }
        let startIndex = pageData.items.count
        let feeds = (0..<10).map { index -> DemoFeedItem in
            DemoFeedItem(title: "\(category.title) Item \(startIndex + index + 1)",
                         subtitle: "加载更多示例第 \(startIndex + index + 1) 行。")
        }
        return feeds.map { PageItemModel(id: $0.id, payload: $0) }
    }
}

// MARK: - Demo Menu

final class DemoMenuProvider: PagerMenuContentProviding {
    func registerMenuCells(in collectionView: UICollectionView) {
        collectionView.register(DemoMenuCell.self, forCellWithReuseIdentifier: DemoMenuCell.reuseIdentifier)
    }

    func pagerMenuCollectionView(_ collectionView: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DemoMenuCell.reuseIdentifier, for: indexPath) as? DemoMenuCell else {
            return UICollectionViewCell()
        }
        let meta = page.userInfo as? DemoCategoryMeta
        cell.configure(title: meta?.title ?? "分类\(indexPath.item + 1)", accentColor: meta?.accentColor ?? .systemGray)
        return cell
    }

    func pagerMenuCollectionView(_ collectionView: UICollectionView, sizeFor page: PageModel, at indexPath: IndexPath) -> CGSize {
        CGSize(width: 96, height: collectionView.bounds.height - 12)
    }

    func menuContentInsets(for collectionView: UICollectionView) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

final class DemoMenuCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoMenuCell"

    private let titleLabel = UILabel()
    private let indicator = UIView()
    private var accentColor: UIColor = .systemBlue

    override var isSelected: Bool {
        didSet { updateSelectionAppearance() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemGray5

        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textAlignment = .center

        indicator.layer.cornerRadius = 1.5
        indicator.backgroundColor = accentColor

        contentView.addSubview(titleLabel)
        contentView.addSubview(indicator)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        indicator.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(24)
            make.height.equalTo(3)
        }
        updateSelectionAppearance()
    }

    func configure(title: String, accentColor: UIColor) {
        titleLabel.text = title
        self.accentColor = accentColor
        indicator.backgroundColor = accentColor
        updateSelectionAppearance()
    }

    private func updateSelectionAppearance() {
        contentView.backgroundColor = isSelected ? accentColor.withAlphaComponent(0.15) : UIColor.systemGray5
        indicator.isHidden = !isSelected
        titleLabel.textColor = isSelected ? accentColor : .label
    }
}

// MARK: - Demo Page State

final class DemoPageStateProvider: PagerPagePresentationProviding {
    
    private weak var dataStore: DemoDataStore?
    
    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }
    
    func registerPageStateCells(in collectionView: UICollectionView) {
        collectionView.register(DemoPageStateCell.self, forCellWithReuseIdentifier: DemoPageStateCell.reuseIdentifier)
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, pageContainer: UICollectionView, cellFor page: PageModel, at indexPath: IndexPath) -> UICollectionViewCell? {
        guard let pageData = dataStore?.pageData(for: page.pageId) else { return nil }
        
        switch pageData.state {
        case .loaded:
            // 返回 nil 表示展示数据列表
            return nil
        case .loading, .empty, .failed:
            guard let cell = pageContainer.dequeueReusableCell(withReuseIdentifier: DemoPageStateCell.reuseIdentifier, for: indexPath) as? DemoPageStateCell else {
                return nil
            }
            cell.render(state: pageData.state)
            return cell
        }
    }
}

final class DemoPageStateCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoPageStateCell"

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
    }

    func render(state: DemoDataStore.PageState) {
        switch state {
        case .loading:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            titleLabel.text = "加载中..."
            subtitleLabel.text = "正在获取数据，请稍候"
        case .empty:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = "暂无内容"
            subtitleLabel.text = "可以稍后再试或更换分类"
        case .failed(let message):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = "加载失败"
            subtitleLabel.text = message
        case .loaded:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            titleLabel.text = nil
            subtitleLabel.text = nil
        }
    }
}

// MARK: - Demo Page Data

final class DemoPageDataAdapter: PagerPageDataRendering {
    
    private weak var dataStore: DemoDataStore?
    
    init(dataStore: DemoDataStore) {
        self.dataStore = dataStore
    }
    
    func registerDataCells(in collectionView: UICollectionView) {
        collectionView.register(DemoFeedCell.self, forCellWithReuseIdentifier: DemoFeedCell.reuseIdentifier)
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, layoutFor page: PageModel) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(80))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func pagerView(_ pagerView: MultiCategoryPagerView, itemsFor page: PageModel) -> [PageItemModel] {
        dataStore?.pageData(for: page.pageId)?.items ?? []
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, collectionView: UICollectionView, cellFor item: PageItemModel, at indexPath: IndexPath, page: PageModel) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DemoFeedCell.reuseIdentifier, for: indexPath) as? DemoFeedCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: item.payload as? DemoFeedItem)
        return cell
    }

    func pagerView(_ pagerView: MultiCategoryPagerView, didSelect item: PageItemModel, at indexPath: IndexPath, page: PageModel) {
        let feedTitle = (item.payload as? DemoFeedItem)?.title ?? ""
        print("Tapped feed \(feedTitle) under page \(page.pageId)")
    }
}

final class DemoFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "DemoFeedCell"

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(containerView)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.backgroundColor = UIColor.secondarySystemBackground

        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        containerView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(with item: DemoFeedItem?) {
        titleLabel.text = item?.title ?? "未命名 Item"
        subtitleLabel.text = item?.subtitle ?? ""
    }
}

// MARK: - Demo Load More Provider

final class DemoLoadMoreProvider: PagerLoadMoreProviding {
    
    private weak var dataStore: DemoDataStore?
    private var loadMoreHandler: ((PageModel) -> Void)?
    
    /// Footer 缓存：pageId -> footer，避免重复创建
    private var footerCache: [AnyHashable: MJRefreshAutoNormalFooter] = [:]
    
    init(dataStore: DemoDataStore, loadMoreHandler: @escaping (PageModel) -> Void) {
        self.dataStore = dataStore
        self.loadMoreHandler = loadMoreHandler
    }
    
    func pagerView(_ pagerView: MultiCategoryPagerView,
                   loadMoreFooterFor page: PageModel) -> MJRefreshFooter? {
        guard let pageData = dataStore?.pageData(for: page.pageId) else {
            return nil
        }
        
        // 只有 loaded 状态且有数据时才返回 footer
        guard case .loaded = pageData.state, !pageData.items.isEmpty else {
            return nil
        }
        
        // 获取或创建 footer
        let footer = footerCache[page.pageId] ?? createFooter(for: page)
        
        // 根据 hasMore 状态配置 footer（仅在 cell 首次配置时生效）
        if !pageData.hasMore {
            footer.endRefreshingWithNoMoreData()
        }
        
        return footer
    }
    
    /// 结束加载更多，更新 footer 状态
    func endRefreshing(for pageId: AnyHashable, hasMore: Bool) {
        guard let footer = footerCache[pageId] else { return }
        if hasMore {
            footer.endRefreshing()
        } else {
            footer.endRefreshingWithNoMoreData()
        }
    }
    
    private func createFooter(for page: PageModel) -> MJRefreshAutoNormalFooter {
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.loadMoreHandler?(page)
        }
        footer.setTitle("上拉加载更多", for: .idle)
        footer.setTitle("正在加载...", for: .refreshing)
        footer.setTitle("— 已经到底了 —", for: .noMoreData)
        footer.stateLabel?.font = UIFont.systemFont(ofSize: 14)
        footer.stateLabel?.textColor = .secondaryLabel
        
        footerCache[page.pageId] = footer
        return footer
    }
}

// MARK: - Demo Models

struct DemoCategoryMeta {
    let id: String
    let title: String
    let accentColor: UIColor
}

struct DemoFeedItem: Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
}
