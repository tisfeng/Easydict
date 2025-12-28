---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git commit:*),  Bash(cat:*), Bash(echo:*), Bash(rm:*)
argument-hint: [message]
description: Generate an Angular-style git commit message
model: ANTHROPIC_DEFAULT_HAIKU_MODEL
---

Angular-style git commit message generator

You are an intelligent Git commit message generator.
Your goal is to generate a clear, professional **Git commit message** based on the currently staged changes.

## Context

- Current git status: !`git status`
- Current git staged changes: !`git status && git diff --staged`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Improved Commit Flow Process

**Step-by-step process:**
1. Analyze staged changes with `git status && git diff --staged`; identify additions (+) vs deletions (-) to describe impact accurately.
2. Draft the commit message in English following Angular style (`type(scope): subject`), keep title ≤80 chars and total ≤600 chars.
3. Provide a Simplified Chinese translation for preview only (do not include in the commit file).
4. Show the English + Chinese preview and wait for explicit approval.
5. After approval, write the message to `commit_message.txt`, run `git commit -F commit_message.txt && rm commit_message.txt`.

**Important Rules:**
- Do not run `git add` or `git push`.
- Do not commit without explicit user authorization.
- Keep titles concise (≤80 chars) and the whole message under 600 chars.
- Use Angular Conventional Commit style; Chinese translation is for preview only.

## Additional Context
User-provided description: $ARGUMENTS

## Angular Conventional Commit style

An Angular-style message should include:
  1. `type(scope): subject` — `type` is the change category, `scope` is the touched module or file, `subject` is a concise summary.
  2. A detailed body explaining the motivation and what was changed.
  3. Impact notes for breaking changes or special considerations.

## Git Commit Message Examples

```
fix(screenshot): resolve crash by deferring screenshot capture

This commit fixes a critical crash that occurred when initiating a screenshot.

The root cause was that the screenshot was being captured directly within the `ScreenshotOverlayView` initializer. This action, happening before the view was fully integrated into the view hierarchy, led to `NSHostingView` constraint conflicts and a subsequent crash.

The fix defers the screenshot capture until the view has fully appeared by moving the capture logic from the `init` method to an `.onAppear` block. This ensures that the view is in a stable state, preventing the race condition and resolving the crash.
```