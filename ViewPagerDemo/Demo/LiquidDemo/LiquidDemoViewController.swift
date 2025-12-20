import UIKit
import SnapKit

/// Liquid Glass 效果演示
///
/// 展示 iOS 26+ 引入的 Liquid Glass 设计语言，包括：
/// - 玻璃容器效果（不同变体）
/// - 动态模糊与光泽
/// - 交互式玻璃组件
/// - Tab Bar / Navigation Bar 样式
/// - 玻璃组件组合
@available(iOS 26.0, *)
final class LiquidDemoViewController: UIViewController {

    // MARK: - Properties

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 28
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.systemCyan.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemPurple.cgColor,
            UIColor.systemPink.cgColor,
            UIColor.systemOrange.cgColor
        ]
        layer.locations = [0.0, 0.25, 0.5, 0.75, 1.0]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()

    private var animatedViews: [UIView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDemoSections()
        startBackgroundAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = backgroundImageView.bounds
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Liquid Glass"
        view.backgroundColor = .systemBackground

        // 背景
        view.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(gradientLayer)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 滚动视图
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 内容 StackView
        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    private func setupDemoSections() {
        // 1. Glass Style 样式对比
        addSection(title: "Glass Style 样式", description: ".regular vs .clear 效果对比") {
            self.createGlassStyleComparison()
        }

        // 2. Tint 色调效果
        addSection(title: "Glass Tint 色调", description: "使用 tint 添加语义化颜色") {
            self.createGlassTintDemo()
        }

        // 3. Interactive 交互效果
        addSection(title: "Interactive 交互", description: "启用 isInteractive 的按压反馈效果") {
            self.createInteractiveGlassDemo()
        }

        // 4. 基础玻璃效果变体
        addSection(title: "基础玻璃效果", description: "UIGlassEffect 的不同呈现方式") {
            self.createBasicGlassVariants()
        }

        // 5. 玻璃样式按钮
        addSection(title: "玻璃按钮", description: "带有 Liquid Glass 效果的交互按钮") {
            self.createGlassButtons()
        }

        // 3. 圆形玻璃图标
        addSection(title: "圆形玻璃图标", description: "App 图标风格的圆形玻璃效果") {
            self.createCircularGlassIcons()
        }

        // 4. 玻璃卡片
        addSection(title: "玻璃卡片", description: "信息展示卡片") {
            self.createGlassCard()
        }

        // 5. 玻璃 Tab Bar
        addSection(title: "玻璃 Tab Bar", description: "iOS 26 风格的底部导航") {
            self.createGlassTabBar()
        }

        // 6. 玻璃分段控制器
        addSection(title: "玻璃分段控制", description: "带有玻璃背景的分段选择器") {
            self.createGlassSegmentedControl()
        }

        // 7. 玻璃输入框
        addSection(title: "玻璃输入框", description: "带有玻璃效果的搜索框") {
            self.createGlassTextField()
        }

        // 8. 玻璃进度条和滑块
        addSection(title: "玻璃进度控件", description: "音量/亮度调节风格") {
            self.createGlassProgressControls()
        }

        // 9. 玻璃开关
        addSection(title: "玻璃开关", description: "设置选项风格") {
            self.createGlassToggles()
        }

        // 10. 玻璃列表
        addSection(title: "玻璃列表", description: "透明列表项") {
            self.createGlassList()
        }

        // 11. 玻璃悬浮按钮
        addSection(title: "悬浮操作按钮", description: "FAB 风格的玻璃按钮") {
            self.createFloatingActionButtons()
        }

        // 12. 玻璃工具栏
        addSection(title: "玻璃工具栏", description: "底部工具栏风格") {
            self.createGlassToolbar()
        }

        // 13. 玻璃弹出菜单
        addSection(title: "玻璃弹出菜单", description: "上下文菜单风格") {
            self.createGlassContextMenu()
        }

        // 14. 玻璃通知样式
        addSection(title: "玻璃通知", description: "通知横幅风格") {
            self.createGlassNotification()
        }

        // 15. 嵌套玻璃效果
        addSection(title: "嵌套玻璃", description: "多层玻璃叠加效果") {
            self.createNestedGlass()
        }
    }

    private func startBackgroundAnimation() {
        // 动态渐变动画
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = [
            UIColor.systemOrange.cgColor,
            UIColor.systemPink.cgColor,
            UIColor.systemPurple.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemCyan.cgColor
        ]
        animation.duration = 5.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")
    }

    // MARK: - Section Builder

    private func addSection(title: String, description: String, contentBuilder: () -> UIView) {
        let sectionContainer = UIStackView()
        sectionContainer.axis = .vertical
        sectionContainer.spacing = 12
        sectionContainer.alignment = .fill

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowOpacity = 0.3
        titleLabel.layer.shadowRadius = 2

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .white.withAlphaComponent(0.8)
        descLabel.layer.shadowColor = UIColor.black.cgColor
        descLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        descLabel.layer.shadowOpacity = 0.2
        descLabel.layer.shadowRadius = 1

        sectionContainer.addArrangedSubview(titleLabel)
        sectionContainer.addArrangedSubview(descLabel)
        sectionContainer.addArrangedSubview(contentBuilder())

        contentStackView.addArrangedSubview(sectionContainer)
    }

    // MARK: - Demo Components

    // MARK: Glass Style 样式对比

    /// Glass Style: .regular vs .clear
    private func createGlassStyleComparison() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16

        // Regular Style
        let regularContainer = createStyledGlassView(
            style: .regular,
            title: ".regular",
            description: "标准玻璃效果，中等透明度\n适用于：工具栏、按钮、导航栏、Tab Bar"
        )

        // Clear Style
        let clearContainer = createStyledGlassView(
            style: .clear,
            title: ".clear",
            description: "高透明度玻璃效果\n适用于：照片/地图上的浮动控件"
        )

        // Side by side comparison
        let comparisonStack = UIStackView()
        comparisonStack.axis = .horizontal
        comparisonStack.spacing = 12
        comparisonStack.distribution = .fillEqually

        let regularButton = createStyleButton(style: .regular, label: "Regular")
        let clearButton = createStyleButton(style: .clear, label: "Clear")

        comparisonStack.addArrangedSubview(regularButton)
        comparisonStack.addArrangedSubview(clearButton)

        container.addArrangedSubview(regularContainer)
        container.addArrangedSubview(clearContainer)
        container.addArrangedSubview(comparisonStack)

        return container
    }

    private func createStyledGlassView(style: UIGlassEffect.Style, title: String, description: String) -> UIView {
        let glassEffect = UIGlassEffect(style: style)
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 20
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.alignment = .leading

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label

        let styleTag = UILabel()
        styleTag.text = style == .regular ? "默认" : "高透明"
        styleTag.font = .systemFont(ofSize: 12, weight: .medium)
        styleTag.textColor = .white
        styleTag.backgroundColor = style == .regular ? .systemBlue : .systemPurple
        styleTag.layer.cornerRadius = 8
        styleTag.clipsToBounds = true
        styleTag.textAlignment = .center
        styleTag.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.height.equalTo(22)
        }

        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(styleTag)

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0

        container.addArrangedSubview(headerStack)
        container.addArrangedSubview(descLabel)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        }

        return glassView
    }

    private func createStyleButton(style: UIGlassEffect.Style, label: String) -> UIView {
        let glassEffect = UIGlassEffect(style: style)
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let iconName = style == .regular ? "circle.fill" : "circle.dashed"
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = style == .regular ? .systemBlue : .systemPurple
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(28)
        }

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)

        glassView.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16))
        }

        return glassView
    }

    // MARK: Glass Tint 色调

    /// Glass Tint 色调效果
    private func createGlassTintDemo() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 12

        // 说明文字
        let infoGlass = UIGlassEffect()
        let infoView = UIVisualEffectView(effect: infoGlass)
        infoView.layer.cornerRadius = 16
        infoView.clipsToBounds = true

        let infoLabel = UILabel()
        infoLabel.text = "Tint 用于传达语义含义，如主要操作、状态指示器\n建议仅用于关键的 Call-to-Action 元素"
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0

        infoView.contentView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        // Tint 按钮组
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually

        let tintColors: [(UIColor, String, String)] = [
            (.systemBlue, "主要", "checkmark.circle.fill"),
            (.systemGreen, "成功", "checkmark.seal.fill"),
            (.systemOrange, "警告", "exclamationmark.triangle.fill"),
            (.systemRed, "危险", "xmark.circle.fill")
        ]

        for (color, title, icon) in tintColors {
            let button = createTintedGlassButton(tintColor: color, title: title, iconName: icon)
            buttonStack.addArrangedSubview(button)
        }

        // 大型 Tint 卡片示例
        let cardStack = UIStackView()
        cardStack.axis = .horizontal
        cardStack.spacing = 12
        cardStack.distribution = .fillEqually

        let primaryCard = createTintedGlassCard(
            tintColor: .systemBlue,
            title: "确认购买",
            subtitle: "¥99.00",
            iconName: "creditcard.fill"
        )

        let secondaryCard = createTintedGlassCard(
            tintColor: .systemGreen,
            title: "已完成",
            subtitle: "订单 #12345",
            iconName: "bag.fill.badge.checkmark"
        )

        cardStack.addArrangedSubview(primaryCard)
        cardStack.addArrangedSubview(secondaryCard)

        container.addArrangedSubview(infoView)
        container.addArrangedSubview(buttonStack)
        container.addArrangedSubview(cardStack)

        return container
    }

    private func createTintedGlassButton(tintColor: UIColor, title: String, iconName: String) -> UIView {
        let glassEffect = UIGlassEffect()
        glassEffect.tintColor = tintColor
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 14
        glassView.clipsToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = tintColor

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)

        glassView.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 8, bottom: 14, right: 8))
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(glassButtonTapped(_:)))
        glassView.addGestureRecognizer(tapGesture)
        glassView.isUserInteractionEnabled = true

        return glassView
    }

    private func createTintedGlassCard(tintColor: UIColor, title: String, subtitle: String, iconName: String) -> UIView {
        let glassEffect = UIGlassEffect()
        glassEffect.tintColor = tintColor
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 20
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 12
        container.alignment = .leading

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(subtitleLabel)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(glassButtonTapped(_:)))
        glassView.addGestureRecognizer(tapGesture)
        glassView.isUserInteractionEnabled = true

        return glassView
    }

    // MARK: Interactive 交互效果

    /// Interactive 交互效果演示
    private func createInteractiveGlassDemo() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16

        // 说明
        let infoGlass = UIGlassEffect()
        let infoView = UIVisualEffectView(effect: infoGlass)
        infoView.layer.cornerRadius = 16
        infoView.clipsToBounds = true

        let infoLabel = UILabel()
        infoLabel.text = "isInteractive = true 启用以下效果：\n• 按压时缩放动画\n• 弹跳反馈效果\n• 光泽闪烁效果\n• 触摸点辉光扩散"
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0

        infoView.contentView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        // 对比按钮
        let comparisonStack = UIStackView()
        comparisonStack.axis = .horizontal
        comparisonStack.spacing = 12
        comparisonStack.distribution = .fillEqually

        let nonInteractiveButton = createInteractiveComparisonButton(isInteractive: false)
        let interactiveButton = createInteractiveComparisonButton(isInteractive: true)

        comparisonStack.addArrangedSubview(nonInteractiveButton)
        comparisonStack.addArrangedSubview(interactiveButton)

        // Interactive 按钮网格
        let gridStack = UIStackView()
        gridStack.axis = .horizontal
        gridStack.spacing = 12
        gridStack.distribution = .fillEqually

        let actions: [(String, String, UIColor)] = [
            ("play.fill", "播放", .systemBlue),
            ("pause.fill", "暂停", .systemOrange),
            ("stop.fill", "停止", .systemRed),
            ("forward.fill", "快进", .systemGreen)
        ]

        for (icon, title, color) in actions {
            let button = createInteractiveActionButton(iconName: icon, title: title, tintColor: color)
            gridStack.addArrangedSubview(button)
        }

        container.addArrangedSubview(infoView)
        container.addArrangedSubview(comparisonStack)
        container.addArrangedSubview(gridStack)

        return container
    }

    private func createInteractiveComparisonButton(isInteractive: Bool) -> UIView {
        let glassEffect = UIGlassEffect()
        glassEffect.isInteractive = isInteractive
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 20
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: isInteractive ? "hand.tap.fill" : "hand.tap"))
        iconView.tintColor = isInteractive ? .systemBlue : .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        let titleLabel = UILabel()
        titleLabel.text = isInteractive ? "Interactive" : "Non-Interactive"
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = isInteractive ? "点击体验效果" : "无交互反馈"
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel

        let badge = UIView()
        badge.backgroundColor = isInteractive ? .systemGreen : .systemGray
        badge.layer.cornerRadius = 4
        badge.snp.makeConstraints { make in
            make.width.height.equalTo(8)
        }

        let statusStack = UIStackView()
        statusStack.axis = .horizontal
        statusStack.spacing = 6
        statusStack.alignment = .center
        statusStack.addArrangedSubview(badge)
        statusStack.addArrangedSubview(subtitleLabel)

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(statusStack)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16))
        }

        if isInteractive {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(interactiveButtonTapped(_:)))
            glassView.addGestureRecognizer(tapGesture)
            glassView.isUserInteractionEnabled = true
        }

        return glassView
    }

    private func createInteractiveActionButton(iconName: String, title: String, tintColor: UIColor) -> UIView {
        let glassEffect = UIGlassEffect()
        glassEffect.isInteractive = true
        glassEffect.tintColor = tintColor.withAlphaComponent(0.3)
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 11)
        label.textColor = .label

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)

        glassView.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8))
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(interactiveButtonTapped(_:)))
        glassView.addGestureRecognizer(tapGesture)
        glassView.isUserInteractionEnabled = true

        return glassView
    }

    @objc private func interactiveButtonTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }

        // 更强烈的交互反馈动画
        UIView.animate(withDuration: 0.08, animations: {
            view.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.4,
                initialSpringVelocity: 0.8,
                options: []
            ) {
                view.transform = .identity
            }
        }

        // 添加光泽闪烁效果
        // 需要添加到正确的容器：如果是 UIVisualEffectView 则添加到 contentView
        let shimmerView = UIView()
        shimmerView.backgroundColor = .white.withAlphaComponent(0.4)
        shimmerView.layer.cornerRadius = view.layer.cornerRadius
        shimmerView.clipsToBounds = true
        shimmerView.alpha = 0

        if let effectView = view as? UIVisualEffectView {
            shimmerView.frame = effectView.contentView.bounds
            effectView.contentView.addSubview(shimmerView)
        } else {
            shimmerView.frame = view.bounds
            view.addSubview(shimmerView)
        }

        UIView.animate(withDuration: 0.15, animations: {
            shimmerView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.25, animations: {
                shimmerView.alpha = 0
            }) { _ in
                shimmerView.removeFromSuperview()
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // MARK: 基础玻璃效果变体

    /// 4. 基础玻璃效果变体
    private func createBasicGlassVariants() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 12

        // 标准玻璃效果
        let standardGlass = createGlassContainer(label: "标准玻璃效果", cornerRadius: 20)

        // 圆角较大的玻璃效果
        let roundedGlass = createGlassContainer(label: "大圆角玻璃", cornerRadius: 32)

        // 直角玻璃效果
        let sharpGlass = createGlassContainer(label: "直角玻璃", cornerRadius: 4)

        container.addArrangedSubview(standardGlass)
        container.addArrangedSubview(roundedGlass)
        container.addArrangedSubview(sharpGlass)

        return container
    }

    private func createGlassContainer(label: String, cornerRadius: CGFloat) -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = cornerRadius
        glassView.clipsToBounds = true

        let contentLabel = UILabel()
        contentLabel.text = label
        contentLabel.textAlignment = .center
        contentLabel.font = .systemFont(ofSize: 16, weight: .medium)
        contentLabel.textColor = .label

        glassView.contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16))
        }

        return glassView
    }

    /// 2. 玻璃按钮组
    private func createGlassButtons() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.distribution = .fillEqually
        container.spacing = 12

        let buttonConfigs: [(String, UIColor, String)] = [
            ("star.fill", .systemYellow, "收藏"),
            ("heart.fill", .systemPink, "喜欢"),
            ("square.and.arrow.up", .systemBlue, "分享"),
            ("ellipsis", .white, "更多")
        ]

        for (iconName, tintColor, title) in buttonConfigs {
            let button = createGlassButton(iconName: iconName, tintColor: tintColor, title: title)
            container.addArrangedSubview(button)
        }

        return container
    }

    private func createGlassButton(iconName: String, tintColor: UIColor, title: String) -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 6

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12)
        label.textColor = .label

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)

        glassView.contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8))
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(glassButtonTapped(_:)))
        glassView.addGestureRecognizer(tapGesture)
        glassView.isUserInteractionEnabled = true

        return glassView
    }

    /// 3. 圆形玻璃图标
    private func createCircularGlassIcons() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.distribution = .equalSpacing
        container.alignment = .center

        let icons: [(String, UIColor)] = [
            ("phone.fill", .systemGreen),
            ("message.fill", .systemBlue),
            ("camera.fill", .systemGray),
            ("envelope.fill", .systemBlue),
            ("safari.fill", .systemBlue)
        ]

        for (iconName, color) in icons {
            let iconView = createCircularGlassIcon(iconName: iconName, color: color)
            container.addArrangedSubview(iconView)
        }

        return container
    }

    private func createCircularGlassIcon(iconName: String, color: UIColor) -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 30
        glassView.clipsToBounds = true

        glassView.snp.makeConstraints { make in
            make.width.height.equalTo(60)
        }

        let iconImageView = UIImageView(image: UIImage(systemName: iconName))
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit

        glassView.contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(glassButtonTapped(_:)))
        glassView.addGestureRecognizer(tapGesture)
        glassView.isUserInteractionEnabled = true

        return glassView
    }

    /// 4. 玻璃卡片
    private func createGlassCard() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 24
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16
        container.alignment = .fill

        // 头部
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center

        let avatarView = createAvatarView()
        let infoStack = createInfoStack()

        headerStack.addArrangedSubview(avatarView)
        headerStack.addArrangedSubview(infoStack)

        // 内容
        let contentLabel = UILabel()
        contentLabel.text = "Liquid Glass 是 Apple 在 iOS 26 引入的全新设计语言，为应用带来更加现代化、透明的视觉效果。它能够与背景内容动态交互，创造出流畅自然的用户界面体验。"
        contentLabel.numberOfLines = 0
        contentLabel.font = .systemFont(ofSize: 15)
        contentLabel.textColor = .label

        // 底部操作
        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 12

        let likeButton = createActionButton(icon: "hand.thumbsup", title: "128")
        let commentButton = createActionButton(icon: "bubble.left", title: "32")
        let shareButton = createActionButton(icon: "square.and.arrow.up", title: "分享")

        actionStack.addArrangedSubview(likeButton)
        actionStack.addArrangedSubview(commentButton)
        actionStack.addArrangedSubview(shareButton)

        container.addArrangedSubview(headerStack)
        container.addArrangedSubview(contentLabel)
        container.addArrangedSubview(actionStack)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        return glassView
    }

    private func createAvatarView() -> UIView {
        let avatarView = UIView()
        avatarView.backgroundColor = .systemBlue.withAlphaComponent(0.6)
        avatarView.layer.cornerRadius = 24

        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(48)
        }

        let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        avatarIcon.tintColor = .white
        avatarIcon.contentMode = .scaleAspectFit

        avatarView.addSubview(avatarIcon)
        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        return avatarView
    }

    private func createInfoStack() -> UIStackView {
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 4

        let nameLabel = UILabel()
        nameLabel.text = "Liquid Glass Demo"
        nameLabel.font = .boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "iOS 26+ 新特性展示"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel

        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(subtitleLabel)

        return infoStack
    }

    private func createActionButton(icon: String, title: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.title = title
        config.imagePadding = 6
        config.baseForegroundColor = .label

        let button = UIButton(configuration: config)
        return button
    }

    /// 5. 玻璃 Tab Bar
    private func createGlassTabBar() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 28
        glassView.clipsToBounds = true

        let tabStack = UIStackView()
        tabStack.axis = .horizontal
        tabStack.distribution = .equalSpacing
        tabStack.alignment = .center

        let tabs: [(String, String, Bool)] = [
            ("house.fill", "首页", true),
            ("magnifyingglass", "搜索", false),
            ("plus.circle.fill", "添加", false),
            ("bell", "通知", false),
            ("person", "我的", false)
        ]

        for (iconName, title, isSelected) in tabs {
            let tabItem = createTabItem(iconName: iconName, title: title, isSelected: isSelected)
            tabStack.addArrangedSubview(tabItem)
        }

        glassView.contentView.addSubview(tabStack)
        tabStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24))
        }

        return glassView
    }

    private func createTabItem(iconName: String, title: String, isSelected: Bool) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .center
        container.spacing = 4

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = isSelected ? .systemBlue : .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 10)
        label.textColor = isSelected ? .systemBlue : .secondaryLabel

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(label)

        return container
    }

    /// 6. 玻璃分段控制器
    private func createGlassSegmentedControl() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let segmentedControl = UISegmentedControl(items: ["全部", "推荐", "热门", "最新"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = .systemBlue.withAlphaComponent(0.4)

        glassView.contentView.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        return glassView
    }

    /// 7. 玻璃输入框
    private func createGlassTextField() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 20
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        let textField = UITextField()
        textField.placeholder = "搜索内容..."
        textField.font = .systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing

        let micIcon = UIImageView(image: UIImage(systemName: "mic.fill"))
        micIcon.tintColor = .secondaryLabel
        micIcon.contentMode = .scaleAspectFit
        micIcon.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        container.addArrangedSubview(searchIcon)
        container.addArrangedSubview(textField)
        container.addArrangedSubview(micIcon)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        }

        return glassView
    }

    /// 8. 玻璃进度控件
    private func createGlassProgressControls() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16

        // 音量控制
        let volumeControl = createSliderRow(icon: "speaker.wave.2.fill", value: 0.6)
        // 亮度控制
        let brightnessControl = createSliderRow(icon: "sun.max.fill", value: 0.8)

        container.addArrangedSubview(volumeControl)
        container.addArrangedSubview(brightnessControl)

        return container
    }

    private func createSliderRow(icon: String, value: Float) -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let slider = UISlider()
        slider.value = value
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray4

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(slider)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }

        return glassView
    }

    /// 9. 玻璃开关
    private func createGlassToggles() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 2

        let toggles: [(String, String, Bool)] = [
            ("wifi", "无线局域网", true),
            ("bluetooth", "蓝牙", true),
            ("airplane", "飞行模式", false),
            ("moon.fill", "勿扰模式", false)
        ]

        for (index, (icon, title, isOn)) in toggles.enumerated() {
            let isFirst = index == 0
            let isLast = index == toggles.count - 1
            let toggle = createToggleRow(icon: icon, title: title, isOn: isOn, isFirst: isFirst, isLast: isLast)
            container.addArrangedSubview(toggle)
        }

        return container
    }

    private func createToggleRow(icon: String, title: String, isOn: Bool, isFirst: Bool, isLast: Bool) -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)

        var maskedCorners: CACornerMask = []
        if isFirst {
            maskedCorners.insert(.layerMinXMinYCorner)
            maskedCorners.insert(.layerMaxXMinYCorner)
        }
        if isLast {
            maskedCorners.insert(.layerMinXMaxYCorner)
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }
        glassView.layer.cornerRadius = isFirst || isLast ? 16 : 0
        glassView.layer.maskedCorners = maskedCorners
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = .systemGreen

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(label)
        container.addArrangedSubview(toggle)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }

        return glassView
    }

    /// 10. 玻璃列表
    private func createGlassList() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0

        let items: [(String, String, String)] = [
            ("doc.text.fill", "文档", "12 项"),
            ("photo.fill", "照片", "1,234 张"),
            ("film.fill", "视频", "56 个"),
            ("folder.fill", "文件夹", "8 个")
        ]

        for (index, (icon, title, detail)) in items.enumerated() {
            let row = createListRow(icon: icon, title: title, detail: detail)
            container.addArrangedSubview(row)

            if index < items.count - 1 {
                let separator = UIView()
                separator.backgroundColor = .separator.withAlphaComponent(0.3)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                }
                container.addArrangedSubview(separator)
            }
        }

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        return glassView
    }

    private func createListRow(icon: String, title: String, detail: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(label)
        container.addArrangedSubview(UIView()) // Spacer
        container.addArrangedSubview(detailLabel)
        container.addArrangedSubview(chevron)

        let wrapper = UIView()
        wrapper.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        }

        return wrapper
    }

    /// 11. 悬浮操作按钮
    private func createFloatingActionButtons() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 16
        container.alignment = .center
        container.distribution = .equalCentering

        let sizes: [(String, CGFloat, UIColor)] = [
            ("plus", 56, .systemBlue),
            ("pencil", 48, .systemOrange),
            ("trash", 44, .systemRed)
        ]

        for (icon, size, color) in sizes {
            let fab = createFAB(icon: icon, size: size, color: color)
            container.addArrangedSubview(fab)
        }

        return container
    }

    private func createFAB(icon: String, size: CGFloat, color: UIColor) -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = size / 2
        glassView.clipsToBounds = true

        // 添加阴影容器
        let shadowContainer = UIView()
        shadowContainer.layer.shadowColor = color.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowContainer.layer.shadowOpacity = 0.3
        shadowContainer.layer.shadowRadius = 8

        shadowContainer.snp.makeConstraints { make in
            make.width.height.equalTo(size)
        }

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit

        glassView.contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(size * 0.45)
        }

        shadowContainer.addSubview(glassView)
        glassView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(glassButtonTapped(_:)))
        shadowContainer.addGestureRecognizer(tapGesture)
        shadowContainer.isUserInteractionEnabled = true

        return shadowContainer
    }

    /// 12. 玻璃工具栏
    private func createGlassToolbar() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 20
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .horizontal
        container.distribution = .equalSpacing
        container.alignment = .center

        let tools: [(String, String)] = [
            ("bold", "粗体"),
            ("italic", "斜体"),
            ("underline", "下划线"),
            ("strikethrough", "删除线"),
            ("list.bullet", "列表"),
            ("link", "链接")
        ]

        for (icon, _) in tools {
            let toolButton = createToolButton(icon: icon)
            container.addArrangedSubview(toolButton)
        }

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }

        return glassView
    }

    private func createToolButton(icon: String) -> UIView {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .label
        button.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        return button
    }

    /// 13. 玻璃弹出菜单
    private func createGlassContextMenu() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 16
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0

        let menuItems: [(String, String, UIColor)] = [
            ("doc.on.doc", "复制", .label),
            ("scissors", "剪切", .label),
            ("doc.on.clipboard", "粘贴", .label),
            ("trash", "删除", .systemRed)
        ]

        for (index, (icon, title, color)) in menuItems.enumerated() {
            let menuRow = createMenuRow(icon: icon, title: title, color: color)
            container.addArrangedSubview(menuRow)

            if index < menuItems.count - 1 {
                let separator = UIView()
                separator.backgroundColor = .separator.withAlphaComponent(0.3)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                }
                container.addArrangedSubview(separator)
            }
        }

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        glassView.snp.makeConstraints { make in
            make.width.equalTo(200)
        }

        let wrapper = UIView()
        wrapper.addSubview(glassView)
        glassView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        return wrapper
    }

    private func createMenuRow(icon: String, title: String, color: UIColor) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        label.textColor = color

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(label)
        container.addArrangedSubview(UIView()) // Spacer

        let wrapper = UIView()
        wrapper.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }

        return wrapper
    }

    /// 14. 玻璃通知
    private func createGlassNotification() -> UIView {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.layer.cornerRadius = 20
        glassView.clipsToBounds = true

        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let iconContainer = UIView()
        iconContainer.backgroundColor = .systemBlue
        iconContainer.layer.cornerRadius = 12

        iconContainer.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        let iconView = UIImageView(image: UIImage(systemName: "bell.fill"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = "新消息通知"
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textColor = .label

        let messageLabel = UILabel()
        messageLabel.text = "您有 3 条未读消息"
        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = .secondaryLabel

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)

        let timeLabel = UILabel()
        timeLabel.text = "刚刚"
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .tertiaryLabel

        container.addArrangedSubview(iconContainer)
        container.addArrangedSubview(textStack)
        container.addArrangedSubview(UIView()) // Spacer
        container.addArrangedSubview(timeLabel)

        glassView.contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }

        return glassView
    }

    /// 15. 嵌套玻璃效果
    private func createNestedGlass() -> UIView {
        let outerGlassEffect = UIGlassEffect()
        let outerGlass = UIVisualEffectView(effect: outerGlassEffect)
        outerGlass.layer.cornerRadius = 28
        outerGlass.clipsToBounds = true

        let innerContainer = UIStackView()
        innerContainer.axis = .horizontal
        innerContainer.spacing = 12
        innerContainer.distribution = .fillEqually

        for i in 0..<3 {
            let innerGlassEffect = UIGlassEffect()
            let innerGlass = UIVisualEffectView(effect: innerGlassEffect)
            innerGlass.layer.cornerRadius = 16
            innerGlass.clipsToBounds = true

            let icons = ["star.fill", "heart.fill", "bolt.fill"]
            let colors: [UIColor] = [.systemYellow, .systemPink, .systemBlue]

            let iconView = UIImageView(image: UIImage(systemName: icons[i]))
            iconView.tintColor = colors[i]
            iconView.contentMode = .scaleAspectFit

            innerGlass.contentView.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(32)
            }

            innerGlass.snp.makeConstraints { make in
                make.height.equalTo(80)
            }

            innerContainer.addArrangedSubview(innerGlass)
        }

        outerGlass.contentView.addSubview(innerContainer)
        innerContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        return outerGlass
    }

    // MARK: - Actions

    @objc private func glassButtonTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }

        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                view.transform = .identity
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Fallback for Earlier iOS Versions

/// 为低版本 iOS 提供的降级版本
final class LiquidDemoFallbackViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Liquid Glass"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Liquid Glass 效果需要 iOS 26.0 或更高版本"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
}

// MARK: - Factory

enum LiquidDemoFactory {

    /// 创建 Liquid Demo 控制器
    /// 根据系统版本自动选择合适的实现
    static func makeViewController() -> UIViewController {
        if #available(iOS 26.0, *) {
            return LiquidDemoViewController()
        } else {
            return LiquidDemoFallbackViewController()
        }
    }
}
