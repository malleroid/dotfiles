#!/usr/bin/env bash
set -euo pipefail

# Bump the pinned nixpkgs revision for the dotfiles CLI bundle.
#
# Policy: never build locally — a revision is only accepted when every
# package is available from the binary cache (enforced via --max-jobs 0).
#
# Usage:
#   scripts/bump-flake.sh            # no lock change; verify cache coverage
#                                    # and regenerate package-versions.json
#   scripts/bump-flake.sh latest     # move nixpkgs input to newest nixpkgs-unstable
#   scripts/bump-flake.sh <rev>      # pin nixpkgs input to an exact revision
#
# The script stops before committing. Review the shown diff, then commit
# flake.lock / flake.nix / package-versions.json together.

cd "$(dirname "$0")/.."

system="aarch64-darwin"
target="${1:-}"

case "$target" in
  "")
    echo "==> No update requested; verifying current lock only."
    ;;
  latest)
    echo "==> Updating nixpkgs input to newest nixpkgs-unstable..."
    nix flake update nixpkgs
    ;;
  *)
    echo "==> Pinning nixpkgs input to revision: $target"
    nix flake lock --override-input nixpkgs "github:NixOS/nixpkgs/$target"
    ;;
esac

echo "==> Verifying binary cache coverage (local builds forbidden)..."
if ! nix build "path:." --no-link --max-jobs 0; then
  echo "!! Some packages are not in the binary cache for this revision." >&2
  echo "!! Pick another revision. To undo the lock change:" >&2
  echo "!!   git restore flake.lock" >&2
  exit 1
fi

echo "==> Regenerating package-versions.json..."
nix eval --json "path:.#packageVersions.$system" | jq --sort-keys . > package-versions.json

echo "==> Done. Review the changes below, then commit manually:"
git --no-pager diff --stat -- flake.nix flake.lock package-versions.json
git --no-pager diff -- package-versions.json
