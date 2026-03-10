# Identity Network

On-chain identity verification registries for the Sky ecosystem. See the [docs](https://github.com/sky-ecosystem/laniakea-docs/blob/main/sky-agents/halo-agents/identity-network.md).

## Contracts

- **`IIdentityNetwork`** - Shared interface exposing `isMember(address) -> bool`.
- **`IdentityNetwork`** - Holds both a direct member set and a list of child subnets. `isMember` checks direct members first, then loops all registered subnets. Buds manage members and subnets. Wards manage auth and bud access.
- **`IdentityFactory`** - Deploys networks with initial admin, buds, members, and subnets in one call.

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

Subnets are themselves `IIdentityNetwork` contracts, so networks compose into trees.

## Build & Test

```shell
forge build
forge test
```
