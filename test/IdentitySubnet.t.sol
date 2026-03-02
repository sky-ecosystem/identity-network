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
import { IdentitySubnet } from "src/IdentitySubnet.sol";

contract IdentitySubnetTest is Test {

    IdentitySubnet subnet;

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

    function setUp() public {
        subnet = new IdentitySubnet();
        subnet.rely(ward);
        subnet.kiss(bud);
    }

    // --- Auth ---

    function testConstructorSetsDeployer() public view {
        assertEq(subnet.wards(address(this)), 1);
    }

    function testRely() public {
        address newWard = address(0xC1);
        vm.expectEmit(true, true, true, true);
        emit Rely(newWard);
        subnet.rely(newWard);
        assertEq(subnet.wards(newWard), 1);
    }

    function testDeny() public {
        vm.expectEmit(true, true, true, true);
        emit Deny(ward);
        subnet.deny(ward);
        assertEq(subnet.wards(ward), 0);
    }

    function testRevertRelyNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.rely(user1);
    }

    function testRevertDenyNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.deny(ward);
    }

    // --- Kiss / Diss ---

    function testKiss() public {
        address newBud = address(0xC2);
        vm.expectEmit(true, true, true, true);
        emit Kiss(newBud);
        subnet.kiss(newBud);
        assertEq(subnet.buds(newBud), 1);
    }

    function testDissSubnet() public {
        vm.expectEmit(true, true, true, true);
        emit Diss(bud);
        subnet.diss(bud);
        assertEq(subnet.buds(bud), 0);
    }

    function testRevertKissNotAuthorized() public {
        vm.prank(bud);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.kiss(user1);
    }

    function testRevertDissNotAuthorized() public {
        vm.prank(bud);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.diss(bud);
    }

    // --- AddMember / RemoveMember ---

    function testAddMember() public {
        vm.expectEmit(true, true, true, true);
        emit AddMember(user1);
        vm.prank(bud);
        subnet.addMember(user1);
        assertTrue(subnet.isMember(user1));
    }

    function testRemoveMember() public {
        vm.prank(bud);
        subnet.addMember(user1);

        vm.expectEmit(true, true, true, true);
        emit RemoveMember(user1);
        vm.prank(bud);
        subnet.removeMember(user1);
        assertFalse(subnet.isMember(user1));
    }

    function testRevertAddMemberNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.addMember(user1);
    }

    function testRevertAddMemberWardNotAuthorized() public {
        vm.prank(ward);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.addMember(user1);
    }

    function testRevertRemoveMemberNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.removeMember(user1);
    }

    function testAddMemberIdempotent() public {
        vm.startPrank(bud);
        subnet.addMember(user1);
        subnet.addMember(user1);
        vm.stopPrank();
        assertTrue(subnet.isMember(user1));
        assertEq(subnet.memberCount(), 1);
    }

    function testRemoveNonMember() public {
        vm.prank(bud);
        subnet.removeMember(user1);
        assertFalse(subnet.isMember(user1));
    }

    function testBudCannotAddAfterDiss() public {
        subnet.diss(bud);

        vm.prank(bud);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.addMember(user1);
    }

    // --- Batch ---

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
        subnet.addMemberBatch(usrs);

        assertTrue(subnet.isMember(user1));
        assertTrue(subnet.isMember(user2));
        assertTrue(subnet.isMember(user3));
        assertEq(subnet.memberCount(), 3);
    }

    function testRemoveMemberBatch() public {
        vm.startPrank(bud);
        subnet.addMember(user1);
        subnet.addMember(user2);
        subnet.addMember(user3);
        vm.stopPrank();

        address[] memory usrs = new address[](2);
        usrs[0] = user1;
        usrs[1] = user3;

        vm.expectEmit(true, true, true, true);
        emit RemoveMember(user1);
        vm.expectEmit(true, true, true, true);
        emit RemoveMember(user3);

        vm.prank(bud);
        subnet.removeMemberBatch(usrs);

        assertFalse(subnet.isMember(user1));
        assertTrue(subnet.isMember(user2));
        assertFalse(subnet.isMember(user3));
        assertEq(subnet.memberCount(), 1);
    }

    function testRevertAddMemberBatchNotAuthorized() public {
        address[] memory usrs = new address[](1);
        usrs[0] = user1;
        vm.prank(user1);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.addMemberBatch(usrs);
    }

    function testRevertRemoveMemberBatchNotAuthorized() public {
        address[] memory usrs = new address[](1);
        usrs[0] = user1;
        vm.prank(user1);
        vm.expectRevert("IdentitySubnet/not-authorized");
        subnet.removeMemberBatch(usrs);
    }

    function testAddMemberBatchEmpty() public {
        vm.prank(bud);
        subnet.addMemberBatch(new address[](0));
    }

    // --- Query ---

    function testIsMemberDefault() public view {
        assertFalse(subnet.isMember(user1));
    }

    function testMemberCount() public {
        assertEq(subnet.memberCount(), 0);

        vm.startPrank(bud);
        subnet.addMember(user1);
        assertEq(subnet.memberCount(), 1);
        subnet.addMember(user2);
        assertEq(subnet.memberCount(), 2);
        subnet.removeMember(user1);
        assertEq(subnet.memberCount(), 1);
        vm.stopPrank();
    }

    function testMemberAt() public {
        vm.startPrank(bud);
        subnet.addMember(user1);
        subnet.addMember(user2);
        vm.stopPrank();

        assertEq(subnet.memberAt(0), user1);
        assertEq(subnet.memberAt(1), user2);
    }

    function testGetMembers() public {
        vm.startPrank(bud);
        subnet.addMember(user1);
        subnet.addMember(user2);
        subnet.addMember(user3);
        vm.stopPrank();

        address[] memory members = subnet.getMembers();
        assertEq(members.length, 3);
        assertEq(members[0], user1);
        assertEq(members[1], user2);
        assertEq(members[2], user3);
    }
}
