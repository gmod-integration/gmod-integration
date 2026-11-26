#!/usr/bin/env python3
"""Exercise the actual release workflow shell against disposable local Git repos."""

from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parent.parent
VERSION_FILE = "lua/autorun/gmod_integration.lua"


def workflow_script(step_name: str) -> str:
    workflow = (ROOT / ".github/workflows/auto-release.yml").read_text()
    step = workflow.split(f"            - name: {step_name}\n", 1)[1]
    run = step.split("              run: |\n", 1)[1]
    lines = []
    for line in run.splitlines():
        if line and not line.startswith("                  "):
            break
        lines.append(line)
    return textwrap.dedent("\n".join(lines))


class ReleaseWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.remote = self.directory / "origin.git"
        self.repository = self.directory / "checkout"
        self.repository.mkdir()
        self.command("git", "init", "--bare", str(self.remote))
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Release Test")
        self.git("config", "user.email", "release-test@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", "/dev/null")
        self.git("remote", "add", "origin", str(self.remote))
        self.commit_version("5.2.9", "initial release")
        self.git("tag", "v5.2.9")
        self.source = self.commit_version("5.2.10", "chore: bump version to 5.2.10")
        self.git("tag", "v5.2.10")
        self.git("push", "origin", "main", "--tags")

    def command(self, *arguments: str, **kwargs) -> subprocess.CompletedProcess:
        return subprocess.run(
            arguments, cwd=self.repository, text=True, capture_output=True,
            check=True, **kwargs,
        )

    def git(self, *arguments: str) -> str:
        return self.command("git", *arguments).stdout.strip()

    def commit_version(self, version: str, subject: str, run_id: str | None = None,
                       source: str | None = None) -> str:
        path = self.repository / VERSION_FILE
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f'gmInte.version = "{version}" // GitHub Actions\n')
        self.git("add", VERSION_FILE)
        messages = ["-m", subject]
        if run_id is not None:
            messages += ["-m", f"Release-Source: {source or self.source}", "-m", f"Release-Run: {run_id}"]
        self.git("commit", "--allow-empty", *messages)
        return self.git("rev-parse", "HEAD")

    def run_step(self, name: str, *, event: str = "workflow_dispatch", bump: str = "major",
                 run_id: str = "200", source: str | None = None,
                 ref_type: str = "branch", ref_name: str = "main", outputs=None):
        values = {
            "github.sha": source or self.source,
            "github.ref_type": ref_type,
            "github.ref_name": ref_name,
            "github.event.inputs.version_type || 'patch'": bump,
        }
        values.update({f"steps.resolve.outputs.{key}": value for key, value in (outputs or {}).items()})
        script = re.sub(r"\$\{\{\s*(.*?)\s*\}\}", lambda match: values[match[1]], workflow_script(name))
        output = self.directory / "outputs"
        output.write_text("")
        environment = dict(os.environ, GITHUB_EVENT_NAME=event, GITHUB_RUN_ID=run_id,
                           GITHUB_OUTPUT=str(output))
        result = subprocess.run(["bash", "-c", script], cwd=self.repository,
                                env=environment, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return dict(line.split("=", 1) for line in output.read_text().splitlines())

    def resolve(self, **kwargs):
        self.git("checkout", "--detach", kwargs.get("source", self.source))
        return self.run_step("Resolve release state", **kwargs)

    def publish_locally(self, outputs, **kwargs):
        self.run_step("Create or reuse version commit and tag", outputs=outputs, **kwargs)

    def test_manual_bump_after_tagged_patch_honors_requested_type(self):
        for bump, version in [("major", "6.0.0"), ("minor", "5.3.0"), ("patch", "5.2.11")]:
            with self.subTest(bump=bump):
                result = self.resolve(bump=bump)
                self.assertEqual(result["new_version"], version)
                self.assertEqual(result["version_type"], bump)
                self.assertEqual(result["needs_version_commit"], "true")
                self.assertEqual(result["tag_exists"], "false")

    def test_manual_major_after_untagged_patch_commit(self):
        self.git("tag", "-d", "v5.2.10")
        self.git("push", "origin", ":refs/tags/v5.2.10")
        self.assertEqual(self.resolve()["new_version"], "6.0.0")

    def test_completed_manual_run_rerun_reuses_release(self):
        self.publish_locally(self.resolve())
        release = self.git("rev-parse", "v6.0.0")
        result = self.resolve()
        self.assertEqual(result["new_version"], "6.0.0")
        self.assertEqual(result["release_commit"], release)
        self.assertEqual(result["needs_version_commit"], "false")
        self.assertEqual(result["tag_exists"], "true")
        self.publish_locally(result)
        self.assertEqual(self.git("rev-parse", "refs/remotes/origin/main"), release)
        self.assertEqual(self.git("tag", "--list", "v7*"), "")

    def test_manual_rerun_repairs_missing_tag(self):
        self.publish_locally(self.resolve())
        release = self.git("rev-parse", "v6.0.0")
        self.git("tag", "-d", "v6.0.0")
        self.git("push", "origin", ":refs/tags/v6.0.0")
        result = self.resolve()
        self.assertEqual(result["release_commit"], release)
        self.assertEqual(result["tag_exists"], "false")
        self.publish_locally(result)
        self.assertEqual(self.git("rev-parse", "v6.0.0"), release)

    def test_manual_rerun_repairs_tag_only_attempt(self):
        release = self.commit_version("6.0.0", "chore: bump version to 6.0.0", "200")
        self.git("tag", "v6.0.0")
        self.git("push", "origin", "refs/tags/v6.0.0")
        result = self.resolve()
        self.assertEqual(result["release_commit"], release)
        self.publish_locally(result)
        self.assertEqual(self.git("rev-parse", "refs/remotes/origin/main"), release)

    def test_new_manual_run_at_same_tagged_source_is_new_request(self):
        first = self.resolve(run_id="199")
        second = self.resolve(run_id="200")
        self.assertEqual(first["new_version"], "6.0.0")
        self.assertEqual(second["needs_version_commit"], "true")
        self.assertEqual(second["release_commit"], "")

    def test_manual_run_ignores_another_run_attempt(self):
        other = self.commit_version("6.0.0", "chore: bump version to 6.0.0", "199")
        self.git("tag", "v6.0.0")
        self.git("push", "origin", "refs/tags/v6.0.0")
        result = self.resolve()
        self.assertEqual(result["new_version"], "7.0.0")
        self.assertEqual(result["release_commit"], "")
        self.assertNotEqual(other, self.source)

    def test_fresh_manual_run_rejects_a_branch_that_advanced(self):
        self.commit_version("5.2.11", "chore: bump version to 5.2.11")
        self.git("push", "origin", "main")
        with self.assertRaisesRegex(AssertionError, "Branch advanced since this manual request"):
            self.resolve()
        self.assertEqual(self.git("tag", "--list", "v6*"), "")

    def test_existing_target_version_still_records_manual_run(self):
        source = self.commit_version("6.0.0", "prepare new version")
        self.git("push", "origin", "main")
        self.publish_locally(self.resolve(source=source), source=source)
        release = self.git("rev-parse", "v6.0.0")
        self.assertNotEqual(release, source)
        self.assertIn("Release-Run: 200", self.git("show", "-s", "--format=%B", release))
        self.assertEqual(self.resolve(source=source)["release_commit"], release)

    def test_automatic_push_creates_a_patch_for_new_changes(self):
        source = self.commit_version("5.2.10", "feat: ship transport changes")
        self.git("push", "origin", "main")
        result = self.resolve(event="push", bump="patch", source=source)
        self.assertEqual(result["new_version"], "5.2.11")
        self.assertEqual(result["needs_version_commit"], "true")
        self.publish_locally(result, event="push", source=source)
        release = self.git("rev-parse", "v5.2.11")
        self.assertEqual(self.git("rev-parse", "refs/remotes/origin/main"), release)
        self.assertEqual(self.resolve(event="push", bump="patch", source=source)["release_commit"], release)

    def test_automatic_push_keeps_existing_tagged_release(self):
        result = self.resolve(event="push", bump="patch")
        self.assertEqual(result["new_version"], "5.2.10")
        self.assertEqual(result["release_commit"], self.source)
        self.assertEqual(result["tag_exists"], "true")

    def test_automatic_push_recovers_legacy_tagged_child(self):
        release = self.commit_version("5.2.11", "chore: bump version to 5.2.11")
        self.git("tag", "v5.2.11")
        self.git("push", "origin", "refs/tags/v5.2.11")
        result = self.resolve(event="push", bump="patch")
        self.assertEqual(result["release_commit"], release)
        self.assertEqual(result["new_version"], "5.2.11")

    def test_automatic_push_recovers_untagged_version_commit(self):
        self.git("tag", "-d", "v5.2.10")
        self.git("push", "origin", ":refs/tags/v5.2.10")
        result = self.resolve(event="push", bump="patch")
        self.assertEqual(result["release_commit"], self.source)
        self.assertEqual(result["new_version"], "5.2.10")
        self.assertEqual(result["tag_exists"], "false")

    def test_tag_trigger_keeps_existing_version(self):
        result = self.resolve(event="push", ref_type="tag", ref_name="v5.2.10", bump="patch")
        self.assertEqual(result["new_version"], "5.2.10")
        self.assertEqual(result["needs_version_commit"], "false")
        self.assertEqual(result["tag_exists"], "true")


if __name__ == "__main__":
    unittest.main()
