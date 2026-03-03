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

import { IdentityNetwork } from "src/IdentityNetwork.sol";

contract IdentityFactory {

    // --- Events ---
    event CreateNetwork(address indexed network, address indexed admin, address[] buds, address[] members, address[] subnets);

    // --- Factory ---
    function createNetwork(address admin, address[] calldata buds, address[] calldata members, address[] calldata subnets) external returns (address network) {
        IdentityNetwork n = new IdentityNetwork();
        for (uint256 i; i < buds.length;) {
            n.kiss(buds[i]);
            unchecked { ++i; }
        }
        if (members.length > 0 || subnets.length > 0) {
            n.kiss(address(this));
            if (members.length > 0) n.addMemberBatch(members);
            if (subnets.length > 0) n.addSubnetBatch(subnets);
            n.diss(address(this));
        }
        n.rely(admin);
        n.deny(address(this));
        network = address(n);
        emit CreateNetwork(network, admin, buds, members, subnets);
    }
}
