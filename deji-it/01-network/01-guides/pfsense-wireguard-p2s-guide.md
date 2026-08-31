# WireGuard Point-to-Site (P2S) on pfSense — Manual Setup Guide

Point-to-Site = individual remote devices (phone, laptop) connecting into your network, as opposed to Site-to-Site (S2S), which links two whole networks together. This guide covers manual configuration end to end, no wizards, based on a working setup.

---

## Core concepts before you start

- **WireGuard tunnels are not VLANs.** A VLAN needs a physical NIC and tagged trunk traffic from a switch. A WireGuard tunnel is a virtual interface (`tun_wgN`) that terminates encrypted UDP from remote peers directly — no switch involved. Don't create a VLAN expecting it to "catch" WireGuard clients; assign the tunnel interface itself.
- **Allowed IPs means something different on each side:**
    - **On the pfSense peer entry** — identifies the peer. Should be narrow: exactly that device's tunnel IP (`/32`). Also acts as an anti-spoofing filter (pfSense only accepts packets claiming that source).
    - **On the client config** — routing instruction. Broad: every destination subnet you want that device to reach through the tunnel.
- **A tunnel handshake succeeding only proves the encrypted transport works.** It does not mean routing, firewall rules, or DNS are correct. Test each layer separately: handshake → ping tunnel gateway → ping internal hosts → DNS resolution.
- **Double-NAT is normal.** If your ISP router does NAT and pfSense WAN sits behind it on a private range, that's fine — just make sure the port forward, the pfSense WAN rule, and the client's Endpoint IP are all set to the _actual public-facing_ IP, not the private one pfSense sees.

