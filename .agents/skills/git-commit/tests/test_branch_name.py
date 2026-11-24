from __future__ import annotations

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'branch_name.py'
spec = importlib.util.spec_from_file_location('branch_name_under_test', SCRIPT)
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class BranchNameTests(unittest.TestCase):
    def test_task_types_and_summary(self):
        for task_type in policy.TASK_TYPES:
            self.assertEqual(policy.task_name(task_type, 'translate-text-2'), f'{task_type}/translate-text-2')
        for name in ('codex/translate-text', 'claude/translate-text', 'fix/Bad', 'fix/two_words', 'fix/two--words'):
            self.assertFalse(policy.is_task_name(name), name)
        for task_type, summary in (('codex', 'text'), ('fix', 'two words'), ('fix', '修复'), ('fix', '-text')):
            with self.assertRaises(ValueError):
                policy.task_name(task_type, summary)

    def test_explicit_names_remain_literal(self):
        self.assertEqual(policy.validate_literal('feature/Existing_Name'), 'feature/Existing_Name')
        self.assertEqual(policy.validate_literal('dev'), 'dev')
        for name in ('@{-1}', '-bad', 'fix/bad..name', 'fix/bad.lock', 'bad\nname', ''):
            with self.assertRaises(ValueError, msg=name):
                policy.validate_literal(name)

    def test_review_identity_and_mode(self):
        sha = 'ABCDEF1234' + '0' * 30
        self.assertEqual(policy.review_name(42, sha), 'review/pr-42-abcdef1234')
        self.assertEqual(policy.review_name(42, sha, merge_latest=True), 'review/pr-42-merge-abcdef1234')
        for number, value in ((0, sha), (-1, sha), (42, 'head'), (42, '../main')):
            with self.assertRaises(ValueError):
                policy.review_name(number, value)

    def test_release_versions(self):
        for version in ('2.25.0', 'v0.7.3', '2.25.0-beta.1'):
            self.assertEqual(policy.release_name(version), f'release/sync-{version}')
        for version in ('../../main', '', 'version', '2.25.0-Beta'):
            with self.assertRaises(ValueError):
                policy.release_name(version)

    def test_collision_candidates(self):
        self.assertEqual(policy.candidate_name('fix/text', 1), 'fix/text')
        self.assertEqual(policy.candidate_name('fix/text', 2), 'fix/text-2')
        self.assertEqual(policy.candidate_name('feature/User_Name', 3), 'feature/User_Name-3')
        with self.assertRaises(ValueError):
            policy.candidate_name('fix/text', 0)

    def test_cli_is_read_only_and_returns_specific_statuses(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*args):
                return subprocess.check_output(['git', '-C', str(root), *args])
            git('init', '-q')
            head = git('symbolic-ref', 'HEAD')
            commands = (
                (['task', '--type', 'fix', '--summary', 'text'], 0, 'fix/text'),
                (['review', '--pr', '42', '--sha', 'a' * 40], 0, 'review/pr-42-aaaaaaaaaa'),
                (['review', '--pr', '42', '--sha', 'a' * 40, '--merge-latest'], 0, 'review/pr-42-merge-aaaaaaaaaa'),
                (['release', '--version', '2.25.0'], 0, 'release/sync-2.25.0'),
                (['candidate', '--name', 'fix/text', '--number', '2'], 0, 'fix/text-2'),
                (['is-task', '--name', 'codex/text'], 1, ''),
                (['validate', '--name', '@{-1}'], 2, ''),
            )
            for arguments, status, output in commands:
                result = subprocess.run([sys.executable, str(SCRIPT), *arguments], cwd=root, text=True, capture_output=True)
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertEqual(result.stdout.strip(), output)
            self.assertEqual(git('symbolic-ref', 'HEAD'), head)
            self.assertFalse((root / '.git/index').exists())
            self.assertEqual(list((root / '.git/refs/heads').iterdir()), [])


if __name__ == '__main__':
    unittest.main()
