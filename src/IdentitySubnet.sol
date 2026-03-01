// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { IIdentityNetwork } from "src/IIdentityNetwork.sol";

contract IdentitySubnet is IIdentityNetwork {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Auth ---
    mapping(address usr => uint256 allowed) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "IdentitySubnet/not-authorized");
        _;
    }

    // --- Data ---
    EnumerableSet.AddressSet private _members;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event AddMember(address indexed usr);
    event RemoveMember(address indexed usr);

    // --- Constructor ---
    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Member Management ---
    function addMember(address usr) external auth {
        _members.add(usr);
        emit AddMember(usr);
    }

    function removeMember(address usr) external auth {
        _members.remove(usr);
        emit RemoveMember(usr);
    }

    function addMemberBatch(address[] calldata usrs) external auth {
        for (uint256 i; i < usrs.length;) {
            _members.add(usrs[i]);
            emit AddMember(usrs[i]);
            unchecked { ++i; }
        }
    }

    function removeMemberBatch(address[] calldata usrs) external auth {
        for (uint256 i; i < usrs.length;) {
            _members.remove(usrs[i]);
            emit RemoveMember(usrs[i]);
            unchecked { ++i; }
        }
    }

    // --- Query ---
    function isMember(address usr) external view returns (uint256) {
        return _members.contains(usr) ? 1 : 0;
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
}
