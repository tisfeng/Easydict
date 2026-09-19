# OCR 调试浮窗拖动修复

- 参考 Scoco 提交 `8811b4c6f`，修复无标题 OCR 调试窗口的装饰层拦截背景拖动问题。
- `OCRWindow` 启用 `isMovableByWindowBackground`；因此将根背景、标题栏毛玻璃、底部分隔线和静态标题退出命中测试。
- 保留 Pin 按钮、OCR 图片点选、分栏拖动和合并文本编辑等真实交互区域。
- 验证：`git diff --check`；运行 Debug 构建以确认 SwiftUI 源码集成。
- 尚未进行完整应用 GUI 拖动回归；需在运行中的 OCR Debug 浮窗验证背景/标题拖动及交互保留。
