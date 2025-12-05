import UIKit

/// 页面滚动位置缓存
///
/// 用于记录每个 page 的滚动位置，在切换 page 后恢复滚动位置
///
/// - Note: 线程安全，内部使用 NSLock 保护
final class PageScrollCache {
    
    /// 存储结构：pageId → 滚动偏移量
    private var storage: [AnyHashable: CGPoint] = [:]
    
    /// 线程安全锁
    private let lock = NSLock()

    /// 获取指定 page 的缓存滚动位置
    /// - Parameter pageId: 页面标识
    /// - Returns: 缓存的滚动位置，如果没有缓存则返回 nil
    func offset(for pageId: AnyHashable) -> CGPoint? {
        lock.lock()
        defer { lock.unlock() }
        return storage[pageId]
    }

    /// 设置指定 page 的滚动位置
    /// - Parameters:
    ///   - offset: 滚动偏移量
    ///   - pageId: 页面标识
    func set(offset: CGPoint, for pageId: AnyHashable) {
        lock.lock()
        storage[pageId] = offset
        lock.unlock()
    }
    
    /// 清空所有缓存
    func clear() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }
    
    /// 移除指定 page 的缓存
    /// - Parameter pageId: 页面标识
    func remove(for pageId: AnyHashable) {
        lock.lock()
        storage.removeValue(forKey: pageId)
        lock.unlock()
    }
}
