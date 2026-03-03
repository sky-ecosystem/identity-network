// SPDX-FileCopyrightText: © 2026 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.24;

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { IIdentityNetwork } from "src/IIdentityNetwork.sol";

contract IdentityNetwork is IIdentityNetwork {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Auth ---
    mapping(address usr => uint256 allowed) public wards;
    mapping(address usr => uint256 allowed) public buds; // TODO: decide if we want to split this to two roles
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    function kiss(address usr) external auth { buds[usr] = 1; emit Kiss(usr); }
    function diss(address usr) external auth { buds[usr] = 0; emit Diss(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "IdentityNetwork/not-authorized");
        _;
    }
    modifier toll {
        require(buds[msg.sender] == 1, "IdentityNetwork/not-operator");
        _;
    }

    // --- Data ---
    EnumerableSet.AddressSet private _members;
    EnumerableSet.AddressSet private _subnets;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Kiss(address indexed usr);
    event Diss(address indexed usr);
    event AddMember(address indexed usr);
    event RemoveMember(address indexed usr);
    event AddSubnet(address indexed subnet);
    event RemoveSubnet(address indexed subnet);

    // --- Constructor ---
    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Member Management ---
    function addMember(address usr) external toll {
        _members.add(usr);
        emit AddMember(usr);
    }

    function removeMember(address usr) external toll {
        _members.remove(usr);
        emit RemoveMember(usr);
    }

    function addMemberBatch(address[] calldata usrs) external toll {
        for (uint256 i; i < usrs.length;) {
            _members.add(usrs[i]);
            emit AddMember(usrs[i]);
            unchecked { ++i; }
        }
    }

    function removeMemberBatch(address[] calldata usrs) external toll {
        for (uint256 i; i < usrs.length;) {
            _members.remove(usrs[i]);
            emit RemoveMember(usrs[i]);
            unchecked { ++i; }
        }
    }

    // --- Subnet Management ---
    // Warning: avoid adding subnets that create loops
    function addSubnet(address subnet) external toll {
        _subnets.add(subnet);
        emit AddSubnet(subnet);
    }

    function removeSubnet(address subnet) external toll {
        _subnets.remove(subnet);
        emit RemoveSubnet(subnet);
    }

    function addSubnetBatch(address[] calldata subs) external toll {
        for (uint256 i; i < subs.length;) {
            _subnets.add(subs[i]);
            emit AddSubnet(subs[i]);
            unchecked { ++i; }
        }
    }

    function removeSubnetBatch(address[] calldata subs) external toll {
        for (uint256 i; i < subs.length;) {
            _subnets.remove(subs[i]);
            emit RemoveSubnet(subs[i]);
            unchecked { ++i; }
        }
    }

    // --- Query ---
    function isMember(address usr) external view returns (bool) {
        if (_members.contains(usr)) return true;
        uint256 len = _subnets.length();
        for (uint256 i; i < len;) {
            if (IIdentityNetwork(_subnets.at(i)).isMember(usr)) {
                return true;
            }
            unchecked { ++i; }
        }
        return false;
    }

    function memberCount() external view returns (uint256) {
        return _members.length();
    }

    function memberAt(uint256 idx) external view returns (address) {
        return _members.at(idx);
    }

    function getMembers() external view returns (address[] memory) {
        return _members.values();
    }

    function isSubnet(address subnet) external view returns (bool) {
        return _subnets.contains(subnet);
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
