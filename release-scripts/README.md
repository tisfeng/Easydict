# Easydict release workflow

Easydict releases are orchestrated by `asc workflow`. The workflow keeps the
individual build, notarization, packaging, GitHub, and Sparkle stages small and
resumable while exposing one command for the normal release path.

The former monolithic script is preserved as
`release-easydict-legacy.sh`. It is available as a temporary fallback and is
not called by the new workflow.

## Release model

`dev` remains the everyday development branch. A release starts from the union
of the current remote `dev` and `main` histories:

1. Fetch `origin/dev`, `origin/main`, and tags.
2. Create an isolated `release/sync-<version>` worktree from `origin/dev`.
3. Merge `origin/main` into that branch.
4. Stop for manual conflict resolution if the branches cannot merge cleanly.
5. Build and verify from the merged result.
6. Atomically update both remote branches to the same release commit.

This recovers changes that were accidentally merged only to `main` without
making the developer's current checkout switch branches or modify its index.
The atomic push also prevents `dev` and `main` from being updated separately.
The release automation itself must be committed and present in that merged
history; unrelated dirty files in the original checkout remain untouched.

## First-time setup

Install and authenticate these tools:

- Xcode command-line tools and a Developer ID Application certificate.
- [`asc`](https://github.com/rorkai/App-Store-Connect-CLI).
- [`create-dmg`](https://github.com/sindresorhus/create-dmg).
- GitHub CLI (`gh`).
- Sparkle's `generate_appcast` tool and the `ed25519` key in Keychain.

The workflow expects App Store Connect API authentication to be configured for
`asc`, and verifies it with:

```bash
asc auth status --validate
gh auth status
```

By default, `generate_appcast` is discovered in `PATH`, then in Sparkle's
Xcode package artifacts. Set `GENERATE_APPCAST` to an executable path when it
lives elsewhere. Secrets stay in Keychain or the tools' own credential stores;
none are written to the repository or release metadata.

## One-command release

Run from the repository root:

```bash
./release-scripts/release-easydict.sh release 2.22.0
```

The default channel is `beta`. For a stable update:

```bash
./release-scripts/release-easydict.sh release 2.22.0 --channel stable
```

Optional release notes and an explicit build number can be supplied:

```bash
./release-scripts/release-easydict.sh release 2.22.0 \
    --notes /absolute/path/release-notes.md \
    --build-number 64
```

Without `--build-number`, the workflow increments the Xcode build number. The
version must be greater than the newest Sparkle feed version, and the build
must be greater than the newest feed build.

## Safer staged commands

Use a smaller workflow when a release needs human inspection between stages:

```bash
# Build, sign, notarize, package, generate appcast, and verify locally.
./release-scripts/release-easydict.sh prepare 2.22.0

# Prepare, synchronize the release refs, and create a verified GitHub draft.
./release-scripts/release-easydict.sh draft 2.22.0

# Publish an existing verified draft, install the appcast, and verify remotely.
./release-scripts/release-easydict.sh publish 2.22.0
```

Pass the same `--channel stable` option to a separate `publish` command when
the prepared release is stable.

Preview the exact `asc` plan without executing release steps:

```bash
./release-scripts/release-easydict.sh release 2.22.0 --dry-run
```

## Resume after failure

`asc` records run state under `.asc/runs/`, which Git ignores. After fixing a
transient problem, resume with the run ID printed by `asc`:

```bash
./release-scripts/release-easydict.sh resume <run-id>
```

Release state and artifacts are kept in `.tmp/release/<version>/` for audit and
recovery. A successful publish removes only the isolated Git worktree. Each
stage is written to be safe to retry or to fail before replacing an existing
remote asset or feed entry.

## What the full workflow does

The `release` workflow performs these checkpoints in order:

1. Validate tools, credentials, certificate, Sparkle key, notes, and config.
2. Merge remote `main` into remote `dev` in an isolated worktree.
3. Update and commit Xcode marketing/build versions.
4. Archive with `asc xcode archive` and export with `xcodebuild`.
5. Submit the app for notarization, staple it, and verify Gatekeeper.
6. Produce Sparkle ZIP and DMG artifacts; notarize and staple the DMG.
7. Generate and strictly validate a candidate `appcast.xml`.
8. Atomically push `dev`, `main`, and the annotated version tag.
9. Create and verify a GitHub draft with ZIP, DMG, and checksums.
10. Publish the GitHub release, install the appcast, and atomically update both
    branches again.
11. Verify remote refs, release assets, and the public Sparkle feed before
    removing the isolated worktree.

The public feed is updated only after the GitHub release is published, so it
never advertises an unavailable archive. A failure before that point leaves a
GitHub draft and resumable local state rather than a half-published feed.

## Files

- `.asc/workflow.json`: workflow graph and checkpoints.
- `release-easydict.sh`: stable command-line entry point.
- `release-common.sh`: paths, release configuration, and safety helpers.
- `release-preflight.sh`: local environment and release-state checks.
- `release-branch-sync.sh`: isolated worktree and branch/tag synchronization.
- `release-build.sh`: version, archive, and export stages.
- `release-package.sh`: notarization, ZIP, DMG, and checksums.
- `release-appcast.sh` / `release-appcast.py`: Sparkle generation and strict
  feed validation.
- `release-github.sh`: idempotent draft/publish and asset verification.
- `release-verify.sh`: local artifact and final remote verification.
- `export-options.plist`: Developer ID export settings.

Repository/team defaults are environment-overridable in `release-common.sh`,
but the normal Easydict release should not need flags beyond version, channel,
and notes.

## Failure behavior

- Dirty original checkout: allowed except for `.asc/` and `release-scripts/`;
  the workflow never builds from that checkout.
- Dirty release worktree: stop, preserving state for inspection.
- `dev`/`main` merge conflict: stop before versioning or pushing.
- Existing tag on another commit: stop.
- Existing release asset with a different size: stop instead of overwriting.
- Notarization or signature failure: stop before GitHub publication.
- Unexpected changes to older appcast entries: stop before feed installation.
- Remote verification failure: preserve the release directory for diagnosis and
  resume.
