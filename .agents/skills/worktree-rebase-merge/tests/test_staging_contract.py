"""Regression invariants for the shared Git staging contract."""

from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
GIT_COMMIT_SKILL = REPOSITORY_ROOT / "skills/git-commit/SKILL.md"
WORKTREE_SKILL = REPOSITORY_ROOT / "skills/worktree-rebase-merge/SKILL.md"
GIT_DELIVERY_AGENT = REPOSITORY_ROOT / ".codex/agents/git-delivery.toml"
GIT_WORKFLOW = REPOSITORY_ROOT / "docs/agents/git-workflow.md"


class StagingContractTests(unittest.TestCase):
    def test_all_delivery_layers_share_the_four_staging_strategies(self) -> None:
        required_strategies = {
            "existing-index",
            "explicit-paths",
            "explicit-worktree-once",
            "auto-exact",
        }

        for path in (GIT_COMMIT_SKILL, WORKTREE_SKILL, GIT_DELIVERY_AGENT, GIT_WORKFLOW):
            with self.subTest(path=path):
                content = path.read_text(encoding="utf-8")
                for strategy in required_strategies:
                    self.assertIn(strategy, content)

    def test_worktree_delegates_empty_index_staging_to_git_commit(self) -> None:
        content = WORKTREE_SKILL.read_text(encoding="utf-8")

        self.assertIn("完整复用 `git-commit` 的 **暂存决策**", content)
        self.assertIn("`explicit-worktree-once`", content)
        self.assertNotIn("空索引时停止并要求用户精确暂存文件", content)


if __name__ == "__main__":
    unittest.main()
