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
import { IdentitySubnet }  from "src/IdentitySubnet.sol";

contract IdentityNetworkTest is Test {

    IdentityNetwork network;
    IdentitySubnet  subnetUS;
    IdentitySubnet  subnetEU;
    IdentitySubnet  subnetInst;

    address ward  = address(0xA1);
    address bud   = address(0xA2);
    address user1 = address(0xB1);
    address user2 = address(0xB2);

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Kiss(address indexed usr);
    event Diss(address indexed usr);
    event AddSubnet(address indexed subnet);
    event RemoveSubnet(address indexed subnet);

    function setUp() public {
        network    = new IdentityNetwork();
        network.rely(ward);
        network.kiss(bud);

        subnetUS   = new IdentitySubnet();
        subnetUS.kiss(address(this));
        subnetEU   = new IdentitySubnet();
        subnetEU.kiss(address(this));
        subnetInst = new IdentitySubnet();
        subnetInst.kiss(address(this));
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

    function testDissNetwork() public {
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

    // --- AddSubnet / RemoveSubnet ---

    function testAddSubnet() public {
        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(subnetUS));
        vm.prank(bud);
        network.addSubnet(address(subnetUS));

        assertEq(network.subnetCount(), 1);
        assertEq(network.isSubnet(address(subnetUS)), 1);
        assertEq(network.subnetAt(0), address(subnetUS));
    }

    function testAddSubnetMultiple() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        network.addSubnet(address(subnetInst));
        vm.stopPrank();

        assertEq(network.subnetCount(), 3);
    }

    function testAddSubnetIdempotent() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetUS));
        vm.stopPrank();

        assertEq(network.subnetCount(), 1);
    }

    function testRemoveSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));

        vm.expectEmit(true, true, true, true);
        emit RemoveSubnet(address(subnetUS));
        network.removeSubnet(address(subnetUS));
        vm.stopPrank();

        assertEq(network.isSubnet(address(subnetUS)), 0);
    }

    function testReAddAfterRemoveSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.removeSubnet(address(subnetUS));
        network.addSubnet(address(subnetUS));
        vm.stopPrank();

        assertEq(network.subnetCount(), 1);
        assertEq(network.isSubnet(address(subnetUS)), 1);
    }

    function testRevertAddSubnetNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.addSubnet(address(subnetUS));
    }

    function testRevertAddSubnetWardNotAuthorized() public {
        vm.prank(ward);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.addSubnet(address(subnetUS));
    }

    function testRevertRemoveSubnetNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.removeSubnet(address(subnetUS));
    }

    function testBudCannotAddAfterDiss() public {
        network.diss(bud);

        vm.prank(bud);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.addSubnet(address(subnetUS));
    }

    // --- Batch ---

    function testAddSubnetBatch() public {
        address[] memory subs = new address[](3);
        subs[0] = address(subnetUS);
        subs[1] = address(subnetEU);
        subs[2] = address(subnetInst);

        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(subnetUS));
        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(subnetEU));
        vm.expectEmit(true, true, true, true);
        emit AddSubnet(address(subnetInst));

        vm.prank(bud);
        network.addSubnetBatch(subs);

        assertEq(network.subnetCount(), 3);
        assertEq(network.isSubnet(address(subnetUS)), 1);
        assertEq(network.isSubnet(address(subnetEU)), 1);
        assertEq(network.isSubnet(address(subnetInst)), 1);
    }

    function testRemoveSubnetBatch() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        network.addSubnet(address(subnetInst));

        address[] memory subs = new address[](2);
        subs[0] = address(subnetUS);
        subs[1] = address(subnetInst);

        vm.expectEmit(true, true, true, true);
        emit RemoveSubnet(address(subnetUS));
        vm.expectEmit(true, true, true, true);
        emit RemoveSubnet(address(subnetInst));

        network.removeSubnetBatch(subs);
        vm.stopPrank();

        assertEq(network.isSubnet(address(subnetUS)), 0);
        assertEq(network.isSubnet(address(subnetEU)), 1);
        assertEq(network.isSubnet(address(subnetInst)), 0);
        assertEq(network.subnetCount(), 1);
    }

    function testRevertAddSubnetBatchNotAuthorized() public {
        address[] memory subs = new address[](1);
        subs[0] = address(subnetUS);
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.addSubnetBatch(subs);
    }

    function testRevertRemoveSubnetBatchNotAuthorized() public {
        address[] memory subs = new address[](1);
        subs[0] = address(subnetUS);
        vm.prank(user1);
        vm.expectRevert("IdentityNetwork/not-authorized");
        network.removeSubnetBatch(subs);
    }

    function testAddSubnetBatchEmpty() public {
        vm.prank(bud);
        network.addSubnetBatch(new address[](0));
    }

    // --- isMember ---

    function testIsMemberSingleSubnet() public {
        vm.prank(bud);
        network.addSubnet(address(subnetUS));
        subnetUS.addMember(user1);

        assertTrue(network.isMember(user1));
        assertFalse(network.isMember(user2));
    }

    function testIsMemberMultipleSubnets() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        vm.stopPrank();

        subnetUS.addMember(user1);
        subnetEU.addMember(user2);

        assertTrue(network.isMember(user1));
        assertTrue(network.isMember(user2));
    }

    function testIsMemberNotInAny() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        vm.stopPrank();

        assertFalse(network.isMember(user1));
    }

    function testIsMemberAfterRemoveSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        vm.stopPrank();

        subnetUS.addMember(user1);
        assertTrue(network.isMember(user1));

        vm.prank(bud);
        network.removeSubnet(address(subnetUS));

        assertFalse(network.isMember(user1));
    }

    function testIsMemberAfterSubnetRemoval() public {
        vm.prank(bud);
        network.addSubnet(address(subnetUS));
        subnetUS.addMember(user1);

        assertTrue(network.isMember(user1));

        subnetUS.removeMember(user1);

        assertFalse(network.isMember(user1));
    }

    function testIsMemberNoSubnets() public view {
        assertFalse(network.isMember(user1));
    }

    function testIsMemberSkipsRemovedSubnet() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        network.removeSubnet(address(subnetUS));
        vm.stopPrank();

        subnetUS.addMember(user1);
        subnetEU.addMember(user2);

        assertFalse(network.isMember(user1));
        assertTrue(network.isMember(user2));
    }

    // --- Query ---

    function testSubnetCount() public {
        assertEq(network.subnetCount(), 0);

        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        assertEq(network.subnetCount(), 1);
        network.addSubnet(address(subnetEU));
        assertEq(network.subnetCount(), 2);
        network.removeSubnet(address(subnetUS));
        assertEq(network.subnetCount(), 1);
        vm.stopPrank();
    }

    function testSubnetAt() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        vm.stopPrank();

        assertEq(network.subnetAt(0), address(subnetUS));
        assertEq(network.subnetAt(1), address(subnetEU));
    }

    function testGetSubnets() public {
        vm.startPrank(bud);
        network.addSubnet(address(subnetUS));
        network.addSubnet(address(subnetEU));
        network.addSubnet(address(subnetInst));
        vm.stopPrank();

        address[] memory subs = network.getSubnets();
        assertEq(subs.length, 3);
        assertEq(subs[0], address(subnetUS));
        assertEq(subs[1], address(subnetEU));
        assertEq(subs[2], address(subnetInst));
    }
}
