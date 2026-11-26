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
import { IdentityNetworkInit } from "./IdentityNetworkInit.sol";

interface WardsLike {
    function rely(address) external;
    function deny(address) external;
}

struct IdentityNetworkDeployerConfig {
    address   admin;   // ward of the network
    address[] buds;    // operators allowed to manage members and subnets
    address[] members; // initial direct members
    address[] subnets; // initial subnets
}

/// @notice One-time deployer: deploys and initializes an IdentityNetwork in its constructor,
///         hands ownership over to `cfg.admin` and keeps no permissions over it.
contract IdentityNetworkDeployer {
    address public immutable network;

    constructor(IdentityNetworkDeployerConfig memory cfg) {
        require(cfg.admin != address(0),    "IdentityNetworkDeployer/admin-zero-address");
        require(cfg.admin != address(this), "IdentityNetworkDeployer/admin-is-deployer");

        network = address(new IdentityNetwork());

        IdentityNetworkInit.init(network, cfg.buds, cfg.members, cfg.subnets);

        WardsLike(network).rely(cfg.admin);
        WardsLike(network).deny(address(this));
    }
}
