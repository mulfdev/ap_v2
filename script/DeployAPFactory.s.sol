// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { AP1155 } from "../src/AP1155.sol";
import { APFactory } from "../src/APFactory.sol";
import { Script, console } from "forge-std/Script.sol";

contract APFactoryScript is Script {

    APFactory public apFactory;

    function setUp() public { }

    function run() public {
        vm.startBroadcast();
        apFactory = new APFactory(0xcDad9f233dAFC49E81b3aC1Abef7C8ef8334986A);
        vm.stopBroadcast();
    }

}
