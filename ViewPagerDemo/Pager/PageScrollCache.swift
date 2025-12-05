#if canImport(UIKit)
import UIKit

final class PageScrollCache {
    private var storage: [AnyHashable: CGPoint] = [:]
    private let lock = NSLock()

    func offset(for pageId: AnyHashable) -> CGPoint? {
        lock.lock()
        defer { lock.unlock() }
        return storage[pageId]
    }

    func set(offset: CGPoint, for pageId: AnyHashable) {
        lock.lock()
        storage[pageId] = offset
        lock.unlock()
    }
    
    func clear() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }
    
    func remove(for pageId: AnyHashable) {
        lock.lock()
        storage.removeValue(forKey: pageId)
        lock.unlock()
    }
}
#endif

