// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IdentitySubnet }  from "src/IdentitySubnet.sol";
import { IdentityNetwork } from "src/IdentityNetwork.sol";

contract IdentityFactory {

    // --- Events ---
    event CreateSubnet(address indexed subnet, address indexed admin);
    event CreateNetwork(address indexed network, address indexed admin);

    // --- Factory ---
    function createSubnet(address admin, address[] calldata members) external returns (address subnet) {
        IdentitySubnet s = new IdentitySubnet();
        if (members.length > 0) s.addMemberBatch(members);
        s.rely(admin);
        s.deny(address(this));
        subnet = address(s);
        emit CreateSubnet(subnet, admin);
    }

    function createNetwork(address admin, address[] calldata subnets) external returns (address network) {
        IdentityNetwork n = new IdentityNetwork();
        if (subnets.length > 0) n.addSubnetBatch(subnets);
        n.rely(admin);
        n.deny(address(this));
        network = address(n);
        emit CreateNetwork(network, admin);
    }
}
