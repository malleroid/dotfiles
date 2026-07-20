# Nix Flake Operations

Day-to-day operations for the Nix CLI bundle. The source of truth is `flake.nix` (package list) and `flake.lock` (pinned input revisions). `package-versions.json` is a generated manifest (package → version) committed alongside the lock so that lock bumps produce human-readable diffs; regenerate it with `scripts/bump-flake.sh`, never edit it by hand. Installation is automated via the chezmoi script `run_onchange_after_10-nix-packages.sh.tmpl`.

Policy: the bundle never builds locally — a revision is only accepted when every package is available from the binary cache. `scripts/bump-flake.sh` enforces this with `nix build --max-jobs 0`.

## Adding a package

```sh
# 1. Edit flake.nix — add the package to paths in the appropriate `## Category`
# 2. Verify cache hit and regenerate the version manifest
scripts/bump-flake.sh   # no args: no lock change, verify + regenerate only

# 3. Re-install bundle
chezmoi apply

# 4. Verify and commit
which <pkg>
git add flake.nix flake.lock package-versions.json  # flake.lock not always changed
git commit -m ":heavy_plus_sign: add <pkg> to nix bundle"
```

If `scripts/bump-flake.sh` fails the cache check, the package isn't cached for `aarch64-darwin` at the current pinned revision. See [Cache miss handling](#cache-miss-handling).

## Removing a package

```sh
# 1. Edit flake.nix — delete the package line
# 2. Regenerate the version manifest
scripts/bump-flake.sh

# 3. Apply (bundle re-installs without it)
chezmoi apply

# 4. Verify removed
which <pkg>   # should fail
git add flake.nix package-versions.json
git commit -m ":heavy_minus_sign: remove <pkg> from nix bundle"
```

The new bundle does not include the package, so it is removed from `~/.nix-profile/bin` after re-install. The store path remains until garbage collection.

## Regular updates

Recommended cadence: monthly, or whenever new package versions are needed. Updates are manual and always go through `scripts/bump-flake.sh`:

```sh
scripts/bump-flake.sh latest    # move nixpkgs input to newest nixpkgs-unstable
scripts/bump-flake.sh <rev>     # pin nixpkgs input to an exact revision
```

The script:
1. Updates (or pins) the `nixpkgs` input in `flake.lock`
2. Verifies binary cache coverage with `nix build --max-jobs 0` — fails hard if anything would build locally
3. Regenerates `package-versions.json`
4. Shows the per-package version diff for human review, then stops (no commit)

After reviewing the diff:
```sh
git add flake.lock package-versions.json
git commit -m ":up: bump nixpkgs lockfile"
chezmoi apply   # re-install bundle with new revisions
```

Note: the former fish function `nix-update-bundle` was removed in favor of this script; the deployed copy is cleaned up from machines via `.chezmoiremove`.

## Cache miss handling

When `scripts/bump-flake.sh` fails the cache check (some packages would need a local build), you have three options:

### Revert update
Most conservative. The current committed `flake.lock` is fine; just throw away the update.
```sh
git restore flake.lock
```
Try again later — the cache may catch up. Or try a slightly older revision with `scripts/bump-flake.sh <rev>` until the check passes.

### Pin the offender separately
For packages that consistently lag on `aarch64-darwin` (e.g., `yt-dlp` chains in `deno`/`rusty-v8`), pin them to a known-cached revision in a dedicated input.

```nix
# flake.nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # YYYY-MM-DD: <reason>
  nixpkgs-<pkg>.url = "github:NixOS/nixpkgs/<rev-with-cache>";
};

outputs = { nixpkgs, nixpkgs-<pkg>, ... }:
  let
    pkgs = import nixpkgs { inherit system; };
    pkgs<Pkg> = import nixpkgs-<pkg> { inherit system; };
  in {
    packages.${system}.default = pkgs.buildEnv {
      paths = with pkgs; [
        # ...
        pkgs<Pkg>.<pkg>   # qualified reference, not bare name
      ];
    };
  };
```

Finding a cached revision: try the previous `flake.lock` revision, or use [lazamar.co.uk/nix-versions](https://lazamar.co.uk/nix-versions/).

After editing:
```sh
nix flake update         # picks up the new input
scripts/bump-flake.sh    # verify cache hit + regenerate manifest
chezmoi apply
```

## Reviewing pins

Pinned inputs accumulate over time. Run `nix-check-pins` to see if any can be merged back to the main `nixpkgs` input.

```sh
nix-check-pins
```

It uses `--override-input` to dry-run each pinned input as if it were main `nixpkgs`. If the result is fully cached, the pin is no longer needed.

To merge back:
1. Edit `flake.nix`:
   - Replace `pkgs<Pkg>.<pkg>` with `<pkg>` (drop the qualifier)
   - Remove `pkgs<Pkg> = import nixpkgs-<pkg> ...` from `let`
   - Remove `inputs.nixpkgs-<pkg>` and the corresponding `outputs` argument
2. `nix flake update` (drops the orphan input from lock)
3. `scripts/bump-flake.sh` (verify still cached + regenerate manifest)
4. Commit

## Garbage collection

Run periodically (monthly or so):

```sh
nix profile wipe-history --older-than 30d   # drop old generations
nix-collect-garbage -d                      # delete orphaned store paths
```

The first one is fast; the second can free several GB on a long-running machine.

## Recovery

### Profile entries duplicated or broken
If `nix profile list` shows multiple entries or stale ones:
```sh
nix profile remove --all
nix profile add "path:$HOME/ghq/github.com/malleroid/dotfiles"
```
Or `chezmoi apply` (the script does this automatically when `flake.{nix,lock}` change).

### `~/.nix-profile/bin/<X>` missing after install
Most often caused by editing `flake.nix` and forgetting `chezmoi apply`. Run `chezmoi apply`. If the script's hash trigger is stale:
```sh
nix profile remove dotfiles
nix profile add "path:$HOME/ghq/github.com/malleroid/dotfiles"
```

### Update broke something
Revert `flake.lock` (and the manifest that goes with it) to the previous commit:
```sh
git checkout HEAD~1 -- flake.lock package-versions.json
chezmoi apply
git add flake.lock package-versions.json
git commit -m ":rewind: revert nixpkgs lockfile"
```

### Shell broken because user-profile binaries gone
If you ran `nix profile remove --all` without immediate re-install, the running fish keeps working (binary mmap'd) but new sessions can't start (login shell points to gone binary).

Recovery from any working shell:
```sh
/nix/var/nix/profiles/default/bin/nix profile add "path:$HOME/ghq/github.com/malleroid/dotfiles"
```

The system `nix` binary at `/nix/var/nix/profiles/default/bin/nix` is unaffected by user profile removal.

## Fresh machine setup

The bootstrap commands in the main `README.md` (`sh -c "$(curl ...)" -- init --apply ...`) handle everything: chezmoi clones the repo, deploys dotfiles, runs `run_onchange_after_10-nix-packages.sh.tmpl`, which installs the bundle from `flake.lock`.

First install pulls every package; on a cold cache this can take 10–30 minutes. Subsequent applies are no-ops unless `flake.{nix,lock}` change.
