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
import { IdentityFactory } from "src/IdentityFactory.sol";
import { IdentityNetwork } from "src/IdentityNetwork.sol";

contract IdentityFactoryTest is Test {

    IdentityFactory factory;

    address admin    = address(0xA1);
    address operator = address(0xA2);
    address user1    = address(0xB1);
    address user2    = address(0xB2);
    address user3    = address(0xB3);

    address[] noBuds;
    address[] noAddrs;

    event CreateNetwork(address indexed network, address indexed admin, address[] buds, address[] members, address[] subnets);

    function setUp() public {
        factory = new IdentityFactory();
    }

    // --- createNetwork (empty) ---

    function testCreateNetworkEmpty() public {
        address addr = factory.createNetwork(admin, noBuds, noAddrs, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.buds(address(factory)), 0);
        assertEq(n.memberCount(), 0);
        assertEq(n.subnetCount(), 0);
    }

    // --- createNetwork with buds ---

    function testCreateNetworkWithBuds() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        address addr = factory.createNetwork(admin, buds, noAddrs, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.buds(operator), 1);

        vm.prank(operator);
        n.addMember(user1);
        assertTrue(n.isMember(user1));
    }

    // --- createNetwork with members ---

    function testCreateNetworkWithMembers() public {
        address[] memory members = new address[](3);
        members[0] = user1;
        members[1] = user2;
        members[2] = user3;

        address addr = factory.createNetwork(admin, noBuds, members, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.buds(address(factory)), 0);
        assertEq(n.memberCount(), 3);
        assertTrue(n.isMember(user1));
        assertTrue(n.isMember(user2));
        assertTrue(n.isMember(user3));
    }

    // --- createNetwork with subnets ---

    function testCreateNetworkWithSubnets() public {
        address s1 = factory.createNetwork(admin, noBuds, noAddrs, noAddrs);
        address s2 = factory.createNetwork(admin, noBuds, noAddrs, noAddrs);

        address[] memory subs = new address[](2);
        subs[0] = s1;
        subs[1] = s2;

        address addr = factory.createNetwork(admin, noBuds, noAddrs, subs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.buds(address(factory)), 0);
        assertEq(n.subnetCount(), 2);
        assertEq(n.isSubnet(s1), 1);
        assertEq(n.isSubnet(s2), 1);
    }

    // --- createNetwork with buds and members ---

    function testCreateNetworkWithBudsAndMembers() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        address[] memory members = new address[](2);
        members[0] = user1;
        members[1] = user2;

        address addr = factory.createNetwork(admin, buds, members, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.buds(operator), 1);
        assertEq(n.memberCount(), 2);
        assertTrue(n.isMember(user1));
        assertTrue(n.isMember(user2));
    }

    // --- createNetwork with members and subnets ---

    function testCreateNetworkWithMembersAndSubnets() public {
        address child = factory.createNetwork(admin, noBuds, noAddrs, noAddrs);

        address[] memory members = new address[](1);
        members[0] = user1;

        address[] memory subs = new address[](1);
        subs[0] = child;

        address addr = factory.createNetwork(admin, noBuds, members, subs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.memberCount(), 1);
        assertEq(n.subnetCount(), 1);
        assertTrue(n.isMember(user1));
        assertEq(n.isSubnet(child), 1);
    }

    // --- Event ---

    function testCreateNetworkEmitsEvent() public {
        vm.recordLogs();
        factory.createNetwork(admin, noBuds, noAddrs, noAddrs);
    }

    // --- Factory cleanup ---

    function testCreateNetworkFactoryHasNoAuth() public {
        address addr = factory.createNetwork(admin, noBuds, noAddrs, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        vm.prank(address(factory));
        vm.expectRevert("IdentityNetwork/not-authorized");
        n.addMember(user1);

        vm.prank(address(factory));
        vm.expectRevert("IdentityNetwork/not-authorized");
        n.addSubnet(address(0x1));
    }

    // --- End-to-end ---

    function testEndToEndMembership() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        // Create a leaf network with direct members
        address[] memory members = new address[](2);
        members[0] = user1;
        members[1] = user2;
        address leaf = factory.createNetwork(admin, buds, members, noAddrs);

        // Create another leaf, add a member via operator
        address leaf2 = factory.createNetwork(admin, buds, noAddrs, noAddrs);
        vm.prank(operator);
        IdentityNetwork(leaf2).addMember(user3);

        // Create a root network aggregating both leaves
        address[] memory subs = new address[](2);
        subs[0] = leaf;
        subs[1] = leaf2;
        address root = factory.createNetwork(admin, noBuds, noAddrs, subs);
        IdentityNetwork n = IdentityNetwork(root);

        assertTrue(n.isMember(user1));
        assertTrue(n.isMember(user2));
        assertTrue(n.isMember(user3));
        assertFalse(n.isMember(address(0xDEAD)));
    }

    function testEndToEndDirectAndSubnetMembership() public {
        // Create a child with user2 as a member
        address[] memory childMembers = new address[](1);
        childMembers[0] = user2;
        address child = factory.createNetwork(admin, noBuds, childMembers, noAddrs);

        // Create root with user1 as direct member and the child as subnet
        address[] memory rootMembers = new address[](1);
        rootMembers[0] = user1;
        address[] memory subs = new address[](1);
        subs[0] = child;
        address root = factory.createNetwork(admin, noBuds, rootMembers, subs);
        IdentityNetwork n = IdentityNetwork(root);

        assertTrue(n.isMember(user1));  // direct
        assertTrue(n.isMember(user2));  // via subnet
        assertFalse(n.isMember(user3)); // neither
    }
}
