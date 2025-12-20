import UIKit

/// Demo 列表入口
///
/// 以列表展示所有可用示例，点击后进入对应的示例页面。
final class DemoListViewController: UITableViewController {

    private struct DemoItem {
        let title: String
        let subtitle: String
        let builder: () -> UIViewController
    }

    private lazy var demos: [DemoItem] = [
        DemoItem(
            title: "Pager - 多分类内容流",
            subtitle: "MultiCategoryPagerView + PageableViewModel 示例",
            builder: { PagerDemoViewController() }
        ),
        DemoItem(
            title: "Pageable - 列表容器",
            subtitle: "PageableViewModel + PageableViewContainer 示例",
            builder: { PageableDemoViewController() }
        ),
        DemoItem(
            title: "Liquid Glass - 玻璃效果",
            subtitle: "iOS 26+ UIGlassEffect 设计语言示例",
            builder: { LiquidDemoFactory.makeViewController() }
        )
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ViewPager Demos"
        tableView.rowHeight = 68
        tableView.tableFooterView = UIView()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DemoCell")

        let item = demos[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = demos[indexPath.row]
        let controller = item.builder()
        navigationController?.pushViewController(controller, animated: true)
    }
}
