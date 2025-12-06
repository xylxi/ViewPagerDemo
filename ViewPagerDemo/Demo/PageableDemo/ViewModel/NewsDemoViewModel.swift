import Foundation
import Combine

/// 新闻 Demo 主 ViewModel
///
/// 管理场景切换和对应的 PageableViewModel 创建
@MainActor
final class NewsDemoViewModel: ObservableObject {

    // MARK: - Scenario

    /// 演示场景
    enum Scenario: Int, CaseIterable {
        case normal = 0
        case error
        case empty

        var title: String {
            switch self {
            case .normal: return "正常加载"
            case .error: return "错误重试"
            case .empty: return "空数据"
            }
        }

        var description: String {
            switch self {
            case .normal:
                return "分页加载 + 下拉刷新 + 加载更多的基础示例。"
            case .error:
                return "前两次请求失败，第三次成功，演示失败态与重试。"
            case .empty:
                return "返回空数据，演示空态处理。"
            }
        }
    }

    // MARK: - Published Properties

    /// 当前场景
    @Published private(set) var currentScenario: Scenario = .normal

    /// 当前场景的分页 ViewModel
    @Published private(set) var pageableViewModel: PageableViewModel<NewsItem, Int>?

    // MARK: - Public Methods

    /// 切换场景
    ///
    /// - Parameter scenario: 目标场景
    func switchScenario(_ scenario: Scenario) {
        currentScenario = scenario
        pageableViewModel = createPageableViewModel(for: scenario)
        pageableViewModel?.loadInitial()
    }

    /// 初始化加载
    func load() {
        switchScenario(currentScenario)
    }

    // MARK: - Private Methods

    private func createPageableViewModel(for scenario: Scenario) -> PageableViewModel<NewsItem, Int> {
        let service = createService(for: scenario)

        return PageableViewModel<NewsItem, Int>(initialCursor: 0) { page in
            try await service.fetchNews(page: page)
        }
    }

    private func createService(for scenario: Scenario) -> NewsService {
        switch scenario {
        case .normal:
            return NewsService(mode: .normal)
        case .error:
            return NewsService(mode: .error(failCount: 2))
        case .empty:
            return NewsService(mode: .empty)
        }
    }
}
