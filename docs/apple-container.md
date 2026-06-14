# Apple container

This repository installs Apple's `container` CLI through the Homebrew formula
in `Brewfile.formulae`. Homebrew manages runtime upgrades and the placement of
the CLI and service plugins. The system services are started manually when
needed.

The initial proof of concept uses `container machine` as a persistent Linux
development environment. Docker Desktop remains installed for Compose,
Dev Containers, Testcontainers, and tools that require the Docker Engine API.

## Install

Preview and apply the chezmoi changes:

```sh
chezmoi diff
chezmoi apply
```

After the first install, start the system and allow it to install the default
Linux kernel:

```sh
container system start --enable-kernel-install
```

Apple container does not currently start automatically after a Mac restart.
Start it manually when needed:

```sh
container system start
```

Verify the installation:

```sh
container system status
container system version
```

Stop the system when it is no longer needed:

```sh
container system stop
```

Update it through the normal Homebrew workflow:

```sh
brew update
brew upgrade container
```

## Create a PoC machine

Start with an Ubuntu machine that has limited host access:

```sh
container machine create \
  --name dev-poc \
  --set-default \
  --cpus 4 \
  --memory 8G \
  --home-mount ro \
  ubuntu:24.04
```

Open a login shell:

```sh
container machine run
```

Run a command as root when installing system packages:

```sh
container machine run --root
```

Use the read-only home mount first. Change it to read-write only if the
workflow requires direct access to host repositories:

```sh
container machine stop
container machine set home-mount=rw
container machine run
```

For stronger separation, keep source code in the machine filesystem and clone
the repository from inside the machine using an authentication method chosen
for the PoC.

## Evaluate

Use one real project for the PoC and check:

1. Dependency installation and build time.
2. Test execution time.
3. File watching and hot reload.
4. LSP and editor integration.
5. Recovery after stopping and restarting the machine.
6. Whether Docker Desktop is still needed during normal development.

## Remove the PoC

```sh
container machine stop dev-poc
container machine delete dev-poc
```

After deleting any machines that are no longer needed, uninstall the runtime
through Homebrew:

```sh
brew uninstall container
```

Homebrew does not remove Apple container's application data. Avoid deleting
that data manually during the PoC; remove machines with
`container machine delete` instead.
