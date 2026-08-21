# vpn-split-route

Routes only selected domains through a VPN, leaving everything else on the
normal default route. For VPNs where a handful of hosts are reachable only from
the VPN's egress IP, but sending all traffic through the tunnel is wasteful.

macOS routes by IP, so this works by resolving the configured domains and
pinning host routes for the resulting addresses to the VPN interface.

## Prerequisite

The VPN must be split-tunnelled, otherwise there is nothing to fix:

> System Settings → Network → VPN → *service* → Details →
> **uncheck "Send all traffic over VPN connection"**

## Setup

```bash
mkdir -p ~/.config/vpn-split-route
cp ~/.local/share/vpn-split-route/config.example ~/.config/vpn-split-route/config
$EDITOR ~/.config/vpn-split-route/config
```

`service` is the name as printed by `scutil --nc list`.

The real config stays outside this repository on purpose: it names internal
hosts, and this repository is public.

## Usage

```bash
vpn-split-route connect      # connect, wait, then add the routes
vpn-split-route sync         # (re-)add routes for an already-connected VPN
vpn-split-route status       # show VPN state and whether each address is routed
vpn-split-route disconnect
```

`connect` and `sync` shell out to `sudo` for `route`, so expect a password
prompt. Bringing the VPN up needs no privileges.

The connect step uses `networksetup -connectpppoeservice`, not
`scutil --nc start`. macOS keeps the L2TP password and the IPSec shared secret
in `/Library/Keychains/System.keychain`, and `scutil` fails to resolve them —
even under `sudo` — with "IPSec 共有シークレットが見つかりません". `networksetup`
takes the same path the GUI does. Despite the name, its PPPoE verbs drive
PPP-based VPNs such as L2TP.

## Notes

- The kernel drops the host routes together with the VPN interface, so nothing
  needs cleaning up on disconnect — but the routes must be re-added after every
  connect. That is what `connect` does in one step.
- Load-balanced targets rotate their addresses. If a host stops responding
  mid-session, `sync` re-resolves and adds whatever is missing.
- Routing is IPv4-only. A target that gains an AAAA record may be reached over
  IPv6 outside the tunnel, bypassing this entirely.
- The interface is resolved per service rather than assumed to be `ppp0`;
  a second VPN connected first will take that name.
