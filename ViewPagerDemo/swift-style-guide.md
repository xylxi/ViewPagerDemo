# Google Swift Style Guide (LLM-Friendly Version)

> 基于 Google Swift Style Guide 整理，适用于 LLM 代码生成参考

---

## 1. 源文件基础

### 1.1 文件编码
- 使用 `.swift` 扩展名
- 使用 UTF-8 编码
- 仅使用水平空格 (U+0020)，禁止使用制表符 (Tab)

### 1.2 特殊字符
- 优先使用转义序列：`\t`, `\n`, `\r`, `\"`, `\'`, `\\`, `\0`
- 避免在字符串中混用字面 Unicode 和转义序列

---

## 2. 源文件结构

### 2.1 Import 语句顺序
```swift
// 1. 模块导入（按字母排序）
import CoreLocation
import Foundation
import UIKit

// 2. 单独声明导入
import struct Darwin.errno

// 3. @testable 导入
@testable import MyModuleUnderTest
```

### 2.2 文件命名
- 单一类型文件：`MyType.swift`
- 协议扩展文件：`MyType+ProtocolName.swift`
- 相关类型可放在同一文件中

### 2.3 成员排序
- 使用 `// MARK:` 注释组织代码
- 重载方法连续放置，不插入其他代码

---

## 3. 格式化规则

### 3.1 行宽限制
- **最大 100 字符**
- 例外：URL、import 语句、生成的代码

### 3.2 大括号风格 (K&R Style)
```swift
// ✅ 正确
if condition {
    doSomething()
} else {
    doSomethingElse()
}

// ❌ 错误
if condition
{
    doSomething()
}
```

### 3.3 分号
- **永远不使用分号**

### 3.4 每行一条语句
```swift
// ✅ 正确
let a = 1
let b = 2

// ❌ 错误
let a = 1; let b = 2
```

### 3.5 单行代码块（允许）
```swift
// ✅ 允许的单行写法
guard let value = optional else { return }
defer { cleanup() }
```

### 3.6 换行规则
- 逗号分隔列表：要么全部在一行，要么每个元素独占一行
```swift
// ✅ 全部一行
func process(a: Int, b: Int, c: Int) { }

// ✅ 每个一行
func process(
    a: Int,
    b: Int,
    c: Int
) { }

// ❌ 混合（禁止）
func process(a: Int, b: Int,
    c: Int) { }
```

---

## 4. 空格规则

### 4.1 需要空格
```swift
// 关键字后面
if condition { }
guard let x = y else { }
while true { }
switch value { }

// 二元运算符两侧
let sum = a + b
let isEqual = x == y
let result = condition ? a : b

// 逗号后面
func process(a: Int, b: Int)

// 冒号后面（类型声明）
let name: String
func getValue() -> Int

// 注释前后
let value = 42  // 两个空格后接注释
```

### 4.2 不需要空格
```swift
// 成员访问点
object.property
array[index]

// 范围运算符
0..<10
0...9

// 冒号前面
let dict: [String: Int]
```

---

## 5. 命名规范

### 5.1 基本规则
- 遵循 Apple API Design Guidelines
- 使用 lowerCamelCase（小驼峰）命名变量、函数、属性
- 使用 UpperCamelCase（大驼峰）命名类型、协议

### 5.2 命名示例
```swift
// ✅ 正确
let maximumItemCount = 100
func fetchUserData() { }
class NetworkManager { }
protocol DataSource { }

// ❌ 错误（匈牙利命名法）
let kMaximumItemCount = 100
let MAX_ITEM_COUNT = 100
```

### 5.3 初始化器参数
```swift
// ✅ 使用 self. 区分属性和参数
init(name: String, age: Int) {
    self.name = name
    self.age = age
}
```

### 5.4 静态属性
```swift
// ✅ 返回自身类型时省略类型后缀
class Color {
    static let red = Color(...)  // 而不是 redColor
}
```

---

## 6. 编程实践

### 6.1 错误处理
```swift
// ✅ 多种失败情况：使用 Error 类型
enum NetworkError: Error {
    case invalidURL
    case timeout
    case serverError(Int)
}

func fetchData() throws -> Data {
    throw NetworkError.invalidURL
}

// ✅ 单一明显失败：使用 Optional
func findUser(byID id: String) -> User? {
    return users.first { $0.id == id }
}
```

