#!/usr/bin/env bash
set -euo pipefail

# Check that the dotfiles CLI bundle can be installed from the binary cache alone.
#
# Usage:
#   scripts/check-flake-cache.sh [extra nix build args...]
#   scripts/check-flake-cache.sh --override-input nixpkgs-foo github:NixOS/nixpkgs/nixpkgs-unstable
#
# Exit status:
#   0  every package is substitutable
#   1  some derivations would build locally (printed to stdout, one per line)
#   2  evaluation failed (nix output printed to stderr)

cd "$(dirname "$0")/.."

# The bundle itself is a buildEnv symlink farm, so its hash changes with every
# lock bump and it is never in the public cache. Only its inputs have to be
# substitutable, hence the dry run plus the dotfiles-cli exclusion.
if ! plan="$(nix build "path:." --no-link --max-jobs 0 --dry-run "$@" 2>&1)"; then
  echo "$plan" >&2
  exit 2
fi

uncached="$(printf '%s\n' "$plan" \
  | grep -o '/nix/store/[^ ]*\.drv' \
  | grep -v -- '-dotfiles-cli\.drv$' || true)"

if [ -n "$uncached" ]; then
  echo "$uncached"
  exit 1
fi
