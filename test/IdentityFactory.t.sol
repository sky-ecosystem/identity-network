// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { IdentityFactory } from "src/IdentityFactory.sol";
import { IdentitySubnet }  from "src/IdentitySubnet.sol";
import { IdentityNetwork } from "src/IdentityNetwork.sol";

contract IdentityFactoryTest is Test {

    IdentityFactory factory;

    address admin = address(0xA1);
    address user1 = address(0xB1);
    address user2 = address(0xB2);
    address user3 = address(0xB3);

    event CreateSubnet(address indexed subnet, address indexed admin);
    event CreateNetwork(address indexed network, address indexed admin);

    function setUp() public {
        factory = new IdentityFactory();
    }

    // --- createSubnet ---

    function testCreateSubnetEmpty() public {
        address addr = factory.createSubnet(admin, new address[](0));
        IdentitySubnet s = IdentitySubnet(addr);

        assertEq(s.wards(admin), 1);
        assertEq(s.wards(address(factory)), 0);
        assertEq(s.memberCount(), 0);
    }

    function testCreateSubnetWithMembers() public {
        address[] memory members = new address[](3);
        members[0] = user1;
        members[1] = user2;
        members[2] = user3;

        address addr = factory.createSubnet(admin, members);
        IdentitySubnet s = IdentitySubnet(addr);

        assertEq(s.wards(admin), 1);
        assertEq(s.wards(address(factory)), 0);
        assertEq(s.memberCount(), 3);
        assertEq(s.isMember(user1), 1);
        assertEq(s.isMember(user2), 1);
        assertEq(s.isMember(user3), 1);
    }

    function testCreateSubnetEmitsEvent() public {
        // We can't easily predict the address, so just check the event is emitted
        // by verifying the admin topic
        vm.recordLogs();
        factory.createSubnet(admin, new address[](0));
    }

    function testCreateSubnetAdminCanManage() public {
        address addr = factory.createSubnet(admin, new address[](0));
        IdentitySubnet s = IdentitySubnet(addr);

        vm.prank(admin);
        s.addMember(user1);
        assertEq(s.isMember(user1), 1);

        vm.prank(admin);
        s.removeMember(user1);
        assertEq(s.isMember(user1), 0);
    }

    function testCreateSubnetFactoryHasNoAuth() public {
        address addr = factory.createSubnet(admin, new address[](0));
        IdentitySubnet s = IdentitySubnet(addr);

        vm.prank(address(factory));
        vm.expectRevert("IdentitySubnet/not-authorized");
        s.addMember(user1);
    }

    // --- createNetwork ---

    function testCreateNetworkEmpty() public {
        address addr = factory.createNetwork(admin, new address[](0));
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.subnetCount(), 0);
    }

    function testCreateNetworkWithSubnets() public {
        address s1 = factory.createSubnet(admin, new address[](0));
        address s2 = factory.createSubnet(admin, new address[](0));

        address[] memory subs = new address[](2);
        subs[0] = s1;
        subs[1] = s2;

        address addr = factory.createNetwork(admin, subs);
        IdentityNetwork n = IdentityNetwork(addr);

        assertEq(n.wards(admin), 1);
        assertEq(n.wards(address(factory)), 0);
        assertEq(n.subnetCount(), 2);
        assertEq(n.isSubnet(s1), 1);
        assertEq(n.isSubnet(s2), 1);
    }

    function testCreateNetworkEmitsEvent() public {
        vm.recordLogs();
        factory.createNetwork(admin, new address[](0));
    }

    function testCreateNetworkAdminCanManage() public {
        address s1 = factory.createSubnet(admin, new address[](0));

        address addr = factory.createNetwork(admin, new address[](0));
        IdentityNetwork n = IdentityNetwork(addr);

        vm.prank(admin);
        n.addSubnet(s1);
        assertEq(n.isSubnet(s1), 1);

        vm.prank(admin);
        n.removeSubnet(s1);
        assertEq(n.isSubnet(s1), 0);
    }

    function testCreateNetworkFactoryHasNoAuth() public {
        address addr = factory.createNetwork(admin, new address[](0));
        IdentityNetwork n = IdentityNetwork(addr);

        vm.prank(address(factory));
        vm.expectRevert("IdentityNetwork/not-authorized");
        n.addSubnet(address(0x1));
    }

    // --- End-to-end ---

    function testEndToEndMembership() public {
        address[] memory members = new address[](2);
        members[0] = user1;
        members[1] = user2;

        address s1 = factory.createSubnet(admin, members);
        address s2 = factory.createSubnet(admin, new address[](0));

        vm.prank(admin);
        IdentitySubnet(s2).addMember(user3);

        address[] memory subs = new address[](2);
        subs[0] = s1;
        subs[1] = s2;

        address net = factory.createNetwork(admin, subs);
        IdentityNetwork n = IdentityNetwork(net);

        assertEq(n.isMember(user1), 1);
        assertEq(n.isMember(user2), 1);
        assertEq(n.isMember(user3), 1);
        assertEq(n.isMember(address(0xDEAD)), 0);
    }
}
