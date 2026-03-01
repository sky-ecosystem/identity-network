// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

interface IIdentityNetwork {
    function isMember(address usr) external view returns (uint256);
}
