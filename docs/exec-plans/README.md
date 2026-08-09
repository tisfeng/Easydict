# Execution Plans

Execution plans capture multi-step work that spans multiple commits, modules,
or validation stages.

- Active plans live in `active/`.
- Completed plans move to `completed/`.
- Start from `templates/execution-plan.md`.
- Keep progress, risks, decisions, and validation in the plan itself.
- Do not leave completed or abandoned work in `active/`.

`active/swift-migration.md` is the long-term Objective-C-to-Swift roadmap. Keep
its completed history and remaining work synchronized with the current source;
create focused plans for individual migration slices when they need separate
milestones or validation.
