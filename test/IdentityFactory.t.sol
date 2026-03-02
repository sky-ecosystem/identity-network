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
import { IdentitySubnet }  from "src/IdentitySubnet.sol";
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

    event CreateSubnet(address indexed subnet, address indexed admin, address[] buds, address[] members);
    event CreateNetwork(address indexed network, address indexed admin, address[] buds, address[] subnets);

    function setUp() public {
        factory = new IdentityFactory();
    }

    // --- createSubnet ---

    function testCreateSubnetEmpty() public {
        address addr = factory.createSubnet(admin, noBuds, noAddrs);
        IdentitySubnet s = IdentitySubnet(addr);

        assertEq(s.wards(admin), 1);
        assertEq(s.wards(address(factory)), 0);
        assertEq(s.buds(address(factory)), 0);
        assertEq(s.memberCount(), 0);
    }

    function testCreateSubnetWithBuds() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        address addr = factory.createSubnet(admin, buds, noAddrs);
        IdentitySubnet s = IdentitySubnet(addr);

        assertEq(s.buds(operator), 1);

        vm.prank(operator);
        s.addMember(user1);
        assertTrue(s.isMember(user1));
    }

    function testCreateSubnetWithMembers() public {
        address[] memory members = new address[](3);
        members[0] = user1;
        members[1] = user2;
        members[2] = user3;

        address addr = factory.createSubnet(admin, noBuds, members);
        IdentitySubnet s = IdentitySubnet(addr);

        assertEq(s.wards(admin), 1);
        assertEq(s.wards(address(factory)), 0);
        assertEq(s.buds(address(factory)), 0);
        assertEq(s.memberCount(), 3);
        assertTrue(s.isMember(user1));
        assertTrue(s.isMember(user2));
        assertTrue(s.isMember(user3));
    }

    function testCreateSubnetWithBudsAndMembers() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        address[] memory members = new address[](2);
        members[0] = user1;
        members[1] = user2;

        address addr = factory.createSubnet(admin, buds, members);
        IdentitySubnet s = IdentitySubnet(addr);

        assertEq(s.buds(operator), 1);
        assertEq(s.memberCount(), 2);
        assertTrue(s.isMember(user1));
        assertTrue(s.isMember(user2));
    }

    function testCreateSubnetEmitsEvent() public {
        vm.recordLogs();
        factory.createSubnet(admin, noBuds, noAddrs);
    }

    function testCreateSubnetFactoryHasNoAuth() public {
        address addr = factory.createSubnet(admin, noBuds, noAddrs);
        IdentitySubnet s = IdentitySubnet(addr);

        vm.prank(address(factory));
        vm.expectRevert("IdentitySubnet/not-authorized");
        s.addMember(user1);
    }

    // --- createNetwork ---

    function testCreateNetworkEmpty() public {
        address addr = factory.createNetwork(admin, noBuds, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.buds(address(factory)), 0);
        assertEq(n.subnetCount(), 0);
    }

    function testCreateNetworkWithBuds() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        address addr = factory.createNetwork(admin, buds, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.buds(operator), 1);

        address s1 = factory.createSubnet(admin, noBuds, noAddrs);
        vm.prank(operator);
        n.addSubnet(s1);
        assertEq(n.isSubnet(s1), 1);
    }

    function testCreateNetworkWithSubnets() public {
        address s1 = factory.createSubnet(admin, noBuds, noAddrs);
        address s2 = factory.createSubnet(admin, noBuds, noAddrs);

        address[] memory subs = new address[](2);
        subs[0] = s1;
        subs[1] = s2;

        address addr = factory.createNetwork(admin, noBuds, subs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.buds(address(factory)), 0);
        assertEq(n.subnetCount(), 2);
        assertEq(n.isSubnet(s1), 1);
        assertEq(n.isSubnet(s2), 1);
    }

    function testCreateNetworkEmitsEvent() public {
        vm.recordLogs();
        factory.createNetwork(admin, noBuds, noAddrs);
    }

    function testCreateNetworkFactoryHasNoAuth() public {
        address addr = factory.createNetwork(admin, noBuds, noAddrs);
        IdentityNetwork n = IdentityNetwork(addr);

        vm.prank(address(factory));
        vm.expectRevert("IdentityNetwork/not-authorized");
        n.addSubnet(address(0x1));
    }

    // --- End-to-end ---

    function testEndToEndMembership() public {
        address[] memory buds = new address[](1);
        buds[0] = operator;

        address[] memory members = new address[](2);
        members[0] = user1;
        members[1] = user2;

        address s1 = factory.createSubnet(admin, buds, members);
        address s2 = factory.createSubnet(admin, buds, noAddrs);

        vm.prank(operator);
        IdentitySubnet(s2).addMember(user3);

        address[] memory subs = new address[](2);
        subs[0] = s1;
        subs[1] = s2;

        address net = factory.createNetwork(admin, noBuds, subs);
        IdentityNetwork n = IdentityNetwork(net);

        assertTrue(n.isMember(user1));
        assertTrue(n.isMember(user2));
        assertTrue(n.isMember(user3));
        assertFalse(n.isMember(address(0xDEAD)));
    }
}
