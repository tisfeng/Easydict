# Easydict 架构总览

Easydict 是一款 macOS 词典和翻译应用，支持直接查词、文本翻译、划词翻译、
OCR 截图翻译，以及多个翻译或 AI 服务提供商。

应用支持 macOS 13.0 及更高版本。新的 UI 组件使用 SwiftUI；在平台集成需要时，
保留现有的 AppKit 和 Objective-C 边界。

## 源码布局

```text
Easydict/
├── App/                         # 入口、资源、plist、本地化
├── Swift/
│   ├── Feature/                 # 产品功能和操作流程
│   ├── Model/                   # 共享数据模型
│   ├── Service/                 # 翻译和 AI 服务提供商
│   ├── Utility/                 # 事件监视器和跨功能辅助工具
│   └── View/                    # 共享 SwiftUI 和面向 AppKit 的视图
└── objc/                        # 遗留 Objective-C 实现

EasydictTests/                   # 单元测试和行为测试
Easydict.xcodeproj/              # Xcode 工程和共享 scheme
Easydict.xcworkspace/            # workspace 和 SwiftPM 集成
scripts/release/                # 发布、签名、打包和 appcast 流程
```

## 运行时边界

- 应用入口和共享状态位于 `Easydict/App` 及相关的 Swift 功能模块中。
- 翻译服务提供商在 `Easydict/Swift/Service` 下实现特定服务的请求和响应解析。
- 划词、快捷键、截图和操作路由属于功能模块；可复用的事件以及
  Foundation/AppKit 辅助工具放在 `Utility` 下。
- Objective-C 代码仍是遗留边界。新的 UI 和产品组件使用 SwiftUI，除非现有的
  AppKit 或 Objective-C 集成要求使用其他边界。
- 测试应在最窄的稳定边界验证具体行为，避免与视图实现细节耦合。

## 构建与验证边界

主要的 Xcode 入口是使用 `Easydict` scheme 的 `Easydict.xcworkspace`。构建和
测试的触发条件与命令位于 `../agents/build-and-test.md`；本文记录架构，不重复
命令矩阵。

## 文档边界

- Agent 内部规则：`../agents/`。
- 公共英文和中文指南：`../user-docs/en/` 和 `../user-docs/zh/`。
- 当前任务计划和已完成工作记录：`../exec-plans/` 和 `../histories/`。
