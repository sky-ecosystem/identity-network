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

import "dss-test/DssTest.sol";
import { IdentityNetwork } from "src/IdentityNetwork.sol";
import { IdentityNetworkDeploy } from "deploy/IdentityNetworkDeploy.sol";
import { IdentityNetworkInit } from "deploy/IdentityNetworkInit.sol";

contract IdentityNetworkDeployTest is DssTest {

    address admin     = address(0xA1);
    address operator1 = address(0xA2);
    address operator2 = address(0xA3);
    address operator3 = address(0xA4);
    address user1     = address(0xB1);
    address user2     = address(0xB2);
    address user3     = address(0xB3);

    address[] noAddrs;

    // This test contract acts as the deployer and (when owner) as the executor of the init (e.g. the pause proxy)
    function _deployAndInit(
        address[] memory buds,
        address[] memory members,
        address[] memory subnets
    ) internal returns (IdentityNetwork n) {
        address network = IdentityNetworkDeploy.deploy(address(this), address(this));
        IdentityNetworkInit.init(network, buds, members, subnets);
        n = IdentityNetwork(network);
    }

    function initExternal(
        address          network,
        address[] memory buds,
        address[] memory members,
        address[] memory subnets
    ) external {
        IdentityNetworkInit.init(network, buds, members, subnets);
    }

    // --- Deploy ---

    function testDeploy() public {
        IdentityNetwork n = IdentityNetwork(IdentityNetworkDeploy.deploy(address(this), admin));

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(this)), 0);
        assertEq(n.buds(address(this)), 0);
        assertEq(n.directMemberCount(), 0);
        assertEq(n.subnetCount(), 0);
    }

    function testDeploySameDeployerAndOwner() public {
        IdentityNetwork n = IdentityNetwork(IdentityNetworkDeploy.deploy(address(this), address(this)));

        assertEq(n.wards(address(this)), 1);
    }

    // --- Init ---

    function testInitEmpty() public {
        IdentityNetwork n = _deployAndInit(noAddrs, noAddrs, noAddrs);

        assertEq(n.buds(address(this)), 0);
        assertEq(n.directMemberCount(), 0);
        assertEq(n.subnetCount(), 0);
    }

    function testInitNotAuthorized() public {
        address network = IdentityNetworkDeploy.deploy(address(this), admin);

        address[] memory members = new address[](1);
        members[0] = user1;

        vm.expectRevert("IdentityNetworkInit/not-authorized");
        this.initExternal(network, noAddrs, members, noAddrs);
    }

    function testInitWithBuds() public {
        address[] memory operators = new address[](3);
        operators[0] = operator1;
        operators[1] = operator2;
        operators[2] = operator3;

        IdentityNetwork n = _deployAndInit(operators, noAddrs, noAddrs);

        assertEq(n.buds(operator1), 1);
        assertEq(n.buds(operator2), 1);
        assertEq(n.buds(operator3), 1);

        vm.prank(operator1);
        n.addMember(user1);
        assertTrue(n.isMember(user1));
    }

    function testInitWithMembers() public {
        address[] memory members = new address[](3);
        members[0] = user1;
        members[1] = user2;
        members[2] = user3;

        IdentityNetwork n = _deployAndInit(noAddrs, members, noAddrs);

        assertEq(n.buds(address(this)), 0);
        assertEq(n.directMemberCount(), 3);
        assertTrue(n.isMember(user1));
        assertTrue(n.isMember(user2));
        assertTrue(n.isMember(user3));
    }

    function testInitComplete() public {
        IdentityNetwork s1 = _deployAndInit(noAddrs, noAddrs, noAddrs);
        IdentityNetwork s2 = _deployAndInit(noAddrs, noAddrs, noAddrs);

        address[] memory operators = new address[](1);
        operators[0] = operator1;
        address[] memory members = new address[](2);
        members[0] = user1;
        members[1] = user2;
        address[] memory subnets = new address[](2);
        subnets[0] = address(s1);
        subnets[1] = address(s2);

        IdentityNetwork n = _deployAndInit(operators, members, subnets);

        assertEq(n.buds(operator1), 1);
        assertEq(n.directMemberCount(), 2);
        assertTrue(n.isMember(user1));
        assertTrue(n.isMember(user2));
        assertEq(n.subnetCount(), 2);
        assertTrue(n.isSubnet(address(s1)));
        assertTrue(n.isSubnet(address(s2)));
    }

    function testInitExecutorAlreadyBud() public {
        address[] memory operators = new address[](1);
        operators[0] = address(this);

        // Executor listed as a bud keeps the role after init
        IdentityNetwork n = _deployAndInit(operators, noAddrs, noAddrs);

        assertEq(n.buds(address(this)), 1);
    }

    function testInitExecutorHasNoBudRole() public {
        address[] memory members = new address[](1);
        members[0] = user1;
        address[] memory subnets = new address[](1);
        subnets[0] = address(0x1);

        IdentityNetwork n = _deployAndInit(noAddrs, members, subnets);

        assertEq(n.buds(address(this)), 0);
    }
}
