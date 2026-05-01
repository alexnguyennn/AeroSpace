# Brew Tap Update

Update the `alexnguyennn/tap` cask after a successful release.

## Prerequisites

- A GitHub release exists at `alexnguyennn/AeroSpace` with the `.zip` asset
- The sha256 digest is known (from the release asset metadata)

## Get version and sha256

The cask needs the release tag (for version) and the sha256 of the `.zip` asset.

### With gh auth

```bash
TAG="v0.20.3-Beta-d11b0900-alex"  # replace with actual tag

# Get sha256 from release asset digest
SHA256=$(gh release view "$TAG" --repo alexnguyennn/AeroSpace --json assets \
  --jq '.assets[] | select(.name | endswith(".zip")) | .digest' \
  | sed 's/sha256://')

VERSION="${TAG#v}"
echo "Version: $VERSION"
echo "SHA256: $SHA256"
```

### Without gh auth

Download the zip and compute sha256 locally:

```bash
TAG="v0.20.3-Beta-d11b0900-alex"  # replace with actual tag
VERSION="${TAG#v}"

# The release URL is public; download and hash it
curl -L -o /tmp/aerospace-release.zip \
  "https://github.com/alexnguyennn/AeroSpace/releases/download/$TAG/AeroSpace-$TAG.zip"
SHA256=$(shasum -a 256 /tmp/aerospace-release.zip | awk '{print $1}')
rm /tmp/aerospace-release.zip

echo "Version: $VERSION"
echo "SHA256: $SHA256"
```

### Last resort

If neither approach works (e.g. private repo, download fails), ask the user
to provide the tag and sha256 manually.

## Locate the tap

```bash
TAP_DIR="/opt/homebrew/Library/Taps/alexnguyennn/homebrew-tap"
CASK_FILE="$TAP_DIR/Casks/aerospace.rb"
cat "$CASK_FILE"
```

## Update version and sha256

Replace the `version` and `sha256` lines in the cask file. The URL template
`https://github.com/alexnguyennn/AeroSpace/releases/download/v#{version}/AeroSpace-v#{version}.zip`
uses interpolation so only version and sha256 need updating.

```bash
# Use sed or the edit tool to update these two lines:
#   version '...'
#   sha256 "..."
```

**Do not change the URL template, postflight, binary paths, or other lines.**

## Commit and push

```bash
cd "$TAP_DIR"
CI=true git add Casks/aerospace.rb
CI=true git commit -m "chore: bump aerospace to $TAG"
git push origin main
```

If push fails with no upstream:
```bash
git push --set-upstream origin main
```

## Verify

```bash
brew update
brew info alexnguyennn/tap/aerospace
```

The version should match the new tag. Upgrade with:
```bash
brew upgrade aerospace
# or via Nix:
# nh darwin switch -v .
```

## Cask file structure reference

The cask at `Casks/aerospace.rb` follows this structure (do not change
paths -- they match the release zip layout):

```ruby
cask "aerospace" do
  version 'X.Y.Z-Beta-HASH-alex'
  sha256 "..."
  url "https://github.com/alexnguyennn/AeroSpace/releases/download/v#{version}/AeroSpace-v#{version}.zip"
  name "AeroSpace"
  desc "AeroSpace is an i3-like tiling window manager for macOS"
  homepage "https://github.com/nikitabobko/AeroSpace"
  conflicts_with cask: 'aerospace-dev'
  depends_on macos: ">= :ventura"
  postflight do
    system "xattr -d com.apple.quarantine #{staged_path}/bin/aerospace"
    system "xattr -d com.apple.quarantine #{appdir}/AeroSpace.app"
  end
  app "AeroSpace.app"
  binary "bin/aerospace"
  # shell completions and manpages follow
end
```
