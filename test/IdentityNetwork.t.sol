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

contract IdentityNetworkTest is DssTest {

    IdentityNetwork network;
    IdentityNetwork childA;
    IdentityNetwork childB;
    IdentityNetwork childC;

    address ward  = address(0xA1);
    address bud   = address(0xA2);
    address user1 = address(0xB1);
    address user2 = address(0xB2);
    address user3 = address(0xB3);

    event Kiss(address indexed usr);
    event Diss(address indexed usr);
    event AddMember(address indexed usr);
    event RemoveMember(address indexed usr);
    event AddSubnet(address indexed subnet);
    event RemoveSubnet(address indexed subnet);

    function setUp() public {
        network = new IdentityNetwork();
        network.rely(ward);
        network.kiss(bud);

        childA = new IdentityNetwork();
        childA.kiss(address(this));
        childB = new IdentityNetwork();
        childB.kiss(address(this));
        childC = new IdentityNetwork();
        childC.kiss(address(this));
    }

    // --- Auth ---

    function testConstructor() public {
        vm.expectEmit();
        emit Rely(address(this));
        IdentityNetwork n = new IdentityNetwork();
        assertEq(n.wards(address(this)), 1);
    }

    function testAuth() public {
        checkAuth(address(network), "IdentityNetwork");
    }

    function testModifiers() public {
        bytes4[] memory authedMethods = new bytes4[](2);
        authedMethods[0] = network.kiss.selector;
        authedMethods[1] = network.diss.selector;

        vm.startPrank(address(0xBEEF));
        checkModifier(address(network), "IdentityNetwork/not-authorized", authedMethods);
        vm.stopPrank();

        bytes4[] memory tolledMethods = new bytes4[](8);
        tolledMethods[0] = network.addMember.selector;
        tolledMethods[1] = network.removeMember.selector;
        tolledMethods[2] = network.addMemberBatch.selector;
        tolledMethods[3] = network.removeMemberBatch.selector;
        tolledMethods[4] = network.addSubnet.selector;
        tolledMethods[5] = network.removeSubnet.selector;
        tolledMethods[6] = network.addSubnetBatch.selector;
        tolledMethods[7] = network.removeSubnetBatch.selector;

        vm.startPrank(address(0xBEEF));
        checkModifier(address(network), "IdentityNetwork/not-operator", tolledMethods);
        vm.stopPrank();
    }

    // --- Kiss / Diss ---

    function testKissDiss() public {
        address newBud = address(0xC2);

        assertEq(network.buds(newBud), 0);

        vm.expectEmit();
        emit Kiss(newBud);
        network.kiss(newBud);
        assertEq(network.buds(newBud), 1);

        vm.expectEmit();
        emit Diss(newBud);
        network.diss(newBud);
        assertEq(network.buds(newBud), 0);
    }

    function testRevertBudNotAuthorized() public {
        vm.expectRevert("IdentityNetwork/not-authorized");
        vm.prank(bud); network.kiss(user1);

        vm.expectRevert("IdentityNetwork/not-authorized");
        vm.prank(bud); network.diss(bud);
    }

    // --- AddMember / RemoveMember ---

    function testAddMember() public {
        vm.expectEmit();
        emit AddMember(user1);
        vm.prank(bud); network.addMember(user1);
        assertTrue(network.isMember(user1));
    }

    function testRemoveMember() public {
        vm.prank(bud); network.addMember(user1);

        vm.expectEmit();
        emit RemoveMember(user1);
        vm.prank(bud); network.removeMember(user1);
        assertFalse(network.isMember(user1));
    }

    function testAddMemberIdempotent() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user1);
        vm.stopPrank();
        assertTrue(network.isMember(user1));
        assertEq(network.directMemberCount(), 1);
    }

    function testRemoveNonMember() public {
        vm.prank(bud); network.removeMember(user1);
        assertFalse(network.isMember(user1));
    }

    // --- Member Batch ---

    function testAddMemberBatch() public {
        address[] memory usrs = new address[](3);
        usrs[0] = user1;
        usrs[1] = user2;
        usrs[2] = user3;

        vm.expectEmit();
        emit AddMember(user1);
        vm.expectEmit();
        emit AddMember(user2);
        vm.expectEmit();
        emit AddMember(user3);
        vm.prank(bud); network.addMemberBatch(usrs);

        assertTrue(network.isMember(user1));
        assertTrue(network.isMember(user2));
        assertTrue(network.isMember(user3));
        assertEq(network.directMemberCount(), 3);
    }

    function testRemoveMemberBatch() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user2);
        network.addMember(user3);
        vm.stopPrank();

        address[] memory usrs = new address[](2);
        usrs[0] = user1;
        usrs[1] = user3;

        vm.expectEmit();
        emit RemoveMember(user1);
        vm.expectEmit();
        emit RemoveMember(user3);
        vm.prank(bud); network.removeMemberBatch(usrs);

        assertFalse(network.isMember(user1));
        assertTrue(network.isMember(user2));
        assertFalse(network.isMember(user3));
        assertEq(network.directMemberCount(), 1);
    }

    function testAddMemberBatchEmpty() public {
        vm.prank(bud); network.addMemberBatch(new address[](0));
    }

    // --- Member Query ---

    function testIsMemberDefault() public view {
        assertFalse(network.isMember(user1));
    }

    function testDirectMemberCount() public {
        assertEq(network.directMemberCount(), 0);

        vm.startPrank(bud);
        network.addMember(user1);
        assertEq(network.directMemberCount(), 1);
        network.addMember(user2);
        assertEq(network.directMemberCount(), 2);
        network.removeMember(user1);
        assertEq(network.directMemberCount(), 1);
        vm.stopPrank();
    }

    function testDirectMemberAt() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user2);
        vm.stopPrank();

        assertEq(network.directMemberAt(0), user1);
        assertEq(network.directMemberAt(1), user2);
    }

    function testGetDirectMembers() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user2);
        network.addMember(user3);
        vm.stopPrank();

        address[] memory members = network.getDirectMembers();
        assertEq(members.length, 3);
        assertEq(members[0], user1);
        assertEq(members[1], user2);
        assertEq(members[2], user3);
    }

    function testGetDirectMembersPaginated() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user2);
        network.addMember(user3);
        vm.stopPrank();

        address[] memory page = network.getDirectMembers(1, 3);
        assertEq(page.length, 2);
        assertEq(page[0], user2);
        assertEq(page[1], user3);

        // end past length is clamped
        page = network.getDirectMembers(2, 10);
        assertEq(page.length, 1);
        assertEq(page[0], user3);

        // start past end returns empty
        assertEq(network.getDirectMembers(5, 10).length, 0);
        assertEq(network.getDirectMembers(2, 1).length, 0);
    }

    function testIsDirectMemberDefault() public view {
        assertFalse(network.isDirectMember(user1));
    }

    function testIsDirectMemberTrue() public {
        vm.prank(bud); network.addMember(user1);
        assertTrue(network.isDirectMember(user1));
    }

    function testIsDirectMemberAfterRemove() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.removeMember(user1);
        vm.stopPrank();
        assertFalse(network.isDirectMember(user1));
    }

    function testIsDirectMemberNotSubnetMember() public {
        childA.addMember(user1);
        vm.prank(bud); network.addSubnet(address(childA));

        assertTrue(network.isMember(user1));
        assertFalse(network.isDirectMember(user1));
    }

    // --- AddSubnet / RemoveSubnet ---

    function testAddSubnet() public {
        vm.expectEmit();
        emit AddSubnet(address(childA));
        vm.prank(bud); network.addSubnet(address(childA));

        assertEq(network.subnetCount(), 1);
        assertTrue(network.isSubnet(address(childA)));
        assertEq(network.subnetAt(0), address(childA));
    }

    function testAddSubnetMultiple() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        network.addSubnet(address(childC));
        vm.stopPrank();

        assertEq(network.subnetCount(), 3);
    }

    function testAddSubnetIdempotent() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childA));
        vm.stopPrank();

        assertEq(network.subnetCount(), 1);
    }

    function testRemoveSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));

        vm.expectEmit();
        emit RemoveSubnet(address(childA));
        network.removeSubnet(address(childA));
        vm.stopPrank();

        assertFalse(network.isSubnet(address(childA)));
    }

    function testReAddAfterRemoveSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.removeSubnet(address(childA));
        network.addSubnet(address(childA));
        vm.stopPrank();

        assertEq(network.subnetCount(), 1);
        assertTrue(network.isSubnet(address(childA)));
    }

    // --- Subnet Batch ---

    function testAddSubnetBatch() public {
        address[] memory subs = new address[](3);
        subs[0] = address(childA);
        subs[1] = address(childB);
        subs[2] = address(childC);

        vm.expectEmit();
        emit AddSubnet(address(childA));
        vm.expectEmit();
        emit AddSubnet(address(childB));
        vm.expectEmit();
        emit AddSubnet(address(childC));
        vm.prank(bud); network.addSubnetBatch(subs);

        assertEq(network.subnetCount(), 3);
        assertTrue(network.isSubnet(address(childA)));
        assertTrue(network.isSubnet(address(childB)));
        assertTrue(network.isSubnet(address(childC)));
    }

    function testRemoveSubnetBatch() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        network.addSubnet(address(childC));

        address[] memory subs = new address[](2);
        subs[0] = address(childA);
        subs[1] = address(childC);

        vm.expectEmit();
        emit RemoveSubnet(address(childA));
        vm.expectEmit();
        emit RemoveSubnet(address(childC));
        network.removeSubnetBatch(subs);
        vm.stopPrank();

        assertFalse(network.isSubnet(address(childA)));
        assertTrue(network.isSubnet(address(childB)));
        assertFalse(network.isSubnet(address(childC)));
        assertEq(network.subnetCount(), 1);
    }

    function testAddSubnetBatchEmpty() public {
        vm.prank(bud); network.addSubnetBatch(new address[](0));
    }

    // --- Subnet Query ---

    function testSubnetCount() public {
        assertEq(network.subnetCount(), 0);

        vm.startPrank(bud);
        network.addSubnet(address(childA));
        assertEq(network.subnetCount(), 1);
        network.addSubnet(address(childB));
        assertEq(network.subnetCount(), 2);
        network.removeSubnet(address(childA));
        assertEq(network.subnetCount(), 1);
        vm.stopPrank();
    }

    function testSubnetAt() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        vm.stopPrank();

        assertEq(network.subnetAt(0), address(childA));
        assertEq(network.subnetAt(1), address(childB));
    }

    function testGetSubnets() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        network.addSubnet(address(childC));
        vm.stopPrank();

        address[] memory subs = network.getSubnets();
        assertEq(subs.length, 3);
        assertEq(subs[0], address(childA));
        assertEq(subs[1], address(childB));
        assertEq(subs[2], address(childC));
    }

    function testGetSubnetsPaginated() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        network.addSubnet(address(childC));
        vm.stopPrank();

        address[] memory page = network.getSubnets(0, 2);
        assertEq(page.length, 2);
        assertEq(page[0], address(childA));
        assertEq(page[1], address(childB));

        // end past length is clamped
        page = network.getSubnets(2, 10);
        assertEq(page.length, 1);
        assertEq(page[0], address(childC));

        // start past end returns empty
        assertEq(network.getSubnets(5, 10).length, 0);
    }

    // --- isMember (direct + subnets) ---

    function testIsMemberDirectMember() public {
        vm.prank(bud); network.addMember(user1);

        assertTrue(network.isMember(user1));
        assertFalse(network.isMember(user2));
    }

    function testIsMemberViaSubnet() public {
        vm.prank(bud); network.addSubnet(address(childA));
        childA.addMember(user1);

        assertTrue(network.isMember(user1));
        assertFalse(network.isMember(user2));
    }

    function testIsMemberMultipleSubnets() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        vm.stopPrank();

        childA.addMember(user1);
        childB.addMember(user2);

        assertTrue(network.isMember(user1));
        assertTrue(network.isMember(user2));
    }

    function testIsMemberDirectAndSubnet() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addSubnet(address(childA));
        vm.stopPrank();

        childA.addMember(user2);

        assertTrue(network.isMember(user1));
        assertTrue(network.isMember(user2));
    }

    function testIsMemberNotInAny() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addSubnet(address(childA));
        vm.stopPrank();

        childA.addMember(user2);

        assertFalse(network.isMember(user3));
    }

    function testIsMemberAfterRemoveSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        vm.stopPrank();

        childA.addMember(user1);
        assertTrue(network.isMember(user1));

        vm.prank(bud); network.removeSubnet(address(childA));

        assertFalse(network.isMember(user1));
    }

    function testIsMemberAfterSubnetMemberRemoval() public {
        vm.prank(bud); network.addSubnet(address(childA));
        childA.addMember(user1);

        assertTrue(network.isMember(user1));

        childA.removeMember(user1);

        assertFalse(network.isMember(user1));
    }

    function testIsMemberNoMembersNoSubnets() public view {
        assertFalse(network.isMember(user1));
    }

    function testIsMemberSkipsRemovedSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(childA));
        network.addSubnet(address(childB));
        network.removeSubnet(address(childA));
        vm.stopPrank();

        childA.addMember(user1);
        childB.addMember(user2);

        assertFalse(network.isMember(user1));
        assertTrue(network.isMember(user2));
    }

    function testIsMemberDirectTakesPrecedence() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addSubnet(address(childA));
        vm.stopPrank();

        // user1 is both a direct member and in a subnet — should still return true
        childA.addMember(user1);
        assertTrue(network.isMember(user1));

        // removing from subnet doesn't matter, still a direct member
        childA.removeMember(user1);
        assertTrue(network.isMember(user1));
    }
}