### 6.2 强制解包
```swift
// ❌ 避免强制解包
let value = optional!

// ✅ 使用安全解包
if let value = optional {
    // 使用 value
}

guard let value = optional else {
    return
}

// ✅ 可接受的强制解包场景：
// 1. 单元测试
// 2. 明确的程序员错误（fatalError）
```

### 6.3 Guard 语句
```swift
// ✅ 使用 guard 进行早期退出
func process(data: Data?) {
    guard let data = data else {
        return
    }
    // 处理 data
}

// ❌ 避免深层嵌套
func process(data: Data?) {
    if let data = data {
        if data.count > 0 {
            // 深层嵌套
        }
    }
}
```

### 6.4 For-Where 循环
```swift
// ✅ 使用 where 子句
for item in items where item.isValid {
    process(item)
}

// ❌ 避免循环内 if
for item in items {
    if item.isValid {
        process(item)
    }
}
```

---

## 7. 类型语法

### 7.1 简写语法
```swift
// ✅ 使用简写
var items: [String]
var cache: [String: Int]
var optional: String?

// ❌ 避免完整写法
var items: Array<String>
var cache: Dictionary<String, Int>
var optional: Optional<String>
```

### 7.2 计算属性
```swift
// ✅ 只读属性省略 get
var fullName: String {
    return "\(firstName) \(lastName)"
}

// ❌ 不必要的 get
var fullName: String {
    get {
        return "\(firstName) \(lastName)"
    }
}
```

### 7.3 函数类型返回值
```swift
// ✅ 使用 Void
var completion: () -> Void

// ❌ 使用空元组
var completion: () -> ()

// ✅ 函数声明省略返回类型
func doSomething() {
    // 隐式返回 Void
}
```

---

## 8. 模式匹配

### 8.1 Let/Var 位置
```swift
// ✅ 每个元素前放置 let/var
switch result {
case let .success(value):
    print(value)
case let .failure(error):
    print(error)
}

// ✅ 元组解构
let (x, y) = point
if case let (a, b) = tuple { }
```

### 8.2 忽略标签
```swift
// ✅ 变量名匹配时省略标签
enum Result {
    case success(value: Int)
}

switch result {
case let .success(value):  // 省略 value:
    print(value)
}
```

---

## 9. 文档注释

### 9.1 格式
```swift
// ✅ 使用三斜线
/// 计算两个数的和
///
/// - Parameters:
///   - a: 第一个数
///   - b: 第二个数
/// - Returns: 两数之和
/// - Throws: 如果结果溢出则抛出 `CalculationError.overflow`
func add(_ a: Int, _ b: Int) throws -> Int {
    // 实现
}

// ❌ 不使用块注释
/**
 * 这种格式不推荐
 */
```

### 9.2 文档要求
- 为所有 `public` 和 `open` 声明添加文档
- 以单句摘要开头
- 按顺序使用 `Parameter(s)`, `Returns`, `Throws` 标签

---

## 10. 访问控制

### 10.1 原则
- 使用访问控制隐藏实现细节，而非命名约定
- 不使用下划线前缀表示私有

```swift
// ✅ 使用访问控制
private var internalState: Int
fileprivate func helperMethod() { }

// ❌ 使用命名约定
var _internalState: Int
func _helperMethod() { }
```

---

## 快速参考清单

| 规则 | 要求 |
|------|------|
| 行宽 | ≤ 100 字符 |
| 缩进 | 空格（非 Tab） |
| 分号 | 禁止 |
| 大括号 | K&R 风格 |
| 强制解包 | 避免 |
| 命名 | lowerCamelCase / UpperCamelCase |
| 数组类型 | `[Element]` 非 `Array<Element>` |
| 可选类型 | `Type?` 非 `Optional<Type>` |
| 文档注释 | `///` 非 `/** */` |
| Guard | 优先用于早期退出 |

---

*文档整理自 [Google Swift Style Guide](https://google.github.io/swift/)*
