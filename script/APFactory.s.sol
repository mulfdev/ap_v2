// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { APFactory } from "../src/APFactory.sol";
import { Script, console } from "forge-std/Script.sol";

contract APFactoryScript is Script {

    APFactory public apFactory;

    function setUp() public { }

    function run() public {
        vm.startBroadcast();

        apFactory = new APFactory();
        string memory metadata =
            '{"name":"Test NFT #1","description":"A test NFT for the AP1155 contract deployment","image":"https://media.mulf.wtf/testnft-img.png","attributes":[{"trait_type":"Collection","value":"Test Collection"},{"trait_type":"Rarity","value":"Common"}],"external_url":"https://your-website.com","background_color":"000000"}';

        apFactory.deployNew(metadata, 1000);

        vm.stopBroadcast();
    }

}
