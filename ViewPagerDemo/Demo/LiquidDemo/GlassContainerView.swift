import UIKit
import SnapKit

// MARK: - Glass Style 定义

/// Glass 样式枚举，兼容低版本
enum GlassStyle {
    /// 标准玻璃效果
    case regular
    /// 高透明度玻璃效果
    case clear

    @available(iOS 26.0, *)
    var uiGlassStyle: UIGlassEffect.Style {
        switch self {
        case .regular: return .regular
        case .clear: return .clear
        }
    }
}

// MARK: - GlassContainerView

/// 玻璃容器视图
///
/// 在 iOS 26+ 上使用 Liquid Glass 效果，低版本上使用模糊效果作为降级方案。
/// 使用方式与普通 UIView 类似，将子视图添加到 `contentView` 即可。
///
/// ```swift
/// let glassView = GlassContainerView()
/// glassView.cornerRadius = 20
/// glassView.glassStyle = .regular
/// glassView.contentView.addSubview(yourLabel)
/// ```
class GlassContainerView: UIView {

    // MARK: - Public Properties

    /// 内容视图，所有子视图应添加到此视图
    var contentView: UIView {
        if #available(iOS 26.0, *) {
            return glassEffectView.contentView
        } else {
            return fallbackContentView
        }
    }

    /// 玻璃样式
    var glassStyle: GlassStyle = .regular {
        didSet {
            updateGlassEffect()
        }
    }

    /// 是否启用交互效果（仅 iOS 26+）
    var isInteractive: Bool = false {
        didSet {
            updateGlassEffect()
        }
    }

    /// 玻璃色调颜色
    var glassTintColor: UIColor? {
        didSet {
            updateGlassEffect()
        }
    }

    /// 圆角半径
    var cornerRadius: CGFloat = 0 {
        didSet {
            updateCornerRadius()
        }
    }

    /// 降级时的背景颜色（仅低版本生效）
    var fallbackBackgroundColor: UIColor = .systemBackground.withAlphaComponent(0.8) {
        didSet {
            if #unavailable(iOS 26.0) {
                fallbackContainerView.backgroundColor = fallbackBackgroundColor
            }
        }
    }

    /// 降级时是否使用模糊效果
    var useFallbackBlur: Bool = true {
        didSet {
            updateFallbackAppearance()
        }
    }

    // MARK: - Private Properties

    /// iOS 26+ 使用的玻璃效果视图存储（使用 Any 避免 @available 限制）
    private var _glassEffectView: UIVisualEffectView?

    /// iOS 26+ 使用的玻璃效果视图
    @available(iOS 26.0, *)
    private var glassEffectView: UIVisualEffectView {
        if let view = _glassEffectView {
            return view
        }
        let effect = UIGlassEffect(style: glassStyle.uiGlassStyle)
        let view = UIVisualEffectView(effect: effect)
        view.clipsToBounds = true
        _glassEffectView = view
        return view
    }

    /// 低版本使用的容器视图
    private lazy var fallbackContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = fallbackBackgroundColor
        view.clipsToBounds = true
        return view
    }()

    /// 低版本使用的模糊效果视图
    private lazy var fallbackBlurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()

    /// 低版本使用的内容视图
    private lazy var fallbackContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    /// 便捷初始化方法
    convenience init(style: GlassStyle = .regular, cornerRadius: CGFloat = 0) {
        self.init(frame: .zero)
        self.glassStyle = style
        self.cornerRadius = cornerRadius
        updateGlassEffect()
        updateCornerRadius()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        if #available(iOS 26.0, *) {
            addSubview(glassEffectView)
            glassEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            // 低版本布局
            addSubview(fallbackContainerView)
            fallbackContainerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            fallbackContainerView.addSubview(fallbackBlurView)
            fallbackBlurView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            fallbackContainerView.addSubview(fallbackContentView)
            fallbackContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            updateFallbackAppearance()
        }
    }

    // MARK: - Updates

    private func updateGlassEffect() {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: glassStyle.uiGlassStyle)
            effect.isInteractive = isInteractive
            if let tint = glassTintColor {
                effect.tintColor = tint
            }
            glassEffectView.effect = effect
        } else {
            // 低版本：根据 tintColor 更新背景
            if let tint = glassTintColor {
                fallbackContainerView.backgroundColor = tint.withAlphaComponent(0.15)
            } else {
                fallbackContainerView.backgroundColor = fallbackBackgroundColor
            }
        }
    }

    private func updateCornerRadius() {
        if #available(iOS 26.0, *) {
            glassEffectView.layer.cornerRadius = cornerRadius
        } else {
            fallbackContainerView.layer.cornerRadius = cornerRadius
        }
    }

    private func updateFallbackAppearance() {
        if #unavailable(iOS 26.0) {
            fallbackBlurView.isHidden = !useFallbackBlur
            if useFallbackBlur {
                fallbackContainerView.backgroundColor = .clear
            } else {
                fallbackContainerView.backgroundColor = fallbackBackgroundColor
            }
        }
    }

    // MARK: - Public Methods

    /// 设置玻璃效果动画
    /// - Parameters:
    ///   - style: 目标样式
    ///   - animated: 是否动画
    func setGlassStyle(_ style: GlassStyle, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.glassStyle = style
            }
        } else {
            self.glassStyle = style
        }
    }

    /// 设置色调动画
    /// - Parameters:
    ///   - color: 目标颜色
    ///   - animated: 是否动画
    func setTintColor(_ color: UIColor?, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.glassTintColor = color
            }
        } else {
            self.glassTintColor = color
        }
    }
}

