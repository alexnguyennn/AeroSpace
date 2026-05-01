# Local Install

Download a release (or branch build artifact), back up the current install,
and replace `/Applications/AeroSpace.app` and `/opt/homebrew/bin/aerospace`.

**Always confirm the plan with the user via the question tool before executing.**

## Input: three ways to get the artifact

### From a GitHub release tag

```bash
TAG="v0.20.3-Beta-d11b0900-alex"  # replace with actual tag
WORKDIR="/tmp/aerospace-install"
mkdir -p "$WORKDIR"

# Download the release zip
gh release download "$TAG" \
  --repo alexnguyennn/AeroSpace \
  --pattern "AeroSpace-*.zip" \
  --output "$WORKDIR/release.zip"
```

### From a run ID

```bash
RUN_ID="25243830851"  # replace with actual run ID
WORKDIR="/tmp/aerospace-install"
mkdir -p "$WORKDIR"

# Download artifacts from the build
gh run download "$RUN_ID" \
  --repo alexnguyennn/AeroSpace \
  --dir "$WORKDIR"
```

Branch artifacts are uploaded per-matrix job. Look for the macos-15 or
macos-26 release folder. The artifact itself is a zip containing another zip.

### From a direct artifact URL (no gh auth required)

The user may provide a GitHub Actions artifact URL like:
`https://github.com/alexnguyennn/AeroSpace/actions/runs/25243830851/artifacts/6760633259`

This is a direct browser download link. Use `curl` -- no `gh` auth needed:

```bash
URL="https://github.com/alexnguyennn/AeroSpace/actions/runs/25243830851/artifacts/6760633259"
WORKDIR="/tmp/aerospace-install"
mkdir -p "$WORKDIR"

curl -L -o "$WORKDIR/artifact.zip" "$URL"
unzip -o "$WORKDIR/artifact.zip" -d "$WORKDIR"
```

**Note:** Local install from a direct URL works without `gh` authentication.
Only release tagging, build monitoring, and brew tap operations require `gh` auth.

## Extract

The release zip contains a versioned folder with the app and binary:

```
AeroSpace-v{version}.zip
  └── AeroSpace-v{version}/
      ├── AeroSpace.app/
      ├── bin/
      │   └── aerospace
      ├── legal/
      ├── manpage/
      └── shell-completion/
```

For branch build artifacts, there may be an outer artifact zip wrapping the
inner release zip:

```bash
cd "$WORKDIR"

# If from branch build, find the inner zip
INNER_ZIP=$(find . -name "AeroSpace-*.zip" -type f | head -1)
if [ -n "$INNER_ZIP" ]; then
  unzip -o "$INNER_ZIP" -d "$WORKDIR/extracted"
else
  unzip -o release.zip -d "$WORKDIR/extracted"
fi

# Find the versioned directory
APP_DIR=$(find "$WORKDIR/extracted" -name "AeroSpace.app" -type d | head -1 | xargs dirname)
echo "App dir: $APP_DIR"
```

## Confirm with user

Before proceeding, present the plan:

```
Plan:
- Back up /Applications/AeroSpace.app -> /Applications/AeroSpace.app.bk
- Back up /opt/homebrew/bin/aerospace -> /opt/homebrew/bin/aerospace.bk
- Copy {APP_DIR}/AeroSpace.app -> /Applications/AeroSpace.app
- Copy {APP_DIR}/bin/aerospace -> /opt/homebrew/bin/aerospace
- Remove quarantine attributes

Proceed? (yes/no)
```

Use the question tool for this confirmation.

## Back up and replace

```bash
# Back up existing
if [ -d "/Applications/AeroSpace.app" ]; then
  rm -rf "/Applications/AeroSpace.app.bk"
  mv "/Applications/AeroSpace.app" "/Applications/AeroSpace.app.bk"
fi

if [ -f "/opt/homebrew/bin/aerospace" ]; then
  rm -f "/opt/homebrew/bin/aerospace.bk"
  mv "/opt/homebrew/bin/aerospace" "/opt/homebrew/bin/aerospace.bk"
fi

# Install new
cp -R "$APP_DIR/AeroSpace.app" /Applications/
cp "$APP_DIR/bin/aerospace" /opt/homebrew/bin/

# Remove quarantine
xattr -d com.apple.quarantine /Applications/AeroSpace.app
xattr -d com.apple.quarantine /opt/homebrew/bin/aerospace
```

## Verify

```bash
/opt/homebrew/bin/aerospace --version
ls -la /Applications/AeroSpace.app
ls -la /Applications/AeroSpace.app.bk
```

## Rollback

If something goes wrong:

```bash
rm -rf /Applications/AeroSpace.app
mv /Applications/AeroSpace.app.bk /Applications/AeroSpace.app

rm -f /opt/homebrew/bin/aerospace
mv /opt/homebrew/bin/aerospace.bk /opt/homebrew/bin/aerospace
```

## Cleanup

```bash
rm -rf "$WORKDIR"
```
