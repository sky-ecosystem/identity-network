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
pragma solidity >=0.8.0;

interface IdentityNetworkLike {
    function wards(address) external view returns (uint256);
    function buds(address) external view returns (uint256);
    function kiss(address) external;
    function diss(address) external;
    function addMemberBatch(address[] calldata) external;
    function addSubnetBatch(address[] calldata) external;
}

library IdentityNetworkInit {

    // Expected to be executed by a ward of the network (e.g. the pause proxy within a spell)
    function init(
        address          network_,
        address[] memory buds,
        address[] memory members,
        address[] memory subnets
    ) internal {
        IdentityNetworkLike network = IdentityNetworkLike(network_);

        // --- Sanity checks ---

        require(network.wards(address(this)) == 1, "IdentityNetworkInit/not-authorized");

        // --- Configure buds ---

        for (uint256 i; i < buds.length; i++) {
            network.kiss(buds[i]);
        }

        // --- Configure members and subnets ---

        // Temporarily kiss this contract to be able to add members and subnets,
        // unless it was already configured as a bud
        if (members.length > 0 || subnets.length > 0) {
            bool isBud = network.buds(address(this)) == 1;
            if (!isBud) network.kiss(address(this));
            if (members.length > 0) network.addMemberBatch(members);
            if (subnets.length > 0) network.addSubnetBatch(subnets);
            if (!isBud) network.diss(address(this));
        }
    }
}
