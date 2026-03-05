# Scripts

This directory contains the Aether fork-maintenance helpers used to keep
`Aether-Grid/openfang` aligned with `RightNow-AI/openfang`.

## Branch model

- `main`: exact upstream mirror. Do not develop here.
- `aether/main`: Aether working branch. Do your fork changes here.
- `aether-v*`: Aether release tags.

## Fork maintenance scripts

### `scripts/aether-sync-now.sh`

Triggers the GitHub Actions upstream mirror workflow immediately.

Examples:

```bash
scripts/aether-sync-now.sh
scripts/aether-sync-now.sh --wait
```

Notes:

- Requires `gh` to be installed and authenticated.
- Targets `Aether-Grid/openfang` and `aether/main` by default.

### `scripts/aether-update.sh`

Updates `aether/main` from the mirrored `origin/main`.

Examples:

```bash
scripts/aether-update.sh
scripts/aether-update.sh --merge
scripts/aether-update.sh --sync-now --wait
```

Behavior:

- Default mode is `rebase`.
- `--merge` uses a merge commit instead.
- `--sync-now --wait` first runs the upstream mirror workflow, then updates
  your Aether branch from the freshly mirrored `main`.
- Refuses to run with a dirty worktree.

### `scripts/aether-release.sh`

Creates and pushes an Aether release tag from `aether/main`.

Examples:

```bash
scripts/aether-release.sh 0.3.24.1
scripts/aether-release.sh v0.3.24.1
scripts/aether-release.sh aether-v0.3.24.1
```

Behavior:

- Normalizes tags to the `aether-v*` format.
- Fetches and fast-forwards `aether/main` before tagging unless `--no-pull`
  is provided.
- Refuses to create a tag if it already exists locally or on `origin`.

### `scripts/sync-upstream.sh`

Low-level mirror script used by the `Sync Upstream` GitHub Actions workflow.

Behavior:

- Mirrors upstream branches and tags into `origin`.
- Preserves `aether/*` branches.
- Preserves `aether-*` tags.

You normally do not need to run this script manually. Use
`scripts/aether-sync-now.sh` instead.

## Typical flow

Pull the latest upstream changes into the fork branch:

```bash
scripts/aether-update.sh
```

Force an upstream sync first, then update the fork branch:

```bash
scripts/aether-update.sh --sync-now --wait
```

Cut an Aether release:

```bash
scripts/aether-release.sh 0.3.24.1
```
