import UIKit
import SnapKit
import Combine

/// PageableViewModel + PageableViewContainer 演示页
///
/// 提供三种场景：正常加载、错误重试、空数据。
final class PageableDemoViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = NewsDemoViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let scenarioControl: UISegmentedControl = {
        let items = NewsDemoViewModel.Scenario.allCases.map { $0.title }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let containerHost = UIView()
    private var currentContainer: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.load()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Pageable Demo"
        view.backgroundColor = .systemBackground

        scenarioControl.addTarget(self, action: #selector(scenarioChanged), for: .valueChanged)

        view.addSubview(scenarioControl)
        view.addSubview(descriptionLabel)
        view.addSubview(containerHost)

        scenarioControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(scenarioControl.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        containerHost.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        // 绑定场景描述
        viewModel.$currentScenario
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scenario in
                self?.descriptionLabel.text = scenario.description
            }
            .store(in: &cancellables)

        // 绑定 PageableViewModel 变化
        viewModel.$pageableViewModel
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] pageableVM in
                self?.updateContainer(with: pageableVM)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func scenarioChanged() {
        guard let scenario = NewsDemoViewModel.Scenario(rawValue: scenarioControl.selectedSegmentIndex) else {
            return
        }
        viewModel.switchScenario(scenario)
    }

    // MARK: - Private Methods

    private func updateContainer(with pageableVM: PageableViewModel<NewsItem, Int>) {
        // 移除旧容器
        currentContainer?.removeFromSuperview()

        // 创建新容器
        let container = PageableViewContainer(
            viewModel: pageableVM,
            cellConfigurator: NewsCellConfigurator(),
            stateViewProvider: NewsStateViewProvider(),
            selectionHandler: NewsSelectionHandler()
        )

        containerHost.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        currentContainer = container
    }
}

// MARK: - Selection Handler

/// 新闻选中处理器
final class NewsSelectionHandler: PageableItemSelectionHandling {
    func didSelectItem(_ item: NewsItem, at indexPath: IndexPath) {
        print("选中新闻：\(item.title)")
    }
}
