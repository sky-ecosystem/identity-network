# Identity Network

On-chain identity verification registries for the Sky ecosystem. See the [docs](https://github.com/sky-ecosystem/laniakea-docs/blob/main/sky-agents/halo-agents/identity-network.md).

```
                        Your Contract
                             |
                      isMember(addr)
                             |
                             v
                      IdentityNetwork
                      /      |      \
              isMember(addr) |  isMember(addr)
                  /          |          \
                 v           v           v
            SubnetUS    SubnetEU    SubnetInst
            [members]   [members]   [members]
```

## Contracts

- **`IIdentityNetwork`** - Shared interface exposing `isMember(address) -> bool`.
- **`IdentitySubnet`** - Leaf-level member set. Buds (semi-trusted operators) can add/remove members. Wards manage auth and bud access.
- **`IdentityNetwork`** - Aggregator of subnets. `isMember` loops all registered subnets. Buds manage the subnet list.
- **`IdentityFactory`** - Deploys subnets and networks with initial admin, buds, and members/subnets in one call.

## Build & Test

```shell
forge build
forge test
```
