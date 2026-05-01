# Release Workflow

Step-by-step commands for cutting a release from the AeroSpace fork.

## Prerequisites

- Branch `rr/customise` or `rr/customise-update` is up to date
- All local changes are committed (no dirty worktree)
- The branch build is green (verify first if unsure)

## Verify branch build is green

```bash
gh run list --repo alexnguyennn/AeroSpace --branch rr/customise-update --limit 3
```

If the latest run is not `success`, either wait or push and monitor:

```bash
CI=true git push --force-with-lease origin rr/customise-update
# wait for run to appear
sleep 10
gh run list --repo alexnguyennn/AeroSpace --branch rr/customise-update --limit 1
gh run watch <RUN_ID> --repo alexnguyennn/AeroSpace
```

**Do not proceed to tagging until all jobs are green.**

## Determine the version tag

Convention: `v{upstream_version}-{short_sha}-alex`

```bash
UPSTREAM_VERSION="0.20.3-Beta"  # match the upstream tag we're based on
SHORT_SHA=$(git rev-parse --short HEAD)
TAG="v${UPSTREAM_VERSION}-${SHORT_SHA}-alex"
echo "Tag: $TAG"
```

## Tag and push

```bash
CI=true git tag "$TAG"
git push origin "$TAG"
```

This triggers the CI workflow (`.github/workflows/build.yml`) with the
release job enabled (`if: startsWith(github.ref, 'refs/tags/v')`).

## Monitor the release build

```bash
sleep 15
gh run list --repo alexnguyennn/AeroSpace --limit 1
gh run watch <RUN_ID> --repo alexnguyennn/AeroSpace
```

Wait for all jobs: `build-debug` (macos-14, 15, 26), `build-release`
(macos-15, 26), and `Create GitHub Release`.

## Verify the release

```bash
gh release view "$TAG" --repo alexnguyennn/AeroSpace --json assets \
  --jq '.assets[] | {name, size, url}'
```

Expected assets:
- `AeroSpace-v{version}.zip` (~8-9 MB)
- `aerospace.rb` (~1.3 KB)

Note the **sha256** from the asset digest for the brew tap update:
```bash
gh release view "$TAG" --repo alexnguyennn/AeroSpace --json assets \
  --jq '.assets[] | select(.name | endswith(".zip")) | .digest'
```

## Handle build failures

If any job fails:
- Fetch logs: `gh run view <RUN_ID> --repo alexnguyennn/AeroSpace --log-failed`
- Grep for the error: look for `error:`, `FAILED`, or `Exit code`
- Common causes: visibility (`public` vs `internal`), missing imports, Xcode version
- Fix, commit (fixup + autosquash if appropriate), push branch, re-monitor
- Once green, delete the failed tag and re-tag:
  ```bash
  git tag -d "$TAG" && git push origin ":refs/tags/$TAG"
  # re-create with new HEAD
  ```

## Branch build (pre-release verification)

To verify a branch build without creating a release:

```bash
CI=true git push --force-with-lease origin rr/customise-update
sleep 10
RUN_ID=$(gh run list --repo alexnguyennn/AeroSpace --branch rr/customise-update --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$RUN_ID" --repo alexnguyennn/AeroSpace
```

After the build passes, get the artifact download URL:
```bash
gh run view "$RUN_ID" --repo alexnguyennn/AeroSpace --json jobs \
  --jq '.jobs[] | select(.name | contains("release")) | {name, conclusion}'
```

Artifacts are uploaded per-job. Download with:
```bash
gh run download "$RUN_ID" --repo alexnguyennn/AeroSpace --dir /tmp/aerospace-build
```
