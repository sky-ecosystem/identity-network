# Identity Network

On-chain identity verification registries for the Sky ecosystem. See the [docs](https://github.com/sky-ecosystem/laniakea-docs/).

## Contracts

- **`IIdentityNetwork`** - Shared interface exposing `isMember(address) -> bool`.
- **`IdentityNetwork`** - Holds both a direct member set and a list of child subnets. `isMember` checks direct members first, then loops all registered subnets. Buds manage members and subnets. Wards manage auth and bud access.

### Deploy Libraries (`deploy/`)

- **`IdentityNetworkDeploy`** - `deploy(deployer, owner)` deploys a new `IdentityNetwork` and hands ward over from the deployer to the owner.
- **`IdentityNetworkInit`** - `init(network, buds, members, subnets)` configures a network's initial buds, members and subnets. Must be executed by a ward of the network (e.g. the pause proxy within a spell); the executor is temporarily kissed to add members/subnets and dissed afterwards.
- **`IdentityNetworkDeployer`** - One-time deployer contract: deploys a network and initializes it via `IdentityNetworkInit` in its constructor, hands ward over to `cfg.admin` and keeps no permissions. The network address is exposed via `network()`.

### Access Control

Two-tier auth model following MakerDAO conventions:

| Role | Set by | Can do |
|------|--------|--------|
| **Wards** (`rely`/`deny`) | Other wards | Manage wards and buds |
| **Buds** (`kiss`/`diss`) | Wards | Add/remove members and subnets |

### Membership Resolution

`isMember(usr)` traverses the tree — direct members first, then each subnet recursively:

```
isMember(0xABC)
  │
  ├─ 0xABC in directMembers?  ──► yes → return true
  │
  └─ for each subnet:
       subnet.isMember(0xABC)?  ──► yes → return true
                                        (subnet checks its own
                                         directMembers + subnets)
  return false
```

Subnets are themselves `IIdentityNetwork` contracts, so networks can be composed (by convention, into trees, though the code itself doesn't enforce the shape).

## Build & Test

```shell
forge build
forge test
```
