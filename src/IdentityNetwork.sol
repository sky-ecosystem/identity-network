// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { IIdentityNetwork } from "src/IIdentityNetwork.sol";

contract IdentityNetwork is IIdentityNetwork {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Auth ---
    mapping(address usr => uint256 allowed) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "IdentityNetwork/not-authorized");
        _;
    }

    // --- Data ---
    EnumerableSet.AddressSet private _subnets;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event AddSubnet(address indexed subnet);
    event RemoveSubnet(address indexed subnet);

    // --- Constructor ---
    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Subnet Management ---
    function addSubnet(address subnet) external auth {
        _subnets.add(subnet);
        emit AddSubnet(subnet);
    }

    function removeSubnet(address subnet) external auth {
        _subnets.remove(subnet);
        emit RemoveSubnet(subnet);
    }

    function addSubnetBatch(address[] calldata subs) external auth {
        for (uint256 i; i < subs.length;) {
            _subnets.add(subs[i]);
            emit AddSubnet(subs[i]);
            unchecked { ++i; }
        }
    }

    function removeSubnetBatch(address[] calldata subs) external auth {
        for (uint256 i; i < subs.length;) {
            _subnets.remove(subs[i]);
            emit RemoveSubnet(subs[i]);
            unchecked { ++i; }
        }
    }

    // --- Query ---
    function isMember(address usr) external view returns (uint256) {
        uint256 len = _subnets.length();
        for (uint256 i; i < len;) {
            if (IIdentityNetwork(_subnets.at(i)).isMember(usr) == 1) {
                return 1;
            }
            unchecked { ++i; }
        }
        return 0;
    }

    function isSubnet(address subnet) external view returns (uint256) {
        return _subnets.contains(subnet) ? 1 : 0;
    }

    function subnetCount() external view returns (uint256) {
        return _subnets.length();
    }

    function subnetAt(uint256 idx) external view returns (address) {
        return _subnets.at(idx);
    }

    function getSubnets() external view returns (address[] memory) {
        return _subnets.values();
    }
}
