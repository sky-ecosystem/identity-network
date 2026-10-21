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

import { Test } from "forge-std/Test.sol";
import { IdentityNetwork } from "src/IdentityNetwork.sol";
import { IdentityNetworkDeployer, IdentityNetworkDeployerConfig } from "deploy/IdentityNetworkDeployer.sol";

contract IdentityNetworkDeployerTest is Test {

    address admin    = address(0xA1);
    address operator = address(0xA2);
    address user1    = address(0xB1);
    address user2    = address(0xB2);

    address[] noAddrs;

    function _single(address a) internal pure returns (address[] memory arr) {
        arr = new address[](1);
        arr[0] = a;
    }

    function _deploy(
        address[] memory buds,
        address[] memory members,
        address[] memory subnets
    ) internal returns (IdentityNetworkDeployer deployer, IdentityNetwork n) {
        deployer = new IdentityNetworkDeployer(IdentityNetworkDeployerConfig({
            admin:   admin,
            buds:    buds,
            members: members,
            subnets: subnets
        }));
        n = IdentityNetwork(deployer.network());
    }

    function testDeployerEmpty() public {
        (IdentityNetworkDeployer deployer, IdentityNetwork n) = _deploy(noAddrs, noAddrs, noAddrs);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(deployer)), 0);
        assertEq(n.wards(address(this)), 0);
        assertEq(n.buds(address(deployer)), 0);
        assertEq(n.directMemberCount(), 0);
        assertEq(n.subnetCount(), 0);
    }

    function testDeployerFullSetup() public {
        (, IdentityNetwork child) = _deploy(noAddrs, _single(user2), noAddrs);
        (IdentityNetworkDeployer deployer, IdentityNetwork n) = _deploy(_single(operator), _single(user1), _single(address(child)));

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(deployer)), 0);
        assertEq(n.buds(address(deployer)), 0);
        assertEq(n.buds(operator), 1);
        assertEq(n.directMemberCount(), 1);
        assertEq(n.subnetCount(), 1);
        assertTrue(n.isMember(user1));  // direct
        assertTrue(n.isMember(user2));  // via subnet
        assertTrue(n.isSubnet(address(child)));
    }

    function testDeployerAdminZeroAddress() public {
        vm.expectRevert("IdentityNetworkDeployer/admin-zero-address");
        new IdentityNetworkDeployer(IdentityNetworkDeployerConfig({
            admin:   address(0),
            buds:    noAddrs,
            members: noAddrs,
            subnets: noAddrs
        }));
    }

    function testDeployerAdminIsDeployer() public {
        address predicted = vm.computeCreateAddress(address(this), vm.getNonce(address(this)));

        vm.expectRevert("IdentityNetworkDeployer/admin-is-deployer");
        new IdentityNetworkDeployer(IdentityNetworkDeployerConfig({
            admin:   predicted,
            buds:    noAddrs,
            members: noAddrs,
            subnets: noAddrs
        }));
    }
}
