# Easydict 开发工具脚本

这个目录包含了用于代码格式化和检查的统一脚本，支持多种工具安装方式。

## 脚本说明

### `format.sh`
代码格式化脚本，使用 SwiftFormat 格式化项目代码。

```bash
# 格式化所有代码
./scripts/format.sh

# 仅检查不修改（推荐在 CI 中使用）
./scripts/format.sh --lint
```

### `lint.sh`
代码风格检查脚本，使用 SwiftLint 检查代码风格问题。

```bash
# 运行代码检查
./scripts/lint.sh
```

## 工具检测顺序

脚本会按以下优先级查找工具：

1. **系统安装**（推荐）- 通过 `brew`、`mint` 等安装的全局工具
2. **Swift Package Manager** - 通过 Xcode 添加的包依赖
3. **CocoaPods** - 旧的管理方式（已迁移）

## 安装工具

### 方式 1：Homebrew（最简单）
```bash
brew install swiftformat swiftlint
```

### 方式 2：通过 Xcode 添加 Package Dependencies
1. 打开 `Easydict.xcworkspace`
2. 选择项目根目录
3. 在 "Package Dependencies" 中添加：
   - `https://github.com/nicklockwood/SwiftFormat.git`
   - `https://github.com/realm/SwiftLint.git`

### 方式 3：Mint
```bash
mint install nicklockwood/SwiftFormat
mint install realm/SwiftLint
```

## 配置文件

- `.swiftformat` - SwiftFormat 配置
- `.swiftlint.yml` - SwiftLint 配置

## 故障排除

如果遇到 "找不到工具" 错误：

1. 确认工具已安装（运行 `which swiftformat` 和 `which swiftlint`）
2. 如果通过 Xcode 安装，确保先构建项目以下载 SPM 依赖：
   ```bash
   xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict
   ```
3. 检查脚本是否有执行权限：
   ```bash
   chmod +x scripts/format.sh scripts/lint.sh
   ```