> **Addressing note:** This revision uses `10.0.0.0/24` for the WireGuard client subnet (changed from `172.16.0.0/24`, which collided with Docker's default bridge network on TrueNAS and broke routing/communication for containerized services). The tunnel subnet is a subset of the `10.0.0.0/16` supernet used in client `AllowedIPs` — that's expected and correct, not a conflict (AllowedIPs is meant to include the tunnel subnet plus every other internal range you want routed).

---

## 1. Plan your addressing

Pick a subnet dedicated to WireGuard clients, distinct from existing VLANs — e.g. `10.0.0.0/24`. Reserve:

- `.1` — pfSense's own tunnel address (acts as gateway)
- `.2`, `.3`, `.4`... — one per client device

Decide upfront which internal subnets each device type should reach — this drives both the client Allowed IPs and the firewall rules later.

---

## 2. Create the tunnel (server side)

`VPN > WireGuard > Tunnels > Add Tunnel`

|Field|Value|Why|
|---|---|---|
|Enable Tunnel|checked|required before it can be assigned as an interface|
|Description|e.g. `wg-remote-access`|reference only|
|Listen Port|`51820` (or custom)|this is the port you'll forward/open on WAN|
|Interface Keys|click Generate|creates pfSense's own keypair; only the **public** key ever needs to leave this box|
|Interface Addresses|e.g. `10.0.0.1/24`|pfSense's own address inside the tunnel subnet|

Save. Copy the tunnel's **public key** somewhere — every client config needs it.

---

## 3. Assign the tunnel as a real interface

`Interfaces > Assignments` — select the new `tun_wgN` from the dropdown, add it.

Click into the new interface entry:

- Enable
- IPv4 Configuration Type: **Static** (should already be populated from step 2)
- Save, Apply Changes

It now behaves like any other pfSense interface for firewall/routing purposes.

---

## 4. Open the port on WAN

`Firewall > Rules > WAN` → Add:

- Protocol: **UDP**
- Destination: **WAN address**
- Destination port: your listen port (e.g. `51820`)
- Description: `Allow WireGuard`

If pfSense's WAN sits behind another router (double-NAT), also configure port forwarding on that upstream router: WAN port → pfSense's WAN IP, same port, UDP.

---

## 5. Add a peer per device

`VPN > WireGuard > Peers > Add Peer`, one entry per device:

|Field|Value|Notes|
|---|---|---|
|Tunnel|your tunnel|e.g. `tun_wg0 (wg-remote-access)`|
|Description|e.g. `android-phone`||
|Dynamic Endpoint|checked|correct for mobile/roaming devices without a fixed IP|
|Keep Alive|`25`|keeps NAT mappings alive on both ends|
|Public Key|_(from the device, once generated there)_|this is the peer's key, not the tunnel's|
|Pre-shared Key|optional, Generate if used|adds a symmetric layer; must match exactly on the client|
|Allowed IPs|that device's tunnel IP only, e.g. `10.0.0.2/32`|narrow — identifies the peer, doesn't grant routing|
||||

Save. Repeat per device.

---

## 6. Client configuration (generic — Linux/desktop syntax, values map directly to mobile apps too)

```ini
[Interface]
PrivateKey = <client's own private key>
Address = 10.0.0.2/32
DNS = 10.0.0.1                # optional, only if you want internal DNS resolution

[Peer]
PublicKey = <pfSense tunnel public key>
PresharedKey = <only if set on the pfSense peer entry>
Endpoint = <public IP or DDNS hostname>:51820
AllowedIPs = 10.0.0.0/24, 10.0.0.0/16   # tunnel subnet + every internal range you want reachable — check these don't overlap, see note above
PersistentKeepalive = 25
```

Key points:

- The client generates its own keypair — the private key never goes to pfSense, only the public key does.
- `AllowedIPs` must include the tunnel subnet itself (`10.0.0.0/24`) _and_ every internal subnet you want routed — omit general internet ranges (`0.0.0.0/0`) unless you deliberately want full-tunnel.
- If you're behind CGNAT or an unpredictable public IP, use Dynamic DNS (`Services > Dynamic DNS` on pfSense) and put the hostname in Endpoint instead of a raw IP.

---

## 7. Enable DNS forwarding for the new interface (easy to miss)

If you set `DNS = 10.0.0.1` on clients, pfSense's resolver won't answer unless it's explicitly told to listen on the new interface.

`Services > DNS Resolver` (or `DNS Forwarder`, whichever you run) → **Interfaces** section → add the WireGuard interface (e.g. `deji-vpn`) to the list of interfaces it listens on. Also check **Access Lists** if you've restricted who can query it — the WireGuard subnet needs to be permitted.

This one is the single most common "tunnel works, ping works, but nothing loads" cause.

---

## 8. Firewall rules — from test-mode to production

**Test phase**: one temporary Pass any-any rule on the WireGuard interface tab, to confirm the tunnel and routing work before debugging permissions.

**Production phase**: replace it with explicit allow rules, ordered top-to-bottom (first match wins, default is deny):

```
Pass  TCP  source: 10.0.0.0/24          dest: 10.0.10.0/24 port 443   (admin panels)
Pass  TCP  source: 10.0.0.3/32          dest: 10.0.20.5    port 8096  (desktop-only: media server)
Pass  ICMP source: 10.0.0.0/24          dest: 10.0.0.0/16             (ping for troubleshooting)
```

Considerations:

- Use each peer's individual `/32` as source instead of the whole tunnel subnet if different devices should have different access levels.
- Gate by port, not just subnet, for anything sensitive — "any protocol to this subnet" is broader than most use cases actually need.
- Check the **destination** VLAN's own interface rules too — a Pass rule on the WireGuard interface only covers the outbound leg; the destination VLAN needs to accept traffic sourced from the tunnel subnet as well.
- Decide deliberately whether pfSense's own GUI/SSH should be reachable from the tunnel subnet, rather than leaving it open by accident via a broad LAN rule.
- Use Aliases (`Firewall > Aliases`) for any group of IPs/subnets you'll reference in more than one rule.

---

## 9. Testing checklist, in order

1. **Handshake** — `VPN > WireGuard > Status` on pfSense, and the client app/tool — should show a recent, updating timestamp on both ends.
2. **Tunnel gateway reachable** — `ping 10.0.0.1` from the client. Confirms interface + basic routing.
3. **Internal host reachable** — `ping` a known internal IP. Confirms firewall rules and Allowed IPs routing are correct.
4. **DNS resolution** — try resolving an internal hostname. Confirms resolver is listening on the tunnel interface.
5. **Actual service access** — browse to an internal service by hostname.

If a step fails, the previous step passing tells you which layer to focus on — don't jump straight to firewall rules if the handshake itself isn't happening, and don't blame DNS if raw IP ping already fails.

---

## 10. Common pitfalls recap

|Symptom|Likely cause|
|---|---|
|No handshake ever|WAN firewall rule missing, port forward misconfigured, wrong public IP used as Endpoint, or CGNAT|
|Handshake works, nothing pingable, not even gateway|Interface not enabled, or interface firewall rules blocking even the gateway|
|Gateway pings, internal hosts don't|Client's Allowed IPs doesn't include that subnet yet — remember to toggle tunnel off/on after editing|
|Internal hosts ping by IP, hostnames don't resolve|DNS resolver not listening on the WireGuard interface|
|Works on WiFi at home but not expected to — false negative|Testing over home WiFi hairpins back to your own public IP, which most routers block; always test from an external network (cellular data)|
|Public IP looks fine but nothing ever arrives|Possible CGNAT — check if the ISP router's actual WAN IP falls in `100.64.0.0/10`; if so inbound port-forwarding won't work without a relay/VPS or a static IP add-on from the ISP|
|Tunnel subnet overlaps a Docker bridge network, causing routing/communication failures for containerized services|Docker's default bridge networks commonly land in `172.17.0.0/16`–`172.31.0.0/16`; before locking in a WireGuard client subnet, check `docker network ls` / `docker network inspect` on any Docker hosts (e.g. TrueNAS apps) to avoid a collision|
|</document_content>||