// MARK: - GlassButton

/// 玻璃按钮
///
/// 封装了点击效果的玻璃容器，支持 iOS 26+ Liquid Glass 效果。
final class GlassButton: GlassContainerView {

    // MARK: - Public Properties

    /// 点击回调
    var onTap: (() -> Void)?

    /// 是否启用触觉反馈
    var enableHapticFeedback: Bool = true

    /// 按压缩放比例
    var pressedScale: CGFloat = 0.95

    // MARK: - Private Properties

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGesture()
    }

    convenience init(style: GlassStyle = .regular, cornerRadius: CGFloat = 16) {
        self.init(frame: .zero)
        self.glassStyle = style
        self.cornerRadius = cornerRadius
    }

    // MARK: - Setup

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0
        longPress.cancelsTouchesInView = false
        addGestureRecognizer(longPress)
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTap?()

        if enableHapticFeedback {
            feedbackGenerator.impactOccurred()
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            animatePress(pressed: true)
        case .ended, .cancelled:
            animatePress(pressed: false)
        default:
            break
        }
    }

    private func animatePress(pressed: Bool) {
        UIView.animate(
            withDuration: pressed ? 0.1 : 0.2,
            delay: 0,
            usingSpringWithDamping: pressed ? 1.0 : 0.5,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction]
        ) {
            self.transform = pressed ? CGAffineTransform(scaleX: self.pressedScale, y: self.pressedScale) : .identity
        }
    }
}

// MARK: - GlassCard

/// 玻璃卡片
///
/// 预设了卡片样式的玻璃容器，带有内边距和阴影。
final class GlassCard: GlassContainerView {

    // MARK: - Public Properties

    /// 内容内边距
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet {
            updateContentInsets()
        }
    }

    /// 是否显示阴影
    var showShadow: Bool = true {
        didSet {
            updateShadow()
        }
    }

    /// 阴影颜色
    var shadowColor: UIColor = .black {
        didSet {
            updateShadow()
        }
    }

    // MARK: - Private Properties

    private lazy var innerContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// 重写 contentView 返回带内边距的容器
    override var contentView: UIView {
        return innerContentView
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCard()
    }

    convenience init(cornerRadius: CGFloat = 20, insets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)) {
        self.init(frame: .zero)
        self.cornerRadius = cornerRadius
        self.contentInsets = insets
        updateContentInsets()
    }

    // MARK: - Setup

    private func setupCard() {
        cornerRadius = 20

        // 将 innerContentView 添加到父类的 contentView
        let parentContentView: UIView
        if #available(iOS 26.0, *) {
            parentContentView = super.contentView
        } else {
            parentContentView = super.contentView
        }

        parentContentView.addSubview(innerContentView)
        updateContentInsets()
        updateShadow()
    }

    private func updateContentInsets() {
        innerContentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(contentInsets)
        }
    }

    private func updateShadow() {
        if showShadow {
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowOpacity = 0.15
            layer.shadowRadius = 12
        } else {
            layer.shadowOpacity = 0
        }
    }
}

// MARK: - GlassContainerEffect Wrapper

/// 玻璃容器效果包装器
///
/// 用于将多个 GlassContainerView 组合在一起，使它们可以在接近时合并（仅 iOS 26+）。
@available(iOS 26.0, *)
final class GlassContainerEffectView: UIView {

    // MARK: - Public Properties

    /// 内容视图
    var contentView: UIView {
        return containerEffectView.contentView
    }

    /// 合并距离阈值
    var spacing: CGFloat = 12 {
        didSet {
            updateContainerEffect()
        }
    }

    // MARK: - Private Properties

    private lazy var containerEffectView: UIVisualEffectView = {
        let effect = UIGlassContainerEffect()
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear
        addSubview(containerEffectView)
        containerEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func updateContainerEffect() {
        let effect = UIGlassContainerEffect()
        effect.spacing = spacing
        containerEffectView.effect = effect
    }

    // MARK: - Public Methods

    /// 添加玻璃子视图
    func addGlassView(_ view: GlassContainerView) {
        contentView.addSubview(view)
    }
}

// MARK: - UIView Extension

extension UIView {

    /// 快速包装为玻璃容器
    /// - Parameters:
    ///   - style: 玻璃样式
    ///   - cornerRadius: 圆角
    ///   - insets: 内边距
    /// - Returns: 包装后的玻璃容器
    func wrappedInGlass(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = 16,
        insets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    ) -> GlassContainerView {
        let container = GlassContainerView(style: style, cornerRadius: cornerRadius)
        container.contentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(insets)
        }
        return container
    }
}
