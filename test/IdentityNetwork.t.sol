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

contract IdentityNetworkTest is Test {

    IdentityNetwork network;
    IdentityNetwork childA;
    IdentityNetwork childB;
    IdentityNetwork childC;

    address ward  = address(0xA1);
    address bud   = address(0xA2);
    address user1 = address(0xB1);
    address user2 = address(0xB2);
    address user3 = address(0xB3);

    event Rely(address indexed usr);
    event Deny(address indexed usr);
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

    function testConstructorSetsDeployer() public view {
        assertEq(network.wards(address(this)), 1);
    }

    function testRely() public {
        vm.expectEmit(true, true, true, true);
        emit Rely(address(0xC1));
        network.rely(address(0xC1));
        assertEq(network.wards(address(0xC1)), 1);
    }

    function testDeny() public {
        vm.expectEmit(true, true, true, true);
        emit Deny(ward);
        network.deny(ward);
        assertEq(network.wards(ward), 0);
    }

    function testRevertRelyNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.rely(user1);
    }

    function testRevertDenyNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.deny(ward);
    }

    // --- Kiss / Diss ---

    function testKiss() public {
        address newBud = address(0xC2);
        vm.expectEmit(true, true, true, true);
        emit Kiss(newBud);
        network.kiss(newBud);
        assertEq(network.buds(newBud), 1);
    }

    function testDiss() public {
        vm.expectEmit(true, true, true, true);
        emit Diss(bud);
        network.diss(bud);
        assertEq(network.buds(bud), 0);
    }

    function testRevertKissNotAuthorized() public {
        vm.prank(bud);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.kiss(user1);
    }

    function testRevertDissNotAuthorized() public {
        vm.prank(bud);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.diss(bud);
    }

    // --- AddMember / RemoveMember ---

    function testAddMember() public {
        vm.expectEmit(true, true, true, true);
        emit AddMember(user1);
        vm.prank(bud);
        network.addMember(user1);
        assertTrue(network.isMember(user1));
    }

    function testRemoveMember() public {
        vm.prank(bud);
        network.addMember(user1);

        vm.expectEmit(true, true, true, true);
        emit RemoveMember(user1);
        vm.prank(bud);
        network.removeMember(user1);
        assertFalse(network.isMember(user1));
    }

    function testRevertAddMemberNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addMember(user1);
    }

    function testRevertAddMemberWardNotAuthorized() public {
        vm.prank(ward);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addMember(user1);
    }

    function testRevertRemoveMemberNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.removeMember(user1);
    }

    function testAddMemberIdempotent() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user1);
        vm.stopPrank();
        assertTrue(network.isMember(user1));
        assertEq(network.memberCount(), 1);
    }

    function testRemoveNonMember() public {
        vm.prank(bud);
        network.removeMember(user1);
        assertFalse(network.isMember(user1));
    }

    function testBudCannotAddMemberAfterDiss() public {
        network.diss(bud);

        vm.prank(bud);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addMember(user1);
    }

    // --- Member Batch ---

    function testAddMemberBatch() public {
        address[] memory usrs = new address[](3);
        usrs[0] = user1;
        usrs[1] = user2;
        usrs[2] = user3;

        vm.expectEmit(true, true, true, true);
        emit AddMember(user1);
        vm.expectEmit(true, true, true, true);
        emit AddMember(user2);
        vm.expectEmit(true, true, true, true);
        emit AddMember(user3);

        vm.prank(bud);
        network.addMemberBatch(usrs);

        assertTrue(network.isMember(user1));
        assertTrue(network.isMember(user2));
        assertTrue(network.isMember(user3));
        assertEq(network.memberCount(), 3);
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

        vm.expectEmit(true, true, true, true);
        emit RemoveMember(user1);
        vm.expectEmit(true, true, true, true);
        emit RemoveMember(user3);

        vm.prank(bud);
        network.removeMemberBatch(usrs);

        assertFalse(network.isMember(user1));
        assertTrue(network.isMember(user2));
        assertFalse(network.isMember(user3));
        assertEq(network.memberCount(), 1);
    }

    function testRevertAddMemberBatchNotAuthorized() public {
        address[] memory usrs = new address[](1);
        usrs[0] = user1;
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addMemberBatch(usrs);
    }

    function testRevertRemoveMemberBatchNotAuthorized() public {
        address[] memory usrs = new address[](1);
        usrs[0] = user1;
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.removeMemberBatch(usrs);
    }

    function testAddMemberBatchEmpty() public {
        vm.prank(bud);
        network.addMemberBatch(new address[](0));
    }

    // --- Member Query ---

    function testIsMemberDefault() public view {
        assertFalse(network.isMember(user1));
    }

    function testMemberCount() public {
        assertEq(network.memberCount(), 0);

        vm.startPrank(bud);
        network.addMember(user1);
        assertEq(network.memberCount(), 1);
        network.addMember(user2);
        assertEq(network.memberCount(), 2);
        network.removeMember(user1);
        assertEq(network.memberCount(), 1);
        vm.stopPrank();
    }

    function testMemberAt() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user2);
        vm.stopPrank();

        assertEq(network.memberAt(0), user1);
        assertEq(network.memberAt(1), user2);
    }

    function testGetMembers() public {
        vm.startPrank(bud);
        network.addMember(user1);
        network.addMember(user2);
        network.addMember(user3);
        vm.stopPrank();

        address[] memory members = network.getMembers();
        assertEq(members.length, 3);
        assertEq(members[0], user1);
        assertEq(members[1], user2);
        assertEq(members[2], user3);
    }

    // --- AddSubnet / RemoveSubnet ---

    function testAddSubnet() public {
        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(childA));
        vm.prank(bud);
        network.addSubnet(address(childA));

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

        vm.expectEmit(true, true, true, true);
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

    function testRevertAddSubnetNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addSubnet(address(childA));
    }

    function testRevertAddSubnetWardNotAuthorized() public {
        vm.prank(ward);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addSubnet(address(childA));
    }

    function testRevertRemoveSubnetNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.removeSubnet(address(childA));
    }

    function testBudCannotAddSubnetAfterDiss() public {
        network.diss(bud);

        vm.prank(bud);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addSubnet(address(childA));
    }

    // --- Subnet Batch ---

    function testAddSubnetBatch() public {
        address[] memory subs = new address[](3);
        subs[0] = address(childA);
        subs[1] = address(childB);
        subs[2] = address(childC);

        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(childA));
        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(childB));
        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(childC));

        vm.prank(bud);
        network.addSubnetBatch(subs);

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

        vm.expectEmit(true, true, true, true);
        emit RemoveSubnet(address(childA));
        vm.expectEmit(true, true, true, true);
        emit RemoveSubnet(address(childC));

        network.removeSubnetBatch(subs);
        vm.stopPrank();

        assertFalse(network.isSubnet(address(childA)));
        assertTrue(network.isSubnet(address(childB)));
        assertFalse(network.isSubnet(address(childC)));
        assertEq(network.subnetCount(), 1);
    }

    function testRevertAddSubnetBatchNotAuthorized() public {
        address[] memory subs = new address[](1);
        subs[0] = address(childA);
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.addSubnetBatch(subs);
    }

    function testRevertRemoveSubnetBatchNotAuthorized() public {
        address[] memory subs = new address[](1);
        subs[0] = address(childA);
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-operator");
        network.removeSubnetBatch(subs);
    }

    function testAddSubnetBatchEmpty() public {
        vm.prank(bud);
        network.addSubnetBatch(new address[](0));
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

    // --- isMember (direct + subnets) ---

    function testIsMemberDirectMember() public {
        vm.prank(bud);
        network.addMember(user1);

        assertTrue(network.isMember(user1));
        assertFalse(network.isMember(user2));
    }

    function testIsMemberViaSubnet() public {
        vm.prank(bud);
        network.addSubnet(address(childA));
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

        vm.prank(bud);
        network.removeSubnet(address(childA));

        assertFalse(network.isMember(user1));
    }

    function testIsMemberAfterSubnetMemberRemoval() public {
        vm.prank(bud);
        network.addSubnet(address(childA));
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
